//
//  Pillar.swift
//  Oraculum
//
//  Represents a single pillar (柱) in Ba Zi - Stem + Branch combination
//

import Foundation

/// Represents a single pillar in Ba Zi, combining a Heavenly Stem and Earthly Branch
public struct Pillar: Sendable, Codable, Equatable, Hashable {
    public let stem: HeavenlyStem
    public let branch: EarthlyBranch

    public init(stem: HeavenlyStem, branch: EarthlyBranch) {
        self.stem = stem
        self.branch = branch
    }

    /// The 60-pillar cycle index (0-59), known as Sexagenary cycle (六十甲子)
    public var cycleIndex: Int {
        // The cycle starts at Jia-Zi (甲子)
        // Formula: Find n such that n ≡ stem.rawValue (mod 10) and n ≡ branch.rawValue (mod 12)
        // Using Chinese Remainder Theorem simplified for this case
        var index = stem.rawValue
        while index % 12 != branch.rawValue {
            index += 10
        }
        return index % 60
    }

    /// Chinese name representation (e.g., "甲子")
    public var chineseName: String {
        stem.chineseName + branch.chineseName
    }

    /// Pinyin representation (e.g., "Jiǎ Zǐ")
    public var pinyin: String {
        stem.pinyin + " " + branch.chineseName
    }

    /// The primary element of this pillar (from the stem)
    public var element: FiveElement {
        stem.element
    }

    /// The polarity of this pillar (from the stem)
    public var polarity: YinYang {
        stem.polarity
    }

    /// Creates a pillar from a 60-cycle index
    public static func fromCycleIndex(_ index: Int) -> Pillar {
        let normalizedIndex = ((index % 60) + 60) % 60
        let stemIndex = normalizedIndex % 10
        let branchIndex = normalizedIndex % 12
        return Pillar(
            stem: HeavenlyStem.fromIndex(stemIndex),
            branch: EarthlyBranch.fromIndex(branchIndex)
        )
    }

    /// Creates a pillar from stem and branch indices
    public static func from(stemIndex: Int, branchIndex: Int) -> Pillar {
        Pillar(
            stem: HeavenlyStem.fromIndex(stemIndex),
            branch: EarthlyBranch.fromIndex(branchIndex)
        )
    }
}

/// The complete Four Pillars chart (四柱八字)
public struct FourPillarsChart: Sendable, Codable, Equatable {
    public let yearPillar: Pillar
    public let monthPillar: Pillar
    public let dayPillar: Pillar
    public let hourPillar: Pillar

    public init(
        yearPillar: Pillar,
        monthPillar: Pillar,
        dayPillar: Pillar,
        hourPillar: Pillar
    ) {
        self.yearPillar = yearPillar
        self.monthPillar = monthPillar
        self.dayPillar = dayPillar
        self.hourPillar = hourPillar
    }

    /// The Day Master (日主) - the Heavenly Stem of the Day Pillar
    /// This represents the "self" in Ba Zi analysis
    public var dayMaster: HeavenlyStem {
        dayPillar.stem
    }

    /// All eight characters as an array
    public var allCharacters: [String] {
        [
            yearPillar.stem.chineseName,
            monthPillar.stem.chineseName,
            dayPillar.stem.chineseName,
            hourPillar.stem.chineseName,
            yearPillar.branch.chineseName,
            monthPillar.branch.chineseName,
            dayPillar.branch.chineseName,
            hourPillar.branch.chineseName
        ]
    }

    /// Chinese representation of the chart
    public var chineseRepresentation: String {
        """
        年柱: \(yearPillar.chineseName)
        月柱: \(monthPillar.chineseName)
        日柱: \(dayPillar.chineseName)
        時柱: \(hourPillar.chineseName)
        """
    }

    /// All pillars as an array
    public var pillars: [Pillar] {
        [yearPillar, monthPillar, dayPillar, hourPillar]
    }

    /// All stems in the chart
    public var stems: [HeavenlyStem] {
        pillars.map { $0.stem }
    }

    /// All branches in the chart
    public var branches: [EarthlyBranch] {
        pillars.map { $0.branch }
    }
}
