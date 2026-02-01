//
//  FourPillarsRecalculationTests.swift
//  OraculumTests
//
//  Tests that ALL four pillars recalculate when date components change
//

import XCTest
import CoreLocation
@testable import OraculumCore

final class FourPillarsRecalculationTests: XCTestCase {

    private var calculator: FourPillarsCalculator!
    private let hongKong = CLLocationCoordinate2D(latitude: 22.3, longitude: 114.2)
    private let hongKongTZ = TimeZone(identifier: "Asia/Hong_Kong")!

    override func setUp() async throws {
        calculator = FourPillarsCalculator()
    }

    // MARK: - Change Year: Affects Year Pillar AND Month Stem

    func testChangeYearAffectsYearPillarAndMonthStem() async throws {
        let calendar = Calendar(identifier: .gregorian)

        // Same month, day, time but different years (after Li Chun)
        let date2024 = DateComponents(calendar: calendar, year: 2024, month: 6, day: 15, hour: 12).date!
        let date2025 = DateComponents(calendar: calendar, year: 2025, month: 6, day: 15, hour: 12).date!

        let chart2024 = await calculator.calculate(birthDate: date2024, birthLocation: hongKong, timezone: hongKongTZ)
        let chart2025 = await calculator.calculate(birthDate: date2025, birthLocation: hongKong, timezone: hongKongTZ)

        // Year pillar should change
        XCTAssertNotEqual(chart2024.yearPillar.stem, chart2025.yearPillar.stem,
                         "Year stem should change when year changes")
        XCTAssertNotEqual(chart2024.yearPillar.branch, chart2025.yearPillar.branch,
                         "Year branch (地支) should change when year changes")

        // Month stem should change (Five Tiger Method depends on year stem)
        XCTAssertNotEqual(chart2024.monthPillar.stem, chart2025.monthPillar.stem,
                         "Month stem should change when year changes (Five Tiger Method)")

        // Month branch stays same (same solar term period)
        XCTAssertEqual(chart2024.monthPillar.branch, chart2025.monthPillar.branch,
                      "Month branch should be same for same solar term period")

        // Day pillar changes (different JDN)
        XCTAssertNotEqual(chart2024.dayPillar.chineseName, chart2025.dayPillar.chineseName,
                         "Day pillar should change for different years")
    }

    // MARK: - Change Month: Affects Month Pillar (at Solar Term Boundary)

    func testChangeMonthAffectsMonthPillar() async throws {
        let calendar = Calendar(identifier: .gregorian)

        // Different months in same year
        let march = DateComponents(calendar: calendar, year: 2025, month: 3, day: 15, hour: 12).date!
        let june = DateComponents(calendar: calendar, year: 2025, month: 6, day: 15, hour: 12).date!

        let chartMarch = await calculator.calculate(birthDate: march, birthLocation: hongKong, timezone: hongKongTZ)
        let chartJune = await calculator.calculate(birthDate: june, birthLocation: hongKong, timezone: hongKongTZ)

        // Month pillar should change
        XCTAssertNotEqual(chartMarch.monthPillar.branch, chartJune.monthPillar.branch,
                         "Month branch (地支) should change for different months")
        XCTAssertNotEqual(chartMarch.monthPillar.stem, chartJune.monthPillar.stem,
                         "Month stem should change for different months")

        // Year pillar stays same (same Chinese year)
        XCTAssertEqual(chartMarch.yearPillar.chineseName, chartJune.yearPillar.chineseName,
                      "Year pillar should be same within same Chinese year")

        // Day pillar changes
        XCTAssertNotEqual(chartMarch.dayPillar.chineseName, chartJune.dayPillar.chineseName,
                         "Day pillar should change for different days")
    }

    // MARK: - Change Day: Affects Day Pillar AND Hour Stem

    func testChangeDayAffectsDayPillarAndHourStem() async throws {
        let calendar = Calendar(identifier: .gregorian)

        // Same month, year, hour but different days
        let day15 = DateComponents(calendar: calendar, year: 2025, month: 6, day: 15, hour: 14).date!
        let day16 = DateComponents(calendar: calendar, year: 2025, month: 6, day: 16, hour: 14).date!

        let chart15 = await calculator.calculate(birthDate: day15, birthLocation: hongKong, timezone: hongKongTZ)
        let chart16 = await calculator.calculate(birthDate: day16, birthLocation: hongKong, timezone: hongKongTZ)

        // Day pillar should change
        XCTAssertNotEqual(chart15.dayPillar.stem, chart16.dayPillar.stem,
                         "Day stem should change when day changes")
        XCTAssertNotEqual(chart15.dayPillar.branch, chart16.dayPillar.branch,
                         "Day branch (地支) should change when day changes")

        // Hour stem should change (Five Rat Method depends on day stem)
        // Note: Hour branch stays same (same hour of day)
        XCTAssertEqual(chart15.hourPillar.branch, chart16.hourPillar.branch,
                      "Hour branch should be same for same hour")
        XCTAssertNotEqual(chart15.hourPillar.stem, chart16.hourPillar.stem,
                         "Hour stem should change when day changes (Five Rat Method)")

        // Year and Month stay same
        XCTAssertEqual(chart15.yearPillar.chineseName, chart16.yearPillar.chineseName)
        XCTAssertEqual(chart15.monthPillar.chineseName, chart16.monthPillar.chineseName)
    }

