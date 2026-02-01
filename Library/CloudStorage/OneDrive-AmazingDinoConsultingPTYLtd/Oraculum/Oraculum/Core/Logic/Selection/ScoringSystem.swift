//
//  ScoringSystem.swift
//  Oraculum
//
//  Advanced Utility-Based Scoring System (High-Precision Ba Zi Algorithm)
//  Calculates context-aware scores based on user intent, not just general luck.
//

import Foundation

// MARK: - Qualitative Rating

/// Traditional qualitative rating system (replaces numeric-only scoring)
public enum QualitativeRating: String, Sendable, Codable, CaseIterable {
    case supremelyAuspicious = "SUPREMELY_AUSPICIOUS"  // 大吉 - Extremely favorable
    case auspicious = "AUSPICIOUS"                      // 吉 - Favorable
    case slightlyAuspicious = "SLIGHTLY_AUSPICIOUS"    // 小吉 - Slightly favorable
    case neutral = "NEUTRAL"                            // 平 - Neutral
    case slightlyInauspicious = "SLIGHTLY_INAUSPICIOUS" // 小凶 - Slightly unfavorable
    case inauspicious = "INAUSPICIOUS"                  // 凶 - Unfavorable
    case supremelyInauspicious = "SUPREMELY_INAUSPICIOUS" // 大凶 - Extremely unfavorable

    public var chineseName: String {
        switch self {
        case .supremelyAuspicious: return "大吉"
        case .auspicious: return "吉"
        case .slightlyAuspicious: return "小吉"
        case .neutral: return "平"
        case .slightlyInauspicious: return "小凶"
        case .inauspicious: return "凶"
        case .supremelyInauspicious: return "大凶"
        }
    }

    public var emoji: String {
        switch self {
        case .supremelyAuspicious: return "🌟"
        case .auspicious: return "✨"
        case .slightlyAuspicious: return "✅"
        case .neutral: return "➖"
        case .slightlyInauspicious: return "⚠️"
        case .inauspicious: return "❌"
        case .supremelyInauspicious: return "🚫"
        }
    }

    /// Traditional weight value for calculations
    public var weight: Double {
        switch self {
        case .supremelyAuspicious: return 1.0
        case .auspicious: return 0.75
        case .slightlyAuspicious: return 0.55
        case .neutral: return 0.5
        case .slightlyInauspicious: return 0.35
        case .inauspicious: return 0.2
        case .supremelyInauspicious: return 0.0
        }
    }
}

// MARK: - Personal Factors

/// Personal factors derived from user's Ba Zi chart
public struct PersonalFactors: Sendable {
    public let userChart: FourPillarsChart
    public let usefulGod: UsefulGod?
    public let clashes: [ClashType]
    public let penalties: [PenaltyType]

    // Enhanced analysis data
    public let usefulGodResult: UsefulGodResult?
    public let strengthAnalysis: DayMasterStrengthAnalysis?
    public let patternAnalysis: PatternAnalysisResult?
    public let climateAnalysis: ClimateAnalysisResult?

    // New: Branch combination analysis with the date
    public let branchCombinationAnalysis: BranchCombinationAnalyzer.AnalysisResult?

    // New: Void (空亡) analysis
    public let voidAnalysis: VoidAnalysis?

    // New: Nayin chart result
    public let nayinResult: NayinChartResult?

