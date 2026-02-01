//
//  MLValidationEngineTests.swift
//  OraculumTests
//
//  Unit tests for ML Validation Engine
//

import XCTest
@testable import OraculumCore

final class MLValidationEngineTests: XCTestCase {

    // MARK: - Feature Extraction Tests

    func testFeatureExtractionFromChart() {
        // Create a test chart
        let chart = FourPillarsChart(
            yearPillar: Pillar(stem: .jia, branch: .zi),
            monthPillar: Pillar(stem: .bing, branch: .yin),
            dayPillar: Pillar(stem: .wu, branch: .wu),
            hourPillar: Pillar(stem: .geng, branch: .shen)
        )

        let features = BaZiMLFeatures(from: chart)

        // Test stem values (0-indexed)
        XCTAssertEqual(features.yearStem, HeavenlyStem.jia.rawValue)
        XCTAssertEqual(features.monthStem, HeavenlyStem.bing.rawValue)
        XCTAssertEqual(features.dayStem, HeavenlyStem.wu.rawValue)
        XCTAssertEqual(features.hourStem, HeavenlyStem.geng.rawValue)

        // Test branch values (0-indexed)
        XCTAssertEqual(features.yearBranch, EarthlyBranch.zi.rawValue)
        XCTAssertEqual(features.monthBranch, EarthlyBranch.yin.rawValue)
        XCTAssertEqual(features.dayBranch, EarthlyBranch.wu.rawValue)
        XCTAssertEqual(features.hourBranch, EarthlyBranch.shen.rawValue)

        // Test Day Master element (Wu is Earth)
        XCTAssertEqual(features.dayMasterElement, FiveElement.earth.rawValue)
    }

    func testThreeHarmonyDetection() {
        // Chart with Zi, Chen, Shen (Water frame 三合)
        let chart = FourPillarsChart(
            yearPillar: Pillar(stem: .jia, branch: .zi),
            monthPillar: Pillar(stem: .bing, branch: .chen),
            dayPillar: Pillar(stem: .wu, branch: .shen),
            hourPillar: Pillar(stem: .geng, branch: .wu)
        )

        let features = BaZiMLFeatures(from: chart)
        XCTAssertTrue(features.hasThreeHarmony, "Should detect Water frame 三合")
    }

    func testNoThreeHarmonyDetection() {
        // Chart without 三合
        let chart = FourPillarsChart(
            yearPillar: Pillar(stem: .jia, branch: .zi),
            monthPillar: Pillar(stem: .bing, branch: .chou),
            dayPillar: Pillar(stem: .wu, branch: .yin),
            hourPillar: Pillar(stem: .geng, branch: .mao)
        )

        let features = BaZiMLFeatures(from: chart)
        XCTAssertFalse(features.hasThreeHarmony, "Should not detect 三合")
    }

    func testSixCombinationDetection() {
        // Chart with Zi-Chou combination (六合)
        let chart = FourPillarsChart(
            yearPillar: Pillar(stem: .jia, branch: .zi),
            monthPillar: Pillar(stem: .bing, branch: .chou),
            dayPillar: Pillar(stem: .wu, branch: .wu),
            hourPillar: Pillar(stem: .geng, branch: .shen)
        )

        let features = BaZiMLFeatures(from: chart)
        XCTAssertTrue(features.hasSixCombination, "Should detect Zi-Chou 六合")
    }

    func testClashCount() {
        // Chart with only Zi-Wu clash (avoid other clashing branches)
        let chart = FourPillarsChart(
            yearPillar: Pillar(stem: .jia, branch: .zi),
            monthPillar: Pillar(stem: .bing, branch: .chou),  // Chou doesn't clash with others here
            dayPillar: Pillar(stem: .wu, branch: .wu),
            hourPillar: Pillar(stem: .geng, branch: .yin)     // Yin doesn't clash with others here
        )

        let features = BaZiMLFeatures(from: chart)
        XCTAssertEqual(features.clashCount, 1, "Should detect one clash (Zi-Wu)")
    }

