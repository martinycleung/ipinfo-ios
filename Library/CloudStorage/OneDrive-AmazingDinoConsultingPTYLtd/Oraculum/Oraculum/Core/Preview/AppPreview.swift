//
//  AppPreview.swift
//  OraculumCore
//
//  Preview of the Oraculum app functionality
//

#if canImport(UIKit)
import UIKit
#endif
import SwiftUI

// Cross-platform color helpers
private extension Color {
    static var systemBackground: Color {
        #if canImport(UIKit)
        Color(UIColor.systemBackground)
        #else
        Color(NSColor.windowBackgroundColor)
        #endif
    }

    static var systemGroupedBackground: Color {
        #if canImport(UIKit)
        Color(UIColor.systemGroupedBackground)
        #else
        Color(NSColor.controlBackgroundColor)
        #endif
    }

    static var systemGray5: Color {
        #if canImport(UIKit)
        Color(UIColor.systemGray5)
        #else
        Color(NSColor.systemGray.withAlphaComponent(0.2))
        #endif
    }
}

// MARK: - Preview Data

/// Sample analysis data for previews
public struct PreviewDayAnalysis {
    public let date: Date
    public let dayPillar: Pillar
    public let dayOfficer: DayOfficer
    public let score: Int
    public let recommendation: SelectionRecommendation

    public static let sample: PreviewDayAnalysis = {
        let today = Date()
        let dayPillar = JulianDayConverter.dayPillar(from: today)
        let calculator = DayOfficerCalculator()
        let dayOfficer = calculator.calculate(monthBranch: .yin, dayBranch: dayPillar.branch)

        return PreviewDayAnalysis(
            date: today,
            dayPillar: dayPillar,
            dayOfficer: dayOfficer,
            score: 72,
            recommendation: .good
        )
    }()
}

// MARK: - Boardroom Preview View

public struct BoardroomPreviewView: View {
    let analysis: PreviewDayAnalysis

    public init(analysis: PreviewDayAnalysis = .sample) {
        self.analysis = analysis
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    todayCard
                    dayPillarCard
                    scoreCard
                    Spacer(minLength: 40)
                }
                .padding()
            }
            .background(Color.systemGroupedBackground)
            .navigationTitle("Oraculum")
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DIGITAL METAPHYSICS")
                .font(.caption)
                .foregroundStyle(.secondary)
                .tracking(2)

            Text("Your Strategic Advisor")
                .font(.title2)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var todayCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Energy")
                        .font(.headline)
                    Text(analysis.date, style: .date)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(analysis.recommendation.emoji)
                    .font(.system(size: 40))
            }

            Divider()

            HStack {
                VStack(alignment: .leading) {
                    Text("Day Officer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(analysis.dayOfficer.chineseName) · \(analysis.dayOfficer.englishName)")
                        .font(.title3)
                        .fontWeight(.medium)
                }
                Spacer()
            }

            Text(analysis.dayOfficer.generalMeaning)
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color.systemBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
    }

    private var dayPillarCard: some View {
        VStack(spacing: 16) {
            Text("Day Pillar 日柱")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 40) {
                // Stem
                VStack(spacing: 8) {
                    Text(analysis.dayPillar.stem.chineseName)
                        .font(.system(size: 56, weight: .light))
                    Text(analysis.dayPillar.stem.element.chineseName)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(elementColor(analysis.dayPillar.stem.element).opacity(0.2))
                        .clipShape(Capsule())
                }

                // Branch
                VStack(spacing: 8) {
                    Text(analysis.dayPillar.branch.chineseName)
                        .font(.system(size: 56, weight: .light))
                    Text(analysis.dayPillar.branch.zodiacAnimal)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color.systemBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
    }

    private var scoreCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Overall Score")
                    .font(.headline)
                Spacer()
                Text("\(analysis.score)")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(recommendationColor(analysis.recommendation))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.systemGray5)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(recommendationColor(analysis.recommendation))
                        .frame(width: geo.size.width * CGFloat(analysis.score) / 100)
                }
            }
            .frame(height: 10)

            Text(analysis.recommendation.rawValue)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(recommendationColor(analysis.recommendation))
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
        .background(Color.systemBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
    }

    private func elementColor(_ element: FiveElement) -> Color {
        switch element {
        case .wood: return .green
        case .fire: return .red
        case .earth: return .orange
        case .metal: return .gray
        case .water: return .blue
        }
    }

    private func recommendationColor(_ rec: SelectionRecommendation) -> Color {
        switch rec {
        case .excellent: return .yellow
        case .good: return .green
        case .neutral: return .gray
        case .caution: return .orange
        case .avoid: return .red
        }
    }
}

// MARK: - Previews

#Preview("Boardroom - Good Day") {
    BoardroomPreviewView(analysis: .sample)
}

#Preview("Boardroom - Excellent Day") {
    BoardroomPreviewView(analysis: PreviewDayAnalysis(
        date: Date(),
        dayPillar: Pillar(stem: .jia, branch: .zi),
        dayOfficer: .cheng,
        score: 88,
        recommendation: .excellent
    ))
}

#Preview("Boardroom - Caution Day") {
    BoardroomPreviewView(analysis: PreviewDayAnalysis(
        date: Date(),
        dayPillar: Pillar(stem: .geng, branch: .wu),
        dayOfficer: .po,
        score: 35,
        recommendation: .caution
    ))
}
