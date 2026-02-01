//
//  JulianDayConverter.swift
//  Oraculum
//
//  Julian Day Number calculations for astronomical precision
//

import Foundation

/// Converts between Gregorian calendar dates and Julian Day Numbers
///
/// Julian Day Number (JDN) is a continuous count of days since the beginning
/// of the Julian Period (January 1, 4713 BC in the proleptic Julian calendar).
/// This is the standard in astronomical calculations.
@frozen
public struct JulianDayConverter: Sendable {

    // MARK: - Gregorian to JDN

    /// Converts a Gregorian date to Julian Day Number
    /// - Parameters:
    ///   - year: The year (negative for BCE)
    ///   - month: The month (1-12)
    ///   - day: The day of month (1-31)
    /// - Returns: The Julian Day Number as a Double (integer part = JDN, fractional = time of day)
    public static func julianDayNumber(year: Int, month: Int, day: Int) -> Double {
        // Algorithm from "Astronomical Algorithms" by Jean Meeus
        var y = year
        var m = month

        if m <= 2 {
            y -= 1
            m += 12
        }

        let a = y / 100
        let b = 2 - a + (a / 4)

        let jd = Double(Int(365.25 * Double(y + 4716))) +
                 Double(Int(30.6001 * Double(m + 1))) +
                 Double(day) + Double(b) - 1524.5

        return jd
    }

    /// Converts a Date to Julian Day Number
    /// - Parameter date: The date to convert
    /// - Returns: The Julian Day Number including fractional day
    public static func julianDayNumber(from date: Date) -> Double {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(
            in: TimeZone(identifier: "UTC")!,
            from: date
        )

        guard let year = components.year,
              let month = components.month,
              let day = components.day,
              let hour = components.hour,
              let minute = components.minute,
              let second = components.second else {
            return 0
        }

        let jdn = julianDayNumber(year: year, month: month, day: day)
        let fraction = (Double(hour) + Double(minute) / 60.0 + Double(second) / 3600.0) / 24.0

        return jdn + fraction
    }

    /// Returns the integer Julian Day Number for a date (at noon UTC)
    public static func integerJDN(from date: Date) -> Int {
        Int(julianDayNumber(from: date) + 0.5)
    }

    // MARK: - JDN to Gregorian

    /// Converts Julian Day Number back to Gregorian date components
    /// - Parameter jd: The Julian Day Number
    /// - Returns: A tuple of (year, month, day)
    public static func gregorianDate(from jd: Double) -> (year: Int, month: Int, day: Int) {
        let z = Int(jd + 0.5)
        let f = jd + 0.5 - Double(z)

        var a: Int
        if z < 2299161 {
            a = z
        } else {
            let alpha = Int((Double(z) - 1867216.25) / 36524.25)
            a = z + 1 + alpha - (alpha / 4)
        }

        let b = a + 1524
        let c = Int((Double(b) - 122.1) / 365.25)
        let d = Int(365.25 * Double(c))
        let e = Int(Double(b - d) / 30.6001)

        let day = b - d - Int(30.6001 * Double(e))
        let month = e < 14 ? e - 1 : e - 13
        let year = month > 2 ? c - 4716 : c - 4715

        return (year, month, day)
    }

    /// Converts Julian Day Number to a Date
    /// - Parameter jd: The Julian Day Number
    /// - Returns: The corresponding Date
    public static func date(from jd: Double) -> Date {
        let (year, month, day) = gregorianDate(from: jd)

        // Calculate time from fractional part
        let fractionalDay = jd + 0.5 - Double(Int(jd + 0.5))
        let totalSeconds = fractionalDay * 86400.0
        let hour = Int(totalSeconds / 3600)
        let minute = Int((totalSeconds.truncatingRemainder(dividingBy: 3600)) / 60)
        let second = Int(totalSeconds.truncatingRemainder(dividingBy: 60))

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second
        components.timeZone = TimeZone(identifier: "UTC")

        let calendar = Calendar(identifier: .gregorian)
        return calendar.date(from: components) ?? Date()
    }

    // MARK: - Ba Zi Calculations (HPA-BA Algorithm)

    /// Calculates the 60-cycle index for the given Julian Day Number
    ///
    /// HPA-BA Reference: JDN 11 was Jia-Zi (甲子)
    /// Formula: CycleIndex = (JDN - 11) % 60
    ///
    /// - Parameter jdn: The integer Julian Day Number
    /// - Returns: Index into the 60 Jia-Zi cycle (0-59)
    public static func dayCycleIndex(jdn: Int) -> Int {
        return ((jdn - 11) % 60 + 60) % 60
    }

    /// Calculates the Day Stem index (0-9) for the given Julian Day Number
    /// - Parameter jdn: The integer Julian Day Number
    /// - Returns: Index into the Heavenly Stems array (0-9)
    public static func dayStemIndex(jdn: Int) -> Int {
        return dayCycleIndex(jdn: jdn) % 10
    }

    /// Calculates the Day Branch index (0-11) for the given Julian Day Number
    /// - Parameter jdn: The integer Julian Day Number
    /// - Returns: Index into the Earthly Branches array (0-11)
    public static func dayBranchIndex(jdn: Int) -> Int {
        return dayCycleIndex(jdn: jdn) % 12
    }

    /// Calculates the Day Pillar directly from a Date
    /// - Parameter date: The date
    /// - Returns: The Day Pillar
    public static func dayPillar(from date: Date) -> Pillar {
        let jdn = integerJDN(from: date)
        let stemIndex = dayStemIndex(jdn: jdn)
        let branchIndex = dayBranchIndex(jdn: jdn)
        return Pillar.from(stemIndex: stemIndex, branchIndex: branchIndex)
    }

    // MARK: - Day of Year

    /// Calculates the day of year (1-366) for a given date
    /// - Parameter date: The date
    /// - Returns: Day of year (1 = January 1)
    public static func dayOfYear(from date: Date) -> Int {
        let calendar = Calendar(identifier: .gregorian)
        return calendar.ordinality(of: .day, in: .year, for: date) ?? 1
    }
}
