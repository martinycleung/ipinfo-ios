//
//  UsefulGodCalculator.swift
//  Oraculum
//
//  Useful God Calculation (用神/喜用神)
//  Integrates three traditional systems: Strength Balance, Pattern, and Climate
//

import Foundation

// MARK: - Useful God Method

/// The method used to determine the Useful God
public enum UsefulGodMethod: String, Sendable, Codable {
    case strengthBalance = "strength_balance"   // 平衡用神 - Based on Day Master strength
    case patternBased = "pattern_based"         // 格局用神 - Based on chart pattern
    case climateAdjustment = "climate"          // 调候用神 - Based on seasonal climate
    case followPattern = "follow"               // 从格用神 - For special follow patterns
    case combined = "combined"                  // 综合用神 - Combined approach

    /// Chinese name
    public var chineseName: String {
        switch self {
        case .strengthBalance: return "平衡用神"
        case .patternBased: return "格局用神"
        case .climateAdjustment: return "调候用神"
        case .followPattern: return "从格用神"
        case .combined: return "综合用神"
        }
    }
}

// MARK: - Useful God Result

/// Complete result of Useful God calculation
public struct UsefulGodResult: Sendable, Codable {
    /// Primary Useful God element (用神)
    public let usefulGod: FiveElement

    /// Secondary favorable element (喜神)
    public let favorableGod: FiveElement?

    /// Unfavorable element (忌神)
    public let unfavorableGod: FiveElement

    /// Enemy element (仇神)
    public let enemyGod: FiveElement?

    /// Idle/neutral element (闲神)
    public let idleGod: FiveElement?

    /// Method used to determine the Useful God
    public let method: UsefulGodMethod

    /// Confidence level (0-1)
    public let confidence: Double

    /// Detailed breakdown
    public let breakdown: [String: String]

    /// Supporting analysis data
    public let strengthAnalysis: DayMasterStrengthAnalysis?
    public let patternAnalysis: PatternAnalysisResult?
    public let climateAnalysis: ClimateAnalysisResult?

    /// Validation status
    public let validation: UsefulGodValidation?

    public init(
        usefulGod: FiveElement,
        favorableGod: FiveElement?,
        unfavorableGod: FiveElement,
        enemyGod: FiveElement?,
        idleGod: FiveElement?,
        method: UsefulGodMethod,
        confidence: Double,
        breakdown: [String: String],
        strengthAnalysis: DayMasterStrengthAnalysis? = nil,
        patternAnalysis: PatternAnalysisResult? = nil,
        climateAnalysis: ClimateAnalysisResult? = nil,
        validation: UsefulGodValidation? = nil
    ) {
        self.usefulGod = usefulGod
        self.favorableGod = favorableGod
        self.unfavorableGod = unfavorableGod
        self.enemyGod = enemyGod
        self.idleGod = idleGod
        self.method = method
        self.confidence = confidence
        self.breakdown = breakdown
        self.strengthAnalysis = strengthAnalysis
        self.patternAnalysis = patternAnalysis
        self.climateAnalysis = climateAnalysis
        self.validation = validation
    }
}

// MARK: - Useful God Validation

/// Validation of the Useful God's effectiveness in the chart
public struct UsefulGodValidation: Sendable, Codable {
    /// Whether Useful God appears in stems (透干)
    public let appearsInStems: Bool

    /// Whether Useful God has roots in branches (有根)
    public let hasRoots: Bool

    /// Whether Useful God is clashed (被冲)
    public let isClashed: Bool

    /// Whether Useful God is in a void position (空亡)
    public let isVoid: Bool

    /// Whether Useful God is protected (有护)
    public let isProtected: Bool

    /// Overall effectiveness (0-1)
    public var effectiveness: Double {
        var score = 0.5  // Base

        if appearsInStems { score += 0.2 }
        if hasRoots { score += 0.2 }
        if isClashed { score -= 0.3 }
        if isVoid { score -= 0.2 }
        if isProtected { score += 0.1 }

        return max(0, min(1, score))
    }

