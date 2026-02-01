//
//  DayMasterStrengthCalculator.swift
//  Oraculum
//
//  Day Master Strength Analysis (日主强弱分析)
//  Calculates whether the Day Master is strong or weak based on traditional BaZi principles
//

import Foundation

// MARK: - Strength Level

/// The strength level of the Day Master
public enum DayMasterStrengthLevel: String, Sendable, Codable, CaseIterable {
    case extremelyStrong = "extremely_strong"    // 身极旺 - Needs heavy control
    case strong = "strong"                        // 身旺 - Needs some control/drain
    case slightlyStrong = "slightly_strong"      // 身偏强 - Balanced leaning strong
    case balanced = "balanced"                    // 中和 - Perfect balance (rare)
    case slightlyWeak = "slightly_weak"          // 身偏弱 - Balanced leaning weak
    case weak = "weak"                            // 身弱 - Needs support
    case extremelyWeak = "extremely_weak"        // 身极弱 - Special "follow" pattern

    /// Chinese name
    public var chineseName: String {
        switch self {
        case .extremelyStrong: return "身极旺"
        case .strong: return "身旺"
        case .slightlyStrong: return "身偏强"
        case .balanced: return "中和"
        case .slightlyWeak: return "身偏弱"
        case .weak: return "身弱"
        case .extremelyWeak: return "身极弱"
        }
    }

    /// Whether the Day Master needs support (Resource/Companion elements)
    public var needsSupport: Bool {
        switch self {
        case .weak, .extremelyWeak, .slightlyWeak:
            return true
        default:
            return false
        }
    }

    /// Whether the Day Master needs control/drain (Wealth/Officer/Output elements)
    public var needsControl: Bool {
        switch self {
        case .strong, .extremelyStrong, .slightlyStrong:
            return true
        default:
            return false
        }
    }
}

// MARK: - Strength Analysis Result

/// Complete result of Day Master strength analysis
public struct DayMasterStrengthAnalysis: Sendable, Codable {
    /// The overall strength level
    public let strengthLevel: DayMasterStrengthLevel

    /// Numeric score (0-100, 50 = balanced)
    /// Below 50 = weak, Above 50 = strong
    public let strengthScore: Double

    /// Seasonal strength contribution (得令)
    public let seasonalStrength: Double

    /// Rooting strength contribution (得根)
    public let rootingStrength: Double

    /// Support from stems contribution (得助)
    public let supportStrength: Double

    /// Combined energy of supporting elements
    public let supportingEnergy: Double

    /// Combined energy of draining/controlling elements
    public let drainingEnergy: Double

    /// Detailed breakdown
    public let breakdown: [String: Double]

    public init(
        strengthLevel: DayMasterStrengthLevel,
        strengthScore: Double,
        seasonalStrength: Double,
        rootingStrength: Double,
        supportStrength: Double,
        supportingEnergy: Double,
        drainingEnergy: Double,
        breakdown: [String: Double]
    ) {
        self.strengthLevel = strengthLevel
        self.strengthScore = strengthScore
        self.seasonalStrength = seasonalStrength
        self.rootingStrength = rootingStrength
        self.supportStrength = supportStrength
        self.supportingEnergy = supportingEnergy
        self.drainingEnergy = drainingEnergy
        self.breakdown = breakdown
    }
}

// MARK: - Day Master Strength Calculator

/// Calculates Day Master strength using traditional BaZi methodology
public struct DayMasterStrengthCalculator: Sendable {

    public init() {}