    // MARK: - Change Hour: Affects Hour Pillar

    func testChangeHourAffectsHourPillar() async throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = hongKongTZ  // Set calendar timezone to match calculation timezone

        // Same day but different hours (in different 时辰)
        // Using midday hours to avoid True Solar Time day boundary shifts
        var components10 = DateComponents()
        components10.year = 2025
        components10.month = 6
        components10.day = 15
        components10.hour = 10
        components10.timeZone = hongKongTZ
        let hour10 = calendar.date(from: components10)!

        var components14 = DateComponents()
        components14.year = 2025
        components14.month = 6
        components14.day = 15
        components14.hour = 14
        components14.timeZone = hongKongTZ
        let hour14 = calendar.date(from: components14)!

        let chart10 = await calculator.calculate(birthDate: hour10, birthLocation: hongKong, timezone: hongKongTZ)
        let chart14 = await calculator.calculate(birthDate: hour14, birthLocation: hongKong, timezone: hongKongTZ)

        // Hour pillar should change
        XCTAssertNotEqual(chart10.hourPillar.branch, chart14.hourPillar.branch,
                         "Hour branch (地支) should change for different hours")
        XCTAssertNotEqual(chart10.hourPillar.stem, chart14.hourPillar.stem,
                         "Hour stem should change for different hours")