    /// Summary description
    public var summary: String {
        var parts: [String] = []
        if appearsInStems { parts.append("透干") }
        if hasRoots { parts.append("有根") }
        if isClashed { parts.append("被冲") }
        if isVoid { parts.append("空亡") }
        if isProtected { parts.append("有护") }
        return parts.isEmpty ? "无特殊" : parts.joined(separator: "、")
    }

    /// Whether the Useful God is considered effective
    public var isEffective: Bool {
        effectiveness >= 0.5
    }
}

// MARK: - Useful God Calculator

/// Calculates the Useful God using three traditional systems
public struct UsefulGodCalculator: Sendable {

    private let strengthCalculator = DayMasterStrengthCalculator()
    private let patternAnalyzer = ChartPatternAnalyzer()
    private let climateCalculator = ClimateAdjustmentCalculator()

    public init() {}

    /// Calculates the Useful God for a chart
    /// - Parameter chart: The Four Pillars chart
    /// - Returns: Complete Useful God result
    public func calculate(chart: FourPillarsChart) -> UsefulGodResult {
        var breakdown: [String: String] = [:]

        // Step 1: Perform all analyses
        let strengthAnalysis = strengthCalculator.analyze(chart: chart)
        let climateAnalysis = climateCalculator.analyze(chart: chart)
        let patternAnalysis = patternAnalyzer.analyze(chart: chart, strengthAnalysis: strengthAnalysis)

        breakdown["Strength Level"] = strengthAnalysis.strengthLevel.chineseName
        breakdown["Climate State"] = climateAnalysis.climateState.chineseName
        breakdown["Pattern"] = patternAnalysis.primaryPattern.chineseName

        // Step 2: Determine primary method based on priorities
        // Traditional priority:
        // 1. Climate (调候) - For extreme births (urgent)
        // 2. Pattern (格局) - For special patterns
        // 3. Strength (平衡) - Default approach

        let method = determineMethod(
            strengthAnalysis: strengthAnalysis,
            patternAnalysis: patternAnalysis,
            climateAnalysis: climateAnalysis
        )
        breakdown["Method Used"] = method.chineseName

        // Step 3: Calculate Useful God based on method
        let result: UsefulGodResult

        switch method {
        case .climateAdjustment:
            result = calculateClimateBasedUsefulGod(
                chart: chart,
                climateAnalysis: climateAnalysis,
                strengthAnalysis: strengthAnalysis,
                patternAnalysis: patternAnalysis,
                breakdown: &breakdown
            )
        case .followPattern:
            result = calculateFollowPatternUsefulGod(
                chart: chart,
                patternAnalysis: patternAnalysis,
                strengthAnalysis: strengthAnalysis,
                climateAnalysis: climateAnalysis,
                breakdown: &breakdown
            )
        case .patternBased:
            result = calculatePatternBasedUsefulGod(
                chart: chart,
                patternAnalysis: patternAnalysis,
                strengthAnalysis: strengthAnalysis,
                climateAnalysis: climateAnalysis,
                breakdown: &breakdown
            )
        default:
            result = calculateStrengthBasedUsefulGod(
                chart: chart,
                strengthAnalysis: strengthAnalysis,
                patternAnalysis: patternAnalysis,
                climateAnalysis: climateAnalysis,
                breakdown: &breakdown
            )
        }

        return result
    }

    // MARK: - Method Determination

    /// Determine which method to use based on chart conditions
    private func determineMethod(
        strengthAnalysis: DayMasterStrengthAnalysis,
        patternAnalysis: PatternAnalysisResult,
        climateAnalysis: ClimateAnalysisResult
    ) -> UsefulGodMethod {
        // 1. Climate takes priority if urgent and not adequately adjusted
        if climateAnalysis.urgency >= 0.7 && !climateAnalysis.hasAdequateAdjustment {
            return .climateAdjustment
        }

        // 2. Special follow patterns take next priority
        if patternAnalysis.primaryPattern.isSpecialPattern {
            return .followPattern
        }

        // 3. Pure patterns with high confidence use pattern method
        if patternAnalysis.isPure && patternAnalysis.confidence >= 0.8 {
            return .patternBased
        }

        // 4. Default to strength-based method
        return .strengthBalance
    }