    public init(
        userChart: FourPillarsChart,
        usefulGod: UsefulGod? = nil,
        clashes: [ClashType] = [],
        penalties: [PenaltyType] = [],
        usefulGodResult: UsefulGodResult? = nil,
        strengthAnalysis: DayMasterStrengthAnalysis? = nil,
        patternAnalysis: PatternAnalysisResult? = nil,
        climateAnalysis: ClimateAnalysisResult? = nil,
        branchCombinationAnalysis: BranchCombinationAnalyzer.AnalysisResult? = nil,
        voidAnalysis: VoidAnalysis? = nil,
        nayinResult: NayinChartResult? = nil
    ) {
        self.userChart = userChart
        self.usefulGod = usefulGod
        self.clashes = clashes
        self.penalties = penalties
        self.usefulGodResult = usefulGodResult
        self.strengthAnalysis = strengthAnalysis
        self.patternAnalysis = patternAnalysis
        self.climateAnalysis = climateAnalysis
        self.branchCombinationAnalysis = branchCombinationAnalysis
        self.voidAnalysis = voidAnalysis
        self.nayinResult = nayinResult
    }

    /// Check if user has a personal day clash (Fan Yin - most dangerous)
    public var hasPersonalDayClash: Bool {
        clashes.contains(.dayClash)
    }

    /// Creates enhanced PersonalFactors with full BaZi analysis
    public static func createEnhanced(
        userChart: FourPillarsChart,
        dayBranch: EarthlyBranch
    ) -> PersonalFactors {
        // Calculate full analysis with validation
        let usefulGodCalculator = UsefulGodCalculator()
        let usefulGodResult = usefulGodCalculator.calculateWithValidation(chart: userChart)

        // Create legacy UsefulGod from result (adjusted by validation effectiveness)
        let effectiveStrength = usefulGodResult.validation?.effectiveness ?? usefulGodResult.confidence
        let usefulGod = UsefulGod(
            element: usefulGodResult.usefulGod,
            strength: usefulGodResult.confidence * effectiveStrength
        )

        // Check for clashes using branch relationships
        var clashes: [ClashType] = []
        if dayBranch == userChart.dayPillar.branch.clash {
            clashes.append(.dayClash)
        }
        if dayBranch == userChart.yearPillar.branch.clash {
            clashes.append(.yearClash)
        }
        if dayBranch == userChart.monthPillar.branch.clash {
            clashes.append(.monthClash)
        }
        if dayBranch == userChart.hourPillar.branch.clash {
            clashes.append(.hourClash)
        }

        // Check for penalties
        var penalties: [PenaltyType] = []
        let userBranches = userChart.branches
        for userBranch in userBranches {
            if userBranch.penalties.contains(dayBranch) {
                // Determine penalty type
                switch dayBranch {
                case .yin, .si, .shen:
                    if !penalties.contains(.ungratefulPenalty) {
                        penalties.append(.ungratefulPenalty)
                    }
                case .chou, .xu, .wei:
                    if !penalties.contains(.bullyingPenalty) {
                        penalties.append(.bullyingPenalty)
                    }
                case .zi, .mao:
                    if !penalties.contains(.uncivilizedPenalty) {
                        penalties.append(.uncivilizedPenalty)
                    }
                case .chen, .wu, .you, .hai:
                    if dayBranch == userBranch && !penalties.contains(.selfPenalty) {
                        penalties.append(.selfPenalty)
                    }
                }
            }
        }

        // NEW: Branch combination analysis between user chart and day
        let branchAnalyzer = BranchCombinationAnalyzer()
        let combinedBranches = userBranches + [dayBranch]
        let branchAnalysis = branchAnalyzer.analyze(branches: combinedBranches)

        // NEW: Void (空亡) analysis
        let voidCalculator = VoidCalculator()
        let voidAnalysis = voidCalculator.analyzeChart(userChart)

        // NEW: Nayin analysis
        let nayinCalculator = NayinCalculator()
        let nayinResult = nayinCalculator.calculateChart(userChart)

        return PersonalFactors(
            userChart: userChart,
            usefulGod: usefulGod,
            clashes: clashes,
            penalties: penalties,
            usefulGodResult: usefulGodResult,
            strengthAnalysis: usefulGodResult.strengthAnalysis,
            patternAnalysis: usefulGodResult.patternAnalysis,
            climateAnalysis: usefulGodResult.climateAnalysis,
            branchCombinationAnalysis: branchAnalysis,
            voidAnalysis: voidAnalysis,
            nayinResult: nayinResult
        )
    }
}

