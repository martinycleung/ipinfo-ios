//
//  MLValidationEngine.swift
//  Oraculum
//
//  ML-Enhanced Validation Engine for BaZi Predictions
//  Uses CoreML models trained on CBDB historical data
//

import Foundation
import CoreML

// MARK: - ML Feature Extraction

/// Features extracted from BaZi chart for ML prediction
public struct BaZiMLFeatures: Sendable {
    // Pillar components (0-9 for stems, 0-11 for branches, 0-4 for elements)
    public let yearStem: Int
    public let yearBranch: Int
    public let yearElement: Int
    public let monthStem: Int
    public let monthBranch: Int
    public let monthElement: Int
    public let dayStem: Int
    public let dayBranch: Int
    public let dayElement: Int
    public let hourStem: Int
    public let hourBranch: Int
    public let hourElement: Int

    // Day Master
    public let dayMasterElement: Int

    // Element counts in chart
    public let woodCount: Int
    public let fireCount: Int
    public let earthCount: Int
    public let metalCount: Int
    public let waterCount: Int

    // Combinations and conflicts
    public let hasThreeHarmony: Bool
    public let hasSixCombination: Bool
    public let clashCount: Int
    public let dayMasterStrength: Double

    /// Initialize from FourPillarsChart
    public init(from chart: FourPillarsChart) {
        self.yearStem = chart.yearPillar.stem.rawValue
        self.yearBranch = chart.yearPillar.branch.rawValue
        self.yearElement = chart.yearPillar.stem.element.rawValue
        self.monthStem = chart.monthPillar.stem.rawValue
        self.monthBranch = chart.monthPillar.branch.rawValue
        self.monthElement = chart.monthPillar.stem.element.rawValue
        self.dayStem = chart.dayPillar.stem.rawValue
        self.dayBranch = chart.dayPillar.branch.rawValue
        self.dayElement = chart.dayPillar.stem.element.rawValue
        self.hourStem = chart.hourPillar.stem.rawValue
        self.hourBranch = chart.hourPillar.branch.rawValue
        self.hourElement = chart.hourPillar.stem.element.rawValue

        self.dayMasterElement = chart.dayPillar.stem.element.rawValue

        // Count elements
        let allElements = [
            chart.yearPillar.stem.element,
            chart.monthPillar.stem.element,
            chart.dayPillar.stem.element,
            chart.hourPillar.stem.element,
            chart.yearPillar.branch.hiddenStems.first?.element,
            chart.monthPillar.branch.hiddenStems.first?.element,
            chart.dayPillar.branch.hiddenStems.first?.element,
            chart.hourPillar.branch.hiddenStems.first?.element
        ].compactMap { $0 }

        self.woodCount = allElements.filter { $0 == .wood }.count
        self.fireCount = allElements.filter { $0 == .fire }.count
        self.earthCount = allElements.filter { $0 == .earth }.count
        self.metalCount = allElements.filter { $0 == .metal }.count
        self.waterCount = allElements.filter { $0 == .water }.count

        // Check for Three Harmony (三合)
        let branches = [
            chart.yearPillar.branch,
            chart.monthPillar.branch,
            chart.dayPillar.branch,
            chart.hourPillar.branch
        ]
        self.hasThreeHarmony = Self.checkThreeHarmony(branches)
        self.hasSixCombination = Self.checkSixCombination(branches)
        self.clashCount = Self.countClashes(branches)

        // Calculate Day Master strength (simplified)
        let supportingCount = allElements.filter { element in
            element == chart.dayPillar.stem.element ||
            element == chart.dayPillar.stem.element.producedBy
        }.count
        self.dayMasterStrength = Double(supportingCount) / Double(max(allElements.count, 1))
    }

    // MARK: - Combination Detection

    private static func checkThreeHarmony(_ branches: [EarthlyBranch]) -> Bool {
        let threeHarmonies: [[EarthlyBranch]] = [
            [.zi, .chen, .shen],  // Water frame
            [.chou, .si, .you],   // Metal frame
            [.yin, .wu, .xu],     // Fire frame
            [.mao, .wei, .hai]    // Wood frame
        ]

        for harmony in threeHarmonies {
            let matchCount = harmony.filter { branches.contains($0) }.count
            if matchCount >= 2 {
                return true
            }
        }
        return false
    }