    // MARK: - Strength-Based Calculation

    /// Calculate Useful God based on Day Master strength
    private func calculateStrengthBasedUsefulGod(
        chart: FourPillarsChart,
        strengthAnalysis: DayMasterStrengthAnalysis,
        patternAnalysis: PatternAnalysisResult,
        climateAnalysis: ClimateAnalysisResult,
        breakdown: inout [String: String]
    ) -> UsefulGodResult {
        let dayMaster = chart.dayMaster
        let dmElement = dayMaster.element

        // Weak Day Master needs support
        // Strong Day Master needs control/drain
        let usefulGod: FiveElement
        let favorableGod: FiveElement?
        let unfavorableGod: FiveElement
        let enemyGod: FiveElement?
        let idleGod: FiveElement?

        if strengthAnalysis.strengthLevel.needsSupport {
            // Weak DM: Useful God = Resource (生我者) or Companion (同我者)
            // Resource produces DM, Companion supports DM
            usefulGod = dmElement.producedBy  // Resource (印)
            favorableGod = dmElement          // Companion (比)
            unfavorableGod = dmElement.controlledBy  // Officer/Killings (官杀)
            enemyGod = dmElement.controls     // Wealth (财)
            idleGod = dmElement.produces      // Output (食伤)

            breakdown["Logic"] = "Weak DM needs Resource support"
        } else if strengthAnalysis.strengthLevel.needsControl {
            // Strong DM: Useful God = Officer (克我者), Wealth (我克), or Output (我生)
            usefulGod = dmElement.controls    // Wealth (财)
            favorableGod = dmElement.produces // Output (食伤)
            unfavorableGod = dmElement.producedBy  // Resource (印)
            enemyGod = dmElement              // Companion (比)
            idleGod = dmElement.controlledBy  // Officer (官)

            breakdown["Logic"] = "Strong DM needs Wealth to drain"
        } else {
            // Balanced: More nuanced - consider pattern
            // Default to moderate wealth/output
            usefulGod = dmElement.produces    // Output
            favorableGod = dmElement.controls // Wealth
            unfavorableGod = dmElement.producedBy
            enemyGod = nil
            idleGod = dmElement.controlledBy

            breakdown["Logic"] = "Balanced DM uses Output for expression"
        }

        breakdown["Useful God"] = usefulGod.chineseName
        if let fg = favorableGod {
            breakdown["Favorable God"] = fg.chineseName
        }
        breakdown["Unfavorable God"] = unfavorableGod.chineseName

        return UsefulGodResult(
            usefulGod: usefulGod,
            favorableGod: favorableGod,
            unfavorableGod: unfavorableGod,
            enemyGod: enemyGod,
            idleGod: idleGod,
            method: .strengthBalance,
            confidence: 0.75,
            breakdown: breakdown,
            strengthAnalysis: strengthAnalysis,
            patternAnalysis: patternAnalysis,
            climateAnalysis: climateAnalysis
        )
    }

    // MARK: - Climate-Based Calculation