// MARK: - Clash Types

/// Types of clashes between day and user's chart
public enum ClashType: String, Sendable, CaseIterable {
    case yearClash       // Day clashes with user's year branch
    case dayClash        // Day clashes with user's day branch (CRITICAL - Fan Yin)
    case monthClash      // Day clashes with user's month branch
    case hourClash       // Day clashes with user's hour branch

    public var severity: Int {
        switch self {
        case .yearClash: return -40  // Year Breaker for the person
        case .dayClash: return -100  // CRITICAL: Fan Yin - immediate override
        case .monthClash: return -20
        case .hourClash: return -10
        }
    }

    public var isCritical: Bool {
        self == .dayClash
    }
}

// MARK: - Penalty Types

/// Types of penalties (三刑)
public enum PenaltyType: String, Sendable, CaseIterable {
    case ungratefulPenalty    // 無恩之刑: Yin-Si-Shen
    case bullyingPenalty      // 恃勢之刑: Chou-Xu-Wei
    case uncivilizedPenalty   // 無禮之刑: Zi-Mao
    case selfPenalty          // 自刑: Chen-Chen, Wu-Wu, You-You, Hai-Hai

    public var severity: Int {
        switch self {
        case .ungratefulPenalty: return -25
        case .bullyingPenalty: return -20
        case .uncivilizedPenalty: return -15
        case .selfPenalty: return -10
        }
    }
}

// MARK: - Useful God

/// The Useful God (喜用神) - the element needed for balance
public struct UsefulGod: Sendable, Codable {
    public let element: FiveElement
    public let strength: Double  // 0.0 - 1.0, how strongly it's needed

    public init(element: FiveElement, strength: Double = 0.5) {
        self.element = element
        self.strength = max(0, min(1, strength))
    }
}

// MARK: - Day Officer Status

/// Status of the Day Officer (can be compromised by other factors)
public enum DayOfficerStatus: String, Sendable {
    case normal         // Officer operates as expected
    case compromised    // Officer negated by clash/breaker
    case enhanced       // Officer strengthened by auspicious factors

    public var displaySuffix: String {
        switch self {
        case .normal: return ""
        case .compromised: return " ⚠️"
        case .enhanced: return " ✨"
        }
    }
}

// MARK: - Visual Severity

/// Visual severity for UI rendering
public enum VisualSeverity: String, Sendable {
    case excellent = "EXCELLENT"
    case good = "GOOD"
    case neutral = "NEUTRAL"
    case warning = "WARNING"
    case highWarning = "HIGH_WARNING"
    case critical = "CRITICAL"

    public var colorName: String {
        switch self {
        case .excellent: return "gold"
        case .good: return "green"
        case .neutral: return "gray"
        case .warning: return "orange"
        case .highWarning: return "deepOrange"
        case .critical: return "red"
        }
    }
}

// MARK: - Scoring Result

/// Result of the scoring calculation with professional insights
public struct ScoringResult: Sendable {
    public let totalScore: Int
    public let baseScore: Int
    public let dayOfficerScore: Int
    public let lunarStarsScore: Int
    public let personalScore: Int
    public let usefulGodScore: Int
    public let breakdown: [String: Int]
    public let warnings: [String]
    public let instantFail: Bool

    // Advanced fields for professional insights
    public let dayOfficerStatus: DayOfficerStatus
    public let visualSeverity: VisualSeverity
    public let professionalTitle: String
    public let professionalInsight: String
    public let alternativeDateSuggestion: String?
    public let isYearBreaker: Bool
    public let hasPersonalClash: Bool

