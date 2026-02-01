//
//  YinYang.swift
//  Oraculum
//
//  Yin-Yang polarity enumeration
//

import Foundation

/// Represents the Yin-Yang polarity in Chinese metaphysics
public enum YinYang: Int, CaseIterable, Sendable, Codable, Hashable {
    case yang = 0  // 陽 - Active, masculine, bright
    case yin = 1   // 陰 - Passive, feminine, dark

    /// Chinese character representation
    public var chineseName: String {
        switch self {
        case .yang: return "陽"
        case .yin: return "陰"
        }
    }

    /// English name
    public var englishName: String {
        switch self {
        case .yang: return "Yang"
        case .yin: return "Yin"
        }
    }

    /// The opposite polarity
    public var opposite: YinYang {
        switch self {
        case .yang: return .yin
        case .yin: return .yang
        }
    }
}
