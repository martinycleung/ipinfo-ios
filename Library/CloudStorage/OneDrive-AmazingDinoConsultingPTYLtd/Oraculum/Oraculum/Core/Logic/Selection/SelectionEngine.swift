//
//  SelectionEngine.swift
//  Oraculum
//
//  Main orchestrator for auspicious date selection
//

import Foundation
import CoreLocation

/// Result of analyzing a single day
public struct DayAnalysisResult: Sendable, Identifiable {
    public let id: UUID
    public let date: Date
    public let dayPillar: Pillar
    public let monthPillar: Pillar
    public let yearPillar: Pillar
    public let dayOfficer: DayOfficer
    public let lunarStars: [LunarStar]
    public let scoringResult: ScoringResult
    public let solarTerm: SolarTerm

    public var score: Int { scoringResult.totalScore }
    public var recommendation: SelectionRecommendation { scoringResult.recommendation }
    public var warnings: [String] { scoringResult.warnings }

    public init(
        id: UUID = UUID(),
        date: Date,
        dayPillar: Pillar,
        monthPillar: Pillar,
        yearPillar: Pillar,
        dayOfficer: DayOfficer,
        lunarStars: [LunarStar],
        scoringResult: ScoringResult,
        solarTerm: SolarTerm
    ) {
        self.id = id
        self.date = date
        self.dayPillar = dayPillar
        self.monthPillar = monthPillar
        self.yearPillar = yearPillar
        self.dayOfficer = dayOfficer
        self.lunarStars = lunarStars
        self.scoringResult = scoringResult
        self.solarTerm = solarTerm
    }
}

/// Warning types for day selection
public struct SelectionWarning: Sendable, Identifiable {
    public let id: UUID
    public let severity: WarningSeverity
    public let title: String
    public let description: String

    public enum WarningSeverity: String, Sendable {
        case critical = "Critical"
        case warning = "Warning"
        case info = "Info"
    }

    public init(id: UUID = UUID(), severity: WarningSeverity, title: String, description: String) {
        self.id = id
        self.severity = severity
        self.title = title
        self.description = description
    }
}

