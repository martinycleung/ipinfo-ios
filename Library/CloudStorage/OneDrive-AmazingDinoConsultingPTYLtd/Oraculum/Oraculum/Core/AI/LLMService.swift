//
//  LLMService.swift
//  Oraculum
//
//  Protocol and types for LLM integration
//

import Foundation

/// Protocol for LLM services
public protocol LLMService: Sendable {
    func generateConsultation(context: ConsultationContext) async throws -> String
}

/// Context for consultation generation
public struct ConsultationContext: Sendable, Codable {
    public let userProfile: UserProfileContext
    public let dayData: DayDataContext
    public let userIntent: String

    public init(
        userProfile: UserProfileContext,
        dayData: DayDataContext,
        userIntent: String
    ) {
        self.userProfile = userProfile
        self.dayData = dayData
        self.userIntent = userIntent
    }
}

/// User profile context for LLM
public struct UserProfileContext: Sendable, Codable {
    public let industry: String?
    public let elementBalance: String
    public let location: String

    public init(industry: String?, elementBalance: String, location: String) {
        self.industry = industry
        self.elementBalance = elementBalance
        self.location = location
    }
}

/// Day data context for LLM
public struct DayDataContext: Sendable, Codable {
    public let date: String
    public let pillars: String
    public let stars: [String]
    public let score: Int
    public let dayOfficer: String
    public let solarTerm: String

    public init(
        date: String,
        pillars: String,
        stars: [String],
        score: Int,
        dayOfficer: String,
        solarTerm: String
    ) {
        self.date = date
        self.pillars = pillars
        self.stars = stars
        self.score = score
        self.dayOfficer = dayOfficer
        self.solarTerm = solarTerm
    }
}

/// Errors for LLM operations
public enum LLMError: Error, LocalizedError {
    case modelNotAvailable
    case generationFailed(String)
    case contextTooLong
    case responseEmpty

    public var errorDescription: String? {
        switch self {
        case .modelNotAvailable:
            return "The AI model is not available on this device."
        case .generationFailed(let reason):
            return "Failed to generate response: \(reason)"
        case .contextTooLong:
            return "The context is too long for the model."
        case .responseEmpty:
            return "The model returned an empty response."
        }
    }
}
