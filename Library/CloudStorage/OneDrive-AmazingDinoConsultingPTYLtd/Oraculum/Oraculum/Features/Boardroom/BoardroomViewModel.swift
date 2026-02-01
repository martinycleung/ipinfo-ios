//
//  BoardroomViewModel.swift
//  Oraculum
//
//  ViewModel for the Boardroom Dashboard
//

import Foundation
import SwiftUI
import OraculumCore

@MainActor
@Observable
final class BoardroomViewModel: ObservableObject {
    private let selectionEngine = SelectionEngine()

    var todayAnalysis: DayAnalysisResult?
    var nextOptimalWindow: DayAnalysisResult?
    var upcomingGoodDays: [DayAnalysisResult] = []
    var isLoading = false
    var error: Error?

    /// Use a consistent Gregorian calendar for all date operations
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone.current
        return cal
    }

    /// Loads dashboard data for a specific activity
    func loadData(
        activity: Activity,
        userChart: FourPillarsChart? = nil,
        usefulGod: UsefulGod? = nil
    ) async {
        isLoading = true
        error = nil

        do {
            // Normalize today's date to start of day for consistency
            let today = calendar.startOfDay(for: Date())

            // Analyze today
            todayAnalysis = await selectionEngine.analyzeDay(
                date: today,
                activity: activity,
                userChart: userChart,
                usefulGod: usefulGod
            )

            // Find optimal days in the next 30 days
            let startDate = today
            let endDate = calendar.date(byAdding: .day, value: 30, to: startDate) ?? startDate

            let optimalDays = await selectionEngine.findOptimalDays(
                in: startDate...endDate,
                for: activity,
                userChart: userChart,
                usefulGod: usefulGod,
                limit: 10
            )

            // First optimal day is the "next window"
            nextOptimalWindow = optimalDays.first

            // Rest are upcoming good days
            upcomingGoodDays = optimalDays

            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }

    /// Refreshes data
    func refresh(activity: Activity, userChart: FourPillarsChart? = nil) async {
        await loadData(activity: activity, userChart: userChart)
    }

    /// Gets recommendation text for the current day - uses professional insight if available
    func getTodayRecommendation() -> String {
        guard let analysis = todayAnalysis else {
            return "Analyzing today's energy..."
        }

        // Use the professional insight if available (personalized advice)
        if !analysis.scoringResult.professionalInsight.isEmpty {
            return analysis.scoringResult.professionalInsight
        }

        // Fallback to generic recommendation
        switch analysis.recommendation {
        case .excellent:
            return "Today is an excellent day for important activities."
        case .good:
            return "Today is favorable for most planned activities."
        case .neutral:
            return "A balanced day. Proceed with routine matters."
        case .caution:
            return "Exercise caution today. Consider postponing major decisions."
        case .avoid:
            return "Not recommended for significant activities today."
        }
    }

    /// Gets the professional insight title
    func getTodayInsightTitle() -> String? {
        guard let analysis = todayAnalysis,
              !analysis.scoringResult.professionalTitle.isEmpty else {
            return nil
        }
        return analysis.scoringResult.professionalTitle
    }

    /// Whether today has a personal clash (most critical warning)
    var hasCriticalWarning: Bool {
        todayAnalysis?.scoringResult.hasPersonalClash ?? false
    }

    /// Whether today is a year breaker day
    var isYearBreaker: Bool {
        todayAnalysis?.scoringResult.isYearBreaker ?? false
    }

    /// Gets the time window suggestion
    func getOptimalTimeWindow() -> String? {
        guard let next = nextOptimalWindow else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d 'at' h:mm a"

        // For now, suggest midday (wu hour) for most activities
        if let noonDate = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: next.date) {
            return formatter.string(from: noonDate)
        }

        return formatter.string(from: next.date)
    }
}
