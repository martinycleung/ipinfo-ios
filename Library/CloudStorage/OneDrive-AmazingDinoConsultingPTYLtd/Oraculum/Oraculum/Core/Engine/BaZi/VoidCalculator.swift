//
//  VoidCalculator.swift
//  Oraculum
//
//  Void (空亡) Calculator - Also known as Kong Wang or Empty positions
//  In the 60 Jiazi cycle, each set of 10 stems paired with 12 branches leaves 2 branches "void"
//

import Foundation

// MARK: - Void Result

/// Result of void calculation
public struct VoidResult: Sendable {
    /// The two void branches for the given pillar
    public let voidBranches: (EarthlyBranch, EarthlyBranch)

    /// Chinese name
    public var chineseName: String {
        "\(voidBranches.0.chineseName)\(voidBranches.1.chineseName)空亡"
    }

    /// Check if a branch is void
    public func isVoid(_ branch: EarthlyBranch) -> Bool {
        branch == voidBranches.0 || branch == voidBranches.1
    }
}

// MARK: - Void Calculator

/// Calculates void (空亡) positions based on the 60 Jiazi cycle
/// Void positions are the two branches not covered in a 10-day cycle
public struct VoidCalculator: Sendable {

    public init() {}

    /// The void lookup table based on the starting pillar of each 10-day cycle
    /// Each group of 10 stems starting from a Jia day has specific void branches
    private static let voidTable: [EarthlyBranch: (EarthlyBranch, EarthlyBranch)] = [
        // 甲子旬 (Jia-Zi cycle): 戌亥空亡
        .zi: (.xu, .hai),
        // 甲戌旬 (Jia-Xu cycle): 申酉空亡
        .xu: (.shen, .you),
        // 甲申旬 (Jia-Shen cycle): 午未空亡
        .shen: (.wu, .wei),
        // 甲午旬 (Jia-Wu cycle): 辰巳空亡
        .wu: (.chen, .si),
        // 甲辰旬 (Jia-Chen cycle): 寅卯空亡
        .chen: (.yin, .mao),
        // 甲寅旬 (Jia-Yin cycle): 子丑空亡
        .yin: (.zi, .chou)
    ]

    /// Calculate void branches from a day pillar
    /// - Parameter dayPillar: The day pillar to calculate void from
    /// - Returns: The void result containing the two void branches
    public func calculateFromDayPillar(_ dayPillar: Pillar) -> VoidResult {
        // Find which Jia cycle this pillar belongs to
        let cycleStartBranch = findCycleStart(pillar: dayPillar)

        guard let voidBranches = Self.voidTable[cycleStartBranch] else {
            // Fallback - should never happen
            return VoidResult(voidBranches: (.xu, .hai))
        }

        return VoidResult(voidBranches: voidBranches)
    }

    /// Find the starting branch of the 10-day Jia cycle this pillar belongs to
    private func findCycleStart(pillar: Pillar) -> EarthlyBranch {
        // Calculate how many days from the start of the current Jia cycle
        // Stem index: Jia=0, Yi=1, ... Gui=9
        let stemIndex = pillar.stem.rawValue

        // Branch index: Zi=0, Chou=1, ... Hai=11
        let branchIndex = pillar.branch.rawValue

        // Days since Jia of this cycle = stem index
        // Start branch = current branch - stem index (mod 12)
        var startBranchIndex = branchIndex - stemIndex
        if startBranchIndex < 0 {
            startBranchIndex += 12
        }

        // The Jia cycles start at: Zi(0), Xu(10), Shen(8), Wu(6), Chen(4), Yin(2)
        // Map to the nearest Jia cycle start
        let validStarts = [0, 2, 4, 6, 8, 10] // Zi, Yin, Chen, Wu, Shen, Xu
        let nearestStart = validStarts.min(by: {
            abs($0 - startBranchIndex) < abs($1 - startBranchIndex) ||
            (abs($0 - startBranchIndex) == abs($1 - startBranchIndex) && $0 < $1)
        }) ?? startBranchIndex

        // Convert back to branch
        return EarthlyBranch(rawValue: nearestStart) ?? .zi
    }

