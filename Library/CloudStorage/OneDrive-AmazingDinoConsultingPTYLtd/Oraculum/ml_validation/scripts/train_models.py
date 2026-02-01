"""
BaZi ML Model Training
Trains XGBoost, Transformer, and Bayesian Network models on CBDB data
"""

import os
import pickle
from pathlib import Path
from typing import Dict, List, Optional, Tuple
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.metrics import (
    mean_absolute_error, mean_squared_error, r2_score,
    f1_score, accuracy_score, classification_report,
    roc_auc_score
)
import xgboost as xgb
from dataclasses import dataclass
import json

# Optional imports with fallbacks
try:
    import torch
    import torch.nn as nn
    from torch.utils.data import DataLoader, TensorDataset
    TORCH_AVAILABLE = True
except ImportError:
    TORCH_AVAILABLE = False
    print("PyTorch not available - skipping Transformer model")

try:
    from pgmpy.models import BayesianNetwork
    from pgmpy.estimators import MaximumLikelihoodEstimator, HillClimbSearch, BicScore
    PGMPY_AVAILABLE = True
except ImportError:
    PGMPY_AVAILABLE = False
    print("pgmpy not available - skipping Bayesian Network model")


@dataclass
class ModelMetrics:
    """Metrics for a trained model"""
    model_type: str
    target: str
    mae: Optional[float] = None  # For regression
    rmse: Optional[float] = None
    r2: Optional[float] = None
    f1: Optional[float] = None  # For classification
    accuracy: Optional[float] = None
    auc: Optional[float] = None
    cv_scores: Optional[List[float]] = None


class BaZiFeatureProcessor:
    """Processes BaZi features for ML models"""

    def __init__(self):
        self.scaler = StandardScaler()
        self.label_encoders = {}
        self.feature_columns = None

    def prepare_features(self, df: pd.DataFrame) -> Tuple[np.ndarray, List[str]]:
        """Prepare feature matrix from DataFrame"""
        # Select numeric feature columns (exclude targets and IDs)
        exclude_cols = ['person_id', 'lifespan', 'career_peak_age',
                       'highest_office_rank', 'office_count', 'social_connections',
                       'death_year']

        feature_cols = [col for col in df.columns
                       if col not in exclude_cols
                       and df[col].dtype in ['int64', 'float64', 'int32', 'float32']]

        self.feature_columns = feature_cols
        X = df[feature_cols].fillna(0).values

        return X, feature_cols

    def fit_transform(self, X: np.ndarray) -> np.ndarray:
        """Fit scaler and transform features"""
        return self.scaler.fit_transform(X)

    def transform(self, X: np.ndarray) -> np.ndarray:
        """Transform features using fitted scaler"""
        return self.scaler.transform(X)

    def save(self, path: Path):
        """Save processor state"""
        state = {
            'scaler_mean': self.scaler.mean_.tolist() if hasattr(self.scaler, 'mean_') else None,
            'scaler_scale': self.scaler.scale_.tolist() if hasattr(self.scaler, 'scale_') else None,
            'feature_columns': self.feature_columns
        }
        with open(path, 'w') as f:
            json.dump(state, f)

    def load(self, path: Path):
        """Load processor state"""
        with open(path, 'r') as f:
            state = json.load(f)
        self.feature_columns = state['feature_columns']
        if state['scaler_mean'] and state['scaler_scale']:
            self.scaler.mean_ = np.array(state['scaler_mean'])
            self.scaler.scale_ = np.array(state['scaler_scale'])


