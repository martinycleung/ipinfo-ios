//
//  SolarTermCalculator.swift
//  Oraculum
//
//  Calculates the 24 Solar Terms (節氣) based on Sun's geocentric longitude
//

import Foundation

/// Represents one of the 24 Solar Terms (二十四節氣)
public struct SolarTerm: Sendable, Identifiable, Codable, Equatable {
    public let id: Int  // 0-23
    public let name: String
    public let chineseName: String
    public let solarLongitude: Double  // Degrees (0-360)

    /// All 24 Solar Terms in order
    public static let all: [SolarTerm] = [
        SolarTerm(id: 0, name: "Start of Spring", chineseName: "立春", solarLongitude: 315),
        SolarTerm(id: 1, name: "Rain Water", chineseName: "雨水", solarLongitude: 330),
        SolarTerm(id: 2, name: "Awakening of Insects", chineseName: "驚蟄", solarLongitude: 345),
        SolarTerm(id: 3, name: "Spring Equinox", chineseName: "春分", solarLongitude: 0),
        SolarTerm(id: 4, name: "Clear and Bright", chineseName: "清明", solarLongitude: 15),
        SolarTerm(id: 5, name: "Grain Rain", chineseName: "穀雨", solarLongitude: 30),
        SolarTerm(id: 6, name: "Start of Summer", chineseName: "立夏", solarLongitude: 45),
        SolarTerm(id: 7, name: "Small Full", chineseName: "小滿", solarLongitude: 60),
        SolarTerm(id: 8, name: "Grain in Ear", chineseName: "芒種", solarLongitude: 75),
        SolarTerm(id: 9, name: "Summer Solstice", chineseName: "夏至", solarLongitude: 90),
        SolarTerm(id: 10, name: "Minor Heat", chineseName: "小暑", solarLongitude: 105),
        SolarTerm(id: 11, name: "Major Heat", chineseName: "大暑", solarLongitude: 120),
        SolarTerm(id: 12, name: "Start of Autumn", chineseName: "立秋", solarLongitude: 135),
        SolarTerm(id: 13, name: "End of Heat", chineseName: "處暑", solarLongitude: 150),
        SolarTerm(id: 14, name: "White Dew", chineseName: "白露", solarLongitude: 165),
        SolarTerm(id: 15, name: "Autumn Equinox", chineseName: "秋分", solarLongitude: 180),
        SolarTerm(id: 16, name: "Cold Dew", chineseName: "寒露", solarLongitude: 195),
        SolarTerm(id: 17, name: "Frost Descent", chineseName: "霜降", solarLongitude: 210),
        SolarTerm(id: 18, name: "Start of Winter", chineseName: "立冬", solarLongitude: 225),
        SolarTerm(id: 19, name: "Minor Snow", chineseName: "小雪", solarLongitude: 240),
        SolarTerm(id: 20, name: "Major Snow", chineseName: "大雪", solarLongitude: 255),
        SolarTerm(id: 21, name: "Winter Solstice", chineseName: "冬至", solarLongitude: 270),
        SolarTerm(id: 22, name: "Minor Cold", chineseName: "小寒", solarLongitude: 285),
        SolarTerm(id: 23, name: "Major Cold", chineseName: "大寒", solarLongitude: 300)
    ]

    /// Get the Solar Term for a given index
    public static func term(at index: Int) -> SolarTerm {
        all[((index % 24) + 24) % 24]
    }

    /// Li Chun - Start of Spring (important for year pillar change)
    public static let liChun = all[0]

    /// The 12 "Jie" terms that determine month pillars (odd-indexed in traditional order)
    /// These are the major solar terms that mark the beginning of each lunar month
    public static let jieTerms: [SolarTerm] = [
        all[0],  // 立春 - Tiger month
        all[2],  // 驚蟄 - Rabbit month
        all[4],  // 清明 - Dragon month
        all[6],  // 立夏 - Snake month
        all[8],  // 芒種 - Horse month
        all[10], // 小暑 - Goat month
        all[12], // 立秋 - Monkey month
        all[14], // 白露 - Rooster month
        all[16], // 寒露 - Dog month
        all[18], // 立冬 - Pig month
        all[20], // 大雪 - Rat month
        all[22]  // 小寒 - Ox month
    ]

    /// Maps solar longitude range to month branch
    /// Each "Jie" term starts a new month in the Ba Zi system
    public var monthBranch: EarthlyBranch {
        // The 12 Jie terms start new months at these solar longitudes:
        // 立春 315° → Tiger (寅), 驚蟄 345° → Rabbit (卯), 清明 15° → Dragon (辰)
        // 立夏 45° → Snake (巳), 芒種 75° → Horse (午), 小暑 105° → Goat (未)
        // 立秋 135° → Monkey (申), 白露 165° → Rooster (酉), 寒露 195° → Dog (戌)
        // 立冬 225° → Pig (亥), 大雪 255° → Rat (子), 小寒 285° → Ox (丑)
        switch solarLongitude {
        case 315..<345: return .yin    // Tiger (立春 to 驚蟄)
        case 345..<360: return .mao    // Rabbit (驚蟄 to end of year)
        case 0..<15: return .mao       // Rabbit (start of year to 清明)
        case 15..<45: return .chen     // Dragon (清明 to 立夏)
        case 45..<75: return .si       // Snake (立夏 to 芒種)
        case 75..<105: return .wu      // Horse (芒種 to 小暑)
        case 105..<135: return .wei    // Goat (小暑 to 立秋)
        case 135..<165: return .shen   // Monkey (立秋 to 白露)
        case 165..<195: return .you    // Rooster (白露 to 寒露)
        case 195..<225: return .xu     // Dog (寒露 to 立冬)
        case 225..<255: return .hai    // Pig (立冬 to 大雪)
        case 255..<285: return .zi     // Rat (大雪 to 小寒)
        case 285..<315: return .chou   // Ox (小寒 to 立春)
        default: return .yin
        }
    }
}