    /// Calculate Useful God based on climate adjustment needs
    private func calculateClimateBasedUsefulGod(
        chart: FourPillarsChart,
        climateAnalysis: ClimateAnalysisResult,
        strengthAnalysis: DayMasterStrengthAnalysis,
        patternAnalysis: PatternAnalysisResult,
        breakdown: inout [String: String]
    ) -> UsefulGodResult {
        let dayMaster = chart.dayMaster
        let dmElement = dayMaster.element

        // Climate Useful God is the adjustment element
        let usefulGod = climateAnalysis.adjustmentElement ?? dmElement.producedBy

        // Determine other gods based on climate
        let favorableGod: FiveElement?
        let unfavorableGod: FiveElement
        let enemyGod: FiveElement?

        if climateAnalysis.climateState == .extremeCold || climateAnalysis.climateState == .cold {
            // Cold: Need Fire, Wood helps (produces Fire)
            favorableGod = .wood
            unfavorableGod = .water  // Water makes it colder
            enemyGod = .metal        // Metal produces Water
        } else {
            // Hot: Need Water, Metal helps (produces Water)
            favorableGod = .metal
            unfavorableGod = .fire   // Fire makes it hotter
            enemyGod = .wood         // Wood produces Fire
        }

        breakdown["Climate Adjustment"] = usefulGod.chineseName
        breakdown["Logic"] = "Climate urgency (\(String(format: "%.0f%%", climateAnalysis.urgency * 100))) requires \(usefulGod.chineseName)"

        return UsefulGodResult(
            usefulGod: usefulGod,
            favorableGod: favorableGod,
            unfavorableGod: unfavorableGod,
            enemyGod: enemyGod,
            idleGod: nil,
            method: .climateAdjustment,
            confidence: 0.85,
            breakdown: breakdown,
            strengthAnalysis: strengthAnalysis,
            patternAnalysis: patternAnalysis,
            climateAnalysis: climateAnalysis
        )
    }

    // MARK: - Pattern-Based Calculation

    /// Calculate Useful God based on chart pattern
    private func calculatePatternBasedUsefulGod(
        chart: FourPillarsChart,
        patternAnalysis: PatternAnalysisResult,
        strengthAnalysis: DayMasterStrengthAnalysis,
        climateAnalysis: ClimateAnalysisResult,
        breakdown: inout [String: String]
    ) -> UsefulGodResult {
        let dayMaster = chart.dayMaster
        let dmElement = dayMaster.element
        let pattern = patternAnalysis.primaryPattern

        // Pattern-based Useful God selection
        // The key is to protect and enhance the pattern
        let usefulGod: FiveElement
        let favorableGod: FiveElement?
        let unfavorableGod: FiveElement
        let enemyGod: FiveElement?

        switch pattern {
        // Resource Patterns: Protect Resource, use Output to release
        case .zhengYinGe, .pianYinGe:
            usefulGod = dmElement.produces        // Output releases Resource
            favorableGod = dmElement.producedBy   // Resource itself
            unfavorableGod = dmElement.controls   // Wealth (destroys Resource)
            enemyGod = nil

        // Officer Patterns: Protect Officer, use Resource for balance
        case .zhengGuanGe:
            usefulGod = dmElement.producedBy      // Resource protects from Officer
            favorableGod = dmElement.controlledBy // Officer (pattern element)
            unfavorableGod = dmElement.produces   // Output (attacks Officer)
            enemyGod = nil

        case .qiShaGe:
            usefulGod = dmElement.produces        // Output to control Killings
            favorableGod = dmElement.producedBy   // Resource for protection
            unfavorableGod = dmElement.controls   // Wealth produces Killings
            enemyGod = nil

        // Wealth Patterns: Use Output to produce Wealth
        case .zhengCaiGe, .pianCaiGe:
            usefulGod = dmElement.produces        // Output produces Wealth
            favorableGod = dmElement.controls     // Wealth (pattern element)
            unfavorableGod = dmElement              // Companion robs Wealth
            enemyGod = nil

        // Output Patterns: Protect Output, use Wealth to receive
        case .shiShenGe:
            usefulGod = dmElement.controls        // Wealth receives Output
            favorableGod = dmElement.produces     // Output (pattern element)
            unfavorableGod = dmElement.producedBy // Resource suppresses Output
            enemyGod = nil

        case .shangGuanGe:
            usefulGod = dmElement.controls        // Wealth receives Hurting Officer
            favorableGod = dmElement.produces     // Output (pattern element)
            unfavorableGod = dmElement.controlledBy // Officer (conflicts with HO)
            enemyGod = nil

        // Self Patterns: Need drain/control
        case .jianLuGe, .yangRenGe:
            usefulGod = dmElement.controlledBy    // Officer for control
            favorableGod = dmElement.controls     // Wealth for drain
            unfavorableGod = dmElement.producedBy // Too much Resource
            enemyGod = dmElement                   // More Companion = trouble

        default:
            // Default to strength-based for mixed patterns
            if strengthAnalysis.strengthLevel.needsSupport {
                usefulGod = dmElement.producedBy
                favorableGod = dmElement
                unfavorableGod = dmElement.controlledBy
            } else {
                usefulGod = dmElement.controls
                favorableGod = dmElement.produces
                unfavorableGod = dmElement.producedBy
            }
            enemyGod = nil
        }

        breakdown["Pattern Logic"] = "Protect \(pattern.chineseName) structure"
        breakdown["Useful God"] = usefulGod.chineseName

        return UsefulGodResult(
            usefulGod: usefulGod,
            favorableGod: favorableGod,
            unfavorableGod: unfavorableGod,
            enemyGod: enemyGod,
            idleGod: nil,
            method: .patternBased,
            confidence: patternAnalysis.confidence,
            breakdown: breakdown,
            strengthAnalysis: strengthAnalysis,
            patternAnalysis: patternAnalysis,
            climateAnalysis: climateAnalysis
        )
    }