    /// Calculate void for a specific Jiazi (60-cycle) index
    /// - Parameter jiazi: The index in the 60 Jiazi cycle (0-59)
    /// - Returns: The void result
    public func calculateFromJiaziIndex(_ jiazi: Int) -> VoidResult {
        // Each Jia cycle is 10 days
        // Jiazi indices 0-9: 甲子旬 (Xu-Hai void)
        // Jiazi indices 10-19: 甲戌旬 (Shen-You void)
        // etc.
        let cycleIndex = jiazi / 10

        let voidPairs: [(EarthlyBranch, EarthlyBranch)] = [
            (.xu, .hai),     // 甲子旬
            (.shen, .you),   // 甲戌旬
            (.wu, .wei),     // 甲申旬
            (.chen, .si),    // 甲午旬
            (.yin, .mao),    // 甲辰旬
            (.zi, .chou)     // 甲寅旬
        ]

        let safeIndex = cycleIndex % 6
        return VoidResult(voidBranches: voidPairs[safeIndex])
    }

    /// Check if a branch is void relative to a day pillar
    public func isVoid(branch: EarthlyBranch, relativeTo dayPillar: Pillar) -> Bool {
        let voidResult = calculateFromDayPillar(dayPillar)
        return voidResult.isVoid(branch)
    }

    /// Check if the Useful God element is in a void position
    /// - Parameters:
    ///   - usefulGodElement: The Useful God element
    ///   - voidBranches: The void branches
    ///   - chart: The Four Pillars chart
    /// - Returns: True if the Useful God's root is in a void position
    public func isUsefulGodVoid(
        usefulGodElement: FiveElement,
        voidResult: VoidResult,
        chart: FourPillarsChart
    ) -> Bool {
        // Check if any branch containing the Useful God element is void
        let branches = chart.branches

        for branch in branches {
            // Check if this branch contains the Useful God element
            let hasUsefulGod = branch.hiddenStems.contains { $0.element == usefulGodElement }

            if hasUsefulGod && voidResult.isVoid(branch) {
                return true
            }
        }

        return false
    }
}

// MARK: - Void Analysis

/// Comprehensive void analysis for a chart
public struct VoidAnalysis: Sendable {
    /// Void branches based on day pillar
    public let dayVoid: VoidResult

    /// Branches in the chart that are void
    public let voidBranchesInChart: [EarthlyBranch]

    /// Whether the hour branch is void (considered significant)
    public let hourBranchVoid: Bool

    /// Whether any pillar has void branches
    public let hasVoidInChart: Bool

    /// Severity of void impact (0-1)
    public let voidSeverity: Double

    public var description: String {
        if !hasVoidInChart {
            return "八字无空亡"
        }
        return "空亡: \(dayVoid.chineseName), 命中见空: \(voidBranchesInChart.map { $0.chineseName }.joined(separator: ", "))"
    }
}

/// Extension to analyze void in a complete chart
extension VoidCalculator {
    /// Analyze void positions in a chart
    public func analyzeChart(_ chart: FourPillarsChart) -> VoidAnalysis {
        let dayVoid = calculateFromDayPillar(chart.dayPillar)
        let branches = chart.branches

        var voidBranchesInChart: [EarthlyBranch] = []
        for branch in branches {
            if dayVoid.isVoid(branch) {
                voidBranchesInChart.append(branch)
            }
        }

        let hourBranchVoid = dayVoid.isVoid(chart.hourPillar.branch)
        let hasVoidInChart = !voidBranchesInChart.isEmpty

        // Calculate severity
        var severity = 0.0
        if hourBranchVoid {
            severity += 0.4  // Hour void is significant
        }
        if dayVoid.isVoid(chart.monthPillar.branch) {
            severity += 0.3  // Month void is moderately significant
        }
        if dayVoid.isVoid(chart.yearPillar.branch) {
            severity += 0.2  // Year void is less significant
        }
        severity = min(1.0, severity)

        return VoidAnalysis(
            dayVoid: dayVoid,
            voidBranchesInChart: voidBranchesInChart,
            hourBranchVoid: hourBranchVoid,
            hasVoidInChart: hasVoidInChart,
            voidSeverity: severity
        )
    }

    /// Check if a date's branch is void relative to user's day pillar
    public func isDateVoid(
        dateBranch: EarthlyBranch,
        userDayPillar: Pillar
    ) -> Bool {
        let voidResult = calculateFromDayPillar(userDayPillar)
        return voidResult.isVoid(dateBranch)
    }
}