    public init(
        totalScore: Int,
        baseScore: Int,
        dayOfficerScore: Int,
        lunarStarsScore: Int,
        personalScore: Int,
        usefulGodScore: Int,
        breakdown: [String: Int],
        warnings: [String],
        instantFail: Bool,
        dayOfficerStatus: DayOfficerStatus = .normal,
        visualSeverity: VisualSeverity = .neutral,
        professionalTitle: String = "",
        professionalInsight: String = "",
        alternativeDateSuggestion: String? = nil,
        isYearBreaker: Bool = false,
        hasPersonalClash: Bool = false
    ) {
        self.totalScore = totalScore
        self.baseScore = baseScore
        self.dayOfficerScore = dayOfficerScore
        self.lunarStarsScore = lunarStarsScore
        self.personalScore = personalScore
        self.usefulGodScore = usefulGodScore
        self.breakdown = breakdown
        self.warnings = warnings
        self.instantFail = instantFail
        self.dayOfficerStatus = dayOfficerStatus
        self.visualSeverity = visualSeverity
        self.professionalTitle = professionalTitle
        self.professionalInsight = professionalInsight
        self.alternativeDateSuggestion = alternativeDateSuggestion
        self.isYearBreaker = isYearBreaker
        self.hasPersonalClash = hasPersonalClash
    }

    public var recommendation: SelectionRecommendation {
        if instantFail || hasPersonalClash {
            return .avoid
        }
        switch totalScore {
        case 80...100: return .excellent
        case 60..<80: return .good
        case 40..<60: return .neutral
        case 20..<40: return .caution
        default: return .avoid
        }
    }
}

// MARK: - Selection Recommendation

/// Recommendation level for day selection
public enum SelectionRecommendation: String, Sendable, Codable {
    case excellent = "Excellent"   // Score 80-100
    case good = "Good"             // Score 60-79
    case neutral = "Neutral"       // Score 40-59
    case caution = "Caution"       // Score 20-39
    case avoid = "Avoid"           // Score 0-19 or instant fail

    public var emoji: String {
        switch self {
        case .excellent: return "⭐️"
        case .good: return "✅"
        case .neutral: return "➖"
        case .caution: return "⚠️"
        case .avoid: return "❌"
        }
    }

    public var colorName: String {
        switch self {
        case .excellent: return "gold"
        case .good: return "green"
        case .neutral: return "gray"
        case .caution: return "orange"
        case .avoid: return "red"
        }
    }
}

// MARK: - Scoring System

/// Advanced Utility-Based Scoring System
/// Calculates context-aware scores based on user intent
public struct ScoringSystem: Sendable {

    public init() {}