class XGBoostTrainer:
    """Trains XGBoost models for career and longevity prediction"""

    def __init__(self, models_dir: Path):
        self.models_dir = models_dir
        self.models = {}
        self.metrics = {}

    def train_lifespan_model(self, X_train: np.ndarray, y_train: np.ndarray,
                             X_val: np.ndarray, y_val: np.ndarray) -> ModelMetrics:
        """Train model to predict lifespan"""
        # Filter valid lifespan values
        valid_mask_train = ~np.isnan(y_train) & (y_train > 0) & (y_train < 120)
        valid_mask_val = ~np.isnan(y_val) & (y_val > 0) & (y_val < 120)

        X_train_valid = X_train[valid_mask_train]
        y_train_valid = y_train[valid_mask_train]
        X_val_valid = X_val[valid_mask_val]
        y_val_valid = y_val[valid_mask_val]

        if len(y_train_valid) < 100:
            print("Insufficient lifespan data for training")
            return ModelMetrics(model_type="xgboost", target="lifespan")

        model = xgb.XGBRegressor(
            n_estimators=200,
            max_depth=6,
            learning_rate=0.05,
            subsample=0.8,
            colsample_bytree=0.8,
            objective='reg:squarederror',
            random_state=42,
            n_jobs=-1
        )

        model.fit(
            X_train_valid, y_train_valid,
            eval_set=[(X_val_valid, y_val_valid)],
            verbose=False
        )

        # Evaluate
        y_pred = model.predict(X_val_valid)
        mae = mean_absolute_error(y_val_valid, y_pred)
        rmse = np.sqrt(mean_squared_error(y_val_valid, y_pred))
        r2 = r2_score(y_val_valid, y_pred)

        self.models['lifespan'] = model
        metrics = ModelMetrics(
            model_type="xgboost",
            target="lifespan",
            mae=mae,
            rmse=rmse,
            r2=r2
        )
        self.metrics['lifespan'] = metrics

        print(f"Lifespan Model - MAE: {mae:.2f} years, RMSE: {rmse:.2f}, R²: {r2:.3f}")
        return metrics

    def train_career_peak_model(self, X_train: np.ndarray, y_train: np.ndarray,
                                X_val: np.ndarray, y_val: np.ndarray) -> ModelMetrics:
        """Train model to predict career peak age"""
        valid_mask_train = ~np.isnan(y_train) & (y_train > 15) & (y_train < 90)
        valid_mask_val = ~np.isnan(y_val) & (y_val > 15) & (y_val < 90)

        X_train_valid = X_train[valid_mask_train]
        y_train_valid = y_train[valid_mask_train]
        X_val_valid = X_val[valid_mask_val]
        y_val_valid = y_val[valid_mask_val]

        if len(y_train_valid) < 100:
            print("Insufficient career peak data for training")
            return ModelMetrics(model_type="xgboost", target="career_peak")

        model = xgb.XGBRegressor(
            n_estimators=200,
            max_depth=5,
            learning_rate=0.05,
            subsample=0.8,
            colsample_bytree=0.8,
            objective='reg:squarederror',
            random_state=42,
            n_jobs=-1
        )

        model.fit(
            X_train_valid, y_train_valid,
            eval_set=[(X_val_valid, y_val_valid)],
            verbose=False
        )

        y_pred = model.predict(X_val_valid)
        mae = mean_absolute_error(y_val_valid, y_pred)
        rmse = np.sqrt(mean_squared_error(y_val_valid, y_pred))
        r2 = r2_score(y_val_valid, y_pred)

        self.models['career_peak'] = model
        metrics = ModelMetrics(
            model_type="xgboost",
            target="career_peak",
            mae=mae,
            rmse=rmse,
            r2=r2
        )
        self.metrics['career_peak'] = metrics

        print(f"Career Peak Model - MAE: {mae:.2f} years, RMSE: {rmse:.2f}, R²: {r2:.3f}")
        return metrics

    def train_high_office_classifier(self, X_train: np.ndarray, y_train: np.ndarray,
                                     X_val: np.ndarray, y_val: np.ndarray,
                                     threshold: int = 3) -> ModelMetrics:
        """Train binary classifier for high office achievement"""
        # Convert to binary: 1 if rank <= threshold (high office), 0 otherwise
        y_train_binary = (y_train <= threshold).astype(int)
        y_val_binary = (y_val <= threshold).astype(int)

        # Filter valid values
        valid_mask_train = ~np.isnan(y_train)
        valid_mask_val = ~np.isnan(y_val)

        X_train_valid = X_train[valid_mask_train]
        y_train_valid = y_train_binary[valid_mask_train]
        X_val_valid = X_val[valid_mask_val]
        y_val_valid = y_val_binary[valid_mask_val]

        if len(y_train_valid) < 100:
            print("Insufficient office rank data for training")
            return ModelMetrics(model_type="xgboost", target="high_office")

        # Handle class imbalance
        pos_count = y_train_valid.sum()
        neg_count = len(y_train_valid) - pos_count
        scale_pos_weight = neg_count / max(pos_count, 1)

        model = xgb.XGBClassifier(
            n_estimators=200,
            max_depth=5,
            learning_rate=0.05,
            subsample=0.8,
            colsample_bytree=0.8,
            scale_pos_weight=scale_pos_weight,
            objective='binary:logistic',
            random_state=42,
            n_jobs=-1
        )

        model.fit(
            X_train_valid, y_train_valid,
            eval_set=[(X_val_valid, y_val_valid)],
            verbose=False
        )

        y_pred = model.predict(X_val_valid)
        y_pred_proba = model.predict_proba(X_val_valid)[:, 1]

        f1 = f1_score(y_val_valid, y_pred)
        accuracy = accuracy_score(y_val_valid, y_pred)
        auc = roc_auc_score(y_val_valid, y_pred_proba) if len(np.unique(y_val_valid)) > 1 else None

        self.models['high_office'] = model
        metrics = ModelMetrics(
            model_type="xgboost",
            target="high_office",
            f1=f1,
            accuracy=accuracy,
            auc=auc
        )
        self.metrics['high_office'] = metrics

        print(f"High Office Classifier - F1: {f1:.3f}, Accuracy: {accuracy:.3f}, AUC: {auc:.3f if auc else 'N/A'}")
        return metrics

    def save_models(self):
        """Save all trained models"""
        for name, model in self.models.items():
            path = self.models_dir / f"xgboost_{name}.json"
            model.save_model(str(path))
            print(f"Saved {name} model to {path}")


