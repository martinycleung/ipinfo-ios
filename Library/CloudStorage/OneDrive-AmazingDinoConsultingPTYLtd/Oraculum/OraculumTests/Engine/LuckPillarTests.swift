//
//  LuckPillarTests.swift
//  OraculumTests
//
//  Tests for Luck Pillar (大运) calculation - especially gender-based direction
//

import XCTest
import CoreLocation
@testable import OraculumCore

final class LuckPillarTests: XCTestCase {

    private var luckCalculator: LuckPillarCalculator!
    private var pillarsCalculator: FourPillarsCalculator!
    private let hongKong = CLLocationCoordinate2D(latitude: 22.3, longitude: 114.2)
    private let hongKongTZ = TimeZone(identifier: "Asia/Hong_Kong")!

    override func setUp() async throws {
        luckCalculator = LuckPillarCalculator()
        pillarsCalculator = FourPillarsCalculator()
    }

    // MARK: - Gender-Based Direction Tests

    func testYangYearMaleIsForward() async throws {
        // 2024 is Jia Chen (甲辰) year - Jia is Yang stem
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 15
        components.hour = 12
        components.timeZone = hongKongTZ
        let date = calendar.date(from: components)!

        let chart = await pillarsCalculator.calculate(
            birthDate: date,
            birthLocation: hongKong,
            timezone: hongKongTZ
        )

        // Verify year stem is Yang
        XCTAssertEqual(chart.yearPillar.stem.polarity, .yang,
                      "2024 should have Yang year stem (甲)")

        // Male with Yang year = Forward
        let maleResult = luckCalculator.calculate(chart: chart, gender: .male, birthDate: date)
        XCTAssertEqual(maleResult.direction, .forward,
                      "Yang year + Male should produce Forward (顺行) direction")
    }

    func testYangYearFemaleIsBackward() async throws {
        // 2024 is Jia Chen (甲辰) year - Jia is Yang stem
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 15
        components.hour = 12
        components.timeZone = hongKongTZ
        let date = calendar.date(from: components)!

        let chart = await pillarsCalculator.calculate(
            birthDate: date,
            birthLocation: hongKong,
            timezone: hongKongTZ
        )

        // Female with Yang year = Backward
        let femaleResult = luckCalculator.calculate(chart: chart, gender: .female, birthDate: date)
        XCTAssertEqual(femaleResult.direction, .backward,
                      "Yang year + Female should produce Backward (逆行) direction")
    }

    func testYinYearMaleIsBackward() async throws {
        // 2025 is Yi Si (乙巳) year - Yi is Yin stem
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.year = 2025
        components.month = 6
        components.day = 15
        components.hour = 12
        components.timeZone = hongKongTZ
        let date = calendar.date(from: components)!

        let chart = await pillarsCalculator.calculate(
            birthDate: date,
            birthLocation: hongKong,
            timezone: hongKongTZ
        )

        // Verify year stem is Yin
        XCTAssertEqual(chart.yearPillar.stem.polarity, .yin,
                      "2025 should have Yin year stem (乙)")

        // Male with Yin year = Backward
        let maleResult = luckCalculator.calculate(chart: chart, gender: .male, birthDate: date)
        XCTAssertEqual(maleResult.direction, .backward,
                      "Yin year + Male should produce Backward (逆行) direction")
    }

    func testYinYearFemaleIsForward() async throws {
        // 2025 is Yi Si (乙巳) year - Yi is Yin stem
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.year = 2025
        components.month = 6
        components.day = 15
        components.hour = 12
        components.timeZone = hongKongTZ
        let date = calendar.date(from: components)!

        let chart = await pillarsCalculator.calculate(
            birthDate: date,
            birthLocation: hongKong,
            timezone: hongKongTZ
        )

        // Female with Yin year = Forward
        let femaleResult = luckCalculator.calculate(chart: chart, gender: .female, birthDate: date)
        XCTAssertEqual(femaleResult.direction, .forward,
                      "Yin year + Female should produce Forward (顺行) direction")
    }

    // MARK: - Gender Change Produces Different Results

    func testGenderChangeProducesDifferentDirection() async throws {
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 15
        components.hour = 12
        components.timeZone = hongKongTZ
        let date = calendar.date(from: components)!

        let chart = await pillarsCalculator.calculate(
            birthDate: date,
            birthLocation: hongKong,
            timezone: hongKongTZ
        )

        let maleResult = luckCalculator.calculate(chart: chart, gender: .male, birthDate: date)
        let femaleResult = luckCalculator.calculate(chart: chart, gender: .female, birthDate: date)

        // Same date, different gender = opposite direction
        XCTAssertNotEqual(maleResult.direction, femaleResult.direction,
                         "Changing gender should produce opposite Luck Pillar direction")
    }