    // MARK: - Follow Pattern Calculation

    /// Calculate Useful God for special follow patterns
    private func calculateFollowPatternUsefulGod(
        chart: FourPillarsChart,
        patternAnalysis: PatternAnalysisResult,
        strengthAnalysis: DayMasterStrengthAnalysis,
        climateAnalysis: ClimateAnalysisResult,
        breakdown: inout [String: String]
    ) -> UsefulGodResult {
        let dayMaster = chart.dayMaster
        let dmElement = dayMaster.element
        let pattern = patternAnalysis.primaryPattern

        // Follow patterns: Go WITH the flow, not against
        let usefulGod: FiveElement
        let favorableGod: FiveElement?
        let unfavorableGod: FiveElement

        switch pattern {
        case .congQiangGe:
            // Follow Strength: Use Resource and Companion
            usefulGod = dmElement.producedBy  // Resource
            favorableGod = dmElement          // Companion
            unfavorableGod = dmElement.controlledBy  // Officer (would clash)
            breakdown["Logic"] = "Follow Strength: Embrace strong DM"

        case .congCaiGe:
            // Follow Wealth: Use Wealth and Output
            usefulGod = dmElement.controls    // Wealth
            favorableGod = dmElement.produces // Output (produces Wealth)
            unfavorableGod = dmElement        // Companion (robs Wealth)
            breakdown["Logic"] = "Follow Wealth: Go with dominant Wealth"

        case .congGuanGe:
            // Follow Officer: Use Officer and Wealth
            usefulGod = dmElement.controlledBy // Officer
            favorableGod = dmElement.controls  // Wealth (produces Officer)
            unfavorableGod = dmElement.produces // Output (attacks Officer)
            breakdown["Logic"] = "Follow Officer: Embrace authority"

        case .congErGe:
            // Follow Output: Use Output and Wealth
            usefulGod = dmElement.produces    // Output
            favorableGod = dmElement.controls // Wealth (receives Output)
            unfavorableGod = dmElement.producedBy // Resource (suppresses Output)
            breakdown["Logic"] = "Follow Output: Express creativity"

        default:
            // Fallback
            usefulGod = dmElement.controls
            favorableGod = dmElement.produces
            unfavorableGod = dmElement.producedBy
        }

        breakdown["Pattern"] = pattern.chineseName
        breakdown["Useful God"] = usefulGod.chineseName

        return UsefulGodResult(
            usefulGod: usefulGod,
            favorableGod: favorableGod,
            unfavorableGod: unfavorableGod,
            enemyGod: nil,
            idleGod: nil,
            method: .followPattern,
            confidence: 0.8,
            breakdown: breakdown,
            strengthAnalysis: strengthAnalysis,
            patternAnalysis: patternAnalysis,
            climateAnalysis: climateAnalysis
        )
    }