/// Calculates Solar Terms based on Sun's apparent geocentric longitude
public actor SolarTermCalculator {
    private let sunPositionCalculator: SunPositionCalculator

    public init(sunPositionCalculator: SunPositionCalculator = SunPositionCalculator()) {
        self.sunPositionCalculator = sunPositionCalculator
    }

    /// Determines the current solar term for a given date
    /// - Parameter date: The date to check
    /// - Returns: The current solar term
    public func currentSolarTerm(for date: Date) async -> SolarTerm {
        let longitude = await sunPositionCalculator.solarLongitude(at: date)
        return solarTermFromLongitude(longitude)
    }

    /// Determines the solar term from a solar longitude value
    private func solarTermFromLongitude(_ longitude: Double) -> SolarTerm {
        // Normalize longitude to 0-360
        let normalizedLong = ((longitude.truncatingRemainder(dividingBy: 360)) + 360)
            .truncatingRemainder(dividingBy: 360)

        // Find which term this longitude falls into
        for (index, term) in SolarTerm.all.enumerated() {
            let nextIndex = (index + 1) % 24
            let nextTerm = SolarTerm.all[nextIndex]

            let startLong = term.solarLongitude
            var endLong = nextTerm.solarLongitude

            // Handle wrap-around at 0°
            if endLong <= startLong {
                endLong += 360
            }

            var checkLong = normalizedLong
            if checkLong < startLong && startLong > 300 {
                checkLong += 360
            }

            if checkLong >= startLong && checkLong < endLong {
                return term
            }
        }

        return SolarTerm.all[0]
    }

    /// Finds the exact moment when the Sun reaches a specific solar longitude
    /// Uses binary search for precision
    /// - Parameters:
    ///   - targetLongitude: Target solar longitude in degrees
    ///   - year: The year to search
    /// - Returns: The precise Date when the Sun reaches that longitude
    public func findSolarTermMoment(targetLongitude: Double, year: Int) async -> Date {
        // Estimate initial date based on typical dates
        let dayOfYear = estimateDayOfYear(for: targetLongitude)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!

        var components = DateComponents()
        components.year = year
        components.day = dayOfYear

        guard let searchDate = calendar.date(from: components) else {
            return Date()
        }
        _ = searchDate  // Reference base date for search window

        // Binary search with 1-minute precision
        var lowDate = searchDate.addingTimeInterval(-15 * 24 * 3600)  // 15 days before
        var highDate = searchDate.addingTimeInterval(15 * 24 * 3600)  // 15 days after

        while highDate.timeIntervalSince(lowDate) > 60 {  // 1 minute precision
            let midDate = Date(
                timeIntervalSince1970: (lowDate.timeIntervalSince1970 + highDate.timeIntervalSince1970) / 2
            )
            let midLongitude = await sunPositionCalculator.solarLongitude(at: midDate)

            // Handle wrap-around at 0°/360°
            let adjustedTarget = targetLongitude < 45 ? targetLongitude + 360 : targetLongitude
            let adjustedMid = midLongitude < 45 ? midLongitude + 360 : midLongitude

            if adjustedMid < adjustedTarget {
                lowDate = midDate
            } else {
                highDate = midDate
            }
        }

        return lowDate
    }

    /// Estimates the day of year for a given solar longitude
    private func estimateDayOfYear(for longitude: Double) -> Int {
        // Solar longitude increases ~1° per day
        // Spring equinox (0°) is around day 80 (March 21)
        // So for a longitude L, day = 80 + L (wrapping at 360)
        // For Li Chun (315°), day = 80 + 315 - 360 = 35 (Feb 4)
        if longitude >= 270 {
            // Winter half: 270° to 360° → days 355 to 80
            return Int(80 - (360 - longitude))
        } else {
            // Rest of year: 0° to 270° → days 80 to 355
            return Int(80 + longitude)
        }
    }

    /// Gets all solar term moments for a given year
    public func allSolarTermMoments(for year: Int) async -> [(term: SolarTerm, moment: Date)] {
        var results: [(term: SolarTerm, moment: Date)] = []

        for term in SolarTerm.all {
            let moment = await findSolarTermMoment(targetLongitude: term.solarLongitude, year: year)
            results.append((term, moment))
        }

        return results.sorted { $0.moment < $1.moment }
    }

    /// Determines if Li Chun has passed for a given date in its year
    /// This is critical for determining the Year Pillar
    public func hasLiChunPassed(for date: Date) async -> Bool {
        let calendar = Calendar(identifier: .gregorian)
        let year = calendar.component(.year, from: date)
        let liChunMoment = await findSolarTermMoment(
            targetLongitude: SolarTerm.liChun.solarLongitude,
            year: year
        )
        return date >= liChunMoment
    }

    /// Gets the month branch based on the current solar term
    public func monthBranch(for date: Date) async -> EarthlyBranch {
        let term = await currentSolarTerm(for: date)
        return term.monthBranch
    }
}
