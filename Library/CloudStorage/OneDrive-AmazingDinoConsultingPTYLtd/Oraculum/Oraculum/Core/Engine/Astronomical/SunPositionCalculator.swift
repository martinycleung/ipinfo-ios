//
//  SunPositionCalculator.swift
//  Oraculum
//
//  Calculates the Sun's apparent geocentric longitude using VSOP87 theory
//

import Foundation

/// Calculates the Sun's position using simplified VSOP87 theory
///
/// For production use, consider integrating SwiftAA for full VSOP87 precision.
/// This implementation provides accuracy within ~1 arcminute, sufficient for
/// solar term calculations to minute-level precision.
public actor SunPositionCalculator {

    public init() {}

    // MARK: - Constants

    /// Julian centuries from J2000.0
    private func julianCenturies(from jd: Double) -> Double {
        (jd - 2451545.0) / 36525.0
    }

    // MARK: - Solar Longitude Calculation

    /// Calculates the Sun's apparent geocentric ecliptic longitude
    /// - Parameter date: The date/time for calculation
    /// - Returns: Solar longitude in degrees (0-360)
    public func solarLongitude(at date: Date) -> Double {
        let jd = JulianDayConverter.julianDayNumber(from: date)
        let t = julianCenturies(from: jd)

        // Calculate mean longitude of the Sun
        // Using VSOP87 simplified formula
        var l0 = 280.4664567 + 36000.76982779 * t
            + 0.0003032028 * t * t
            + t * t * t / 49931000
            - t * t * t * t / 15300000
            - t * t * t * t * t / 2000000000

        l0 = normalizeAngle(l0)

        // Mean anomaly of the Sun
        var m = 357.5291092 + 35999.0502909 * t
            - 0.0001536 * t * t
            + t * t * t / 24490000

        m = normalizeAngle(m)
        let mRad = m * .pi / 180

        // Equation of center
        let c = (1.9146 - 0.004817 * t - 0.000014 * t * t) * sin(mRad)
            + (0.019993 - 0.000101 * t) * sin(2 * mRad)
            + 0.00029 * sin(3 * mRad)

        // Sun's true longitude
        var sunLong = l0 + c

        // Apparent longitude (corrected for nutation and aberration)
        let omega = 125.04 - 1934.136 * t
        let omegaRad = omega * .pi / 180
        sunLong = sunLong - 0.00569 - 0.00478 * sin(omegaRad)

        return normalizeAngle(sunLong)
    }

    /// Calculates the Sun's mean longitude (without corrections)
    public func meanSolarLongitude(at date: Date) -> Double {
        let jd = JulianDayConverter.julianDayNumber(from: date)
        let t = julianCenturies(from: jd)

        let l0 = 280.4664567 + 36000.76982779 * t
            + 0.0003032028 * t * t

        return normalizeAngle(l0)
    }

    /// Calculates the Sun's mean anomaly
    public func meanAnomaly(at date: Date) -> Double {
        let jd = JulianDayConverter.julianDayNumber(from: date)
        let t = julianCenturies(from: jd)

        let m = 357.5291092 + 35999.0502909 * t
            - 0.0001536 * t * t

        return normalizeAngle(m)
    }

    // MARK: - Utility Functions

    /// Normalizes an angle to the range [0, 360)
    private func normalizeAngle(_ angle: Double) -> Double {
        var result = angle.truncatingRemainder(dividingBy: 360)
        if result < 0 {
            result += 360
        }
        return result
    }

    // MARK: - Solar Term Helpers

    /// Checks if the Sun is at a specific longitude (within tolerance)
    /// - Parameters:
    ///   - date: The date to check
    ///   - targetLongitude: Target longitude in degrees
    ///   - tolerance: Tolerance in degrees (default 0.5°)
    /// - Returns: True if within tolerance
    public func isAtLongitude(
        _ date: Date,
        targetLongitude: Double,
        tolerance: Double = 0.5
    ) -> Bool {
        let currentLong = solarLongitude(at: date)
        let diff = abs(currentLong - targetLongitude)
        return diff < tolerance || diff > (360 - tolerance)
    }

    // MARK: - Additional Solar Data

    /// Calculates the Earth's distance from the Sun in AU
    public func earthSunDistance(at date: Date) -> Double {
        let jd = JulianDayConverter.julianDayNumber(from: date)
        let t = julianCenturies(from: jd)

        let m = 357.5291092 + 35999.0502909 * t
        let mRad = m * .pi / 180

        // Earth's orbital radius in AU
        let r = 1.00014 - 0.01671 * cos(mRad) - 0.00014 * cos(2 * mRad)

        return r
    }

    /// Calculates the Sun's declination
    public func solarDeclination(at date: Date) -> Double {
        let longitude = solarLongitude(at: date)
        let longRad = longitude * .pi / 180

        // Obliquity of the ecliptic (simplified)
        let jd = JulianDayConverter.julianDayNumber(from: date)
        let t = julianCenturies(from: jd)
        let eps = 23.439291 - 0.0130042 * t
        let epsRad = eps * .pi / 180

        let sinDec = sin(epsRad) * sin(longRad)
        return asin(sinDec) * 180 / .pi
    }
}
