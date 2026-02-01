//
//  FourPillarsCalculator.swift
//  Oraculum
//
//  Calculates the complete Four Pillars (四柱八字) chart
//

import Foundation
import CoreLocation

/// Calculates complete Ba Zi (Four Pillars) charts with astronomical precision
public actor FourPillarsCalculator {
    private let solarTermCalculator: SolarTermCalculator
    private let trueSolarTimeCalculator: TrueSolarTimeCalculator

    public init(
        solarTermCalculator: SolarTermCalculator = SolarTermCalculator(),
        trueSolarTimeCalculator: TrueSolarTimeCalculator = TrueSolarTimeCalculator()
    ) {
        self.solarTermCalculator = solarTermCalculator
        self.trueSolarTimeCalculator = trueSolarTimeCalculator
    }

    // MARK: - Complete Chart Calculation

    /// Calculates the complete Ba Zi chart for a given birth moment and location
    /// - Parameters:
    ///   - birthDate: The birth date and time (local time)
    ///   - birthLocation: The geographic coordinates of birth place
    ///   - timezone: The local timezone
    /// - Returns: The complete Four Pillars chart
    public func calculate(
        birthDate: Date,
        birthLocation: CLLocationCoordinate2D,
        timezone: TimeZone
    ) async -> FourPillarsChart {
        // 1. Convert to True Solar Time
        let trueSolarTime = await trueSolarTimeCalculator.trueSolarTime(
            clockTime: birthDate,
            location: birthLocation,
            timezone: timezone
        )

        // 2. Calculate Year Pillar (changes at Li Chun)
        let year = await yearPillar(for: trueSolarTime)

        // 3. Calculate Month Pillar (based on Solar Term)
        let month = await monthPillar(for: trueSolarTime, yearStem: year.stem)

        // 4. Calculate Day Pillar (JDN formula)
        let day = dayPillar(for: trueSolarTime)

        // 5. Calculate Hour Pillar (Five Rat Method)
        let hour = await hourPillar(trueSolarTime: trueSolarTime, dayStem: day.stem)

        return FourPillarsChart(
            yearPillar: year,
            monthPillar: month,
            dayPillar: day,
            hourPillar: hour
        )
    }

    // MARK: - Year Pillar

    /// Calculates the Year Pillar
    /// The year changes at Li Chun (Start of Spring), not January 1st
    private func yearPillar(for date: Date) async -> Pillar {
        let calendar = Calendar(identifier: .gregorian)
        var year = calendar.component(.year, from: date)

        // Check if Li Chun has passed this year
        let liChunPassed = await solarTermCalculator.hasLiChunPassed(for: date)
        if !liChunPassed {
            year -= 1
        }

        // Year stem and branch calculation
        // Reference: 1984 was Jia-Zi (甲子) year
        let cycleYear = year - 1984
        let stemIndex = ((cycleYear % 10) + 10) % 10
        let branchIndex = ((cycleYear % 12) + 12) % 12

        return Pillar.from(stemIndex: stemIndex, branchIndex: branchIndex)
    }

    // MARK: - Month Pillar

    /// Calculates the Month Pillar
    /// The month is determined by which Solar Term (Jie) the date falls in
    private func monthPillar(for date: Date, yearStem: HeavenlyStem) async -> Pillar {
        // Get current solar term to determine month branch
        let monthBranch = await solarTermCalculator.monthBranch(for: date)

        // Calculate month stem using "Five Tiger Method" (五虎遁)
        let monthStem = fiveTigerMethod(yearStem: yearStem, monthBranch: monthBranch)

        return Pillar(stem: monthStem, branch: monthBranch)
    }

    /// Five Tiger Method (五虎遁) - determines month stem from year stem
    ///
    /// HPA-BA Formula: BaseStem = (YearStem * 2 + 2) % 10
    /// This gives the stem for Tiger month, then offset by month branch position.
    ///
    /// Verification:
    /// - Jia(0)/Ji(5): (0*2+2)%10 = 2 = Bing ✓
    /// - Yi(1)/Geng(6): (1*2+2)%10 = 4 = Wu ✓
    /// - Bing(2)/Xin(7): (2*2+2)%10 = 6 = Geng ✓
    /// - Ding(3)/Ren(8): (3*2+2)%10 = 8 = Ren ✓
    /// - Wu(4)/Gui(9): (4*2+2)%10 = 0 = Jia ✓
    private func fiveTigerMethod(yearStem: HeavenlyStem, monthBranch: EarthlyBranch) -> HeavenlyStem {
        // HPA-BA Formula: Base stem for Tiger month
        let baseStemIndex = (yearStem.rawValue * 2 + 2) % 10

        // Calculate offset from Tiger month (Tiger = branch index 2)
        // MonthBranchIndex relative to Tiger: 0=Tiger, 1=Rabbit, ..., 11=Ox
        let offset = (monthBranch.rawValue - EarthlyBranch.yin.rawValue + 12) % 12

        return HeavenlyStem.fromIndex(baseStemIndex + offset)
    }

    // MARK: - Day Pillar

    /// Calculates the Day Pillar using Julian Day Number
    private func dayPillar(for date: Date) -> Pillar {
        JulianDayConverter.dayPillar(from: date)
    }

    // MARK: - Hour Pillar

    /// Calculates the Hour Pillar using "Five Rat Method" (五鼠遁)
    private func hourPillar(trueSolarTime: Date, dayStem: HeavenlyStem) async -> Pillar {
        // Get hour branch from True Solar Time
        let calendar = Calendar(identifier: .gregorian)
        let hour = calendar.component(.hour, from: trueSolarTime)
        let hourBranch = EarthlyBranch.fromHour(hour)

        // Calculate hour stem using Five Rat Method
        let hourStem = fiveRatMethod(dayStem: dayStem, hourBranch: hourBranch)

        return Pillar(stem: hourStem, branch: hourBranch)
    }

    /// Five Rat Method (五鼠遁) - determines hour stem from day stem
    ///
    /// HPA-BA Formula: BaseHourStem = (DayStem * 2) % 10
    /// This gives the stem for Zi (Rat) hour, then offset by hour branch position.
    ///
    /// Verification:
    /// - Jia(0)/Ji(5): (0*2)%10 = 0 = Jia ✓
    /// - Yi(1)/Geng(6): (1*2)%10 = 2 = Bing ✓
    /// - Bing(2)/Xin(7): (2*2)%10 = 4 = Wu ✓
    /// - Ding(3)/Ren(8): (3*2)%10 = 6 = Geng ✓
    /// - Wu(4)/Gui(9): (4*2)%10 = 8 = Ren ✓
    private func fiveRatMethod(dayStem: HeavenlyStem, hourBranch: EarthlyBranch) -> HeavenlyStem {
        // HPA-BA Formula: Base stem for Zi (Rat) hour
        let baseHourStemIndex = (dayStem.rawValue * 2) % 10

        // Hour branch offset from Zi (Zi = branch index 0)
        let offset = hourBranch.rawValue

        return HeavenlyStem.fromIndex(baseHourStemIndex + offset)
    }

    // MARK: - Convenience Methods

    /// Calculates chart for a date with default location (for testing)
    public func calculate(date: Date) async -> FourPillarsChart {
        await calculate(
            birthDate: date,
            birthLocation: CLLocationCoordinate2D(latitude: 22.3, longitude: 114.2), // Hong Kong
            timezone: TimeZone(identifier: "Asia/Hong_Kong")!
        )
    }
}
