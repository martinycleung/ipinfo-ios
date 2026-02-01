//
//  ChartPatternAnalyzer.swift
//  Oraculum
//
//  Chart Pattern Analysis (格局分析)
//  Identifies the structural pattern of a BaZi chart based on Month Branch
//

import Foundation

// MARK: - Pattern Type

/// Types of chart patterns (格局) in BaZi
public enum ChartPattern: String, Sendable, Codable, CaseIterable {
    // Normal Patterns (正格) - Based on Month Branch's dominant Ten God
    case zhengYinGe = "zheng_yin_ge"           // 正印格 - Direct Resource Pattern
    case pianYinGe = "pian_yin_ge"             // 偏印格 - Indirect Resource Pattern
    case zhengGuanGe = "zheng_guan_ge"         // 正官格 - Direct Officer Pattern
    case qiShaGe = "qi_sha_ge"                 // 七杀格 - Seven Killings Pattern
    case zhengCaiGe = "zheng_cai_ge"           // 正财格 - Direct Wealth Pattern
    case pianCaiGe = "pian_cai_ge"             // 偏财格 - Indirect Wealth Pattern
    case shiShenGe = "shi_shen_ge"             // 食神格 - Eating God Pattern
    case shangGuanGe = "shang_guan_ge"         // 伤官格 - Hurting Officer Pattern

    // Special Patterns (特别格局)
    case congQiangGe = "cong_qiang_ge"         // 从强格 - Follow Strength (extremely strong DM)
    case congRuoGe = "cong_ruo_ge"             // 从弱格 - Follow Weakness (extremely weak DM)
    case congCaiGe = "cong_cai_ge"             // 从财格 - Follow Wealth Pattern
    case congGuanGe = "cong_guan_ge"           // 从官格 - Follow Officer Pattern
    case congErGe = "cong_er_ge"               // 从儿格 - Follow Child (Output) Pattern

    // Jian Lu Pattern (建禄格)
    case jianLuGe = "jian_lu_ge"               // 建禄格 - Established Wealth Pattern

    // Yang Ren Pattern (羊刃格)
    case yangRenGe = "yang_ren_ge"             // 羊刃格 - Blade Pattern

    // Unknown/Mixed
    case mixedPattern = "mixed"                 // 杂格 - Mixed pattern, no clear dominant

    /// Chinese name
    public var chineseName: String {
        switch self {
        case .zhengYinGe: return "正印格"
        case .pianYinGe: return "偏印格"
        case .zhengGuanGe: return "正官格"
        case .qiShaGe: return "七杀格"
        case .zhengCaiGe: return "正财格"
        case .pianCaiGe: return "偏财格"
        case .shiShenGe: return "食神格"
        case .shangGuanGe: return "伤官格"
        case .congQiangGe: return "从强格"
        case .congRuoGe: return "从弱格"
        case .congCaiGe: return "从财格"
        case .congGuanGe: return "从官格"
        case .congErGe: return "从儿格"
        case .jianLuGe: return "建禄格"
        case .yangRenGe: return "羊刃格"
        case .mixedPattern: return "杂格"
        }
    }

    /// English description
    public var englishName: String {
        switch self {
        case .zhengYinGe: return "Direct Resource Pattern"
        case .pianYinGe: return "Indirect Resource Pattern"
        case .zhengGuanGe: return "Direct Officer Pattern"
        case .qiShaGe: return "Seven Killings Pattern"
        case .zhengCaiGe: return "Direct Wealth Pattern"
        case .pianCaiGe: return "Indirect Wealth Pattern"
        case .shiShenGe: return "Eating God Pattern"
        case .shangGuanGe: return "Hurting Officer Pattern"
        case .congQiangGe: return "Follow Strength Pattern"
        case .congRuoGe: return "Follow Weakness Pattern"
        case .congCaiGe: return "Follow Wealth Pattern"
        case .congGuanGe: return "Follow Officer Pattern"
        case .congErGe: return "Follow Output Pattern"
        case .jianLuGe: return "Established Prosperity Pattern"
        case .yangRenGe: return "Blade Pattern"
        case .mixedPattern: return "Mixed Pattern"
        }
    }

    /// Whether this is a special pattern (requires extreme conditions)
    public var isSpecialPattern: Bool {
        switch self {
        case .congQiangGe, .congRuoGe, .congCaiGe, .congGuanGe, .congErGe:
            return true
        default:
            return false
        }
    }

