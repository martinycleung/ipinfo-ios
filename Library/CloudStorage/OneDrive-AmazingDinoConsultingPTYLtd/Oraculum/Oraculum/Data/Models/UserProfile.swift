//
//  UserProfile.swift
//  Oraculum
//
//  SwiftData model for user profile with Ba Zi data
//

import Foundation
import SwiftData
import CoreLocation
import OraculumCore

// Note: Gender enum is now in OraculumCore (LuckPillarCalculator.swift)

/// Relationship type for family members
public enum Relationship: String, CaseIterable, Sendable, Codable {
    case selfUser = "Self"
    case spouse = "Spouse"
    case partner = "Business Partner"
    case child = "Child"
    case parent = "Parent"
    case sibling = "Sibling"
    case employee = "Key Employee"
    case other = "Other"
}

/// SwiftData model for user profile
@Model
public final class UserProfile {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var relationship: String  // Stored as String for SwiftData compatibility
    public var gender: String = "Male"  // Stored as String for SwiftData compatibility (Male/Female), default for migration

    // Birth Data
    public var birthDate: Date
    public var birthLatitude: Double
    public var birthLongitude: Double
    public var birthTimezone: String

    // Cached Ba Zi Pillars (stored as integers for persistence)
    public var yearPillarStem: Int
    public var yearPillarBranch: Int
    public var monthPillarStem: Int
    public var monthPillarBranch: Int
    public var dayPillarStem: Int
    public var dayPillarBranch: Int
    public var hourPillarStem: Int
    public var hourPillarBranch: Int

    // Useful God (cached)
    public var usefulGodElement: Int?
    public var usefulGodStrength: Double?

    // Industry for contextual LLM responses
    public var industry: String?

    // Metadata
    public var createdAt: Date
    public var updatedAt: Date

    // Family members relationship
    @Relationship(deleteRule: .cascade, inverse: \FamilyMember.owner)
    public var familyMembers: [FamilyMember] = []

    public init(
        id: UUID = UUID(),
        name: String,
        gender: Gender = .male,
        relationship: Relationship = .selfUser,
        birthDate: Date,
        birthLatitude: Double,
        birthLongitude: Double,
        birthTimezone: String,
        industry: String? = nil
    ) {
        self.id = id
        self.name = name
        self.gender = gender.rawValue
        self.relationship = relationship.rawValue
        self.birthDate = birthDate
        self.birthLatitude = birthLatitude
        self.birthLongitude = birthLongitude
        self.birthTimezone = birthTimezone
        self.industry = industry
        self.createdAt = Date()
        self.updatedAt = Date()

        // Initialize pillar values to 0, will be calculated later
        self.yearPillarStem = 0
        self.yearPillarBranch = 0
        self.monthPillarStem = 0
        self.monthPillarBranch = 0
        self.dayPillarStem = 0
        self.dayPillarBranch = 0
        self.hourPillarStem = 0
        self.hourPillarBranch = 0
    }

    /// Birth location as CLLocationCoordinate2D
    public var birthLocation: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: birthLatitude, longitude: birthLongitude)
    }

    /// Timezone object
    public var timezone: TimeZone? {
        TimeZone(identifier: birthTimezone)
    }

    /// Gender enum value
    public var genderType: Gender {
        Gender(rawValue: gender) ?? .male
    }

    /// Relationship enum value
    public var relationshipType: Relationship {
        Relationship(rawValue: relationship) ?? .other
    }

    /// Year Pillar reconstructed from stored values
    public var yearPillar: Pillar {
        Pillar.from(stemIndex: yearPillarStem, branchIndex: yearPillarBranch)
    }

    /// Month Pillar reconstructed
    public var monthPillar: Pillar {
        Pillar.from(stemIndex: monthPillarStem, branchIndex: monthPillarBranch)
    }

    /// Day Pillar reconstructed
    public var dayPillar: Pillar {
        Pillar.from(stemIndex: dayPillarStem, branchIndex: dayPillarBranch)
    }

    /// Hour Pillar reconstructed
    public var hourPillar: Pillar {
        Pillar.from(stemIndex: hourPillarStem, branchIndex: hourPillarBranch)
    }

    /// Complete Four Pillars chart
    public var baZiChart: FourPillarsChart {
        FourPillarsChart(
            yearPillar: yearPillar,
            monthPillar: monthPillar,
            dayPillar: dayPillar,
            hourPillar: hourPillar
        )
    }

    /// Useful God if calculated
    public var usefulGod: UsefulGod? {
        guard let element = usefulGodElement,
              let strength = usefulGodStrength,
              let fiveElement = FiveElement(rawValue: element) else {
            return nil
        }
        return UsefulGod(element: fiveElement, strength: strength)
    }

    /// Updates the cached Ba Zi chart from calculated pillars
    public func updateChart(_ chart: FourPillarsChart) {
        yearPillarStem = chart.yearPillar.stem.rawValue
        yearPillarBranch = chart.yearPillar.branch.rawValue
        monthPillarStem = chart.monthPillar.stem.rawValue
        monthPillarBranch = chart.monthPillar.branch.rawValue
        dayPillarStem = chart.dayPillar.stem.rawValue
        dayPillarBranch = chart.dayPillar.branch.rawValue
        hourPillarStem = chart.hourPillar.stem.rawValue
        hourPillarBranch = chart.hourPillar.branch.rawValue
        updatedAt = Date()
    }

    /// Updates the Useful God
    public func updateUsefulGod(_ god: UsefulGod) {
        usefulGodElement = god.element.rawValue
        usefulGodStrength = god.strength
        updatedAt = Date()
    }
}
