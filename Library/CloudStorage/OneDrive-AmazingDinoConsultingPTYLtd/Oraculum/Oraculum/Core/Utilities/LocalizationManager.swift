//
//  LocalizationManager.swift
//  Oraculum
//
//  Manages app localization for English, Simplified Chinese, and Traditional Chinese
//

import Foundation
import SwiftUI

/// Supported languages in the app
public enum AppLanguage: String, CaseIterable, Identifiable, Codable, Sendable {
    case english = "en"
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"

    public var id: String { rawValue }

    /// Display name in the language itself
    public var displayName: String {
        switch self {
        case .english: return "English"
        case .simplifiedChinese: return "简体中文"
        case .traditionalChinese: return "繁體中文"
        }
    }

    /// Display name in English
    public var englishName: String {
        switch self {
        case .english: return "English"
        case .simplifiedChinese: return "Simplified Chinese"
        case .traditionalChinese: return "Traditional Chinese"
        }
    }
}

/// Thread-safe localization helper that works without MainActor requirement
public struct Localization: Sendable {
    /// Localizes a string key using the main bundle
    /// This is safe to call from any context
    public static func string(_ key: String, bundle: Bundle = .main, table: String? = nil) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, comment: "")
    }

    /// Localizes a string key with format arguments
    public static func string(_ key: String, _ arguments: CVarArg..., bundle: Bundle = .main) -> String {
        let format = string(key, bundle: bundle)
        return String(format: format, arguments: arguments)
    }

    /// Gets the bundle for a specific language
    public static func bundle(for language: AppLanguage) -> Bundle {
        guard let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
              let langBundle = Bundle(path: path) else {
            return .main
        }
        return langBundle
    }

    /// Detects the system language and returns the closest supported language
    public static func detectSystemLanguage() -> AppLanguage {
        let preferredLanguages = Locale.preferredLanguages

        for language in preferredLanguages {
            if language.hasPrefix("zh-Hans") || language.hasPrefix("zh-CN") {
                return .simplifiedChinese
            } else if language.hasPrefix("zh-Hant") || language.hasPrefix("zh-TW") || language.hasPrefix("zh-HK") {
                return .traditionalChinese
            } else if language.hasPrefix("en") {
                return .english
            }
        }

        return .english
    }
}

/// Manages localization state throughout the app (for UI updates)
@MainActor
@Observable
public final class LocalizationManager: ObservableObject {
    public static let shared = LocalizationManager()

    /// Current app language
    public var currentLanguage: AppLanguage {
        didSet {
            saveLanguagePreference()
            updateBundle()
        }
    }

    /// The bundle to use for localization
    private(set) var bundle: Bundle = .main

    private let languageKey = "app_language_preference"

    private init() {
        if let savedLanguage = UserDefaults.standard.string(forKey: languageKey),
           let language = AppLanguage(rawValue: savedLanguage) {
            self.currentLanguage = language
        } else {
            self.currentLanguage = Localization.detectSystemLanguage()
        }
        updateBundle()
    }

    /// Saves the language preference to UserDefaults
    private func saveLanguagePreference() {
        UserDefaults.standard.set(currentLanguage.rawValue, forKey: languageKey)
    }

    /// Updates the bundle based on current language
    private func updateBundle() {
        bundle = Localization.bundle(for: currentLanguage)
    }

    /// Localizes a string key
    public func localize(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: nil, table: nil)
    }

    /// Localizes a string key with format arguments
    public func localize(_ key: String, _ arguments: CVarArg...) -> String {
        let format = localize(key)
        return String(format: format, arguments: arguments)
    }
}

// MARK: - String Extension for Localization

extension String {
    /// Returns the localized version of this string using the main bundle
    /// Safe to call from any context
    var localized: String {
        Localization.string(self)
    }

    /// Returns the localized version with format arguments
    func localized(_ arguments: CVarArg...) -> String {
        let format = Localization.string(self)
        return String(format: format, arguments: arguments)
    }

    /// Returns the localized version for a specific language
    func localized(for language: AppLanguage) -> String {
        let bundle = Localization.bundle(for: language)
        return Localization.string(self, bundle: bundle)
    }
}

// MARK: - Localization Keys

/// Type-safe localization keys
public enum L10n {
    // App General
    public static var appName: String { "app.name".localized }
    public static var appTagline: String { "app.tagline".localized }

    // Tab Bar
    public static var tabBoardroom: String { "tab.boardroom".localized }
    public static var tabCalendar: String { "tab.calendar".localized }
    public static var tabFamilyOffice: String { "tab.familyOffice".localized }
    public static var tabProfile: String { "tab.profile".localized }

    // Boardroom
    public static var boardroomTitle: String { "boardroom.title".localized }
    public static func boardroomWelcome(_ name: String) -> String { "boardroom.welcome".localized(name) }
    public static var boardroomNextWindow: String { "boardroom.nextWindow".localized }
    public static func boardroomNextWindowFor(_ activity: String) -> String { "boardroom.nextWindowFor".localized(activity) }
    public static var boardroomTodayEnergy: String { "boardroom.todayEnergy".localized }
    public static var boardroomOverallScore: String { "boardroom.overallScore".localized }
    public static var boardroomWhatPlanning: String { "boardroom.whatPlanning".localized }
    public static var boardroomUpcomingOpportunities: String { "boardroom.upcomingOpportunities".localized }
    public static var boardroomViewCalendar: String { "boardroom.viewCalendar".localized }

    // Calendar
    public static var calendarTitle: String { "calendar.title".localized }
    public static var calendarDayPillar: String { "calendar.dayPillar".localized }
    public static var calendarDayOfficer: String { "calendar.dayOfficer".localized }
    public static var calendarSolarTerm: String { "calendar.solarTerm".localized }
    public static var calendarElement: String { "calendar.element".localized }
    public static var calendarActiveStars: String { "calendar.activeStars".localized }

    // Profile
    public static var profileTitle: String { "profile.title".localized }
    public static var profileYourBaZiChart: String { "profile.yourBaZiChart".localized }
    public static var profileDayMaster: String { "profile.dayMaster".localized }
    public static var profileUsefulGod: String { "profile.usefulGod".localized }
    public static var profileSettings: String { "profile.settings".localized }

    // Pillars
    public static var pillarYear: String { "pillar.year".localized }
    public static var pillarMonth: String { "pillar.month".localized }
    public static var pillarDay: String { "pillar.day".localized }
    public static var pillarHour: String { "pillar.hour".localized }

    // Actions
    public static var actionCancel: String { "action.cancel".localized }
    public static var actionDone: String { "action.done".localized }
    public static var actionAdd: String { "action.add".localized }
    public static var actionSave: String { "action.save".localized }
    public static var actionDelete: String { "action.delete".localized }
    public static var actionEdit: String { "action.edit".localized }
}