/// Main engine for auspicious date selection
public actor SelectionEngine {
    private let fourPillarsCalculator: FourPillarsCalculator
    private let solarTermCalculator: SolarTermCalculator
    private let dayOfficerCalculator: DayOfficerCalculator
    private let lunarStarsCalculator: LunarStarsCalculator
    private let scoringSystem: ScoringSystem

    public init(
        fourPillarsCalculator: FourPillarsCalculator = FourPillarsCalculator(),
        solarTermCalculator: SolarTermCalculator = SolarTermCalculator(),
        dayOfficerCalculator: DayOfficerCalculator = DayOfficerCalculator(),
        lunarStarsCalculator: LunarStarsCalculator = LunarStarsCalculator(),
        scoringSystem: ScoringSystem = ScoringSystem()
    ) {
        self.fourPillarsCalculator = fourPillarsCalculator
        self.solarTermCalculator = solarTermCalculator
        self.dayOfficerCalculator = dayOfficerCalculator
        self.lunarStarsCalculator = lunarStarsCalculator
        self.scoringSystem = scoringSystem
    }

    // MARK: - Single Day Analysis

    /// Analyzes a single day for a specific activity
    /// - Parameters:
    ///   - date: The date to analyze
    ///   - activity: The intended activity
    ///   - userChart: User's Ba Zi chart for personal analysis (optional)
    ///   - usefulGod: User's Useful God for enhanced scoring (optional)
    /// - Returns: Complete day analysis result
    public func analyzeDay(
        date: Date,
        activity: Activity,
        userChart: FourPillarsChart? = nil,
        usefulGod: UsefulGod? = nil
    ) async -> DayAnalysisResult {
        // Calculate day's pillars
        let chart = await fourPillarsCalculator.calculate(date: date)

        // Get current solar term
        let solarTerm = await solarTermCalculator.currentSolarTerm(for: date)

        // Calculate day officer
        let dayOfficer = dayOfficerCalculator.calculate(
            monthBranch: chart.monthPillar.branch,
            dayBranch: chart.dayPillar.branch
        )

        // Calculate lunar stars
        let lunarStars = await lunarStarsCalculator.calculate(
            yearBranch: chart.yearPillar.branch,
            monthBranch: chart.monthPillar.branch,
            dayBranch: chart.dayPillar.branch
        )

        // Build personal factors if user chart available
        // Use enhanced PersonalFactors which calculates all BaZi analysis
        var personalFactors: PersonalFactors? = nil
        if let userChart = userChart {
            // Use createEnhanced which calculates:
            // - Useful God with full analysis
            // - Day Master strength
            // - Chart patterns
            // - Climate adjustment
            personalFactors = PersonalFactors.createEnhanced(
                userChart: userChart,
                dayBranch: chart.dayPillar.branch
            )
        }

        // Calculate score with year pillar for Year Breaker detection
        let scoringResult = scoringSystem.calculateScore(
            dayOfficer: dayOfficer,
            lunarStars: lunarStars,
            activity: activity,
            dayPillar: chart.dayPillar,
            monthPillar: chart.monthPillar,
            yearPillar: chart.yearPillar,
            personalFactors: personalFactors
        )

        return DayAnalysisResult(
            date: date,
            dayPillar: chart.dayPillar,
            monthPillar: chart.monthPillar,
            yearPillar: chart.yearPillar,
            dayOfficer: dayOfficer,
            lunarStars: lunarStars,
            scoringResult: scoringResult,
            solarTerm: solarTerm
        )
    }

    // MARK: - Date Range Analysis

    /// Finds optimal days within a date range
    /// - Parameters:
    ///   - dateRange: The range of dates to search
    ///   - activity: The intended activity
    ///   - userChart: User's Ba Zi chart (optional)
    ///   - usefulGod: User's Useful God (optional)
    ///   - limit: Maximum number of results (default 10)
    /// - Returns: Array of day analysis results, sorted by score
    public func findOptimalDays(
        in dateRange: ClosedRange<Date>,
        for activity: Activity,
        userChart: FourPillarsChart? = nil,
        usefulGod: UsefulGod? = nil,
        limit: Int = 10
    ) async -> [DayAnalysisResult] {
        var results: [DayAnalysisResult] = []

        let calendar = Calendar(identifier: .gregorian)
        var currentDate = dateRange.lowerBound

        while currentDate <= dateRange.upperBound {
            let analysis = await analyzeDay(
                date: currentDate,
                activity: activity,
                userChart: userChart,
                usefulGod: usefulGod
            )

            // Only include days that aren't instant fails
            if !analysis.scoringResult.instantFail {
                results.append(analysis)
            }

            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        // Sort by score descending and limit results
        return Array(results.sorted { $0.score > $1.score }.prefix(limit))
    }

    /// Group selection - finds intersection of good days for multiple users
    /// - Parameters:
    ///   - dateRange: The range of dates to search
    ///   - activity: The intended activity
    ///   - userCharts: Array of user Ba Zi charts
    /// - Returns: Days that are good for all users
    public func findGroupOptimalDays(
        in dateRange: ClosedRange<Date>,
        for activity: Activity,
        userCharts: [FourPillarsChart]
    ) async -> [DayAnalysisResult] {
        guard !userCharts.isEmpty else {
            return await findOptimalDays(in: dateRange, for: activity)
        }

        var allResults: [[DayAnalysisResult]] = []

        // Analyze for each user
        for chart in userCharts {
            let results = await findOptimalDays(
                in: dateRange,
                for: activity,
                userChart: chart,
                limit: 100  // Get more results for intersection
            )
            allResults.append(results)
        }

        // Find intersection - days that are in top 30% for all users
        guard let firstResults = allResults.first else { return [] }

        var commonGoodDays: [DayAnalysisResult] = []

        for result in firstResults {
            let isGoodForAll = allResults.dropFirst().allSatisfy { userResults in
                userResults.contains { $0.date == result.date && $0.score >= 50 }
            }

            if isGoodForAll {
                commonGoodDays.append(result)
            }
        }

        return Array(commonGoodDays.prefix(10))
    }

    // MARK: - Helper Methods

    private func calculateClashes(
        dayBranch: EarthlyBranch,
        userChart: FourPillarsChart
    ) -> [ClashType] {
        var clashes: [ClashType] = []

        if dayBranch == userChart.yearPillar.branch.clash {
            clashes.append(.yearClash)
        }
        if dayBranch == userChart.monthPillar.branch.clash {
            clashes.append(.monthClash)
        }
        if dayBranch == userChart.dayPillar.branch.clash {
            clashes.append(.dayClash)
        }
        if dayBranch == userChart.hourPillar.branch.clash {
            clashes.append(.hourClash)
        }

        return clashes
    }

    private func calculatePenalties(
        dayBranch: EarthlyBranch,
        userChart: FourPillarsChart
    ) -> [PenaltyType] {
        var penalties: [PenaltyType] = []

        let userBranches = userChart.branches

        for userBranch in userBranches {
            if dayBranch.penalties.contains(userBranch) {
                // Determine penalty type
                switch (dayBranch, userBranch) {
                case (.yin, .si), (.yin, .shen), (.si, .yin), (.si, .shen), (.shen, .yin), (.shen, .si):
                    if !penalties.contains(.ungratefulPenalty) {
                        penalties.append(.ungratefulPenalty)
                    }
                case (.chou, .xu), (.chou, .wei), (.xu, .chou), (.xu, .wei), (.wei, .chou), (.wei, .xu):
                    if !penalties.contains(.bullyingPenalty) {
                        penalties.append(.bullyingPenalty)
                    }
                case (.zi, .mao), (.mao, .zi):
                    if !penalties.contains(.uncivilizedPenalty) {
                        penalties.append(.uncivilizedPenalty)
                    }
                case (.chen, .chen), (.wu, .wu), (.you, .you), (.hai, .hai):
                    if dayBranch == userBranch && !penalties.contains(.selfPenalty) {
                        penalties.append(.selfPenalty)
                    }
                default:
                    break
                }
            }
        }

        return penalties
    }
}
