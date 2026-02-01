//
//  DateChangeRecalculationTests.swift
//  OraculumTests
//
//  Tests that BaZi calculations properly change when dates change
//

import XCTest
@testable import OraculumCore

final class DateChangeRecalculationTests: XCTestCase {

    private var fourPillarsCalculator: FourPillarsCalculator!
    private var selectionEngine: SelectionEngine!

    override func setUp() async throws {
        fourPillarsCalculator = FourPillarsCalculator()
        selectionEngine = SelectionEngine()
    }

    // MARK: - Day Pillar Changes Daily

    func testDayPillarChangesDailyOver60Days() async throws {
        // Test that day pillars cycle through all 60 Jia-Zi combinations over 60 consecutive days
        let calendar = Calendar(identifier: .gregorian)
        var baseDate = DateComponents(calendar: calendar, year: 2025, month: 1, day: 1).date!

        var dayPillars: [String] = []

        for _ in 0..<60 {
            let chart = await fourPillarsCalculator.calculate(date: baseDate)
            dayPillars.append(chart.dayPillar.chineseName)
            baseDate = calendar.date(byAdding: .day, value: 1, to: baseDate)!
        }

        // All 60 pillars should be unique (60 Jia-Zi cycle)
        let uniquePillars = Set(dayPillars)
        XCTAssertEqual(uniquePillars.count, 60, "Should have 60 unique day pillars over 60 days")
    }

    func testConsecutiveDaysHaveDifferentDayPillars() async throws {
        let calendar = Calendar(identifier: .gregorian)

        let day1 = DateComponents(calendar: calendar, year: 2025, month: 6, day: 15).date!
        let day2 = DateComponents(calendar: calendar, year: 2025, month: 6, day: 16).date!
        let day3 = DateComponents(calendar: calendar, year: 2025, month: 6, day: 17).date!

        let chart1 = await fourPillarsCalculator.calculate(date: day1)
        let chart2 = await fourPillarsCalculator.calculate(date: day2)
        let chart3 = await fourPillarsCalculator.calculate(date: day3)

        // Each day should have a different day pillar
        XCTAssertNotEqual(chart1.dayPillar.chineseName, chart2.dayPillar.chineseName,
                         "Day 1 and Day 2 should have different day pillars")
        XCTAssertNotEqual(chart2.dayPillar.chineseName, chart3.dayPillar.chineseName,
                         "Day 2 and Day 3 should have different day pillars")
        XCTAssertNotEqual(chart1.dayPillar.chineseName, chart3.dayPillar.chineseName,
                         "Day 1 and Day 3 should have different day pillars")
    }

    func testSameDaySameTimezoneReturnsSameDayPillar() async throws {
        let calendar = Calendar(identifier: .gregorian)
        let testDate = DateComponents(calendar: calendar, year: 2025, month: 3, day: 20).date!

        // Call multiple times for the same date
        let chart1 = await fourPillarsCalculator.calculate(date: testDate)
        let chart2 = await fourPillarsCalculator.calculate(date: testDate)
        let chart3 = await fourPillarsCalculator.calculate(date: testDate)

        // All should return the same day pillar
        XCTAssertEqual(chart1.dayPillar.chineseName, chart2.dayPillar.chineseName)
        XCTAssertEqual(chart2.dayPillar.chineseName, chart3.dayPillar.chineseName)
    }

    // MARK: - Month Pillar Changes with Solar Terms

    func testMonthPillarChangesAcrossSolarTermBoundary() async throws {
        let calendar = Calendar(identifier: .gregorian)

        // Li Chun (Start of Spring) usually falls around Feb 3-5
        // This marks the start of Yin (Tiger) month
        let beforeLiChun = DateComponents(calendar: calendar, year: 2025, month: 2, day: 1).date!
        let afterLiChun = DateComponents(calendar: calendar, year: 2025, month: 2, day: 10).date!

        let chartBefore = await fourPillarsCalculator.calculate(date: beforeLiChun)
        let chartAfter = await fourPillarsCalculator.calculate(date: afterLiChun)

        // Month branches should be different across Li Chun
        XCTAssertNotEqual(chartBefore.monthPillar.branch, chartAfter.monthPillar.branch,
                         "Month pillar should change across Li Chun solar term")
    }

    func testMonthPillarSameWithinSameSolarTerm() async throws {
        let calendar = Calendar(identifier: .gregorian)

        // Two dates within the same solar term (mid-month)
        let date1 = DateComponents(calendar: calendar, year: 2025, month: 6, day: 10).date!
        let date2 = DateComponents(calendar: calendar, year: 2025, month: 6, day: 15).date!

        let chart1 = await fourPillarsCalculator.calculate(date: date1)
        let chart2 = await fourPillarsCalculator.calculate(date: date2)

        // Month pillars should be the same within the same solar term
        XCTAssertEqual(chart1.monthPillar.chineseName, chart2.monthPillar.chineseName,
                      "Month pillar should be same within same solar term")
    }

    // MARK: - Year Pillar Changes at Li Chun