    /// Calculates the utility score for a specific date and user intent
    /// - Parameters:
    ///   - dayOfficer: The Day Officer for the day
    ///   - lunarStars: Lunar Stars present on the day
    ///   - activity: The intended activity (determines score context)
    ///   - dayPillar: The day's pillar
    ///   - monthPillar: The month's pillar
    ///   - yearPillar: The year's pillar
    ///   - personalFactors: User's personal factors (optional)
    /// - Returns: Complete scoring result with professional insights
    public func calculateScore(
        dayOfficer: DayOfficer,
        lunarStars: [LunarStar],
        activity: Activity,
        dayPillar: Pillar,
        monthPillar: Pillar? = nil,
        yearPillar: Pillar? = nil,
        personalFactors: PersonalFactors?
    ) -> ScoringResult {
        var breakdown: [String: Int] = [:]
        var warnings: [String] = []
        var instantFail = false
        var dayOfficerStatus: DayOfficerStatus = .normal
        var isYearBreaker = false
        var hasPersonalClash = false

        // Base score starts at 60 (neutral-positive)
        var baseScore = 60
        breakdown["Base"] = baseScore

        // LEVEL 1: Year Breaker (Sui Po) Detection
        // Day Branch clashes with Annual Branch
        if let yearPillar = yearPillar {
            if dayPillar.branch == yearPillar.branch.clash {
                isYearBreaker = true

                // Context-aware Year Breaker scoring
                if activity.isConstructive {
                    baseScore -= 50
                    warnings.append("score.yearBreakerConstructive")
                    dayOfficerStatus = .compromised
                } else if activity.isDestructive {
                    baseScore += 20
                    warnings.append("score.yearBreakerDestructive")
                } else {
                    baseScore -= 20
                    warnings.append("warning.yearBreaker")
                }
                breakdown["Year Breaker"] = isYearBreaker ? (activity.isDestructive ? 20 : -50) : 0
            }
        }

        // LEVEL 2: Personal Clash (Fan Yin) - CRITICAL
        // Day Branch clashes with User's Day Branch
        if let factors = personalFactors, factors.hasPersonalDayClash {
            instantFail = true
            hasPersonalClash = true
            baseScore = 0
            warnings.append("score.personalClashCritical")
            breakdown["Personal Clash (CRITICAL)"] = -100

            // Early return for personal clash
            return ScoringResult(
                totalScore: 0,
                baseScore: 0,
                dayOfficerScore: 0,
                lunarStarsScore: 0,
                personalScore: -100,
                usefulGodScore: 0,
                breakdown: breakdown,
                warnings: warnings,
                instantFail: true,
                dayOfficerStatus: .compromised,
                visualSeverity: .critical,
                professionalTitle: "score.title.personalClash",
                professionalInsight: "score.insight.personalClash",
                alternativeDateSuggestion: nil,
                isYearBreaker: isYearBreaker,
                hasPersonalClash: true
            )
        }

        // LEVEL 3: Day Officer Contextualization
        var officerScore = dayOfficerScore(dayOfficer, for: activity)

        // Officer status can be compromised by Year Breaker
        if isYearBreaker && dayOfficer.isGenerallyAuspicious {
            // "Broken Open" - energy leaks out
            officerScore -= 10
            dayOfficerStatus = .compromised
            warnings.append("score.officerCompromised")
            breakdown["Officer Compromised"] = -10
        }

        breakdown["Day Officer (\(dayOfficer.chineseName))"] = officerScore

        // LEVEL 4: Lunar Stars
        var starsScore = 0
        var hasTianDe = false

        for star in lunarStars {
            if star == .tianDe || star == .yueDe {
                hasTianDe = true
                dayOfficerStatus = dayOfficerStatus == .compromised ? .normal : .enhanced
            }

            if star == .suiPo && !isYearBreaker {
                // Only add if not already counted as year breaker
                starsScore += star.baseScoreImpact
            } else if star != .suiPo {
                starsScore += star.baseScoreImpact
            }
            breakdown["Star: \(star.chineseName)"] = star.baseScoreImpact
        }

        // Heavenly Virtue nullifies some negative star effects
        if hasTianDe {
            for star in lunarStars where star.canBeNullified {
                let nullified = abs(star.baseScoreImpact) / 2
                starsScore += nullified
                breakdown["Nullified: \(star.chineseName)"] = nullified
            }
        }

        // LEVEL 5: Personal Factors (Non-Critical Clashes)
        var personalScore = 0
        var usefulGodScore = 0

        if let factors = personalFactors {
            // Non-day clashes
            for clash in factors.clashes where clash != .dayClash {
                personalScore += clash.severity
                breakdown["Personal Clash (\(clash.rawValue))"] = clash.severity
                warnings.append("warning.dayClash")
            }

            // Penalties
            for penalty in factors.penalties {
                personalScore += penalty.severity
                breakdown["Penalty (\(penalty.rawValue))"] = penalty.severity
            }

            // LEVEL 6: Useful God Resonance (Enhanced)
            if let usefulGodResult = factors.usefulGodResult {
                let dayElement = dayPillar.stem.element
                let usefulGodElement = usefulGodResult.usefulGod
                let confidence = usefulGodResult.confidence

                // Check against Useful God
                if dayElement == usefulGodElement {
                    // Direct support - best case
                    let bonus = Int(30 * confidence)
                    usefulGodScore = bonus
                    breakdown["Useful God Support (Direct)"] = bonus
                } else if dayElement.produces == usefulGodElement {
                    // Indirect support (produces needed element)
                    let bonus = Int(20 * confidence)
                    usefulGodScore = bonus
                    breakdown["Useful God Support (Indirect)"] = bonus
                } else if dayElement == usefulGodResult.favorableGod {
                    // Matches favorable god
                    let bonus = Int(15 * confidence)
                    usefulGodScore = bonus
                    breakdown["Favorable God Match"] = bonus
                } else if dayElement == usefulGodResult.unfavorableGod {
                    // Matches unfavorable god - penalty
                    let penalty = Int(-25 * confidence)
                    usefulGodScore = penalty
                    breakdown["Unfavorable God Match"] = penalty
                    warnings.append("score.unfavorableElement")
                } else if let enemyGod = usefulGodResult.enemyGod, dayElement == enemyGod {
                    // Matches enemy god - stronger penalty
                    let penalty = Int(-20 * confidence)
                    usefulGodScore = penalty
                    breakdown["Enemy God Match"] = penalty
                    warnings.append("score.enemyElement")
                } else if dayElement.controls == usefulGodElement {
                    // Day element suppresses user's needed element
                    let penalty = Int(-15 * confidence)
                    usefulGodScore = penalty
                    breakdown["Element Clash"] = penalty
                    warnings.append("score.elementClash")
                }
            } else if let usefulGod = factors.usefulGod {
                // Fallback to legacy UsefulGod
                let dayElement = dayPillar.stem.element

                if dayElement.controls == usefulGod.element {
                    let penalty = Int(-20 * usefulGod.strength)
                    usefulGodScore = penalty
                    breakdown["Element Clash"] = penalty
                    warnings.append("score.elementClash")
                } else if dayElement == usefulGod.element {
                    let bonus = Int(25 * usefulGod.strength)
                    usefulGodScore = bonus
                    breakdown["Element Support (Direct)"] = bonus
                } else if dayElement.produces == usefulGod.element {
                    let bonus = Int(15 * usefulGod.strength)
                    usefulGodScore = bonus
                    breakdown["Element Support (Indirect)"] = bonus
                }
            }

            // LEVEL 7: Climate Adjustment Bonus (New)
            if let climateAnalysis = factors.climateAnalysis {
                if climateAnalysis.urgency > 0 {
                    let dayElement = dayPillar.stem.element
                    if let neededElement = climateAnalysis.adjustmentElement {
                        if dayElement == neededElement {
                            // Day provides climate adjustment
                            let bonus = Int(15 * climateAnalysis.urgency)
                            usefulGodScore += bonus
                            breakdown["Climate Adjustment Bonus"] = bonus
                        } else if dayElement.produces == neededElement {
                            // Day indirectly supports climate adjustment
                            let bonus = Int(8 * climateAnalysis.urgency)
                            usefulGodScore += bonus
                            breakdown["Climate Support Bonus"] = bonus
                        }
                    }
                }
            }
        }

        // Calculate total
        let totalScore = max(0, min(100,
            baseScore + officerScore + starsScore + personalScore + usefulGodScore
        ))

        // Determine visual severity
        let visualSeverity = determineVisualSeverity(
            score: totalScore,
            isYearBreaker: isYearBreaker,
            hasPersonalClash: hasPersonalClash,
            activity: activity
        )

        // Generate professional insights
        let (title, insight) = generateProfessionalInsight(
            score: totalScore,
            activity: activity,
            isYearBreaker: isYearBreaker,
            dayOfficer: dayOfficer,
            dayOfficerStatus: dayOfficerStatus
        )

        return ScoringResult(
            totalScore: totalScore,
            baseScore: baseScore,
            dayOfficerScore: officerScore,
            lunarStarsScore: starsScore,
            personalScore: personalScore,
            usefulGodScore: usefulGodScore,
            breakdown: breakdown,
            warnings: warnings,
            instantFail: instantFail,
            dayOfficerStatus: dayOfficerStatus,
            visualSeverity: visualSeverity,
            professionalTitle: title,
            professionalInsight: insight,
            alternativeDateSuggestion: nil,
            isYearBreaker: isYearBreaker,
            hasPersonalClash: hasPersonalClash
        )
    }

