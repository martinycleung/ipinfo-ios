//
//  ClimateAdjustmentCalculator.swift
//  Oraculum
//
//  Climate Adjustment Analysis (调候)
//  Handles seasonal temperature balance for extreme birth seasons
//

import Foundation

// MARK: - Climate State

/// The climate state of a birth chart
public enum ClimateState: String, Sendable, Codable, CaseIterable {
    case extremeCold = "extreme_cold"       // 极寒 - Deep winter, urgent need for Fire
    case cold = "cold"                       // 寒 - Winter, need warmth
    case coolBalanced = "cool_balanced"     // 凉 - Late autumn/early spring, slight need for warmth
    case balanced = "balanced"               // 中和 - Temperate, no climate adjustment needed
    case warmBalanced = "warm_balanced"     // 暖 - Late spring/early autumn, slight need for cooling
    case hot = "hot"                         // 热 - Summer, need cooling
    case extremeHot = "extreme_hot"         // 极热 - Peak summer, urgent need for Water

    /// Chinese name
    public var chineseName: String {
        switch self {
        case .extremeCold: return "极寒"
        case .cold: return "寒"
        case .coolBalanced: return "凉"
        case .balanced: return "中和"
        case .warmBalanced: return "暖"
        case .hot: return "热"
        case .extremeHot: return "极热"
        }
    }

    /// The element needed for climate adjustment
    public var neededElement: FiveElement? {
        switch self {
        case .extremeCold, .cold: return .fire     // Need Fire to warm
        case .coolBalanced: return .fire           // Mild need for Fire
        case .balanced: return nil                 // No adjustment needed
        case .warmBalanced: return .water          // Mild need for Water
        case .hot, .extremeHot: return .water      // Need Water to cool
        }
    }

    /// Urgency of climate adjustment (0-1)
    public var urgency: Double {
        switch self {
        case .extremeCold: return 1.0
        case .cold: return 0.7
        case .coolBalanced: return 0.3
        case .balanced: return 0.0
        case .warmBalanced: return 0.3
        case .hot: return 0.7
        case .extremeHot: return 1.0
        }
    }
}

// MARK: - Climate Analysis Result

/// Result of climate adjustment analysis
public struct ClimateAnalysisResult: Sendable, Codable {
    /// The overall climate state
    public let climateState: ClimateState

    /// The element needed for adjustment (调候用神)
    public let adjustmentElement: FiveElement?

    /// Urgency of climate adjustment (0-1)
    public let urgency: Double

    /// Whether the chart has adequate climate adjustment
    public let hasAdequateAdjustment: Bool

    /// Elements present that help with climate adjustment
    public let adjustingElements: [FiveElement]

    /// Climate adjustment score (0-100, higher = better adjusted)
    public let adjustmentScore: Double

    /// Detailed breakdown
    public let breakdown: [String: String]

    public init(
        climateState: ClimateState,
        adjustmentElement: FiveElement?,
        urgency: Double,
        hasAdequateAdjustment: Bool,
        adjustingElements: [FiveElement],
        adjustmentScore: Double,
        breakdown: [String: String]
    ) {
        self.climateState = climateState
        self.adjustmentElement = adjustmentElement
        self.urgency = urgency
        self.hasAdequateAdjustment = hasAdequateAdjustment
        self.adjustingElements = adjustingElements
        self.adjustmentScore = adjustmentScore
        self.breakdown = breakdown
    }
}

// MARK: - Climate Adjustment Calculator

/// Calculates climate adjustment needs for a BaZi chart
public struct ClimateAdjustmentCalculator: Sendable {

    public init() {}

    /// Analyzes the climate adjustment needs of a chart
    /// - Parameter chart: The Four Pillars chart
    /// - Returns: Climate analysis result
    public func analyze(chart: FourPillarsChart) -> ClimateAnalysisResult {
        let monthBranch = chart.monthPillar.branch
        let dayMaster = chart.dayMaster

        var breakdown: [String: String] = [:]

        // Step 1: Determine base climate from month branch
        let baseClimate = determineBaseClimate(monthBranch: monthBranch)
        breakdown["Base Climate"] = baseClimate.chineseName
        breakdown["Birth Month"] = monthBranch.chineseName

        // Step 2: Modify based on Day Master element
        // Some Day Masters are more sensitive to climate
        let dayMasterModifier = getDayMasterClimateModifier(dayMaster: dayMaster, baseClimate: baseClimate)
        breakdown["Day Master"] = dayMaster.chineseName
        breakdown["DM Climate Sensitivity"] = String(format: "%.2f", dayMasterModifier)

        // Step 3: Determine final climate state
        let climateState = calculateFinalClimate(baseClimate: baseClimate, modifier: dayMasterModifier)
        breakdown["Final Climate"] = climateState.chineseName

        // Step 4: Find needed adjustment element
        let adjustmentElement = climateState.neededElement
        if let element = adjustmentElement {
            breakdown["Adjustment Needed"] = element.chineseName
        }

        // Step 5: Check if chart has adequate adjustment elements
        let (hasAdequate, adjustingElements, adjustmentScore) = checkAdjustmentPresence(
            chart: chart,
            neededElement: adjustmentElement,
            urgency: climateState.urgency
        )

        breakdown["Adjustment Present"] = hasAdequate ? "Yes" : "No"
        breakdown["Adjustment Score"] = String(format: "%.0f", adjustmentScore)

        return ClimateAnalysisResult(
            climateState: climateState,
            adjustmentElement: adjustmentElement,
            urgency: climateState.urgency,
            hasAdequateAdjustment: hasAdequate,
            adjustingElements: adjustingElements,
            adjustmentScore: adjustmentScore,
            breakdown: breakdown
        )
    }

