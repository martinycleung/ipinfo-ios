//
//  DayBriefCard.swift
//  Oraculum
//
//  Card showing today's brief analysis
//

import SwiftUI
import OraculumCore

struct DayBriefCard: View {
    @EnvironmentObject var localization: LocalizationManager
    let analysis: DayAnalysisResult

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(localization.localize("boardroom.todayEnergy"))
                    .font(.headline)

                Spacer()

                Text(analysis.recommendation.emoji)
                    .font(.title2)
            }

            // Score bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(localization.localize("boardroom.overallScore"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(analysis.score)/100")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(scoreColor)
                            .frame(width: geometry.size.width * CGFloat(analysis.score) / 100, height: 8)
                    }
                }
                .frame(height: 8)
            }

            // Day details grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                DetailCell(title: localization.localize("calendar.dayPillar"), value: analysis.dayPillar.chineseName)
                DetailCell(title: localization.localize("calendar.dayOfficer"), value: analysis.dayOfficer.chineseName)
                DetailCell(title: localization.localize("calendar.solarTerm"), value: analysis.solarTerm.chineseName)
                DetailCell(title: localization.localize("calendar.element"), value: analysis.dayPillar.element.chineseName)
            }

            // Lunar Stars
            if !analysis.lunarStars.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(localization.localize("calendar.activeStars"))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    FlowLayout(spacing: 8) {
                        ForEach(analysis.lunarStars, id: \.self) { star in
                            StarChip(star: star)
                        }
                    }
                }
            }

            // Professional Insight (personalized advice)
            if !analysis.scoringResult.professionalInsight.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: insightIcon)
                            .foregroundStyle(insightIconColor)
                            .font(.subheadline)
                        Text(localization.localize(analysis.scoringResult.professionalTitle))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }

                    Text(localization.localize(analysis.scoringResult.professionalInsight))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

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

    private var insightIconColor: Color {
        switch analysis.recommendation {
        case .excellent: return .yellow
        case .good: return .green
        case .neutral: return .blue
        case .caution: return .orange
        case .avoid: return .red
        }
    }

    private var scoreColor: Color {
        switch analysis.recommendation {
        case .excellent: return .yellow
        case .good: return .green
        case .neutral: return .gray
        case .caution: return .orange
        case .avoid: return .red
        }
    }
}

struct DetailCell: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct StarChip: View {
    let star: LunarStar

    var body: some View {
        Text(star.chineseName)
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(chipColor.opacity(0.2))
            .foregroundStyle(chipColor)
            .clipShape(Capsule())
    }

    private var chipColor: Color {
        switch star.category {
        case .auspicious: return .green
        case .inauspicious: return .red
        case .neutral: return .gray
        }
    }
}

/// Simple flow layout for horizontal wrapping
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)

        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > width && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: width, height: y + lineHeight)
        }
    }
}

#Preview {
    DayBriefCard(
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
                warnings: [],
                instantFail: false
            ),
            solarTerm: .liChun
        )
    )
    .environmentObject(LocalizationManager.shared)
    .padding()
}