    func testGenderChangeProducesDifferentLuckPillars() async throws {
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 15
        components.hour = 12
        components.timeZone = hongKongTZ
        let date = calendar.date(from: components)!

        let chart = await pillarsCalculator.calculate(
            birthDate: date,
            birthLocation: hongKong,
            timezone: hongKongTZ
        )

        let maleResult = luckCalculator.calculate(chart: chart, gender: .male, birthDate: date)
        let femaleResult = luckCalculator.calculate(chart: chart, gender: .female, birthDate: date)

        // First luck pillar is month pillar for both, but subsequent pillars differ
        // (First luck pillar is the same because it starts from month pillar)
        if maleResult.luckPillars.count > 1 && femaleResult.luckPillars.count > 1 {
            let maleSecond = maleResult.luckPillars[1].pillar.chineseName
            let femaleSecond = femaleResult.luckPillars[1].pillar.chineseName

            XCTAssertNotEqual(maleSecond, femaleSecond,
                             "Second luck pillar should differ between genders (forward vs backward)")
        }
    }

    // MARK: - Luck Pillar Structure Tests

    func testLuckPillarsCount() async throws {
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.year = 2000
        components.month = 6
        components.day = 15
        components.hour = 12
        components.timeZone = hongKongTZ
        let date = calendar.date(from: components)!

        let chart = await pillarsCalculator.calculate(
            birthDate: date,
            birthLocation: hongKong,
            timezone: hongKongTZ
        )

        let result = luckCalculator.calculate(chart: chart, gender: .male, birthDate: date)

        // Should generate 10 luck pillars
        XCTAssertEqual(result.luckPillars.count, 10, "Should generate 10 luck pillars")

        // Each pillar covers 10 years
        for (index, pillar) in result.luckPillars.enumerated() {
            XCTAssertEqual(pillar.endAge - pillar.startAge, 10,
                          "Luck pillar \(index) should cover 10 years")
        }
    }

    func testLuckPillarsSequence() async throws {
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.year = 2024  // Yang year
        components.month = 6
        components.day = 15
        components.hour = 12
        components.timeZone = hongKongTZ
        let date = calendar.date(from: components)!

        let chart = await pillarsCalculator.calculate(
            birthDate: date,
            birthLocation: hongKong,
            timezone: hongKongTZ
        )

        // Male + Yang = Forward
        let forwardResult = luckCalculator.calculate(chart: chart, gender: .male, birthDate: date)

        // Verify forward sequence (stems and branches should advance)
        for i in 0..<forwardResult.luckPillars.count - 1 {
            let current = forwardResult.luckPillars[i].pillar
            let next = forwardResult.luckPillars[i + 1].pillar

            // Stem should advance by 1
            let expectedStemIndex = (current.stem.rawValue + 1) % 10
            XCTAssertEqual(next.stem.rawValue, expectedStemIndex,
                          "Forward: Stem should advance by 1")

            // Branch should advance by 1
            let expectedBranchIndex = (current.branch.rawValue + 1) % 12
            XCTAssertEqual(next.branch.rawValue, expectedBranchIndex,
                          "Forward: Branch should advance by 1")
        }

        // Female + Yang = Backward
        let backwardResult = luckCalculator.calculate(chart: chart, gender: .female, birthDate: date)

        // Verify backward sequence (stems and branches should retreat)
        for i in 0..<backwardResult.luckPillars.count - 1 {
            let current = backwardResult.luckPillars[i].pillar
            let next = backwardResult.luckPillars[i + 1].pillar

            // Stem should retreat by 1
            let expectedStemIndex = (current.stem.rawValue + 9) % 10  // +9 = -1 mod 10
            XCTAssertEqual(next.stem.rawValue, expectedStemIndex,
                          "Backward: Stem should retreat by 1")

            // Branch should retreat by 1
            let expectedBranchIndex = (current.branch.rawValue + 11) % 12  // +11 = -1 mod 12
            XCTAssertEqual(next.branch.rawValue, expectedBranchIndex,
                          "Backward: Branch should retreat by 1")
        }
    }
}