    // MARK: - Day Officer Scoring

    /// Calculates Day Officer score for a specific activity
    private func dayOfficerScore(_ officer: DayOfficer, for activity: Activity) -> Int {
        // Favorable officers give bonus points
        if activity.favorableDayOfficers.contains(officer) {
            return 25
        }

        // Unfavorable officers give penalty
        if activity.unfavorableDayOfficers.contains(officer) {
            return officer == .po ? -50 : -25  // Po (Break) is especially bad
        }

        // Neutral effect based on officer's general nature
        return officer.generalAuspiciousness * 5
    }

    // MARK: - Visual Severity

    private func determineVisualSeverity(
        score: Int,
        isYearBreaker: Bool,
        hasPersonalClash: Bool,
        activity: Activity
    ) -> VisualSeverity {
        if hasPersonalClash {
            return .critical
        }
        if isYearBreaker && activity.isConstructive {
            return .highWarning
        }
        switch score {
        case 80...100: return .excellent
        case 60..<80: return .good
        case 40..<60: return .neutral
        case 20..<40: return .warning
        default: return .highWarning
        }
    }

    // MARK: - Professional Insights

    private func generateProfessionalInsight(
        score: Int,
        activity: Activity,
        isYearBreaker: Bool,
        dayOfficer: DayOfficer,
        dayOfficerStatus: DayOfficerStatus
    ) -> (title: String, insight: String) {
        // Year Breaker context
        if isYearBreaker {
            if activity.isConstructive {
                return (
                    "score.title.unstableFoundation",
                    "score.insight.yearBreakerConstructive"
                )
            } else if activity.isDestructive {
                return (
                    "score.title.viableRemoval",
                    "score.insight.yearBreakerDestructive"
                )
            }
        }

        // Compromised Officer
        if dayOfficerStatus == .compromised {
            return (
                "score.title.deceptiveOpen",
                "score.insight.compromisedOfficer"
            )
        }

        // Score-based insights
        switch score {
        case 80...100:
            return (
                "score.title.optimalWindow",
                "score.insight.excellent"
            )
        case 60..<80:
            return (
                "score.title.favorableConditions",
                "score.insight.good"
            )
        case 40..<60:
            return (
                "score.title.neutralEnergy",
                "score.insight.neutral"
            )
        case 20..<40:
            return (
                "score.title.exerciseCaution",
                "score.insight.caution"
            )
        default:
            return (
                "score.title.strategicPause",
                "score.insight.avoid"
            )
        }
    }
}

// MARK: - Activity Extensions

extension Activity {
    /// Constructive activities are harmed by Year Breaker
    public var isConstructive: Bool {
        switch self {
        case .signContract, .negotiation, .openBusiness, .launchProduct,
             .investMoney, .closeDeal, .hireEmployee, .startPartnership,
             .marriage, .engagement, .moveHouse, .startJob,
             .groundbreaking, .grandOpening, .startConstruction:
            return true
        default:
            return false
        }
    }

    /// Destructive/removal activities benefit from Year Breaker energy
    public var isDestructive: Bool {
        switch self {
        case .demolition, .surgery, .funeral:
            return true
        default:
            return false
        }
    }
}

// MARK: - Day Officer Extensions

extension DayOfficer {
    /// Whether the officer is generally considered auspicious
    public var isGenerallyAuspicious: Bool {
        switch self {
        case .kai, .cheng, .man, .ding, .zhi:
            return true
        default:
            return false
        }
    }
}
