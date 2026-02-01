//
//  PromptBuilder.swift
//  Oraculum
//
//  Builds prompts for LLM consultation
//

import Foundation

/// Builds prompts for LLM consultation
public struct PromptBuilder: Sendable {

    public init() {}

    /// Builds a complete prompt for the LLM
    public static func build(
        context: ConsultationContext,
        persona: ConsultantPersona
    ) -> String {
        let jsonContext = encodeContext(context)

        return """
        \(persona.systemPrompt)

        ---
        CONTEXT DATA:
        \(jsonContext)
        ---

        USER REQUEST: \(context.userIntent)

        Provide your analysis and recommendation.
        """
    }

    /// Encodes the context as formatted JSON
    private static func encodeContext(_ context: ConsultationContext) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let data = try? encoder.encode(context),
              let jsonString = String(data: data, encoding: .utf8) else {
            return "{}"
        }

        return jsonString
    }

    /// Creates a ConsultationContext from analysis result and user profile data
    public static func createContext(
        from analysis: DayAnalysisResult,
        profileData: UserProfileData?,
        intent: String
    ) -> ConsultationContext {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let profileContext = UserProfileContext(
            industry: profileData?.industry,
            elementBalance: profileData?.elementBalance ?? "Unknown",
            location: profileData?.location ?? "Unknown"
        )

        let dayContext = DayDataContext(
            date: dateFormatter.string(from: analysis.date),
            pillars: "\(analysis.yearPillar.chineseName) / \(analysis.monthPillar.chineseName) / \(analysis.dayPillar.chineseName)",
            stars: analysis.lunarStars.map { $0.chineseName },
            score: analysis.score,
            dayOfficer: analysis.dayOfficer.chineseName,
            solarTerm: analysis.solarTerm.chineseName
        )

        return ConsultationContext(
            userProfile: profileContext,
            dayData: dayContext,
            userIntent: intent
        )
    }
}

/// Minimal user profile data for context creation (decoupled from SwiftData model)
public struct UserProfileData: Sendable {
    public let industry: String?
    public let elementBalance: String
    public let location: String
    public let baZiChart: FourPillarsChart?
    public let usefulGod: UsefulGod?

    public init(
        industry: String? = nil,
        elementBalance: String = "Unknown",
        location: String = "Unknown",
        baZiChart: FourPillarsChart? = nil,
        usefulGod: UsefulGod? = nil
    ) {
        self.industry = industry
        self.elementBalance = elementBalance
        self.location = location
        self.baZiChart = baZiChart
        self.usefulGod = usefulGod
    }
}

// MARK: - Analysis Description Helpers

extension PromptBuilder {

    /// Creates a natural language summary of the day
    public static func describeDaySummary(_ analysis: DayAnalysisResult) -> String {
        var parts: [String] = []

        // Score assessment
        switch analysis.recommendation {
        case .excellent:
            parts.append("This is an exceptional day")
        case .good:
            parts.append("This is a favorable day")
        case .neutral:
            parts.append("This is a balanced day")
        case .caution:
            parts.append("Caution is advised for this day")
        case .avoid:
            parts.append("This day should be avoided for major activities")
        }

        // Day officer
        parts.append("under the \(analysis.dayOfficer.englishName) officer")

        // Notable stars
        let auspiciousStars = analysis.lunarStars.filter { $0.category == .auspicious }
        let inauspiciousStars = analysis.lunarStars.filter { $0.category == .inauspicious }

        if !auspiciousStars.isEmpty {
            let starNames = auspiciousStars.map { $0.chineseName }.joined(separator: ", ")
            parts.append("blessed by \(starNames)")
        }

        if !inauspiciousStars.isEmpty {
            let starNames = inauspiciousStars.map { $0.chineseName }.joined(separator: ", ")
            parts.append("challenged by \(starNames)")
        }

        return parts.joined(separator: " ") + "."
    }
}
