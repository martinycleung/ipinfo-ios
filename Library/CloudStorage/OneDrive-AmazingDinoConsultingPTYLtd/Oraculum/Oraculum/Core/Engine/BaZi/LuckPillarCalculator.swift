//
//  LuckPillarCalculator.swift
//  Oraculum
//
//  Luck Pillar (大运) Calculator
//  Calculates the 10-year luck cycles based on gender and year pillar
//

import Foundation

// MARK: - Gender

/// Gender for BaZi calculations (affects Luck Pillar direction)
public enum Gender: String, CaseIterable, Sendable, Codable {
    case male = "Male"
    case female = "Female"

    /// Localization key
    public var localizationKey: String {
        switch self {
        case .male: return "gender.male"
        case .female: return "gender.female"
        }
    }
}

// MARK: - Luck Pillar

/// A single 10-year luck pillar
public struct LuckPillar: Sendable, Identifiable {
    public let id = UUID()

    /// The pillar for this luck cycle
    public let pillar: Pillar

    /// Start age for this luck cycle
    public let startAge: Int

    /// End age for this luck cycle (exclusive)
    public let endAge: Int

    /// The decade index (0 = first luck pillar, 1 = second, etc.)
    public let index: Int

    /// Chinese description
    public var description: String {
        "\(pillar.chineseName) (\(startAge)-\(endAge-1)岁)"
    }
}

// MARK: - Luck Direction

/// Direction of luck pillar progression
public enum LuckDirection: String, Sendable {
    case forward = "forward"    // 顺行 - Forward through the cycle
    case backward = "backward"  // 逆行 - Backward through the cycle

    public var chineseName: String {
        switch self {
        case .forward: return "顺行"
        case .backward: return "逆行"
        }
    }
}

// MARK: - Luck Pillar Result

/// Complete luck pillar calculation result
public struct LuckPillarResult: Sendable {
    /// Direction of luck pillar progression
    public let direction: LuckDirection

    /// Age when first luck pillar starts
    public let startAge: Int

    /// All luck pillars (typically 8-10 decades)
    public let luckPillars: [LuckPillar]

    /// Current luck pillar for a given age
    public func currentLuckPillar(atAge age: Int) -> LuckPillar? {
        luckPillars.first { age >= $0.startAge && age < $0.endAge }
    }

    /// Summary description
    public var description: String {
        "\(direction.chineseName)大运, \(startAge)岁起运"
    }
}

// MARK: - Luck Pillar Calculator

/// Calculates luck pillars based on BaZi chart and gender
public struct LuckPillarCalculator: Sendable {

    public init() {}

    /// Calculate luck pillars for a person
    /// - Parameters:
    ///   - chart: The Four Pillars chart
    ///   - gender: The person's gender
    ///   - birthDate: The birth date (for calculating start age)
    /// - Returns: Complete luck pillar result
    public func calculate(
        chart: FourPillarsChart,
        gender: Gender,
        birthDate: Date
    ) -> LuckPillarResult {
        // Determine direction based on year stem polarity and gender
        let direction = determineDirection(yearStem: chart.yearPillar.stem, gender: gender)

        // Calculate start age based on birth date and next/previous solar term
        let startAge = calculateStartAge(birthDate: birthDate, direction: direction)

        // Generate luck pillars
        let luckPillars = generateLuckPillars(
            startingFrom: chart.monthPillar,
            direction: direction,
            startAge: startAge,
            count: 10  // Generate 10 decades
        )

        return LuckPillarResult(
            direction: direction,
            startAge: startAge,
            luckPillars: luckPillars
        )
    }

    /// Determine luck direction based on year stem and gender
    /// Yang year + Male = Forward, Yang year + Female = Backward
    /// Yin year + Male = Backward, Yin year + Female = Forward
    private func determineDirection(yearStem: HeavenlyStem, gender: Gender) -> LuckDirection {
        let isYangYear = yearStem.polarity == .yang

        switch (isYangYear, gender) {
        case (true, .male):
            return .forward   // 阳年男顺行
        case (true, .female):
            return .backward  // 阳年女逆行
        case (false, .male):
            return .backward  // 阴年男逆行
        case (false, .female):
            return .forward   // 阴年女顺行
        }
    }

    /// Calculate the start age for luck pillars
    /// Based on the distance from birth to the next (forward) or previous (backward) solar term
    private func calculateStartAge(birthDate: Date, direction: LuckDirection) -> Int {
        // Simplified calculation:
        // Count days from birth to next/previous Jie (节) solar term
        // 3 days = 1 year of age

        // For simplicity, we'll use an approximate calculation
        // A more accurate implementation would use the SolarTermCalculator

        let calendar = Calendar(identifier: .gregorian)
        let day = calendar.component(.day, from: birthDate)

        // Approximate: assuming solar terms occur around the 4th-8th of each month
        // This is a simplification - proper implementation would calculate exact solar term dates

        let daysToTerm: Int
        if direction == .forward {
            // Days to next solar term (approximately)
            daysToTerm = max(1, 30 - day + 6)  // Approximate next term
        } else {
            // Days from previous solar term
            daysToTerm = max(1, day - 6)
        }

        // Convert days to years (3 days = 1 year)
        let startAge = max(1, (daysToTerm + 2) / 3)

        return min(10, startAge)  // Cap at 10 years
    }

