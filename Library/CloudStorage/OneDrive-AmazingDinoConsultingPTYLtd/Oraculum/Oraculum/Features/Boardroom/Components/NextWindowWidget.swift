//
//  NextWindowWidget.swift
//  Oraculum
//
//  Primary widget showing the next optimal window for an activity
//

import SwiftUI
import OraculumCore

struct NextWindowWidget: View {
    @EnvironmentObject var localization: LocalizationManager
    let analysis: DayAnalysisResult
    let activity: Activity

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(localization.localize("boardroom.nextWindow"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(localization.localize("boardroom.nextWindowFor", localizedActivityName))
                        .font(.headline)
                }

                Spacer()

                ScoreBadge(score: analysis.score, recommendation: analysis.recommendation)
            }

            Divider()

            // Date and Time
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .foregroundStyle(.blue)

                    Text(formattedDate)
                        .font(.title2)
                        .fontWeight(.semibold)
                }

                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .foregroundStyle(.blue)

                    Text(suggestedTimeWindow)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            // Day Details
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(localization.localize("calendar.dayPillar"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(analysis.dayPillar.chineseName)
                        .font(.title3)
                        .fontWeight(.medium)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(localization.localize("calendar.dayOfficer"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(analysis.dayOfficer.chineseName)
                        .font(.title3)
                        .fontWeight(.medium)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(localization.localize("calendar.solarTerm"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(analysis.solarTerm.chineseName)
                        .font(.title3)
                        .fontWeight(.medium)
                }
            }

            // Warnings if any
            if !analysis.warnings.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(localization.localize("calendar.notes"))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(analysis.warnings, id: \.self) { warning in
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                                .font(.caption)
                            Text(localizedWarning(warning))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var localizedActivityName: String {
        // For Chinese languages, use the built-in chineseName property
        if localization.currentLanguage == .simplifiedChinese || localization.currentLanguage == .traditionalChinese {
            return activity.chineseName
        }
        // For English, return the raw value
        return activity.rawValue
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: localization.currentLanguage.rawValue)
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: analysis.date)
    }

    private var suggestedTimeWindow: String {
        // Suggest optimal hours based on activity type
        switch activity.category {
        case .business:
            return localization.localize("time.siWu")
        case .ceremony:
            return localization.localize("time.maoChen")
        case .personal:
            return localization.localize("time.weiShen")
        default:
            return localization.localize("time.wu")
        }
    }

    private func localizedWarning(_ warning: String) -> String {
        // If warning is a localization key (starts with "warning." or "score."), localize it
        if warning.hasPrefix("warning.") || warning.hasPrefix("score.") {
            return localization.localize(warning)
        }
        // Otherwise return as-is (for backwards compatibility)
        return warning
    }
}

#Preview {
    NextWindowWidget(
        analysis: DayAnalysisResult(
            date: Date(),
            dayPillar: Pillar(stem: .jia, branch: .zi),
            monthPillar: Pillar(stem: .bing, branch: .yin),
            yearPillar: Pillar(stem: .jia, branch: .chen),
            dayOfficer: .cheng,
            lunarStars: [.tianDe],
            scoringResult: ScoringResult(
                totalScore: 85,
                baseScore: 50,
                dayOfficerScore: 20,
                lunarStarsScore: 15,
                personalScore: 0,
                usefulGodScore: 0,
                breakdown: [:],
                warnings: [],
                instantFail: false
            ),
            solarTerm: .liChun
        ),
        activity: .signContract
    )
    .environmentObject(LocalizationManager.shared)
    .padding()
}