    // MARK: - Climate Determination

    /// Determine base climate from month branch
    private func determineBaseClimate(monthBranch: EarthlyBranch) -> ClimateState {
        switch monthBranch {
        // Winter months - Cold
        case .zi:           // 子月 (Dec-Jan) - Peak winter
            return .extremeCold
        case .chou:         // 丑月 (Jan-Feb) - Late winter
            return .cold
        case .hai:          // 亥月 (Nov-Dec) - Early winter
            return .cold

        // Summer months - Hot
        case .wu:           // 午月 (Jun-Jul) - Peak summer
            return .extremeHot
        case .wei:          // 未月 (Jul-Aug) - Late summer
            return .hot
        case .si:           // 巳月 (May-Jun) - Early summer
            return .hot

        // Spring months - Warming
        case .yin:          // 寅月 (Feb-Mar) - Early spring, still cold
            return .coolBalanced
        case .mao:          // 卯月 (Mar-Apr) - Mid spring
            return .balanced
        case .chen:         // 辰月 (Apr-May) - Late spring
            return .warmBalanced

        // Autumn months - Cooling
        case .shen:         // 申月 (Aug-Sep) - Early autumn
            return .warmBalanced
        case .you:          // 酉月 (Sep-Oct) - Mid autumn
            return .balanced
        case .xu:           // 戌月 (Oct-Nov) - Late autumn
            return .coolBalanced
        }
    }

    /// Get Day Master's climate sensitivity modifier
    private func getDayMasterClimateModifier(dayMaster: HeavenlyStem, baseClimate: ClimateState) -> Double {
        let dmElement = dayMaster.element

        // Fire Day Masters are more sensitive to cold
        // Water Day Masters are more sensitive to heat
        // Wood Day Masters need both warmth and moisture
        // Metal Day Masters prefer some cooling
        // Earth Day Masters are relatively stable

        switch (dmElement, baseClimate) {
        case (.fire, .extremeCold), (.fire, .cold):
            return 1.2  // Fire in cold is very uncomfortable
        case (.water, .extremeHot), (.water, .hot):
            return 1.2  // Water in heat evaporates
        case (.wood, .extremeCold), (.wood, .cold):
            return 1.1  // Wood needs warmth to grow
        case (.wood, .extremeHot), (.wood, .hot):
            return 1.1  // Wood dries out in extreme heat
        case (.metal, .extremeHot), (.metal, .hot):
            return 0.9  // Metal can handle some heat
        case (.earth, _):
            return 0.9  // Earth is stable
        default:
            return 1.0
        }
    }

    /// Calculate final climate state with modifier
    private func calculateFinalClimate(baseClimate: ClimateState, modifier: Double) -> ClimateState {
        // Convert to numeric scale
        let climateScale: [ClimateState: Double] = [
            .extremeCold: -3,
            .cold: -2,
            .coolBalanced: -1,
            .balanced: 0,
            .warmBalanced: 1,
            .hot: 2,
            .extremeHot: 3
        ]

        guard let baseValue = climateScale[baseClimate] else {
            return baseClimate
        }

        // Apply modifier (pushes toward extremes)
        let modifiedValue = baseValue * modifier

        // Convert back to climate state
        switch modifiedValue {
        case ...(-2.5):
            return .extremeCold
        case -2.5..<(-1.5):
            return .cold
        case -1.5..<(-0.5):
            return .coolBalanced
        case -0.5..<0.5:
            return .balanced
        case 0.5..<1.5:
            return .warmBalanced
        case 1.5..<2.5:
            return .hot
        default:
            return .extremeHot
        }
    }

    // MARK: - Adjustment Check

    /// Check if the chart has adequate climate adjustment elements
    private func checkAdjustmentPresence(
        chart: FourPillarsChart,
        neededElement: FiveElement?,
        urgency: Double
    ) -> (hasAdequate: Bool, elements: [FiveElement], score: Double) {
        guard let needed = neededElement else {
            // No adjustment needed = perfectly adjusted
            return (true, [], 100.0)
        }

        var adjustingElements: [FiveElement] = []
        var adjustmentStrength = 0.0

        // Check stems for adjustment element
        for stem in chart.stems {
            if stem.element == needed {
                adjustingElements.append(needed)
                adjustmentStrength += 1.0
            }
            // Element that produces the needed element also helps
            if stem.element.produces == needed {
                adjustmentStrength += 0.5
            }
        }

        // Check hidden stems in branches
        for branch in chart.branches {
            for (index, stem) in branch.hiddenStems.enumerated() {
                let weight: Double = index == 0 ? 0.6 : (index == 1 ? 0.3 : 0.1)
                if stem.element == needed {
                    if !adjustingElements.contains(needed) {
                        adjustingElements.append(needed)
                    }
                    adjustmentStrength += weight * 0.5
                }
            }
        }

        // Calculate adequacy based on urgency
        // Higher urgency requires more adjustment elements
        let requiredStrength = urgency * 1.5  // Extreme urgency needs 1.5 units
        let hasAdequate = adjustmentStrength >= requiredStrength

        // Calculate score
        // Start at 50 (no adjustment), go up to 100 if well-adjusted, down to 0 if poor
        var score = 50.0
        if urgency > 0 {
            let adjustmentRatio = min(1.0, adjustmentStrength / requiredStrength)
            score = 50 + (adjustmentRatio * 50)
        } else {
            score = 100.0  // No adjustment needed
        }

        return (hasAdequate, adjustingElements, score)
    }
}