        // Year, Month, Day should stay same (using midday hours avoids TST boundary issues)
        XCTAssertEqual(chart10.yearPillar.chineseName, chart14.yearPillar.chineseName,
                      "Year pillar should be same for different hours on same day")
        XCTAssertEqual(chart10.monthPillar.chineseName, chart14.monthPillar.chineseName,
                      "Month pillar should be same for different hours on same day")
        XCTAssertEqual(chart10.dayPillar.chineseName, chart14.dayPillar.chineseName,
                      "Day pillar should be same for different hours on same day (midday hours)")
    }

    // MARK: - Complete Chart Difference Test

    func testCompletelyDifferentDatesHaveCompletelyDifferentCharts() async throws {
        let calendar = Calendar(identifier: .gregorian)

        let date1 = DateComponents(calendar: calendar, year: 1990, month: 3, day: 10, hour: 6).date!
        let date2 = DateComponents(calendar: calendar, year: 2020, month: 9, day: 25, hour: 18).date!

        let chart1 = await calculator.calculate(birthDate: date1, birthLocation: hongKong, timezone: hongKongTZ)
        let chart2 = await calculator.calculate(birthDate: date2, birthLocation: hongKong, timezone: hongKongTZ)

        // With only 60 Jia-Zi combinations, the full pillar (stem+branch) should differ
        // Note: Individual stems or branches may coincidentally match (10 stems, 12 branches)
        XCTAssertNotEqual(chart1.yearPillar.chineseName, chart2.yearPillar.chineseName,
                         "Year pillar should differ for different years")
        XCTAssertNotEqual(chart1.dayPillar.chineseName, chart2.dayPillar.chineseName,
                         "Day pillar should differ for different days")

        // Verify all pillars have valid stems and branches (calculation completed)
        XCTAssertNotNil(chart1.yearPillar.stem)
        XCTAssertNotNil(chart1.yearPillar.branch)
        XCTAssertNotNil(chart1.monthPillar.stem)
        XCTAssertNotNil(chart1.monthPillar.branch)
        XCTAssertNotNil(chart1.dayPillar.stem)
        XCTAssertNotNil(chart1.dayPillar.branch)
        XCTAssertNotNil(chart1.hourPillar.stem)
        XCTAssertNotNil(chart1.hourPillar.branch)

        XCTAssertNotNil(chart2.yearPillar.stem)
        XCTAssertNotNil(chart2.yearPillar.branch)
        XCTAssertNotNil(chart2.monthPillar.stem)
        XCTAssertNotNil(chart2.monthPillar.branch)
        XCTAssertNotNil(chart2.dayPillar.stem)
        XCTAssertNotNil(chart2.dayPillar.branch)
        XCTAssertNotNil(chart2.hourPillar.stem)
        XCTAssertNotNil(chart2.hourPillar.branch)

        // Count how many pillars differ (at least 2 should differ given 30 year gap)
        var diffCount = 0
        if chart1.yearPillar.chineseName != chart2.yearPillar.chineseName { diffCount += 1 }
        if chart1.monthPillar.chineseName != chart2.monthPillar.chineseName { diffCount += 1 }
        if chart1.dayPillar.chineseName != chart2.dayPillar.chineseName { diffCount += 1 }
        if chart1.hourPillar.chineseName != chart2.hourPillar.chineseName { diffCount += 1 }

        XCTAssertGreaterThanOrEqual(diffCount, 2, "At least 2 pillars should differ for dates 30 years apart")
    }

    // MARK: - Verify All 地支 (Branches) Change

    func testAllBranchesChangeOverTime() async throws {
        let calendar = Calendar(identifier: .gregorian)

        var yearBranches: Set<EarthlyBranch> = []
        var monthBranches: Set<EarthlyBranch> = []
        var dayBranches: Set<EarthlyBranch> = []
        var hourBranches: Set<EarthlyBranch> = []

        // Sample all 12 Chinese hours (时辰) - each is a 2-hour block
        // 子时(23-01), 丑时(01-03), 寅时(03-05), 卯时(05-07), 辰时(07-09), 巳时(09-11)
        // 午时(11-13), 未时(13-15), 申时(15-17), 酉时(17-19), 戌时(19-21), 亥时(21-23)
        let allHours = [0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22]

        // Sample dates across a full year with all 12 Chinese hours
        for month in 1...12 {
            for day in [1, 15] {
                for hour in allHours {
                    if let date = DateComponents(calendar: calendar, year: 2025, month: month, day: day, hour: hour).date {
                        let chart = await calculator.calculate(birthDate: date, birthLocation: hongKong, timezone: hongKongTZ)
                        monthBranches.insert(chart.monthPillar.branch)
                        dayBranches.insert(chart.dayPillar.branch)
                        hourBranches.insert(chart.hourPillar.branch)
                    }
                }
            }
        }

        // Also check different years for year branch (12 year cycle)
        for year in 2020...2031 {
            let date = DateComponents(calendar: calendar, year: year, month: 6, day: 15, hour: 12).date!
            let chart = await calculator.calculate(birthDate: date, birthLocation: hongKong, timezone: hongKongTZ)
            yearBranches.insert(chart.yearPillar.branch)
        }

        // All 12 branches should appear for each pillar
        XCTAssertEqual(yearBranches.count, 12, "All 12 year branches (地支) should appear over 12 years")
        XCTAssertEqual(monthBranches.count, 12, "All 12 month branches (地支) should appear over a year")
        XCTAssertEqual(dayBranches.count, 12, "All 12 day branches (地支) should appear")
        XCTAssertEqual(hourBranches.count, 12, "All 12 hour branches (地支) should appear over all 12 时辰")
    }

    // MARK: - Verify Calculation Consistency

    func testSameDateProducesSameChart() async throws {
        let calendar = Calendar(identifier: .gregorian)
        let date = DateComponents(calendar: calendar, year: 2025, month: 6, day: 15, hour: 14, minute: 30).date!

        let chart1 = await calculator.calculate(birthDate: date, birthLocation: hongKong, timezone: hongKongTZ)
        let chart2 = await calculator.calculate(birthDate: date, birthLocation: hongKong, timezone: hongKongTZ)
        let chart3 = await calculator.calculate(birthDate: date, birthLocation: hongKong, timezone: hongKongTZ)

        // All calculations should produce identical results
        XCTAssertEqual(chart1.yearPillar.chineseName, chart2.yearPillar.chineseName)
        XCTAssertEqual(chart2.yearPillar.chineseName, chart3.yearPillar.chineseName)

        XCTAssertEqual(chart1.monthPillar.chineseName, chart2.monthPillar.chineseName)
        XCTAssertEqual(chart2.monthPillar.chineseName, chart3.monthPillar.chineseName)

        XCTAssertEqual(chart1.dayPillar.chineseName, chart2.dayPillar.chineseName)
        XCTAssertEqual(chart2.dayPillar.chineseName, chart3.dayPillar.chineseName)

        XCTAssertEqual(chart1.hourPillar.chineseName, chart2.hourPillar.chineseName)
        XCTAssertEqual(chart2.hourPillar.chineseName, chart3.hourPillar.chineseName)
    }
}