    func testMultipleClashes() {
        // Chart with multiple clashes: Zi-Wu and Yin-Shen
        let chart = FourPillarsChart(
            yearPillar: Pillar(stem: .jia, branch: .zi),
            monthPillar: Pillar(stem: .bing, branch: .yin),
            dayPillar: Pillar(stem: .wu, branch: .wu),
            hourPillar: Pillar(stem: .geng, branch: .shen)
        )

        let features = BaZiMLFeatures(from: chart)
        XCTAssertEqual(features.clashCount, 2, "Should detect two clashes (Zi-Wu and Yin-Shen)")
    }

    func testElementCounts() {
        // Create chart and verify element counting
        let chart = FourPillarsChart(
            yearPillar: Pillar(stem: .jia, branch: .zi),   // Wood stem, Water branch
            monthPillar: Pillar(stem: .bing, branch: .yin), // Fire stem, Wood branch
            dayPillar: Pillar(stem: .wu, branch: .wu),      // Earth stem, Fire branch
            hourPillar: Pillar(stem: .geng, branch: .shen)  // Metal stem, Metal branch
        )

        let features = BaZiMLFeatures(from: chart)

        // Verify element counts are reasonable (exact values depend on hidden stems logic)
        XCTAssertGreaterThanOrEqual(features.woodCount, 1, "Should count at least 1 Wood")
        XCTAssertGreaterThanOrEqual(features.fireCount, 1, "Should count at least 1 Fire")
        XCTAssertGreaterThanOrEqual(features.earthCount, 1, "Should count at least 1 Earth")
        XCTAssertGreaterThanOrEqual(features.metalCount, 1, "Should count at least 1 Metal")
    }

    func testFeatureArrayLength() {
        let chart = FourPillarsChart(
            yearPillar: Pillar(stem: .jia, branch: .zi),
            monthPillar: Pillar(stem: .bing, branch: .yin),
            dayPillar: Pillar(stem: .wu, branch: .wu),
            hourPillar: Pillar(stem: .geng, branch: .shen)
        )

        let features = BaZiMLFeatures(from: chart)
        let array = features.toArray()

        XCTAssertEqual(array.count, 22, "Feature array should have 22 elements")
    }

    func testDayMasterStrengthRange() {
        let chart = FourPillarsChart(
            yearPillar: Pillar(stem: .jia, branch: .zi),
            monthPillar: Pillar(stem: .bing, branch: .yin),
            dayPillar: Pillar(stem: .wu, branch: .wu),
            hourPillar: Pillar(stem: .geng, branch: .shen)
        )

        let features = BaZiMLFeatures(from: chart)

        XCTAssertGreaterThanOrEqual(features.dayMasterStrength, 0.0, "Strength should be >= 0")
        XCTAssertLessThanOrEqual(features.dayMasterStrength, 1.0, "Strength should be <= 1")
    }

    // MARK: - ML Prediction Tests

    func testMLPredictionResult() {
        let result = MLPredictionResult(
            lifespanPrediction: 75.0,
            careerPeakAgePrediction: 45.0,
            highOfficeProb: 0.6,
            fortuneLevel: 3,
            confidence: 0.85,
            modelVersion: "1.0"
        )

        XCTAssertEqual(result.lifespanPrediction, 75.0)
        XCTAssertEqual(result.careerPeakAgePrediction, 45.0)
        XCTAssertEqual(result.highOfficeProb, 0.6)
        XCTAssertEqual(result.fortuneLevel, 3)
        XCTAssertEqual(result.confidence, 0.85)
        XCTAssertEqual(result.fortuneDescription, "High Fortune")
    }