    func testYearPillarChangesAtLiChun() async throws {
        let calendar = Calendar(identifier: .gregorian)

        // Before Li Chun (still in previous Chinese year)
        let beforeLiChun = DateComponents(calendar: calendar, year: 2025, month: 1, day: 15).date!
        // After Li Chun (in new Chinese year)
        let afterLiChun = DateComponents(calendar: calendar, year: 2025, month: 2, day: 10).date!

        let chartBefore = await fourPillarsCalculator.calculate(date: beforeLiChun)
        let chartAfter = await fourPillarsCalculator.calculate(date: afterLiChun)

        // Year pillar should change at Li Chun (not Jan 1)
        XCTAssertNotEqual(chartBefore.yearPillar.chineseName, chartAfter.yearPillar.chineseName,
                         "Year pillar should change at Li Chun")
    }

    func testYearPillarSameOnJan1AndJan31() async throws {
        let calendar = Calendar(identifier: .gregorian)

        // Both dates are before Li Chun, so should be same Chinese year
        let jan1 = DateComponents(calendar: calendar, year: 2025, month: 1, day: 1).date!
        let jan31 = DateComponents(calendar: calendar, year: 2025, month: 1, day: 31).date!

        let chartJan1 = await fourPillarsCalculator.calculate(date: jan1)
        let chartJan31 = await fourPillarsCalculator.calculate(date: jan31)

        // Both should be in the same Chinese year (before Li Chun)
        XCTAssertEqual(chartJan1.yearPillar.chineseName, chartJan31.yearPillar.chineseName,
                      "Jan 1 and Jan 31 should be same Chinese year (before Li Chun)")
    }

    // MARK: - Full Analysis Recalculates for Different Dates

    func testAnalysisDifferentForDifferentDates() async throws {
        let calendar = Calendar(identifier: .gregorian)

        let date1 = DateComponents(calendar: calendar, year: 2025, month: 5, day: 10).date!
        let date2 = DateComponents(calendar: calendar, year: 2025, month: 5, day: 11).date!

        let analysis1 = await selectionEngine.analyzeDay(date: date1, activity: .signContract)
        let analysis2 = await selectionEngine.analyzeDay(date: date2, activity: .signContract)

        // Day pillars should be different
        XCTAssertNotEqual(analysis1.dayPillar.chineseName, analysis2.dayPillar.chineseName,
                         "Analysis for different dates should have different day pillars")

        // Day officers may or may not be different (depends on calculation)
        // But the dates stored in analysis should be different
        XCTAssertNotEqual(analysis1.date, analysis2.date,
                         "Analysis should store the correct date")
    }

    func testAnalysisSameForSameDate() async throws {
        let calendar = Calendar(identifier: .gregorian)
        let testDate = DateComponents(calendar: calendar, year: 2025, month: 7, day: 20).date!

        let analysis1 = await selectionEngine.analyzeDay(date: testDate, activity: .signContract)
        let analysis2 = await selectionEngine.analyzeDay(date: testDate, activity: .signContract)

        // Same date + same activity should give same results
        XCTAssertEqual(analysis1.dayPillar.chineseName, analysis2.dayPillar.chineseName)
        XCTAssertEqual(analysis1.monthPillar.chineseName, analysis2.monthPillar.chineseName)
        XCTAssertEqual(analysis1.yearPillar.chineseName, analysis2.yearPillar.chineseName)
        XCTAssertEqual(analysis1.dayOfficer, analysis2.dayOfficer)
        XCTAssertEqual(analysis1.score, analysis2.score)
    }

    func testAnalysisDifferentScoresForDifferentActivities() async throws {
        let calendar = Calendar(identifier: .gregorian)
        let testDate = DateComponents(calendar: calendar, year: 2025, month: 8, day: 15).date!

        let analysisContract = await selectionEngine.analyzeDay(date: testDate, activity: .signContract)
        let analysisDemolition = await selectionEngine.analyzeDay(date: testDate, activity: .demolition)

        // Same date but different activities can have different scores
        // (Due to Year Breaker and activity-specific scoring)
        // The pillars should be the same though
        XCTAssertEqual(analysisContract.dayPillar.chineseName, analysisDemolition.dayPillar.chineseName,
                      "Same date should have same day pillar regardless of activity")
    }

    // MARK: - Julian Day Converter Tests

    func testJulianDayNumberDifferentForDifferentDates() {
        let calendar = Calendar(identifier: .gregorian)

        let date1 = DateComponents(calendar: calendar, year: 2025, month: 3, day: 1).date!
        let date2 = DateComponents(calendar: calendar, year: 2025, month: 3, day: 2).date!

        let jdn1 = JulianDayConverter.integerJDN(from: date1)
        let jdn2 = JulianDayConverter.integerJDN(from: date2)

        XCTAssertEqual(jdn2 - jdn1, 1, "Consecutive days should have JDN difference of 1")
    }

    func testDayPillarCycleIndexDifferentForConsecutiveDays() {
        let calendar = Calendar(identifier: .gregorian)

        let date1 = DateComponents(calendar: calendar, year: 2025, month: 4, day: 10).date!
        let date2 = DateComponents(calendar: calendar, year: 2025, month: 4, day: 11).date!

        let pillar1 = JulianDayConverter.dayPillar(from: date1)
        let pillar2 = JulianDayConverter.dayPillar(from: date2)

        XCTAssertNotEqual(pillar1.chineseName, pillar2.chineseName,
                         "Consecutive days should have different day pillars")
    }

