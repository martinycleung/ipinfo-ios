//
//  EarthlyBranch.swift
//  Oraculum
//
//  Twelve Earthly Branches (地支) enumeration
//

import Foundation

/// Represents the Twelve Earthly Branches (十二地支) in Chinese metaphysics
public enum EarthlyBranch: Int, CaseIterable, Sendable, Codable, Hashable {
    case zi = 0    // 子 - Rat
    case chou = 1  // 丑 - Ox
    case yin = 2   // 寅 - Tiger
    case mao = 3   // 卯 - Rabbit
    case chen = 4  // 辰 - Dragon
    case si = 5    // 巳 - Snake
    case wu = 6    // 午 - Horse
    case wei = 7   // 未 - Goat
    case shen = 8  // 申 - Monkey
    case you = 9   // 酉 - Rooster
    case xu = 10   // 戌 - Dog
    case hai = 11  // 亥 - Pig

    /// Chinese character representation
    public var chineseName: String {
        switch self {
        case .zi: return "子"
        case .chou: return "丑"
        case .yin: return "寅"
        case .mao: return "卯"
        case .chen: return "辰"
        case .si: return "巳"
        case .wu: return "午"
        case .wei: return "未"
        case .shen: return "申"
        case .you: return "酉"
        case .xu: return "戌"
        case .hai: return "亥"
        }
    }

    /// Chinese Zodiac animal name
    public var zodiacAnimal: String {
        switch self {
        case .zi: return "Rat"
        case .chou: return "Ox"
        case .yin: return "Tiger"
        case .mao: return "Rabbit"
        case .chen: return "Dragon"
        case .si: return "Snake"
        case .wu: return "Horse"
        case .wei: return "Goat"
        case .shen: return "Monkey"
        case .you: return "Rooster"
        case .xu: return "Dog"
        case .hai: return "Pig"
        }
    }

    /// Chinese Zodiac animal in Chinese
    public var zodiacAnimalChinese: String {
        switch self {
        case .zi: return "鼠"
        case .chou: return "牛"
        case .yin: return "虎"
        case .mao: return "兔"
        case .chen: return "龍"
        case .si: return "蛇"
        case .wu: return "馬"
        case .wei: return "羊"
        case .shen: return "猴"
        case .you: return "雞"
        case .xu: return "狗"
        case .hai: return "豬"
        }
    }

    /// The primary element of this branch
    public var primaryElement: FiveElement {
        switch self {
        case .yin, .mao: return .wood
        case .si, .wu: return .fire
        case .chen, .xu, .chou, .wei: return .earth
        case .shen, .you: return .metal
        case .hai, .zi: return .water
        }
    }

    /// The Yin-Yang polarity of this branch
    public var polarity: YinYang {
        switch self {
        case .zi, .yin, .chen, .wu, .shen, .xu: return .yang
        case .chou, .mao, .si, .wei, .you, .hai: return .yin
        }
    }

    /// Hidden stems within this branch (藏干)
    public var hiddenStems: [HeavenlyStem] {
        switch self {
        case .zi: return [.gui]
        case .chou: return [.ji, .gui, .xin]
        case .yin: return [.jia, .bing, .wu]
        case .mao: return [.yi]
        case .chen: return [.wu, .yi, .gui]
        case .si: return [.bing, .wu, .geng]
        case .wu: return [.ding, .ji]
        case .wei: return [.ji, .ding, .yi]
        case .shen: return [.geng, .ren, .wu]
        case .you: return [.xin]
        case .xu: return [.wu, .xin, .ding]
        case .hai: return [.ren, .jia]
        }
    }

    /// The branch that clashes with this branch (六冲)
    public var clash: EarthlyBranch {
        EarthlyBranch.fromIndex((self.rawValue + 6) % 12)
    }

    /// Get branch by index (0-11), wrapping around
    public static func fromIndex(_ index: Int) -> EarthlyBranch {
        let normalizedIndex = ((index % 12) + 12) % 12
        return EarthlyBranch(rawValue: normalizedIndex)!
    }

    /// Branches that form penalties with this branch (三刑)
    public var penalties: [EarthlyBranch] {
        switch self {
        // Ungrateful Penalty (無恩之刑): Yin-Si-Shen
        case .yin: return [.si, .shen]
        case .si: return [.yin, .shen]
        case .shen: return [.yin, .si]
        // Bullying Penalty (恃勢之刑): Chou-Xu-Wei
        case .chou: return [.xu, .wei]
        case .xu: return [.chou, .wei]
        case .wei: return [.chou, .xu]
        // Uncivilized Penalty (無禮之刑): Zi-Mao
        case .zi: return [.mao]
        case .mao: return [.zi]
        // Self Penalty (自刑): Chen-Chen, Wu-Wu, You-You, Hai-Hai
        case .chen, .wu, .you, .hai: return [self]
        }
    }

    /// The hour range for this branch (True Solar Time)
    public var hourRange: ClosedRange<Int> {
        switch self {
        case .zi: return 23...24  // 23:00 - 01:00 (spans midnight)
        case .chou: return 1...3
        case .yin: return 3...5
        case .mao: return 5...7
        case .chen: return 7...9
        case .si: return 9...11
        case .wu: return 11...13
        case .wei: return 13...15
        case .shen: return 15...17
        case .you: return 17...19
        case .xu: return 19...21
        case .hai: return 21...23
        }
    }

    /// Determines the hour branch from True Solar Time hour (0-23)
    public static func fromHour(_ hour: Int) -> EarthlyBranch {
        let normalizedHour = ((hour % 24) + 24) % 24
        switch normalizedHour {
        case 23, 0: return .zi
        case 1, 2: return .chou
        case 3, 4: return .yin
        case 5, 6: return .mao
        case 7, 8: return .chen
        case 9, 10: return .si
        case 11, 12: return .wu
        case 13, 14: return .wei
        case 15, 16: return .shen
        case 17, 18: return .you
        case 19, 20: return .xu
        case 21, 22: return .hai
        default: return .zi
        }
    }
}