if TORCH_AVAILABLE:
    class TransformerFortuneModel(nn.Module):
        """Transformer model for overall fortune pattern recognition"""

        def __init__(self, input_dim: int, hidden_dim: int = 64,
                     num_heads: int = 4, num_layers: int = 2):
            super().__init__()

            self.input_proj = nn.Linear(input_dim, hidden_dim)

            encoder_layer = nn.TransformerEncoderLayer(
                d_model=hidden_dim,
                nhead=num_heads,
                dim_feedforward=hidden_dim * 4,
                dropout=0.1,
                batch_first=True
            )
            self.transformer = nn.TransformerEncoder(encoder_layer, num_layers=num_layers)

            # Multi-task heads
            self.lifespan_head = nn.Sequential(
                nn.Linear(hidden_dim, 32),
                nn.ReLU(),
                nn.Dropout(0.1),
                nn.Linear(32, 1)
            )

            self.career_head = nn.Sequential(
                nn.Linear(hidden_dim, 32),
                nn.ReLU(),
                nn.Dropout(0.1),
                nn.Linear(32, 1)
            )

            self.fortune_head = nn.Sequential(
                nn.Linear(hidden_dim, 32),
                nn.ReLU(),
                nn.Dropout(0.1),
                nn.Linear(32, 5)  # 5 fortune levels
            )

        def forward(self, x: torch.Tensor) -> Tuple[torch.Tensor, torch.Tensor, torch.Tensor]:
            # Project input to hidden dimension
            x = self.input_proj(x)

            # Add sequence dimension if needed
            if x.dim() == 2:
                x = x.unsqueeze(1)

            # Transformer encoding
            x = self.transformer(x)

            # Pool across sequence dimension
            x = x.mean(dim=1)

            lifespan = self.lifespan_head(x)
            career = self.career_head(x)
            fortune = self.fortune_head(x)

            return lifespan, career, fortune


    class TransformerTrainer:
        """Trains Transformer model for fortune patterns"""

        def __init__(self, models_dir: Path, device: str = 'cpu'):
            self.models_dir = models_dir
            self.device = device
            self.model = None
            self.metrics = {}

        def train(self, X_train: np.ndarray, y_train_dict: Dict[str, np.ndarray],
                  X_val: np.ndarray, y_val_dict: Dict[str, np.ndarray],
                  epochs: int = 50, batch_size: int = 64) -> Dict[str, ModelMetrics]:
            """Train transformer model"""
            input_dim = X_train.shape[1]
            self.model = TransformerFortuneModel(input_dim).to(self.device)

            # Prepare data
            X_train_t = torch.FloatTensor(X_train).to(self.device)
            X_val_t = torch.FloatTensor(X_val).to(self.device)

            lifespan_train = torch.FloatTensor(
                np.nan_to_num(y_train_dict['lifespan'], nan=60.0)
            ).unsqueeze(1).to(self.device)
            lifespan_val = torch.FloatTensor(
                np.nan_to_num(y_val_dict['lifespan'], nan=60.0)
            ).unsqueeze(1).to(self.device)

            career_train = torch.FloatTensor(
                np.nan_to_num(y_train_dict['career_peak'], nan=40.0)
            ).unsqueeze(1).to(self.device)
            career_val = torch.FloatTensor(
                np.nan_to_num(y_val_dict['career_peak'], nan=40.0)
            ).unsqueeze(1).to(self.device)

            # Create fortune labels from office count (binned)
            fortune_train = self._create_fortune_labels(y_train_dict['office_count'])
            fortune_val = self._create_fortune_labels(y_val_dict['office_count'])
            fortune_train_t = torch.LongTensor(fortune_train).to(self.device)
            fortune_val_t = torch.LongTensor(fortune_val).to(self.device)

            # Create DataLoader
            train_dataset = TensorDataset(X_train_t, lifespan_train, career_train, fortune_train_t)
            train_loader = DataLoader(train_dataset, batch_size=batch_size, shuffle=True)

            optimizer = torch.optim.Adam(self.model.parameters(), lr=0.001)
            mse_loss = nn.MSELoss()
            ce_loss = nn.CrossEntropyLoss()

            best_val_loss = float('inf')
            patience = 10
            patience_counter = 0

            for epoch in range(epochs):
                self.model.train()
                total_loss = 0

                for batch_x, batch_life, batch_career, batch_fortune in train_loader:
                    optimizer.zero_grad()

                    life_pred, career_pred, fortune_pred = self.model(batch_x)

                    loss = (mse_loss(life_pred, batch_life) +
                           mse_loss(career_pred, batch_career) +
                           ce_loss(fortune_pred, batch_fortune))

                    loss.backward()
                    optimizer.step()
                    total_loss += loss.item()

                # Validation
                self.model.eval()
                with torch.no_grad():
                    life_pred, career_pred, fortune_pred = self.model(X_val_t)
                    val_loss = (mse_loss(life_pred, lifespan_val) +
                               mse_loss(career_pred, career_val) +
                               ce_loss(fortune_pred, fortune_val_t))

                if val_loss < best_val_loss:
                    best_val_loss = val_loss
                    patience_counter = 0
                    # Save best model
                    torch.save(self.model.state_dict(),
                              self.models_dir / "transformer_fortune.pt")
                else:
                    patience_counter += 1
                    if patience_counter >= patience:
                        print(f"Early stopping at epoch {epoch}")
                        break

                if epoch % 10 == 0:
                    print(f"Epoch {epoch}: Train Loss = {total_loss/len(train_loader):.4f}, Val Loss = {val_loss:.4f}")

            # Calculate final metrics
            self.model.eval()
            with torch.no_grad():
                life_pred, career_pred, fortune_pred = self.model(X_val_t)

                life_pred_np = life_pred.cpu().numpy().flatten()
                career_pred_np = career_pred.cpu().numpy().flatten()
                fortune_pred_np = fortune_pred.argmax(dim=1).cpu().numpy()

                # Only evaluate on valid values
                life_mask = ~np.isnan(y_val_dict['lifespan'])
                career_mask = ~np.isnan(y_val_dict['career_peak'])

                metrics = {}

                if life_mask.sum() > 0:
                    life_mae = mean_absolute_error(y_val_dict['lifespan'][life_mask],
                                                   life_pred_np[life_mask])
                    metrics['lifespan'] = ModelMetrics(
                        model_type="transformer",
                        target="lifespan",
                        mae=life_mae
                    )
                    print(f"Transformer Lifespan MAE: {life_mae:.2f} years")

                if career_mask.sum() > 0:
                    career_mae = mean_absolute_error(y_val_dict['career_peak'][career_mask],
                                                     career_pred_np[career_mask])
                    metrics['career_peak'] = ModelMetrics(
                        model_type="transformer",
                        target="career_peak",
                        mae=career_mae
                    )
                    print(f"Transformer Career Peak MAE: {career_mae:.2f} years")

                fortune_acc = accuracy_score(fortune_val, fortune_pred_np)
                metrics['fortune'] = ModelMetrics(
                    model_type="transformer",
                    target="fortune",
                    accuracy=fortune_acc
                )
                print(f"Transformer Fortune Accuracy: {fortune_acc:.3f}")

            self.metrics = metrics
            return metrics

        def _create_fortune_labels(self, office_count: np.ndarray) -> np.ndarray:
            """Convert office count to fortune level (0-4)"""
            labels = np.zeros(len(office_count), dtype=int)
            labels[office_count >= 1] = 1
            labels[office_count >= 3] = 2
            labels[office_count >= 6] = 3
            labels[office_count >= 10] = 4
            return labels

        def save_for_coreml(self):
            """Export model for CoreML conversion"""
            if self.model is None:
                return

            # Save model architecture info
            info = {
                'input_dim': self.model.input_proj.in_features,
                'hidden_dim': self.model.input_proj.out_features,
            }
            with open(self.models_dir / "transformer_info.json", 'w') as f:
                json.dump(info, f)