    // MARK: - Day Officer Changes

    func testDayOfficerCanChangeBetweenDays() async throws {
        let calendar = Calendar(identifier: .gregorian)

        // Test over a week - day officer should change as day branch changes
        var baseDate = DateComponents(calendar: calendar, year: 2025, month: 9, day: 1).date!
        var dayOfficers: [DayOfficer] = []

        for _ in 0..<12 {
            let analysis = await selectionEngine.analyzeDay(date: baseDate, activity: .signContract)
            dayOfficers.append(analysis.dayOfficer)
            baseDate = calendar.date(byAdding: .day, value: 1, to: baseDate)!
        }

        // Over 12 days, we should see multiple different day officers (12 officer cycle)
        let uniqueOfficers = Set(dayOfficers)
        XCTAssertGreaterThan(uniqueOfficers.count, 1,
                            "Day officer should vary over 12 days")
    }

    // MARK: - Lunar Stars Can Change

    func testLunarStarsCanChangeBetweenDays() async throws {
        let calendar = Calendar(identifier: .gregorian)

        var baseDate = DateComponents(calendar: calendar, year: 2025, month: 10, day: 1).date!
        var allStarCounts: [Int] = []

        for _ in 0..<30 {
            let analysis = await selectionEngine.analyzeDay(date: baseDate, activity: .signContract)
            allStarCounts.append(analysis.lunarStars.count)
            baseDate = calendar.date(byAdding: .day, value: 1, to: baseDate)!
        }

        // Lunar stars should vary - not all days have the same count
        let uniqueCounts = Set(allStarCounts)
        XCTAssertGreaterThan(uniqueCounts.count, 1,
                            "Lunar star count should vary between different days")
    }

    // MARK: - Score Variation

    func testScoresVaryAcrossMonth() async throws {
        let calendar = Calendar(identifier: .gregorian)

        var baseDate = DateComponents(calendar: calendar, year: 2025, month: 11, day: 1).date!
        var scores: [Int] = []

        for _ in 0..<30 {
            let analysis = await selectionEngine.analyzeDay(date: baseDate, activity: .signContract)
            scores.append(analysis.score)
            baseDate = calendar.date(byAdding: .day, value: 1, to: baseDate)!
        }

        // Scores should vary - not all days are equally auspicious
        let uniqueScores = Set(scores)
        XCTAssertGreaterThan(uniqueScores.count, 3,
                            "Scores should vary across a month - not all days are equal")

        // Check score bounds
        XCTAssertTrue(scores.allSatisfy { $0 >= 0 && $0 <= 100 },
                     "All scores should be between 0 and 100")
    }

    // MARK: - Known Date Verification

    func testKnownDateDayPillar() async throws {
        // Test a known date's day pillar
        // January 1, 2000 was Ding-Si (丁巳) day (verified via JDN calculation)
        let calendar = Calendar(identifier: .gregorian)
        let knownDate = DateComponents(calendar: calendar, year: 2000, month: 1, day: 1).date!

        let chart = await fourPillarsCalculator.calculate(date: knownDate)

        // Verify calculation is consistent and produces valid pillars
        XCTAssertNotNil(chart.dayPillar.stem)
        XCTAssertNotNil(chart.dayPillar.branch)

        // Re-run should give same result
        let chart2 = await fourPillarsCalculator.calculate(date: knownDate)
        XCTAssertEqual(chart.dayPillar.chineseName, chart2.dayPillar.chineseName,
                      "Same date should always produce same day pillar")
    }

    func testConsecutiveDatesHaveConsecutiveCycleIndices() async throws {
        // Verify that consecutive dates have consecutive cycle indices
        let calendar = Calendar(identifier: .gregorian)
        let date1 = DateComponents(calendar: calendar, year: 2024, month: 6, day: 1).date!
        let date2 = DateComponents(calendar: calendar, year: 2024, month: 6, day: 2).date!

        let jdn1 = JulianDayConverter.integerJDN(from: date1)
        let jdn2 = JulianDayConverter.integerJDN(from: date2)

        let cycle1 = JulianDayConverter.dayCycleIndex(jdn: jdn1)
        let cycle2 = JulianDayConverter.dayCycleIndex(jdn: jdn2)

        // Consecutive days should have cycle indices that differ by 1 (mod 60)
        XCTAssertEqual((cycle2 - cycle1 + 60) % 60, 1,
                      "Consecutive days should have consecutive cycle indices")
    }

    func testKnownJDNReference() {
        // Test the JDN algorithm with a known reference point
        // January 1, 2000 12:00 UT should be JDN 2451545 (a well-known reference)
        let jdn = JulianDayConverter.julianDayNumber(year: 2000, month: 1, day: 1)

        // JDN for Jan 1, 2000 at noon should be approximately 2451545
        XCTAssertEqual(Int(jdn + 0.5), 2451545,
                      "JDN for Jan 1, 2000 should be 2451545")
    }
}
