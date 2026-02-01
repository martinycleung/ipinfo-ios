//
//  StrategicCalendarView.swift
//  Oraculum
//
//  Strategic Calendar with heatmap view
//

import SwiftUI
import SwiftData
import OraculumCore

struct StrategicCalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var localization: LocalizationManager
    @Query private var profiles: [UserProfile]

    @StateObject private var viewModel = StrategicCalendarViewModel()
    @State private var selectedDate: Date?
    @State private var selectedActivity: Activity = .signContract
    @State private var displayedMonth: Date = Date()

    /// Use a consistent Gregorian calendar with Sunday as first day of week
    /// This ensures alignment between weekday headers and grid regardless of locale
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 1  // Sunday = 1, Monday = 2, etc.
        cal.timeZone = TimeZone.current
        return cal
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Activity Picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Activity.allCases.prefix(10)) { activity in
                            ActivityChip(
                                activity: activity,
                                isSelected: activity == selectedActivity
                            ) {
                                selectedActivity = activity
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 12)

                // Month Navigation
                monthHeader

                // Calendar Grid
                calendarGrid

                Spacer()
            }
            .navigationTitle(localization.localize("calendar.title"))
            .sheet(item: $selectedDate) { date in
                if let analysis = viewModel.analysisFor(date: date) {
                    DayDetailView(analysis: analysis, onDismiss: { selectedDate = nil })
                        .environmentObject(localization)
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.loadMonth(
                    displayedMonth,
                    activity: selectedActivity,
                    userChart: profiles.first?.baZiChart
                )
            }
            .onChange(of: displayedMonth) { _, newMonth in
                Task {
                    await viewModel.loadMonth(
                        newMonth,
                        activity: selectedActivity,
                        userChart: profiles.first?.baZiChart
                    )
                }
            }
            .onChange(of: selectedActivity) { _, newActivity in
                Task {
                    await viewModel.loadMonth(
                        displayedMonth,
                        activity: newActivity,
                        userChart: profiles.first?.baZiChart
                    )
                }
            }
            // Reload when user's birth date changes (triggers BaZi recalculation)
            .onChange(of: profiles.first?.birthDate) { _, _ in
                Task {
                    viewModel.clearCache()
                    await viewModel.loadMonth(
                        displayedMonth,
                        activity: selectedActivity,
                        userChart: profiles.first?.baZiChart
                    )
                }
            }
        }
    }

    private var monthHeader: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.title3)
            }

            Spacer()

            Text(monthYearString)
                .font(.headline)

            Spacer()

            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.title3)
            }
        }
        .padding()
    }

    private var calendarGrid: some View {
        VStack(spacing: 8) {
            // Weekday headers
            HStack {
                ForEach(weekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Days grid
            let days = daysInMonth()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(days, id: \.self) { date in
                    if let date = date {
                        HeatmapCell(
                            date: date,
                            analysis: viewModel.analysisFor(date: date),
                            isSelected: selectedDate == date,
                            isToday: calendar.isDateInToday(date)
                        ) {
                            withAnimation {
                                selectedDate = date
                            }
                        }
                    } else {
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private var weekdaySymbols: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: localization.currentLanguage.rawValue)
        // Get localized weekday symbols (always starts with Sunday at index 0)
        let symbols = formatter.shortWeekdaySymbols ?? ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        // Ensure the symbols match our calendar's firstWeekday (Sunday = 1)
        // shortWeekdaySymbols already starts with Sunday, so no rotation needed
        return symbols
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: localization.currentLanguage.rawValue)
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    private func previousMonth() {
        displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
    }

    private func nextMonth() {
        displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
    }

    private func daysInMonth() -> [Date?] {
        // Get the first day of the month
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth) else {
            return []
        }

        let firstDayOfMonth = monthInterval.start

        // Get the weekday of the first day (1 = Sunday, 2 = Monday, ..., 7 = Saturday)
        // when calendar.firstWeekday = 1
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)

        // Calculate how many empty cells we need before the first day
        // weekday 1 (Sunday) -> 0 empty cells (column 0)
        // weekday 2 (Monday) -> 1 empty cell (column 1)
        // weekday 3 (Tuesday) -> 2 empty cells (column 2)
        // etc.
        let emptyCellsBefore = firstWeekday - 1

        var days: [Date?] = []

        // Add empty cells for days before the 1st
        for _ in 0..<emptyCellsBefore {
            days.append(nil)
        }

        // Add all days of the month
        var currentDate = firstDayOfMonth
        while calendar.isDate(currentDate, equalTo: displayedMonth, toGranularity: .month) {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        return days
    }
}

// Make Date Identifiable for sheet(item:)
extension Date: @retroactive Identifiable {
    public var id: TimeInterval { self.timeIntervalSince1970 }
}

#Preview {
    StrategicCalendarView()
        .environmentObject(LocalizationManager.shared)
        .modelContainer(for: [UserProfile.self])
}