    /// The key Ten God that defines this pattern
    public var definingTenGod: TenGod? {
        switch self {
        case .zhengYinGe: return .zhengyin
        case .pianYinGe: return .pianyin
        case .zhengGuanGe: return .zhengguan
        case .qiShaGe: return .qisha
        case .zhengCaiGe: return .zhengcai
        case .pianCaiGe: return .piancai
        case .shiShenGe: return .shishen
        case .shangGuanGe: return .shangguan
        case .jianLuGe: return .bijian
        case .yangRenGe: return .jiecai
        default: return nil
        }
    }
}

// MARK: - Pattern Analysis Result

/// Result of chart pattern analysis
public struct PatternAnalysisResult: Sendable, Codable {
    /// Primary pattern identified
    public let primaryPattern: ChartPattern

    /// Confidence level (0-1)
    public let confidence: Double

    /// Secondary patterns that may also apply
    public let secondaryPatterns: [ChartPattern]

    /// The dominant Ten God in the chart
    public let dominantTenGod: TenGod?

    /// Pattern quality (pure vs mixed)
    public let isPure: Bool

    /// Detailed breakdown
    public let breakdown: [String: String]

    public init(
        primaryPattern: ChartPattern,
        confidence: Double,
        secondaryPatterns: [ChartPattern] = [],
        dominantTenGod: TenGod? = nil,
        isPure: Bool = false,
        breakdown: [String: String] = [:]
    ) {
        self.primaryPattern = primaryPattern
        self.confidence = confidence
        self.secondaryPatterns = secondaryPatterns
        self.dominantTenGod = dominantTenGod
        self.isPure = isPure
        self.breakdown = breakdown
    }
}

// MARK: - Chart Pattern Analyzer

/// Analyzes the structural pattern of a BaZi chart
public struct ChartPatternAnalyzer: Sendable {

    public init() {}

    /// Analyzes the chart pattern
    /// - Parameters:
    ///   - chart: The Four Pillars chart
    ///   - strengthAnalysis: Pre-calculated Day Master strength analysis
    /// - Returns: Pattern analysis result
    public func analyze(
        chart: FourPillarsChart,
        strengthAnalysis: DayMasterStrengthAnalysis
    ) -> PatternAnalysisResult {
        let dayMaster = chart.dayMaster
        let monthBranch = chart.monthPillar.branch

        var breakdown: [String: String] = [:]

        // Step 1: Check for special patterns first (extreme conditions)
        if let specialPattern = checkSpecialPatterns(
            chart: chart,
            strengthAnalysis: strengthAnalysis
        ) {
            breakdown["Type"] = "Special Pattern"
            breakdown["Reason"] = "Extreme strength condition met"
            return PatternAnalysisResult(
                primaryPattern: specialPattern,
                confidence: 0.8,
                secondaryPatterns: [],
                dominantTenGod: nil,
                isPure: true,
                breakdown: breakdown
            )
        }

        // Step 2: Check for Jian Lu (建禄格) and Yang Ren (羊刃格)
        if let specialSelfPattern = checkSelfPatterns(dayMaster: dayMaster, monthBranch: monthBranch) {
            breakdown["Type"] = "Self Pattern"
            breakdown["Month Branch"] = monthBranch.chineseName
            return PatternAnalysisResult(
                primaryPattern: specialSelfPattern,
                confidence: 0.85,
                secondaryPatterns: [],
                dominantTenGod: specialSelfPattern == .jianLuGe ? .bijian : .jiecai,
                isPure: true,
                breakdown: breakdown
            )
        }

        // Step 3: Standard pattern analysis based on Month Branch's primary Ten God
        let monthTenGod = determineMonthTenGod(dayMaster: dayMaster, monthBranch: monthBranch)
        breakdown["Month Ten God"] = monthTenGod.chineseName

        // Step 4: Check if the pattern is "pure" (透干 - Tou Gan)
        // A pure pattern has the month's Ten God appearing in the stems
        let isPure = checkPatternPurity(
            dayMaster: dayMaster,
            monthTenGod: monthTenGod,
            stems: chart.stems
        )
        breakdown["Pattern Purity"] = isPure ? "Pure (透干)" : "Hidden (暗格)"

        // Step 5: Map Ten God to Pattern
        let primaryPattern = mapTenGodToPattern(monthTenGod)

        // Step 6: Check for secondary patterns
        let secondaryPatterns = identifySecondaryPatterns(
            chart: chart,
            dayMaster: dayMaster,
            primaryPattern: primaryPattern
        )

        // Calculate confidence based on purity and strength
        var confidence = isPure ? 0.9 : 0.7
        if !secondaryPatterns.isEmpty {
            confidence -= 0.1
        }

        return PatternAnalysisResult(
            primaryPattern: primaryPattern,
            confidence: confidence,
            secondaryPatterns: secondaryPatterns,
            dominantTenGod: monthTenGod,
            isPure: isPure,
            breakdown: breakdown
        )
    }