    /// Generate luck pillars from the month pillar
    private func generateLuckPillars(
        startingFrom monthPillar: Pillar,
        direction: LuckDirection,
        startAge: Int,
        count: Int
    ) -> [LuckPillar] {
        var pillars: [LuckPillar] = []
        var currentPillar = monthPillar

        for i in 0..<count {
            // Move to next/previous pillar
            if i > 0 {
                currentPillar = direction == .forward
                    ? nextPillar(from: currentPillar)
                    : previousPillar(from: currentPillar)
            }

            let pillarStartAge = startAge + (i * 10)
            let pillarEndAge = pillarStartAge + 10

            let luckPillar = LuckPillar(
                pillar: currentPillar,
                startAge: pillarStartAge,
                endAge: pillarEndAge,
                index: i
            )

            pillars.append(luckPillar)
        }

        return pillars
    }

    /// Get the next pillar in the 60 Jiazi cycle
    private func nextPillar(from pillar: Pillar) -> Pillar {
        let nextStemIndex = (pillar.stem.rawValue + 1) % 10
        let nextBranchIndex = (pillar.branch.rawValue + 1) % 12

        guard let nextStem = HeavenlyStem(rawValue: nextStemIndex),
              let nextBranch = EarthlyBranch(rawValue: nextBranchIndex) else {
            return pillar
        }

        return Pillar(stem: nextStem, branch: nextBranch)
    }

    /// Get the previous pillar in the 60 Jiazi cycle
    private func previousPillar(from pillar: Pillar) -> Pillar {
        let prevStemIndex = (pillar.stem.rawValue + 9) % 10  // +9 is same as -1 mod 10
        let prevBranchIndex = (pillar.branch.rawValue + 11) % 12  // +11 is same as -1 mod 12

        guard let prevStem = HeavenlyStem(rawValue: prevStemIndex),
              let prevBranch = EarthlyBranch(rawValue: prevBranchIndex) else {
            return pillar
        }

        return Pillar(stem: prevStem, branch: prevBranch)
    }
}

// MARK: - Luck Pillar Analysis

/// Analysis of luck pillar interaction with the natal chart
public struct LuckPillarAnalysis: Sendable {
    /// The luck pillar being analyzed
    public let luckPillar: LuckPillar

    /// Whether the luck pillar supports the Day Master
    public let supportsDayMaster: Bool

    /// Whether the luck pillar brings favorable elements
    public let bringsUsefulGod: Bool

    /// Whether there are clashes with natal chart
    public let hasClashes: Bool

    /// Overall favorability (0-1)
    public let favorability: Double

    /// Description
    public var description: String {
        var parts: [String] = []
        if supportsDayMaster { parts.append("扶身") }
        if bringsUsefulGod { parts.append("用神到位") }
        if hasClashes { parts.append("有冲") }
        return parts.isEmpty ? "平运" : parts.joined(separator: ", ")
    }
}

extension LuckPillarCalculator {
    /// Analyze a luck pillar's interaction with the natal chart
    public func analyzeLuckPillar(
        luckPillar: LuckPillar,
        natalChart: FourPillarsChart,
        usefulGod: FiveElement?
    ) -> LuckPillarAnalysis {
        let dayMaster = natalChart.dayMaster
        let dmElement = dayMaster.element

        // Check if luck pillar supports Day Master
        let luckStem = luckPillar.pillar.stem
        let luckBranch = luckPillar.pillar.branch
        let tenGod = TenGod.relationship(dayMaster: dayMaster, other: luckStem)
        let supportsDM = tenGod.supportsDayMaster

        // Check if luck pillar brings Useful God
        var bringsUsefulGod = false
        if let useful = usefulGod {
            if luckStem.element == useful {
                bringsUsefulGod = true
            }
            // Check hidden stems in luck branch
            for hiddenStem in luckBranch.hiddenStems {
                if hiddenStem.element == useful {
                    bringsUsefulGod = true
                    break
                }
            }
        }

        // Check for clashes with natal branches
        var hasClashes = false
        for natalBranch in natalChart.branches {
            if BranchClash.isClash(luckBranch, natalBranch) {
                hasClashes = true
                break
            }
        }

        // Calculate favorability
        var favorability = 0.5  // Start neutral
        if supportsDM { favorability += 0.2 }
        if bringsUsefulGod { favorability += 0.3 }
        if hasClashes { favorability -= 0.2 }
        favorability = max(0, min(1, favorability))

        return LuckPillarAnalysis(
            luckPillar: luckPillar,
            supportsDayMaster: supportsDM,
            bringsUsefulGod: bringsUsefulGod,
            hasClashes: hasClashes,
            favorability: favorability
        )
    }

    /// Get current age from birth date
    public func currentAge(from birthDate: Date) -> Int {
        let calendar = Calendar(identifier: .gregorian)
        let now = Date()
        let components = calendar.dateComponents([.year], from: birthDate, to: now)
        return components.year ?? 0
    }
}
