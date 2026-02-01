//
//  BoardroomView.swift
//  Oraculum
//
//  The "Boardroom" Dashboard - Home Screen
//

import SwiftUI
import SwiftData
import OraculumCore

struct BoardroomView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var localization: LocalizationManager
    @Query private var profiles: [UserProfile]

    @StateObject private var viewModel = BoardroomViewModel()
    @State private var selectedActivity: Activity = .signContract

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Next Optimal Window Widget
                    if let nextWindow = viewModel.nextOptimalWindow {
                        NextWindowWidget(
                            analysis: nextWindow,
                            activity: selectedActivity
                        )
                    } else {
                        loadingWidget
                    }

                    // Activity Picker
                    activityPicker

                    // Today's Brief
                    if let todayAnalysis = viewModel.todayAnalysis {
                        DayBriefCard(analysis: todayAnalysis)
                    }

                    // Upcoming Good Days
                    upcomingDaysSection
                }
                .padding()
            }
            .background(Color(.systemBackground))
            .navigationTitle(localization.localize("boardroom.title"))
            .navigationBarTitleDisplayMode(.large)
            .task {
                await viewModel.loadData(
                    activity: selectedActivity,
                    userChart: profiles.first?.baZiChart
                )
            }
            .onChange(of: selectedActivity) { _, newActivity in
                Task {
                    await viewModel.loadData(
                        activity: newActivity,
                        userChart: profiles.first?.baZiChart
                    )
                }
            }
            // Reload when user's birth date changes (triggers BaZi recalculation)
            .onChange(of: profiles.first?.birthDate) { _, _ in
                Task {
                    await viewModel.loadData(
                        activity: selectedActivity,
                        userChart: profiles.first?.baZiChart
                    )
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(formattedDate)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let profile = profiles.first {
                Text(localization.localize("boardroom.welcome", profile.name))
                    .font(.title2)
                    .fontWeight(.semibold)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: localization.currentLanguage.rawValue)
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: Date())
    }

    private var loadingWidget: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.secondarySystemBackground))
            .frame(height: 180)
            .overlay {
                ProgressView()
                    .scaleEffect(1.2)
            }
    }

    private var activityPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localization.localize("boardroom.whatPlanning"))
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Activity.allCases.prefix(8)) { activity in
                        ActivityChip(
                            activity: activity,
                            isSelected: activity == selectedActivity
                        ) {
                            selectedActivity = activity
                        }
                    }
                }
            }
        }
    }

    private var upcomingDaysSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(localization.localize("boardroom.upcomingOpportunities"))
                    .font(.headline)

                Spacer()

                NavigationLink(destination: StrategicCalendarView()) {
                    Text(localization.localize("boardroom.viewCalendar"))
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
            }

            if viewModel.upcomingGoodDays.isEmpty {
                Text(localization.localize("boardroom.analyzing"))
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.upcomingGoodDays.prefix(5)) { analysis in
                        UpcomingDayRow(analysis: analysis)
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct ActivityChip: View {
    @EnvironmentObject var localization: LocalizationManager
    let activity: Activity
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(localizedActivityName)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.secondarySystemBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }

    private var localizedActivityName: String {
        // For Chinese languages, use the built-in chineseName property
        if localization.currentLanguage == .simplifiedChinese || localization.currentLanguage == .traditionalChinese {
            return activity.chineseName
        }
        // For English, return the raw value
        return activity.rawValue
    }
}

struct UpcomingDayRow: View {
    @EnvironmentObject var localization: LocalizationManager
    let analysis: DayAnalysisResult

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(formattedDate)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(analysis.dayPillar.chineseName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            ScoreBadge(score: analysis.score, recommendation: analysis.recommendation)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: localization.currentLanguage.rawValue)
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: analysis.date)
    }
}

#Preview {
    BoardroomView()
        .environmentObject(LocalizationManager.shared)
        .modelContainer(for: [UserProfile.self, FamilyMember.self])
}