    // MARK: - Useful God Validation

    /// Validate the Useful God in the chart
    /// Checks: 透干 (appears in stems), 有根 (has roots), 被冲 (is clashed), 空亡 (is void)
    public func validateUsefulGod(
        usefulGod: FiveElement,
        chart: FourPillarsChart
    ) -> UsefulGodValidation {
        // Check if Useful God appears in stems (透干)
        let appearsInStems = chart.stems.contains { $0.element == usefulGod }

        // Check if Useful God has roots in branches (有根)
        var hasRoots = false
        for branch in chart.branches {
            for hiddenStem in branch.hiddenStems {
                if hiddenStem.element == usefulGod {
                    hasRoots = true
                    break
                }
            }
            if hasRoots { break }
        }

        // Check if Useful God is clashed (被冲)
        let isClashed = checkUsefulGodClashed(usefulGod: usefulGod, chart: chart)

        // Check if Useful God is in void position (空亡)
        let voidCalculator = VoidCalculator()
        let isVoid = voidCalculator.isUsefulGodVoid(
            usefulGodElement: usefulGod,
            voidResult: voidCalculator.calculateFromDayPillar(chart.dayPillar),
            chart: chart
        )

        // Check if Useful God is protected (有护)
        // Protected if it's produced by another element present in the chart
        let producingElement = usefulGod.producedBy
        let isProtected = chart.stems.contains { $0.element == producingElement }

        return UsefulGodValidation(
            appearsInStems: appearsInStems,
            hasRoots: hasRoots,
            isClashed: isClashed,
            isVoid: isVoid,
            isProtected: isProtected
        )
    }

    /// Check if the Useful God element is being clashed
    private func checkUsefulGodClashed(usefulGod: FiveElement, chart: FourPillarsChart) -> Bool {
        // The element that controls (克) the Useful God
        let controllingElement = usefulGod.controlledBy

        // Check if controlling element appears strongly in stems
        let controllingCount = chart.stems.filter { $0.element == controllingElement }.count
        if controllingCount >= 2 {
            return true  // Strong clash
        }

        // Check branch combinations for clashes affecting Useful God's roots
        let branchAnalyzer = BranchCombinationAnalyzer()
        let branchAnalysis = branchAnalyzer.analyze(branches: chart.branches)

        // If there are clashes and one involves a branch containing Useful God element
        for (branch1, branch2) in branchAnalysis.clashes {
            // Check if either clashing branch contains Useful God element
            let branch1HasUG = branch1.hiddenStems.contains { $0.element == usefulGod }
            let branch2HasUG = branch2.hiddenStems.contains { $0.element == usefulGod }
            if branch1HasUG || branch2HasUG {
                return true
            }
        }

        return false
    }

    /// Calculate with validation included
    public func calculateWithValidation(chart: FourPillarsChart) -> UsefulGodResult {
        let result = calculate(chart: chart)

        // Add validation
        let validation = validateUsefulGod(usefulGod: result.usefulGod, chart: chart)

        // Recreate result with validation
        return UsefulGodResult(
            usefulGod: result.usefulGod,
            favorableGod: result.favorableGod,
            unfavorableGod: result.unfavorableGod,
            enemyGod: result.enemyGod,
            idleGod: result.idleGod,
            method: result.method,
            confidence: result.confidence * validation.effectiveness,
            breakdown: result.breakdown,
            strengthAnalysis: result.strengthAnalysis,
            patternAnalysis: result.patternAnalysis,
            climateAnalysis: result.climateAnalysis,
            validation: validation
        )
    }
}
