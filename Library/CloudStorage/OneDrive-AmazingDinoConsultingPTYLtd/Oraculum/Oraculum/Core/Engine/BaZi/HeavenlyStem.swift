//
//  HeavenlyStem.swift
//  Oraculum
//
//  Ten Heavenly Stems (天干) enumeration
//

import Foundation

/// Represents the Ten Heavenly Stems (十天干) in Chinese metaphysics
public enum HeavenlyStem: Int, CaseIterable, Sendable, Codable, Hashable {
    case jia = 0   // 甲 - Yang Wood
    case yi = 1    // 乙 - Yin Wood
    case bing = 2  // 丙 - Yang Fire
    case ding = 3  // 丁 - Yin Fire
    case wu = 4    // 戊 - Yang Earth
    case ji = 5    // 己 - Yin Earth
    case geng = 6  // 庚 - Yang Metal
    case xin = 7   // 辛 - Yin Metal
    case ren = 8   // 壬 - Yang Water
    case gui = 9   // 癸 - Yin Water

    /// Chinese character representation
    public var chineseName: String {
        switch self {
        case .jia: return "甲"
        case .yi: return "乙"
        case .bing: return "丙"
        case .ding: return "丁"
        case .wu: return "戊"
        case .ji: return "己"
        case .geng: return "庚"
        case .xin: return "辛"
        case .ren: return "壬"
        case .gui: return "癸"
        }
    }

    /// Pinyin romanization
    public var pinyin: String {
        switch self {
        case .jia: return "Jiǎ"
        case .yi: return "Yǐ"
        case .bing: return "Bǐng"
        case .ding: return "Dīng"
        case .wu: return "Wù"
        case .ji: return "Jǐ"
        case .geng: return "Gēng"
        case .xin: return "Xīn"
        case .ren: return "Rén"
        case .gui: return "Guǐ"
        }
    }

    /// The Five Element associated with this stem
    public var element: FiveElement {
        switch self {
        case .jia, .yi: return .wood
        case .bing, .ding: return .fire
        case .wu, .ji: return .earth
        case .geng, .xin: return .metal
        case .ren, .gui: return .water
        }
    }

    /// The Yin-Yang polarity of this stem
    public var polarity: YinYang {
        switch self {
        case .jia, .bing, .wu, .geng, .ren: return .yang
        case .yi, .ding, .ji, .xin, .gui: return .yin
        }
    }

    /// Get stem by index (0-9), wrapping around
    public static func fromIndex(_ index: Int) -> HeavenlyStem {
        let normalizedIndex = ((index % 10) + 10) % 10
        return HeavenlyStem(rawValue: normalizedIndex)!
    }

    /// The stem that combines with this stem (合)
    /// Jia-Ji, Yi-Geng, Bing-Xin, Ding-Ren, Wu-Gui
    public var combines: HeavenlyStem {
        HeavenlyStem.fromIndex((self.rawValue + 5) % 10)
    }

    /// The element produced when this stem combines with its pair
    public var combinationElement: FiveElement {
        switch self {
        case .jia, .ji: return .earth
        case .yi, .geng: return .metal
        case .bing, .xin: return .water
        case .ding, .ren: return .wood
        case .wu, .gui: return .fire
        }
    }
}