    /// Analyzes the strength of the Day Master in a Four Pillars chart
    /// - Parameter chart: The complete Four Pillars chart
    /// - Returns: Complete strength analysis
    public func analyze(chart: FourPillarsChart) -> DayMasterStrengthAnalysis {
        let dayMaster = chart.dayMaster
        let monthBranch = chart.monthPillar.branch

        var breakdown: [String: Double] = [:]

        // 1. Seasonal Strength (得令 - De Ling)
        // The Day Master's element is in season or out of season
        let seasonalStrength = calculateSeasonalStrength(dayMaster: dayMaster, monthBranch: monthBranch)
        breakdown["Seasonal (得令)"] = seasonalStrength

        // 2. Rooting Strength (得根 - De Gen)
        // Count hidden stems in branches that match Day Master's element
        let rootingStrength = calculateRootingStrength(dayMaster: dayMaster, branches: chart.branches)
        breakdown["Rooting (得根)"] = rootingStrength

        // 3. Support Strength (得助 - De Zhu)
        // Support from other stems (Companion, Rob Wealth, Resource)
        let supportStrength = calculateSupportStrength(dayMaster: dayMaster, stems: chart.stems)
        breakdown["Support (得助)"] = supportStrength

        // 4. Calculate total supporting vs draining energy
        let (supportingEnergy, drainingEnergy) = calculateEnergyBalance(dayMaster: dayMaster, chart: chart)
        breakdown["Supporting Energy"] = supportingEnergy
        breakdown["Draining Energy"] = drainingEnergy

        // 5. Calculate final score
        // Seasonal strength is most important in traditional BaZi
        let baseScore = 50.0 // Start at balanced
        let seasonalWeight = 0.35
        let rootingWeight = 0.25
        let supportWeight = 0.20
        let balanceWeight = 0.20

        // Convert to contributions
        // Seasonal: -20 to +20
        let seasonalContribution = seasonalStrength * seasonalWeight * 40 - 20 * seasonalWeight
        // Rooting: 0 to +15
        let rootingContribution = rootingStrength * rootingWeight * 30
        // Support: -10 to +10
        let supportContribution = supportStrength * supportWeight * 20 - 10 * supportWeight
        // Energy balance: -15 to +15
        let energyRatio = supportingEnergy > 0 ? (supportingEnergy - drainingEnergy) / max(supportingEnergy + drainingEnergy, 1) : 0
        let balanceContribution = energyRatio * balanceWeight * 30

        var finalScore = baseScore + seasonalContribution + rootingContribution + supportContribution + balanceContribution
        finalScore = max(0, min(100, finalScore))

        // Determine strength level based on score
        let strengthLevel = determineStrengthLevel(score: finalScore)

        return DayMasterStrengthAnalysis(
            strengthLevel: strengthLevel,
            strengthScore: finalScore,
            seasonalStrength: seasonalStrength,
            rootingStrength: rootingStrength,
            supportStrength: supportStrength,
            supportingEnergy: supportingEnergy,
            drainingEnergy: drainingEnergy,
            breakdown: breakdown
        )
    }

    // MARK: - Seasonal Strength (得令)

    /// Calculate seasonal strength based on Month Branch
    /// Traditional rule: Element is strong in its season, weak in opposite season
    private func calculateSeasonalStrength(dayMaster: HeavenlyStem, monthBranch: EarthlyBranch) -> Double {
        let dmElement = dayMaster.element

        // Seasonal element mapping
        // Spring (寅卯): Wood prosperous, Fire phase, Earth dead, Metal captive, Water rest
        // Summer (巳午): Fire prosperous, Earth phase, Metal dead, Water captive, Wood rest
        // Late Summer (辰戌丑未): Earth prosperous but complex
        // Autumn (申酉): Metal prosperous, Water phase, Wood dead, Fire captive, Earth rest
        // Winter (亥子): Water prosperous, Wood phase, Fire dead, Earth captive, Metal rest

        let seasonalElement = getSeasonalElement(monthBranch: monthBranch)

        // Full strength: Day Master matches seasonal element
        if dmElement == seasonalElement {
            return 1.0 // 得令 - In season
        }

        // Strong: Day Master is produced by seasonal element
        if dmElement == seasonalElement.produces {
            return 0.7 // 相 - Phase position
        }

        // Moderate: Day Master produces seasonal element (resting)
        if dmElement.produces == seasonalElement {
            return 0.4 // 休 - Resting
        }

        // Weak: Day Master controls seasonal element (captive)
        if dmElement.controls == seasonalElement {
            return 0.2 // 囚 - Captive
        }

        // Very weak: Day Master is controlled by seasonal element (dead)
        if dmElement.controlledBy == seasonalElement {
            return 0.0 // 死 - Dead
        }

        return 0.5 // Default moderate
    }