if PGMPY_AVAILABLE:
    class BayesianNetworkTrainer:
        """Trains Bayesian Network for causal inference and timing"""

        def __init__(self, models_dir: Path):
            self.models_dir = models_dir
            self.model = None
            self.metrics = {}

        def train(self, df: pd.DataFrame) -> ModelMetrics:
            """Train Bayesian Network on discretized features"""
            # Prepare discretized data
            bn_df = self._prepare_data(df)

            # Structure learning
            print("Learning Bayesian Network structure...")
            hc = HillClimbSearch(bn_df)
            best_model = hc.estimate(scoring_method=BicScore(bn_df), max_iter=50)

            print(f"Learned structure with {len(best_model.edges())} edges")

            # Create and fit model
            self.model = BayesianNetwork(best_model.edges())
            self.model.fit(bn_df, estimator=MaximumLikelihoodEstimator)

            # Save model
            with open(self.models_dir / "bayesian_network.pkl", 'wb') as f:
                pickle.dump(self.model, f)

            print("Bayesian Network trained and saved")

            return ModelMetrics(model_type="bayesian", target="timing")

        def _prepare_data(self, df: pd.DataFrame) -> pd.DataFrame:
            """Prepare discretized data for Bayesian Network"""
            bn_df = pd.DataFrame()

            # Discretize key features
            if 'day_master_element' in df.columns:
                bn_df['day_master'] = df['day_master_element'].astype(int)

            if 'wood_count' in df.columns:
                bn_df['element_balance'] = (
                    (df['wood_count'] + df['fire_count'] >
                     df['metal_count'] + df['water_count']).astype(int)
                )

            if 'clash_count' in df.columns:
                bn_df['has_clash'] = (df['clash_count'] > 0).astype(int)

            if 'lifespan' in df.columns:
                bn_df['long_life'] = (df['lifespan'] > 60).astype(int)

            if 'office_count' in df.columns:
                bn_df['high_career'] = (df['office_count'] > 3).astype(int)

            if 'career_peak_age' in df.columns:
                bn_df['early_peak'] = (df['career_peak_age'] < 40).astype(int)

            # Remove rows with NaN
            bn_df = bn_df.dropna()

            return bn_df