    // MARK: - Special Patterns

    /// Check for special patterns requiring extreme conditions
    private func checkSpecialPatterns(
        chart: FourPillarsChart,
        strengthAnalysis: DayMasterStrengthAnalysis
    ) -> ChartPattern? {
        let dayMaster = chart.dayMaster

        // Cong Qiang (从强格) - Follow Strength
        // Day Master is extremely strong with no controlling elements
        if strengthAnalysis.strengthLevel == .extremelyStrong {
            // Check if there are any Officer/Wealth elements
            let hasControlling = checkForControllingElements(dayMaster: dayMaster, chart: chart)
            if !hasControlling {
                return .congQiangGe
            }
        }

        // Cong Ruo (从弱格) - Follow Weakness
        // Day Master is extremely weak with no support
        if strengthAnalysis.strengthLevel == .extremelyWeak {
            // Check dominant element type
            let dominantCategory = findDominantCategory(dayMaster: dayMaster, chart: chart)
            switch dominantCategory {
            case .wealth:
                return .congCaiGe  // Follow Wealth
            case .officer:
                return .congGuanGe // Follow Officer
            case .output:
                return .congErGe   // Follow Output
            case .resource, .self:
                return nil // Can't follow if support exists
            }
        }

        return nil
    }

    /// Check if there are significant controlling elements
    private func checkForControllingElements(dayMaster: HeavenlyStem, chart: FourPillarsChart) -> Bool {
        for stem in chart.stems where stem != dayMaster {
            let tenGod = TenGod.relationship(dayMaster: dayMaster, other: stem)
            if tenGod == .zhengguan || tenGod == .qisha || tenGod == .zhengcai || tenGod == .piancai {
                return true
            }
        }
        return false
    }

    /// Categories of Ten Gods
    private enum TenGodCategory {
        case `self`     // Bi Jian, Jie Cai
        case resource   // Zheng Yin, Pian Yin
        case output     // Shi Shen, Shang Guan
        case wealth     // Zheng Cai, Pian Cai
        case officer    // Zheng Guan, Qi Sha
    }

    /// Find the dominant category in the chart
    private func findDominantCategory(dayMaster: HeavenlyStem, chart: FourPillarsChart) -> TenGodCategory {
        var categoryCounts: [TenGodCategory: Double] = [:]

        for stem in chart.stems where stem != dayMaster {
            let tenGod = TenGod.relationship(dayMaster: dayMaster, other: stem)
            let category = categorize(tenGod)
            categoryCounts[category, default: 0] += 1.0
        }

        // Count hidden stems with reduced weight
        for branch in chart.branches {
            for (index, stem) in branch.hiddenStems.enumerated() {
                let weight: Double = index == 0 ? 0.6 : (index == 1 ? 0.3 : 0.1)
                let tenGod = TenGod.relationship(dayMaster: dayMaster, other: stem)
                let category = categorize(tenGod)
                categoryCounts[category, default: 0] += weight
            }
        }

        return categoryCounts.max(by: { $0.value < $1.value })?.key ?? .self
    }

    /// Categorize a Ten God
    private func categorize(_ tenGod: TenGod) -> TenGodCategory {
        switch tenGod {
        case .bijian, .jiecai: return .self
        case .zhengyin, .pianyin: return .resource
        case .shishen, .shangguan: return .output
        case .zhengcai, .piancai: return .wealth
        case .zhengguan, .qisha: return .officer
        }
    }

    // MARK: - Self Patterns

