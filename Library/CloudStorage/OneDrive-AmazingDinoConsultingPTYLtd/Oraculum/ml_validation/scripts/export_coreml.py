"""
CoreML Export Script
Converts trained models to CoreML format for iOS deployment
"""

import json
from pathlib import Path
from typing import Dict, List, Optional
import numpy as np

try:
    import coremltools as ct
    from coremltools.models.neural_network import quantization_utils
    COREML_AVAILABLE = True
except ImportError:
    COREML_AVAILABLE = False
    print("coremltools not available - install with: pip install coremltools")

try:
    import xgboost as xgb
    XGBOOST_AVAILABLE = True
except ImportError:
    XGBOOST_AVAILABLE = False

try:
    import torch
    TORCH_AVAILABLE = True
except ImportError:
    TORCH_AVAILABLE = False


class CoreMLExporter:
    """Exports trained models to CoreML format"""

    def __init__(self, models_dir: str = "../models", exports_dir: str = "../exports"):
        self.models_dir = Path(models_dir)
        self.exports_dir = Path(exports_dir)
        self.exports_dir.mkdir(parents=True, exist_ok=True)

        # Load feature info
        processor_path = self.models_dir / "feature_processor.json"
        if processor_path.exists():
            with open(processor_path, 'r') as f:
                self.feature_info = json.load(f)
        else:
            self.feature_info = None

    def export_xgboost_models(self) -> List[str]:
        """Export XGBoost models to CoreML"""
        if not COREML_AVAILABLE or not XGBOOST_AVAILABLE:
            print("Missing dependencies for XGBoost CoreML export")
            return []

        exported = []

        model_configs = [
            ('xgboost_lifespan.json', 'BaZiLifespanPredictor', 'regression'),
            ('xgboost_career_peak.json', 'BaZiCareerPeakPredictor', 'regression'),
            ('xgboost_high_office.json', 'BaZiHighOfficeClassifier', 'classification'),
        ]

        for filename, output_name, mode in model_configs:
            model_path = self.models_dir / filename
            if not model_path.exists():
                print(f"Model not found: {model_path}")
                continue

            try:
                # Load XGBoost model
                model = xgb.Booster()
                model.load_model(str(model_path))

                # Get feature names
                feature_names = self.feature_info.get('feature_columns', []) if self.feature_info else None
                if not feature_names:
                    # Generate default feature names
                    feature_names = [f"feature_{i}" for i in range(30)]

                # Convert to CoreML
                if mode == 'classification':
                    coreml_model = ct.converters.xgboost.convert(
                        model,
                        feature_names=feature_names,
                        mode='classifier'
                    )
                else:
                    coreml_model = ct.converters.xgboost.convert(
                        model,
                        feature_names=feature_names,
                        mode='regressor'
                    )

                # Set metadata
                coreml_model.author = "Oraculum BaZi ML"
                coreml_model.short_description = f"BaZi {output_name} - predicts {mode} outcomes"
                coreml_model.version = "1.0"

                # Add input/output descriptions
                if mode == 'regression':
                    coreml_model.output_description['prediction'] = "Predicted value"
                else:
                    coreml_model.output_description['prediction'] = "Predicted class"
                    if 'classProbability' in coreml_model.output_description:
                        coreml_model.output_description['classProbability'] = "Class probabilities"

                # Save
                output_path = self.exports_dir / f"{output_name}.mlmodel"
                coreml_model.save(str(output_path))
                exported.append(str(output_path))
                print(f"Exported: {output_path}")

            except Exception as e:
                print(f"Error exporting {filename}: {e}")

        return exported

    def export_ensemble_model(self) -> Optional[str]:
        """Create and export ensemble predictor combining all models"""
        if not COREML_AVAILABLE:
            print("coremltools not available")
            return None

        try:
            # Create a simple ensemble pipeline model
            # This model will be used to combine predictions from individual models

            feature_names = self.feature_info.get('feature_columns', []) if self.feature_info else None
            if not feature_names:
                feature_names = [f"feature_{i}" for i in range(30)]

            # Define input features
            input_features = [(name, ct.models.datatypes.Double()) for name in feature_names]

            # Create neural network for ensemble combination
            builder = ct.models.neural_network.NeuralNetworkBuilder(
                input_features,
                [('ensemble_score', ct.models.datatypes.Double())],
                mode=None
            )

            # Simple weighted combination layer
            # In practice, this would combine outputs from the individual models
            num_features = len(feature_names)

            # Add a simple dense layer that learns to weight features
            weights = np.random.randn(1, num_features) * 0.01
            bias = np.array([50.0])  # Start with neutral score

            builder.add_inner_product(
                name='ensemble_combine',
                W=weights.T,
                b=bias,
                input_channels=num_features,
                output_channels=1,
                has_bias=True,
                input_name=feature_names[0],  # Will need proper input handling
                output_name='raw_score'
            )

            # Clamp output to 0-100 range
            builder.add_clip(
                name='score_clip',
                input_name='raw_score',
                output_name='ensemble_score',
                min_value=0.0,
                max_value=100.0
            )

            # Build and save
            mlmodel = builder.spec
            model = ct.models.MLModel(mlmodel)

            model.author = "Oraculum BaZi ML"
            model.short_description = "BaZi Ensemble Score Predictor"
            model.version = "1.0"

            output_path = self.exports_dir / "BaZiEnsemblePredictor.mlmodel"
            model.save(str(output_path))
            print(f"Exported ensemble model: {output_path}")

            return str(output_path)

        except Exception as e:
            print(f"Error creating ensemble model: {e}")
            return None

    def create_model_manifest(self) -> Dict:
        """Create manifest of exported models for iOS app"""
        manifest = {
            'version': '1.0',
            'models': [],
            'feature_columns': self.feature_info.get('feature_columns', []) if self.feature_info else [],
            'scaler': {
                'mean': self.feature_info.get('scaler_mean', []) if self.feature_info else [],
                'scale': self.feature_info.get('scaler_scale', []) if self.feature_info else []
            }
        }

        # List exported models
        for mlmodel in self.exports_dir.glob("*.mlmodel"):
            model_info = {
                'name': mlmodel.stem,
                'filename': mlmodel.name,
                'type': 'classifier' if 'Classifier' in mlmodel.stem else 'regressor'
            }
            manifest['models'].append(model_info)

        # Save manifest
        manifest_path = self.exports_dir / "model_manifest.json"
        with open(manifest_path, 'w') as f:
            json.dump(manifest, f, indent=2)

        print(f"Created manifest: {manifest_path}")
        return manifest

    def export_all(self) -> Dict:
        """Export all models and create manifest"""
        results = {
            'xgboost': [],
            'ensemble': None,
            'manifest': None
        }

        print("=== Exporting XGBoost Models ===")
        results['xgboost'] = self.export_xgboost_models()

        print("\n=== Creating Ensemble Model ===")
        results['ensemble'] = self.export_ensemble_model()

        print("\n=== Creating Manifest ===")
        results['manifest'] = self.create_model_manifest()

        return results