class MLTrainingPipeline:
    """Main training pipeline orchestrating all models"""

    def __init__(self, data_dir: str = "../data", models_dir: str = "../models"):
        self.data_dir = Path(data_dir)
        self.models_dir = Path(models_dir)
        self.models_dir.mkdir(parents=True, exist_ok=True)

        self.processor = BaZiFeatureProcessor()
        self.xgb_trainer = XGBoostTrainer(self.models_dir)

        if TORCH_AVAILABLE:
            self.transformer_trainer = TransformerTrainer(self.models_dir)
        else:
            self.transformer_trainer = None

        if PGMPY_AVAILABLE:
            self.bn_trainer = BayesianNetworkTrainer(self.models_dir)
        else:
            self.bn_trainer = None

    def load_data(self, filename: str = "training_data.parquet") -> pd.DataFrame:
        """Load training data"""
        path = self.data_dir / filename
        if not path.exists():
            raise FileNotFoundError(f"Training data not found at {path}. Run cbdb_pipeline.py first.")
        return pd.read_parquet(path)

    def train_all(self, df: Optional[pd.DataFrame] = None) -> Dict[str, ModelMetrics]:
        """Train all models"""
        if df is None:
            df = self.load_data()

        print(f"Training with {len(df)} records")

        # Prepare features
        X, feature_cols = self.processor.prepare_features(df)
        X_scaled = self.processor.fit_transform(X)

        # Prepare targets
        y_lifespan = df['lifespan'].values
        y_career_peak = df['career_peak_age'].values
        y_office_rank = df['highest_office_rank'].values
        y_office_count = df['office_count'].values

        # Split data
        X_train, X_val, idx_train, idx_val = train_test_split(
            X_scaled, np.arange(len(X_scaled)), test_size=0.2, random_state=42
        )

        y_train_dict = {
            'lifespan': y_lifespan[idx_train],
            'career_peak': y_career_peak[idx_train],
            'office_rank': y_office_rank[idx_train],
            'office_count': y_office_count[idx_train]
        }

        y_val_dict = {
            'lifespan': y_lifespan[idx_val],
            'career_peak': y_career_peak[idx_val],
            'office_rank': y_office_rank[idx_val],
            'office_count': y_office_count[idx_val]
        }

        all_metrics = {}

        # Train XGBoost models
        print("\n=== Training XGBoost Models ===")
        metrics = self.xgb_trainer.train_lifespan_model(
            X_train, y_train_dict['lifespan'],
            X_val, y_val_dict['lifespan']
        )
        all_metrics['xgb_lifespan'] = metrics

        metrics = self.xgb_trainer.train_career_peak_model(
            X_train, y_train_dict['career_peak'],
            X_val, y_val_dict['career_peak']
        )
        all_metrics['xgb_career_peak'] = metrics

        metrics = self.xgb_trainer.train_high_office_classifier(
            X_train, y_train_dict['office_rank'],
            X_val, y_val_dict['office_rank']
        )
        all_metrics['xgb_high_office'] = metrics

        self.xgb_trainer.save_models()

        # Train Transformer
        if self.transformer_trainer:
            print("\n=== Training Transformer Model ===")
            transformer_metrics = self.transformer_trainer.train(
                X_train, y_train_dict,
                X_val, y_val_dict
            )
            all_metrics.update({f'transformer_{k}': v for k, v in transformer_metrics.items()})
            self.transformer_trainer.save_for_coreml()

        # Train Bayesian Network
        if self.bn_trainer:
            print("\n=== Training Bayesian Network ===")
            bn_metrics = self.bn_trainer.train(df)
            all_metrics['bayesian'] = bn_metrics

        # Save processor
        self.processor.save(self.models_dir / "feature_processor.json")

        # Save all metrics
        metrics_dict = {k: vars(v) for k, v in all_metrics.items()}
        with open(self.models_dir / "training_metrics.json", 'w') as f:
            json.dump(metrics_dict, f, indent=2, default=str)

        print("\n=== Training Complete ===")
        print(f"Models saved to {self.models_dir}")

        return all_metrics


def main():
    """Main training execution"""
    pipeline = MLTrainingPipeline()

    try:
        metrics = pipeline.train_all()

        print("\n=== Final Metrics Summary ===")
        for name, m in metrics.items():
            if m.mae is not None:
                print(f"{name}: MAE={m.mae:.2f}")
            if m.f1 is not None:
                print(f"{name}: F1={m.f1:.3f}, Accuracy={m.accuracy:.3f}")

    except FileNotFoundError as e:
        print(f"Error: {e}")
        print("Please run cbdb_pipeline.py first to generate training data.")


if __name__ == "__main__":
    main()
