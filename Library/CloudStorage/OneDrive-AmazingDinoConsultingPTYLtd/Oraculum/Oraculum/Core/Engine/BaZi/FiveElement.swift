//
//  FiveElement.swift
//  Oraculum
//
//  Five Elements (Wu Xing) enumeration
//

import Foundation

/// Represents the Five Elements (五行) in Chinese metaphysics
public enum FiveElement: Int, CaseIterable, Sendable, Codable, Hashable {
    case wood = 0   // 木
    case fire = 1   // 火
    case earth = 2  // 土
    case metal = 3  // 金
    case water = 4  // 水

    /// Chinese character representation
    public var chineseName: String {
        switch self {
        case .wood: return "木"
        case .fire: return "火"
        case .earth: return "土"
        case .metal: return "金"
        case .water: return "水"
        }
    }

    /// English name
    public var englishName: String {
        switch self {
        case .wood: return "Wood"
        case .fire: return "Fire"
        case .earth: return "Earth"
        case .metal: return "Metal"
        case .water: return "Water"
        }
    }

    /// The element that this element produces (generates)
    /// Wood → Fire → Earth → Metal → Water → Wood
    public var produces: FiveElement {
        switch self {
        case .wood: return .fire
        case .fire: return .earth
        case .earth: return .metal
        case .metal: return .water
        case .water: return .wood
        }
    }

    /// The element that produces (generates) this element
    public var producedBy: FiveElement {
        switch self {
        case .wood: return .water
        case .fire: return .wood
        case .earth: return .fire
        case .metal: return .earth
        case .water: return .metal
        }
    }

    /// The element that this element controls (克)
    /// Wood → Earth → Water → Fire → Metal → Wood
    public var controls: FiveElement {
        switch self {
        case .wood: return .earth
        case .fire: return .metal
        case .earth: return .water
        case .metal: return .wood
        case .water: return .fire
        }
    }

    /// The element that controls this element
    public var controlledBy: FiveElement {
        switch self {
        case .wood: return .metal
        case .fire: return .water
        case .earth: return .wood
        case .metal: return .fire
        case .water: return .earth
        }
    }

    /// Associated color for UI
    public var associatedColor: String {
        switch self {
        case .wood: return "green"
        case .fire: return "red"
        case .earth: return "brown"
        case .metal: return "white"
        case .water: return "black"
        }
    }
}
