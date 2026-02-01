//
//  FamilyMember.swift
//  Oraculum
//
//  SwiftData model for family members in the "Family Office" feature
//

import Foundation
import SwiftData
import CoreLocation
import OraculumCore

/// SwiftData model for family members
@Model
public final class FamilyMember {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var relationship: String
    public var gender: String  // Stored as String for SwiftData compatibility (Male/Female)

    // Birth Data
    public var birthDate: Date
    public var birthLatitude: Double
    public var birthLongitude: Double
    public var birthTimezone: String

    // Cached Ba Zi Pillars
    public var yearPillarStem: Int
    public var yearPillarBranch: Int
    public var monthPillarStem: Int
    public var monthPillarBranch: Int
    public var dayPillarStem: Int
    public var dayPillarBranch: Int
    public var hourPillarStem: Int
    public var hourPillarBranch: Int

    // Useful God
    public var usefulGodElement: Int?
    public var usefulGodStrength: Double?

    // Notes
    public var notes: String?

    // Metadata
    public var createdAt: Date
    public var updatedAt: Date

    // Owner relationship
    public var owner: UserProfile?

    public init(
        id: UUID = UUID(),
        name: String,
        gender: Gender = .male,
        relationship: Relationship,
        birthDate: Date,
        birthLatitude: Double,
        birthLongitude: Double,
        birthTimezone: String,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.gender = gender.rawValue
        self.relationship = relationship.rawValue
        self.birthDate = birthDate
        self.birthLatitude = birthLatitude
        self.birthLongitude = birthLongitude
        self.birthTimezone = birthTimezone
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()

        // Initialize pillar values
        self.yearPillarStem = 0
        self.yearPillarBranch = 0
        self.monthPillarStem = 0
        self.monthPillarBranch = 0
        self.dayPillarStem = 0
        self.dayPillarBranch = 0
        self.hourPillarStem = 0
        self.hourPillarBranch = 0
    }

    /// Birth location
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

    /// Complete Four Pillars chart
    public var baZiChart: FourPillarsChart {
        FourPillarsChart(
            yearPillar: Pillar.from(stemIndex: yearPillarStem, branchIndex: yearPillarBranch),
            monthPillar: Pillar.from(stemIndex: monthPillarStem, branchIndex: monthPillarBranch),
            dayPillar: Pillar.from(stemIndex: dayPillarStem, branchIndex: dayPillarBranch),
            hourPillar: Pillar.from(stemIndex: hourPillarStem, branchIndex: hourPillarBranch)
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

    /// Updates the cached chart
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
}