def create_swift_feature_extractor():
    """Generate Swift code for feature extraction matching Python implementation"""

    swift_code = '''
// Auto-generated BaZi Feature Extractor for CoreML
// Generated by export_coreml.py

import Foundation
import CoreML

/// Feature extraction matching Python BaZiFeatureExtractor
struct BaZiMLFeatures {
    // Pillar components
    var yearStem: Int
    var yearBranch: Int
    var yearElement: Int
    var monthStem: Int
    var monthBranch: Int
    var monthElement: Int
    var dayStem: Int
    var dayBranch: Int
    var dayElement: Int
    var hourStem: Int
    var hourBranch: Int
    var hourElement: Int

    // Day Master
    var dayMasterElement: Int

    // Element counts
    var woodCount: Int
    var fireCount: Int
    var earthCount: Int
    var metalCount: Int
    var waterCount: Int

    // Combinations and conflicts
    var hasThreeHarmony: Bool
    var hasSixCombination: Bool
    var clashCount: Int
    var dayMasterStrength: Double

    /// Convert to MLMultiArray for CoreML input
    func toMLMultiArray() throws -> MLMultiArray {
        let features = try MLMultiArray(shape: [30], dataType: .double)

        features[0] = NSNumber(value: yearStem)
        features[1] = NSNumber(value: yearBranch)
        features[2] = NSNumber(value: yearElement)
        features[3] = NSNumber(value: monthStem)
        features[4] = NSNumber(value: monthBranch)
        features[5] = NSNumber(value: monthElement)
        features[6] = NSNumber(value: dayStem)
        features[7] = NSNumber(value: dayBranch)
        features[8] = NSNumber(value: dayElement)
        features[9] = NSNumber(value: hourStem)
        features[10] = NSNumber(value: hourBranch)
        features[11] = NSNumber(value: hourElement)
        features[12] = NSNumber(value: dayMasterElement)
        features[13] = NSNumber(value: woodCount)
        features[14] = NSNumber(value: fireCount)
        features[15] = NSNumber(value: earthCount)
        features[16] = NSNumber(value: metalCount)
        features[17] = NSNumber(value: waterCount)
        features[18] = NSNumber(value: hasThreeHarmony ? 1 : 0)
        features[19] = NSNumber(value: hasSixCombination ? 1 : 0)
        features[20] = NSNumber(value: clashCount)
        features[21] = NSNumber(value: dayMasterStrength)

        // Padding for remaining features
        for i in 22..<30 {
            features[i] = NSNumber(value: 0.0)
        }

        return features
    }
}
'''
    return swift_code


def main():
    """Main export execution"""
    if not COREML_AVAILABLE:
        print("Error: coremltools is required for CoreML export")
        print("Install with: pip install coremltools")
        return

    exporter = CoreMLExporter()
    results = exporter.export_all()

    print("\n=== Export Summary ===")
    print(f"XGBoost models: {len(results['xgboost'])}")
    print(f"Ensemble model: {'Yes' if results['ensemble'] else 'No'}")
    print(f"Manifest: {'Created' if results['manifest'] else 'Failed'}")

    # Generate Swift code
    print("\n=== Generating Swift Feature Extractor ===")
    swift_code = create_swift_feature_extractor()
    swift_path = Path("../exports/BaZiMLFeatures.swift")
    swift_path.parent.mkdir(parents=True, exist_ok=True)
    with open(swift_path, 'w') as f:
        f.write(swift_code)
    print(f"Generated: {swift_path}")


if __name__ == "__main__":
    main()