    /// Check for Jian Lu and Yang Ren patterns
    private func checkSelfPatterns(dayMaster: HeavenlyStem, monthBranch: EarthlyBranch) -> ChartPattern? {
        // Jian Lu (建禄格): Month branch is the "Lu" (禄) position of Day Master
        // Yang Ren (羊刃格): Month branch is the "Ren" (刃) position of Day Master

        let luBranch = getLuBranch(for: dayMaster)
        let renBranch = getRenBranch(for: dayMaster)

        if monthBranch == luBranch {
            return .jianLuGe
        }
        if monthBranch == renBranch {
            return .yangRenGe
        }

        return nil
    }

    /// Get the Lu (禄) branch for a Day Master
    private func getLuBranch(for stem: HeavenlyStem) -> EarthlyBranch {
        // 禄 is where the Day Master element is strongest
        // 甲禄在寅, 乙禄在卯, 丙戊禄在巳, 丁己禄在午
        // 庚禄在申, 辛禄在酉, 壬禄在亥, 癸禄在子
        switch stem {
        case .jia: return .yin
        case .yi: return .mao
        case .bing, .wu: return .si
        case .ding, .ji: return .wu
        case .geng: return .shen
        case .xin: return .you
        case .ren: return .hai
        case .gui: return .zi
        }
    }

    /// Get the Ren (刃/Blade) branch for a Day Master
    private func getRenBranch(for stem: HeavenlyStem) -> EarthlyBranch {
        // Yang stems have Yang Ren (羊刃) one position after Lu
        // 甲刃在卯, 丙戊刃在午, 庚刃在酉, 壬刃在子
        // Yin stems don't have Yang Ren in traditional interpretation
        switch stem {
        case .jia: return .mao
        case .yi: return .chen  // Not traditional Yang Ren
        case .bing, .wu: return .wu
        case .ding, .ji: return .wei  // Not traditional Yang Ren
        case .geng: return .you
        case .xin: return .xu   // Not traditional Yang Ren
        case .ren: return .zi
        case .gui: return .chou // Not traditional Yang Ren
        }
    }

    // MARK: - Standard Pattern Analysis

    /// Determine the Ten God of the Month Branch's primary hidden stem
    private func determineMonthTenGod(dayMaster: HeavenlyStem, monthBranch: EarthlyBranch) -> TenGod {
        guard let primaryStem = monthBranch.hiddenStems.first else {
            // Fallback to element-based relationship
            return TenGod.relationshipForBranch(dayMaster: dayMaster, branch: monthBranch)
        }
        return TenGod.relationship(dayMaster: dayMaster, other: primaryStem)
    }

    /// Check if the pattern is "pure" (透干)
    private func checkPatternPurity(dayMaster: HeavenlyStem, monthTenGod: TenGod, stems: [HeavenlyStem]) -> Bool {
        for stem in stems where stem != dayMaster {
            let tenGod = TenGod.relationship(dayMaster: dayMaster, other: stem)
            if tenGod == monthTenGod {
                return true  // The month's Ten God appears in the stems
            }
        }
        return false
    }

    /// Map a Ten God to its corresponding pattern
    private func mapTenGodToPattern(_ tenGod: TenGod) -> ChartPattern {
        switch tenGod {
        case .zhengyin: return .zhengYinGe
        case .pianyin: return .pianYinGe
        case .zhengguan: return .zhengGuanGe
        case .qisha: return .qiShaGe
        case .zhengcai: return .zhengCaiGe
        case .piancai: return .pianCaiGe
        case .shishen: return .shiShenGe
        case .shangguan: return .shangGuanGe
        case .bijian: return .jianLuGe
        case .jiecai: return .yangRenGe
        }
    }

    /// Identify secondary patterns in the chart
    private func identifySecondaryPatterns(
        chart: FourPillarsChart,
        dayMaster: HeavenlyStem,
        primaryPattern: ChartPattern
    ) -> [ChartPattern] {
        var secondary: [ChartPattern] = []

        // Check for strong presence of other Ten Gods in stems
        var tenGodCounts: [TenGod: Int] = [:]

        for stem in chart.stems where stem != dayMaster {
            let tenGod = TenGod.relationship(dayMaster: dayMaster, other: stem)
            tenGodCounts[tenGod, default: 0] += 1
        }

        // If any Ten God appears multiple times, it could be a secondary pattern
        for (tenGod, count) in tenGodCounts where count >= 2 {
            let pattern = mapTenGodToPattern(tenGod)
            if pattern != primaryPattern {
                secondary.append(pattern)
            }
        }

        return secondary
    }
}
