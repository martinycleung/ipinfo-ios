//
//  TrueSolarTimeCalculator.swift
//  Oraculum
//
//  Calculates True Solar Time for accurate Ba Zi hour determination
//

import Foundation
import CoreLocation

/// Calculates True Solar Time (真太陽時) for astronomical precision
///
/// True Solar Time differs from clock time due to:
/// 1. Longitude difference from the timezone's standard meridian
/// 2. Equation of Time (Earth's orbital eccentricity and axial tilt)
///
/// Formula: T_true = T_clock + (LongitudeDiff × 4 minutes) + Equation of Time
public actor TrueSolarTimeCalculator {

    public init() {}

    // MARK: - Standard Timezone Meridians

    /// Standard meridians for common timezones (degrees East)
    public static let standardMeridians: [String: Double] = [
        "Asia/Shanghai": 120.0,      // China Standard Time
        "Asia/Hong_Kong": 120.0,     // Hong Kong Time
        "Asia/Taipei": 120.0,        // Taiwan Time
        "Asia/Singapore": 105.0,     // Singapore Time (changed to 120° in 1982)
        "Asia/Tokyo": 135.0,         // Japan Standard Time
        "Asia/Seoul": 135.0,         // Korea Standard Time
        "Australia/Melbourne": 150.0, // Australian Eastern Standard Time
        "Australia/Sydney": 150.0,
        "America/New_York": -75.0,   // Eastern Standard Time
        "America/Los_Angeles": -120.0, // Pacific Standard Time
        "Europe/London": 0.0,        // Greenwich Mean Time
        "UTC": 0.0
    ]

    // MARK: - Equation of Time

    /// Calculates the Equation of Time for a given day of year
    ///
    /// The Equation of Time is the difference between apparent solar time
    /// and mean solar time. It varies throughout the year due to:
    /// - Earth's elliptical orbit (orbital eccentricity)
    /// - Earth's axial tilt (obliquity of the ecliptic)
    ///
    /// - Parameter dayOfYear: The day number (1-365/366)
    /// - Returns: Equation of Time in minutes (can be positive or negative)
    public func equationOfTime(dayOfYear: Int) -> Double {
        // Simplified formula from the spec
        // More accurate formula uses orbital elements
        let b = 2.0 * .pi * Double(dayOfYear - 81) / 365.0
        return 9.87 * sin(2 * b) - 7.53 * cos(b) - 1.5 * sin(b)
    }

    /// Calculates the Equation of Time for a specific date
    public func equationOfTime(for date: Date) -> Double {
        let dayOfYear = JulianDayConverter.dayOfYear(from: date)
        return equationOfTime(dayOfYear: dayOfYear)
    }

    // MARK: - Longitude Correction

    /// Calculates the longitude correction in minutes
    ///
    /// Each degree of longitude = 4 minutes of time difference
    /// (360° / 24 hours = 15° per hour = 4 minutes per degree)
    ///
    /// - Parameters:
    ///   - userLongitude: User's longitude in degrees (East positive)
    ///   - timezoneMeridian: Standard meridian for the timezone in degrees
    /// - Returns: Correction in minutes (positive = ahead, negative = behind)
    public func longitudeCorrection(
        userLongitude: Double,
        timezoneMeridian: Double
    ) -> Double {
        return (userLongitude - timezoneMeridian) * 4.0
    }

    /// Gets the standard meridian for a timezone identifier
    public func standardMeridian(for timezoneId: String) -> Double {
        if let meridian = Self.standardMeridians[timezoneId] {
            return meridian
        }

        // Calculate from UTC offset as fallback
        if let timezone = TimeZone(identifier: timezoneId) {
            let offsetSeconds = timezone.secondsFromGMT()
            return Double(offsetSeconds) / 240.0  // 3600 / 15 = 240
        }

        return 0.0
    }

    // MARK: - True Solar Time Conversion

    /// Converts clock time to True Solar Time
    ///
    /// - Parameters:
    ///   - clockTime: The local clock time
    ///   - location: The user's geographic coordinates
    ///   - timezone: The local timezone
    /// - Returns: The True Solar Time
    public func trueSolarTime(
        clockTime: Date,
        location: CLLocationCoordinate2D,
        timezone: TimeZone
    ) -> Date {
        // Get corrections
        let meridian = standardMeridian(for: timezone.identifier)
        let longitudeCorrection = longitudeCorrection(
            userLongitude: location.longitude,
            timezoneMeridian: meridian
        )
        let eot = equationOfTime(for: clockTime)

        // Total correction in minutes
        let totalCorrectionMinutes = longitudeCorrection + eot

        // Apply correction
        return clockTime.addingTimeInterval(totalCorrectionMinutes * 60)
    }

    /// Gets the True Solar Time hour (0-23) for Ba Zi calculation
    public func trueSolarHour(
        clockTime: Date,
        location: CLLocationCoordinate2D,
        timezone: TimeZone
    ) -> Int {
        let tst = trueSolarTime(clockTime: clockTime, location: location, timezone: timezone)
        let calendar = Calendar(identifier: .gregorian)
        return calendar.component(.hour, from: tst)
    }

    /// Gets the True Solar Time hour branch for Ba Zi
    public func trueSolarHourBranch(
        clockTime: Date,
        location: CLLocationCoordinate2D,
        timezone: TimeZone
    ) -> EarthlyBranch {
        let hour = trueSolarHour(clockTime: clockTime, location: location, timezone: timezone)
        return EarthlyBranch.fromHour(hour)
    }

    // MARK: - Detailed Components

    /// Returns detailed breakdown of time corrections
    public func correctionDetails(
        for date: Date,
        at location: CLLocationCoordinate2D,
        timezone: TimeZone
    ) -> TrueSolarTimeCorrection {
        let meridian = standardMeridian(for: timezone.identifier)
        let longCorr = longitudeCorrection(
            userLongitude: location.longitude,
            timezoneMeridian: meridian
        )
        let eot = equationOfTime(for: date)

        return TrueSolarTimeCorrection(
            longitudeCorrection: longCorr,
            equationOfTime: eot,
            totalCorrection: longCorr + eot,
            standardMeridian: meridian,
            userLongitude: location.longitude
        )
    }
}

/// Detailed breakdown of True Solar Time corrections
public struct TrueSolarTimeCorrection: Sendable {
    /// Correction due to longitude difference from standard meridian (minutes)
    public let longitudeCorrection: Double
    /// Equation of Time correction (minutes)
    public let equationOfTime: Double
    /// Total correction to apply (minutes)
    public let totalCorrection: Double
    /// The standard meridian used for the timezone (degrees)
    public let standardMeridian: Double
    /// The user's longitude (degrees)
    public let userLongitude: Double

    /// Description of the correction
    public var description: String {
        """
        True Solar Time Correction:
        - Standard Meridian: \(String(format: "%.1f", standardMeridian))°
        - User Longitude: \(String(format: "%.4f", userLongitude))°
        - Longitude Correction: \(String(format: "%.1f", longitudeCorrection)) min
        - Equation of Time: \(String(format: "%.1f", equationOfTime)) min
        - Total Correction: \(String(format: "%.1f", totalCorrection)) min
        """
    }
}
