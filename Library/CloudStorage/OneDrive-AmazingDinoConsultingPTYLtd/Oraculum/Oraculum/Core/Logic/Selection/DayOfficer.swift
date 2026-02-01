//
//  DayOfficer.swift
//  Oraculum
//
//  The Twelve Day Officers (建除十二神) for day selection
//

import Foundation

/// The Twelve Day Officers (建除十二神)
/// These officers cycle through the days and influence the auspiciousness of activities
public enum DayOfficer: Int, CaseIterable, Sendable, Codable, Hashable {
    case jian = 0   // 建 - Establish
    case chu = 1    // 除 - Remove
    case man = 2    // 滿 - Full
    case ping = 3   // 平 - Balance
    case ding = 4   // 定 - Stable
    case zhi = 5    // 執 - Execute
    case po = 6     // 破 - Break
    case wei = 7    // 危 - Danger
    case cheng = 8  // 成 - Success
    case shou = 9   // 收 - Receive
    case kai = 10   // 開 - Open
    case bi = 11    // 閉 - Close

    /// Chinese character representation
    public var chineseName: String {
        switch self {
        case .jian: return "建"
        case .chu: return "除"
        case .man: return "滿"
        case .ping: return "平"
        case .ding: return "定"
        case .zhi: return "執"
        case .po: return "破"
        case .wei: return "危"
        case .cheng: return "成"
        case .shou: return "收"
        case .kai: return "開"
        case .bi: return "閉"
        }
    }

    /// English name
    public var englishName: String {
        switch self {
        case .jian: return "Establish"
        case .chu: return "Remove"
        case .man: return "Full"
        case .ping: return "Balance"
        case .ding: return "Stable"
        case .zhi: return "Execute"
        case .po: return "Break"
        case .wei: return "Danger"
        case .cheng: return "Success"
        case .shou: return "Receive"
        case .kai: return "Open"
        case .bi: return "Close"
        }
    }

    /// General meaning and interpretation
    public var generalMeaning: String {
        switch self {
        case .jian:
            return "Day of establishment. Good for starting new ventures, but avoid extreme actions."
        case .chu:
            return "Day of removal. Good for clearing obstacles, medical treatment, ending bad habits."
        case .man:
            return "Day of abundance. Good for celebrations, harvesting, receiving blessings."
        case .ping:
            return "Day of balance. Neutral day, suitable for routine activities."
        case .ding:
            return "Day of stability. Good for signing contracts, making decisions, settling matters."
        case .zhi:
            return "Day of execution. Good for construction, capturing, taking action."
        case .po:
            return "Day of breaking. Avoid major activities. Only suitable for demolition."
        case .wei:
            return "Day of danger. Caution advised. Avoid risky activities."
        case .cheng:
            return "Day of success. Excellent for negotiations, signing deals, completions."
        case .shou:
            return "Day of receiving. Good for collecting debts, receiving guests, acquisitions."
        case .kai:
            return "Day of opening. Excellent for grand openings, starting journeys, new beginnings."
        case .bi:
            return "Day of closing. Good for funerals, closing deals, ending projects."
        }
    }

    /// General auspiciousness level (-2 to +2)
    public var generalAuspiciousness: Int {
        switch self {
        case .jian: return 1
        case .chu: return 1
        case .man: return 2
        case .ping: return 0
        case .ding: return 1
        case .zhi: return 1
        case .po: return -2
        case .wei: return -1
        case .cheng: return 2
        case .shou: return 1
        case .kai: return 2
        case .bi: return -1
        }
    }

    /// Get officer by index (0-11), wrapping around
    public static func fromIndex(_ index: Int) -> DayOfficer {
        let normalizedIndex = ((index % 12) + 12) % 12
        return DayOfficer(rawValue: normalizedIndex)!
    }
}

/// Calculator for Day Officers
public struct DayOfficerCalculator: Sendable {

    public init() {}

    /// Calculates the Day Officer based on Month Branch and Day Branch
    ///
    /// The 12 officers cycle starting from "Jian" (建) at the month's branch.
    /// For example, if the month branch is Tiger (寅), then:
    /// - Tiger day = Jian (建)
    /// - Rabbit day = Chu (除)
    /// - Dragon day = Man (滿)
    /// ... and so on
    ///
    /// - Parameters:
    ///   - monthBranch: The Earthly Branch of the month
    ///   - dayBranch: The Earthly Branch of the day
    /// - Returns: The Day Officer for this combination
    public func calculate(monthBranch: EarthlyBranch, dayBranch: EarthlyBranch) -> DayOfficer {
        // The officer index = (day branch - month branch) mod 12
        let offset = (dayBranch.rawValue - monthBranch.rawValue + 12) % 12
        return DayOfficer.fromIndex(offset)
    }
}