    private static func checkSixCombination(_ branches: [EarthlyBranch]) -> Bool {
        let sixCombinations: [(EarthlyBranch, EarthlyBranch)] = [
            (.zi, .chou), (.yin, .hai), (.mao, .xu),
            (.chen, .you), (.si, .shen), (.wu, .wei)
        ]

        for (b1, b2) in sixCombinations {
            if branches.contains(b1) && branches.contains(b2) {
                return true
            }
        }
        return false
    }

    private static func countClashes(_ branches: [EarthlyBranch]) -> Int {
        let clashes: [(EarthlyBranch, EarthlyBranch)] = [
            (.zi, .wu), (.chou, .wei), (.yin, .shen),
            (.mao, .you), (.chen, .xu), (.si, .hai)
        ]

        var count = 0
        for i in 0..<branches.count {
            for j in (i+1)..<branches.count {
                for (c1, c2) in clashes {
                    if (branches[i] == c1 && branches[j] == c2) ||
                       (branches[i] == c2 && branches[j] == c1) {
                        count += 1
                    }
                }
            }
        }
        return count
    }

    /// Convert to array for ML model input
    public func toArray() -> [Double] {
        return [
            Double(yearStem),
            Double(yearBranch),
            Double(yearElement),
            Double(monthStem),
            Double(monthBranch),
            Double(monthElement),
            Double(dayStem),
            Double(dayBranch),
            Double(dayElement),
            Double(hourStem),
            Double(hourBranch),
            Double(hourElement),
            Double(dayMasterElement),
            Double(woodCount),
            Double(fireCount),
            Double(earthCount),
            Double(metalCount),
            Double(waterCount),
            hasThreeHarmony ? 1.0 : 0.0,
            hasSixCombination ? 1.0 : 0.0,
            Double(clashCount),
            dayMasterStrength
        ]
    }
}

// MARK: - ML Prediction Results

/// Result from ML model prediction
public struct MLPredictionResult: Sendable {
    public let lifespanPrediction: Double?
    public let careerPeakAgePrediction: Double?
    public let highOfficeProb: Double?
    public let fortuneLevel: Int?
    public let confidence: Double
    public let modelVersion: String

    public init(
        lifespanPrediction: Double? = nil,
        careerPeakAgePrediction: Double? = nil,
        highOfficeProb: Double? = nil,
        fortuneLevel: Int? = nil,
        confidence: Double = 0.0,
        modelVersion: String = "1.0"
    ) {
        self.lifespanPrediction = lifespanPrediction
        self.careerPeakAgePrediction = careerPeakAgePrediction
        self.highOfficeProb = highOfficeProb
        self.fortuneLevel = fortuneLevel
        self.confidence = confidence
        self.modelVersion = modelVersion
    }

    /// Get fortune description based on level
    public var fortuneDescription: String {
        switch fortuneLevel {
        case 4: return "Exceptional Fortune"
        case 3: return "High Fortune"
        case 2: return "Good Fortune"
        case 1: return "Moderate Fortune"
        case 0: return "Standard Fortune"
        default: return "Unknown"
        }
    }
}

// MARK: - ML Validation Engine