    /// Get the dominant element for a month branch
    private func getSeasonalElement(monthBranch: EarthlyBranch) -> FiveElement {
        switch monthBranch {
        case .yin, .mao:      // Spring
            return .wood
        case .si, .wu:        // Summer
            return .fire
        case .shen, .you:     // Autumn
            return .metal
        case .hai, .zi:       // Winter
            return .water
        case .chen, .xu, .chou, .wei:  // Earth months (season transitions)
            return .earth
        }
    }

    // MARK: - Rooting Strength (得根)

    /// Calculate rooting strength from hidden stems in branches
    private func calculateRootingStrength(dayMaster: HeavenlyStem, branches: [EarthlyBranch]) -> Double {
        let dmElement = dayMaster.element
        var rootCount = 0.0

        for branch in branches {
            let hiddenStems = branch.hiddenStems
            for (index, stem) in hiddenStems.enumerated() {
                if stem.element == dmElement {
                    // Primary hidden stem (本气) counts most
                    // Secondary and tertiary count less
                    switch index {
                    case 0: rootCount += 1.0   // Primary
                    case 1: rootCount += 0.5   // Secondary
                    case 2: rootCount += 0.3   // Tertiary
                    default: break
                    }
                }

                // Same element producing Day Master (Resource) also helps
                if stem.element == dmElement.producedBy {
                    switch index {
                    case 0: rootCount += 0.5
                    case 1: rootCount += 0.25
                    case 2: rootCount += 0.15
                    default: break
                    }
                }
            }
        }

        // Normalize to 0-1 range (max possible ~8 with all roots)
        return min(1.0, rootCount / 4.0)
    }

    // MARK: - Support Strength (得助)

    /// Calculate support from other stems
    private func calculateSupportStrength(dayMaster: HeavenlyStem, stems: [HeavenlyStem]) -> Double {
        var supportCount = 0.0
        var drainCount = 0.0

        for stem in stems where stem != dayMaster {
            let tenGod = TenGod.relationship(dayMaster: dayMaster, other: stem)

            if tenGod.supportsDayMaster {
                supportCount += tenGod.strengthContribution
            } else if tenGod.drainsDayMaster {
                drainCount += abs(tenGod.strengthContribution)
            }
        }

        // Calculate relative support (0 = all drain, 0.5 = balanced, 1 = all support)
        let total = supportCount + drainCount
        if total == 0 { return 0.5 }

        return supportCount / total
    }

    // MARK: - Energy Balance

    /// Calculate total supporting vs draining energy from whole chart
    private func calculateEnergyBalance(dayMaster: HeavenlyStem, chart: FourPillarsChart) -> (supporting: Double, draining: Double) {
        var supporting = 0.0
        var draining = 0.0

        // Analyze all stems
        for stem in chart.stems where stem != dayMaster {
            let tenGod = TenGod.relationship(dayMaster: dayMaster, other: stem)
            if tenGod.supportsDayMaster {
                supporting += abs(tenGod.strengthContribution)
            } else {
                draining += abs(tenGod.strengthContribution)
            }
        }

        // Analyze hidden stems in branches
        for branch in chart.branches {
            for (index, stem) in branch.hiddenStems.enumerated() {
                // Weight by position (primary, secondary, tertiary)
                let weight: Double
                switch index {
                case 0: weight = 0.6
                case 1: weight = 0.3
                case 2: weight = 0.1
                default: weight = 0
                }

                let tenGod = TenGod.relationship(dayMaster: dayMaster, other: stem)
                if tenGod.supportsDayMaster {
                    supporting += abs(tenGod.strengthContribution) * weight
                } else {
                    draining += abs(tenGod.strengthContribution) * weight
                }
            }
        }

        return (supporting, draining)
    }

    // MARK: - Strength Level Determination

    /// Determine strength level from numeric score
    private func determineStrengthLevel(score: Double) -> DayMasterStrengthLevel {
        switch score {
        case 85...100:
            return .extremelyStrong
        case 65..<85:
            return .strong
        case 55..<65:
            return .slightlyStrong
        case 45..<55:
            return .balanced
        case 35..<45:
            return .slightlyWeak
        case 15..<35:
            return .weak
        default:
            return .extremelyWeak
        }
    }
}
