//
//  DayDetailView.swift
//  Oraculum
//
//  Detail sheet for a selected day
//

import SwiftUI
import OraculumCore

struct DayDetailView: View {
    @EnvironmentObject var localization: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    let analysis: DayAnalysisResult
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(formattedDate)
                                .font(.headline)
                            Text(analysis.dayPillar.chineseName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        ScoreBadge(score: analysis.score, recommendation: analysis.recommendation)
                    }

                    Divider()

                    // Details Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        DetailItem(title: localization.localize("calendar.dayOfficer"), value: analysis.dayOfficer.chineseName)
                        DetailItem(title: localization.localize("calendar.solarTerm"), value: analysis.solarTerm.chineseName)
                        DetailItem(title: localization.localize("calendar.element"), value: analysis.dayPillar.element.chineseName)
                    }

                    // Lunar Stars
                    if !analysis.lunarStars.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(localization.localize("calendar.activeStars"))
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(analysis.lunarStars, id: \.self) { star in
                                        StarChip(star: star)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Warnings
                    if !analysis.warnings.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(analysis.warnings, id: \.self) { warning in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.orange)
                                        .font(.caption)
                                    Text(localizedWarning(warning))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    // Recommendation
                    HStack {
                        Image(systemName: recommendationIcon)
                            .foregroundStyle(recommendationColor)
                        Text(recommendationText)
                            .font(.subheadline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(recommendationColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    // Professional Insight (personalized advice)
                    if !analysis.scoringResult.professionalInsight.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: insightIcon)
                                    .foregroundStyle(insightColor)
                                Text(localization.localize(analysis.scoringResult.professionalTitle))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }

                            Text(localization.localize(analysis.scoringResult.professionalInsight))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)

                            // Show alternative date suggestion if available
                            if let suggestion = analysis.scoringResult.alternativeDateSuggestion {
                                HStack(spacing: 6) {
                                    Image(systemName: "calendar.badge.clock")
                                        .foregroundStyle(.blue)
                                        .font(.caption)
                                    Text(localization.localize(suggestion))
                                        .font(.caption)
                                        .foregroundStyle(.blue)
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(insightBackgroundColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
            }
            .navigationTitle(localization.localize("calendar.dayDetail"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                        onDismiss?()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.gray)
                    }
                }
            }
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: localization.currentLanguage.rawValue)
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: analysis.date)
    }

    private func localizedWarning(_ warning: String) -> String {
        // If warning is a localization key (starts with "warning." or "score."), localize it
        if warning.hasPrefix("warning.") || warning.hasPrefix("score.") {
            return localization.localize(warning)
        }
        // Otherwise return as-is (for backwards compatibility)
        return warning
    }

    // MARK: - Professional Insight Styling

    private var insightIcon: String {
        if analysis.scoringResult.hasPersonalClash {
            return "person.crop.circle.badge.exclamationmark"
        } else if analysis.scoringResult.isYearBreaker {
            return "exclamationmark.shield"
        } else if analysis.recommendation == .avoid || analysis.recommendation == .caution {
            return "lightbulb.fill"
        } else {
            return "sparkles"
        }
    }

    private var insightColor: Color {
        switch analysis.recommendation {
        case .excellent: return .yellow
        case .good: return .green
        case .neutral: return .blue
        case .caution: return .orange
        case .avoid: return .red
        }
    }

    private var insightBackgroundColor: Color {
        switch analysis.recommendation {
        case .excellent: return Color.yellow.opacity(0.1)
        case .good: return Color.green.opacity(0.1)
        case .neutral: return Color.blue.opacity(0.05)
        case .caution: return Color.orange.opacity(0.1)
        case .avoid: return Color.red.opacity(0.1)
        }
    }

    private var recommendationIcon: String {
        switch analysis.recommendation {
        case .excellent: return "star.fill"
        case .good: return "checkmark.circle.fill"
        case .neutral: return "minus.circle.fill"
        case .caution: return "exclamationmark.triangle.fill"
        case .avoid: return "xmark.circle.fill"
        }
    }

    private var recommendationColor: Color {
        switch analysis.recommendation {
        case .excellent: return .yellow
        case .good: return .green
        case .neutral: return .gray
        case .caution: return .orange
        case .avoid: return .red
        }
    }

    private var recommendationText: String {
        switch analysis.recommendation {
        case .excellent: return localization.localize("day.excellent")
        case .good: return localization.localize("day.good")
        case .neutral: return localization.localize("day.neutral")
        case .caution: return localization.localize("day.caution")
        case .avoid: return localization.localize("day.avoid")
        }
    }
}

struct DetailItem: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    DayDetailView(
        analysis: DayAnalysisResult(
            date: Date(),
            dayPillar: Pillar(stem: .jia, branch: .zi),
            monthPillar: Pillar(stem: .bing, branch: .yin),
            yearPillar: Pillar(stem: .jia, branch: .chen),
            dayOfficer: .cheng,
            lunarStars: [.tianDe, .yueDe],
            scoringResult: ScoringResult(
                totalScore: 75,
                baseScore: 50,
                dayOfficerScore: 15,
                lunarStarsScore: 10,
                personalScore: 0,
                usefulGodScore: 0,
                breakdown: [:],
                warnings: ["Minor clash with month branch"],
                instantFail: false
            ),
            solarTerm: .liChun
        )
    )
    .environmentObject(LocalizationManager.shared)
}