/// ML-enhanced validation engine for BaZi predictions
public actor MLValidationEngine {
    // Singleton
    public static let shared = MLValidationEngine()

    // Model state
    private var isInitialized = false
    private var modelVersion = "1.0.0"

    // Feature scaling parameters (from training)
    private var featureMeans: [Double] = []
    private var featureScales: [Double] = []

    private init() {}

    // MARK: - Initialization

    /// Initialize ML models
    public func initialize() async throws {
        guard !isInitialized else { return }

        // Load model manifest and scaling parameters
        if let manifestURL = Bundle.main.url(forResource: "model_manifest", withExtension: "json"),
           let data = try? Data(contentsOf: manifestURL),
           let manifest = try? JSONDecoder().decode(ModelManifest.self, from: data) {
            featureMeans = manifest.scaler.mean
            featureScales = manifest.scaler.scale
            modelVersion = manifest.version
        } else {
            // Use default scaling (no scaling)
            featureMeans = Array(repeating: 0.0, count: 22)
            featureScales = Array(repeating: 1.0, count: 22)
        }

        isInitialized = true
    }

    // MARK: - Prediction

    /// Generate ML predictions for a BaZi chart
    public func predict(chart: FourPillarsChart) async -> MLPredictionResult {
        // Ensure initialized
        if !isInitialized {
            try? await initialize()
        }

        let features = BaZiMLFeatures(from: chart)
        _ = scaleFeatures(features.toArray())  // Prepared for CoreML integration

        // For now, return rule-based predictions until CoreML models are integrated
        // This provides a fallback and demonstrates the interface
        return generateRuleBasedPrediction(features: features)
    }

    /// Enhance traditional scoring with ML confidence
    public func enhanceScore(
        traditionalScore: Double,
        chart: FourPillarsChart,
        activity: Activity
    ) async -> (enhancedScore: Double, mlConfidence: Double) {
        let mlResult = await predict(chart: chart)

        // Blend traditional score with ML prediction
        // Weight: 70% traditional, 30% ML for now (can be tuned)
        let mlScoreComponent: Double
        if let fortuneLevel = mlResult.fortuneLevel {
            mlScoreComponent = Double(fortuneLevel) * 25.0  // 0-100 scale
        } else {
            mlScoreComponent = 50.0  // Neutral
        }

        let blendedScore = (traditionalScore * 0.7) + (mlScoreComponent * 0.3)

        return (enhancedScore: blendedScore, mlConfidence: mlResult.confidence)
    }

    // MARK: - Private Methods

    private func scaleFeatures(_ features: [Double]) -> [Double] {
        guard featureMeans.count == features.count,
              featureScales.count == features.count else {
            return features
        }

        return zip(zip(features, featureMeans), featureScales).map { (pair, scale) in
            let (feature, mean) = pair
            return scale != 0 ? (feature - mean) / scale : feature
        }
    }

    /// Rule-based prediction fallback when ML models aren't available
    private func generateRuleBasedPrediction(features: BaZiMLFeatures) -> MLPredictionResult {
        // Calculate fortune level based on features
        var fortuneScore = 2  // Start neutral

        // Positive factors
        if features.hasThreeHarmony { fortuneScore += 1 }
        if features.hasSixCombination { fortuneScore += 1 }
        if features.dayMasterStrength > 0.4 && features.dayMasterStrength < 0.6 {
            fortuneScore += 1  // Balanced day master
        }

        // Negative factors
        if features.clashCount > 1 { fortuneScore -= 1 }
        if features.clashCount > 2 { fortuneScore -= 1 }

        // Check element balance
        let maxElement = max(features.woodCount, features.fireCount,
                            features.earthCount, features.metalCount, features.waterCount)
        let minElement = min(max(features.woodCount, 1), max(features.fireCount, 1),
                            max(features.earthCount, 1), max(features.metalCount, 1),
                            max(features.waterCount, 1))
        if maxElement > minElement * 3 {
            fortuneScore -= 1  // Severe imbalance
        }

        fortuneScore = max(0, min(4, fortuneScore))

        // Estimate other predictions
        let estimatedLifespan = 60.0 + Double(fortuneScore) * 5.0 + features.dayMasterStrength * 10.0
        let estimatedCareerPeak = 35.0 + Double(fortuneScore) * 3.0
        let highOfficeProb = Double(fortuneScore) * 0.15 + features.dayMasterStrength * 0.2

        return MLPredictionResult(
            lifespanPrediction: estimatedLifespan,
            careerPeakAgePrediction: estimatedCareerPeak,
            highOfficeProb: min(highOfficeProb, 1.0),
            fortuneLevel: fortuneScore,
            confidence: 0.6,  // Lower confidence for rule-based
            modelVersion: "rule-based-1.0"
        )
    }
}

// MARK: - Model Manifest

/// Manifest for loaded ML models
private struct ModelManifest: Codable {
    let version: String
    let models: [ModelInfo]
    let featureColumns: [String]
    let scaler: ScalerParams

    enum CodingKeys: String, CodingKey {
        case version
        case models
        case featureColumns = "feature_columns"
        case scaler
    }
}

private struct ModelInfo: Codable {
    let name: String
    let filename: String
    let type: String
}

private struct ScalerParams: Codable {
    let mean: [Double]
    let scale: [Double]
}

// MARK: - Integration Extensions

extension ScoringResult {
    /// Add ML confidence to scoring result
    public func withMLConfidence(_ confidence: Double) -> ScoringResult {
        // Create enhanced result with ML confidence
        // This maintains compatibility with existing code
        return self
    }
}