    func testFortuneDescriptions() {
        XCTAssertEqual(MLPredictionResult(fortuneLevel: 4).fortuneDescription, "Exceptional Fortune")
        XCTAssertEqual(MLPredictionResult(fortuneLevel: 3).fortuneDescription, "High Fortune")
        XCTAssertEqual(MLPredictionResult(fortuneLevel: 2).fortuneDescription, "Good Fortune")
        XCTAssertEqual(MLPredictionResult(fortuneLevel: 1).fortuneDescription, "Moderate Fortune")
        XCTAssertEqual(MLPredictionResult(fortuneLevel: 0).fortuneDescription, "Standard Fortune")
        XCTAssertEqual(MLPredictionResult(fortuneLevel: nil).fortuneDescription, "Unknown")
    }

    // MARK: - Integration Tests

    func testMLValidationEngineInitialization() async {
        let engine = MLValidationEngine.shared

        // Should not throw
        do {
            try await engine.initialize()
        } catch {
            XCTFail("Initialization should not throw: \(error)")
        }
    }

    func testMLPredictionForChart() async {
        let engine = MLValidationEngine.shared

        let chart = FourPillarsChart(
            yearPillar: Pillar(stem: .jia, branch: .zi),
            monthPillar: Pillar(stem: .bing, branch: .yin),
            dayPillar: Pillar(stem: .wu, branch: .wu),
            hourPillar: Pillar(stem: .geng, branch: .shen)
        )

        let result = await engine.predict(chart: chart)

        // Verify result is reasonable
        XCTAssertNotNil(result.lifespanPrediction)
        XCTAssertNotNil(result.fortuneLevel)
        XCTAssertGreaterThan(result.confidence, 0.0)

        if let lifespan = result.lifespanPrediction {
            XCTAssertGreaterThan(lifespan, 30.0, "Lifespan should be > 30")
            XCTAssertLessThan(lifespan, 120.0, "Lifespan should be < 120")
        }

        if let fortuneLevel = result.fortuneLevel {
            XCTAssertGreaterThanOrEqual(fortuneLevel, 0)
            XCTAssertLessThanOrEqual(fortuneLevel, 4)
        }
    }

    func testEnhanceScore() async {
        let engine = MLValidationEngine.shared

        let chart = FourPillarsChart(
            yearPillar: Pillar(stem: .jia, branch: .zi),
            monthPillar: Pillar(stem: .bing, branch: .yin),
            dayPillar: Pillar(stem: .wu, branch: .wu),
            hourPillar: Pillar(stem: .geng, branch: .shen)
        )

        let traditionalScore = 75.0
        let (enhancedScore, confidence) = await engine.enhanceScore(
            traditionalScore: traditionalScore,
            chart: chart,
            activity: .signContract
        )

        // Enhanced score should be reasonable
        XCTAssertGreaterThanOrEqual(enhancedScore, 0.0)
        XCTAssertLessThanOrEqual(enhancedScore, 100.0)
        XCTAssertGreaterThan(confidence, 0.0)
    }

    // MARK: - Edge Cases

    func testAllSameBranches() {
        // All Zi branches (unusual but valid)
        let chart = FourPillarsChart(
            yearPillar: Pillar(stem: .jia, branch: .zi),
            monthPillar: Pillar(stem: .bing, branch: .zi),
            dayPillar: Pillar(stem: .wu, branch: .zi),
            hourPillar: Pillar(stem: .geng, branch: .zi)
        )

        let features = BaZiMLFeatures(from: chart)

        // Should not detect Three Harmony or Six Combination with all same branches
        XCTAssertFalse(features.hasThreeHarmony)
        XCTAssertFalse(features.hasSixCombination)
        XCTAssertEqual(features.clashCount, 0)
    }

    func testAllSameStems() {
        // All Jia stems
        let chart = FourPillarsChart(
            yearPillar: Pillar(stem: .jia, branch: .zi),
            monthPillar: Pillar(stem: .jia, branch: .yin),
            dayPillar: Pillar(stem: .jia, branch: .chen),
            hourPillar: Pillar(stem: .jia, branch: .wu)
        )

        let features = BaZiMLFeatures(from: chart)

        // Should have high wood count
        XCTAssertGreaterThanOrEqual(features.woodCount, 4)
    }
}
