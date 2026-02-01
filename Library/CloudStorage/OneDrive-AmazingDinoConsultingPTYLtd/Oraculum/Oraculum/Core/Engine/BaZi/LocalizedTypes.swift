//
//  LocalizedTypes.swift
//  Oraculum
//
//  Localization extensions for core Ba Zi types
//

import Foundation

// MARK: - FiveElement Localization

extension FiveElement {
    /// Localized name based on current language
    public func localizedName(for language: AppLanguage = Localization.detectSystemLanguage()) -> String {
        switch language {
        case .english:
            return englishName
        case .simplifiedChinese, .traditionalChinese:
            return chineseName
        }
    }

    /// Localization key for this element
    public var localizationKey: String {
        switch self {
        case .wood: return "element.wood"
        case .fire: return "element.fire"
        case .earth: return "element.earth"
        case .metal: return "element.metal"
        case .water: return "element.water"
        }
    }
}

// MARK: - YinYang Localization

extension YinYang {
    /// Localized name based on current language
    public func localizedName(for language: AppLanguage = Localization.detectSystemLanguage()) -> String {
        switch language {
        case .english:
            return englishName
        case .simplifiedChinese, .traditionalChinese:
            return chineseName
        }
    }

    /// Localization key
    public var localizationKey: String {
        switch self {
        case .yin: return "yinyang.yin"
        case .yang: return "yinyang.yang"
        }
    }
}

// MARK: - HeavenlyStem Localization

extension HeavenlyStem {
    /// Localized name based on current language
    public func localizedName(for language: AppLanguage = Localization.detectSystemLanguage()) -> String {
        switch language {
        case .english:
            return pinyin
        case .simplifiedChinese, .traditionalChinese:
            return chineseName
        }
    }

    /// Localization key
    public var localizationKey: String {
        switch self {
        case .jia: return "stem.jia"
        case .yi: return "stem.yi"
        case .bing: return "stem.bing"
        case .ding: return "stem.ding"
        case .wu: return "stem.wu"
        case .ji: return "stem.ji"
        case .geng: return "stem.geng"
        case .xin: return "stem.xin"
        case .ren: return "stem.ren"
        case .gui: return "stem.gui"
        }
    }
}

// MARK: - EarthlyBranch Localization

extension EarthlyBranch {
    /// Localized name based on current language
    public func localizedName(for language: AppLanguage = Localization.detectSystemLanguage()) -> String {
        switch language {
        case .english:
            return "\(chineseName) (\(zodiacAnimal))"
        case .simplifiedChinese, .traditionalChinese:
            return chineseName
        }
    }

    /// Localized zodiac animal name
    public func localizedZodiacName(for language: AppLanguage = Localization.detectSystemLanguage()) -> String {
        switch language {
        case .english:
            return zodiacAnimal
        case .simplifiedChinese, .traditionalChinese:
            return zodiacAnimalChinese
        }
    }

    /// Localization key for branch
    public var localizationKey: String {
        switch self {
        case .zi: return "branch.zi"
        case .chou: return "branch.chou"
        case .yin: return "branch.yin"
        case .mao: return "branch.mao"
        case .chen: return "branch.chen"
        case .si: return "branch.si"
        case .wu: return "branch.wu"
        case .wei: return "branch.wei"
        case .shen: return "branch.shen"
        case .you: return "branch.you"
        case .xu: return "branch.xu"
        case .hai: return "branch.hai"
        }
    }

    /// Localization key for zodiac
    public var zodiacLocalizationKey: String {
        switch self {
        case .zi: return "zodiac.rat"
        case .chou: return "zodiac.ox"
        case .yin: return "zodiac.tiger"
        case .mao: return "zodiac.rabbit"
        case .chen: return "zodiac.dragon"
        case .si: return "zodiac.snake"
        case .wu: return "zodiac.horse"
        case .wei: return "zodiac.goat"
        case .shen: return "zodiac.monkey"
        case .you: return "zodiac.rooster"
        case .xu: return "zodiac.dog"
        case .hai: return "zodiac.pig"
        }
    }
}

// MARK: - DayOfficer Localization

extension DayOfficer {
    /// Localized name based on current language
    public func localizedName(for language: AppLanguage = Localization.detectSystemLanguage()) -> String {
        switch language {
        case .english:
            return englishName
        case .simplifiedChinese, .traditionalChinese:
            return chineseName
        }
    }

    /// Localized meaning description
    public func localizedMeaning(for language: AppLanguage = Localization.detectSystemLanguage()) -> String {
        localizationKey.appending(".meaning").localized(for: language)
    }

    /// Localization key
    public var localizationKey: String {
        switch self {
        case .jian: return "officer.jian"
        case .chu: return "officer.chu"
        case .man: return "officer.man"
        case .ping: return "officer.ping"
        case .ding: return "officer.ding"
        case .zhi: return "officer.zhi"
        case .po: return "officer.po"
        case .wei: return "officer.wei"
        case .cheng: return "officer.cheng"
        case .shou: return "officer.shou"
        case .kai: return "officer.kai"
        case .bi: return "officer.bi"
        }
    }
}

// MARK: - LunarStar Localization

extension LunarStar {
    /// Localized name based on current language
    public func localizedName(for language: AppLanguage = Localization.detectSystemLanguage()) -> String {
        switch language {
        case .english:
            return localizationKey.localized(for: .english)
        case .simplifiedChinese, .traditionalChinese:
            return chineseName
        }
    }

    /// Localization key
    public var localizationKey: String {
        switch self {
        case .tianDe: return "star.tianDe"
        case .yueDe: return "star.yueDe"
        case .tianDeHe: return "star.tianDeHe"
        case .yueDheHe: return "star.yueDheHe"
        case .tianXi: return "star.tianXi"
        case .tianYi: return "star.tianYi"
        case .luShen: return "star.luShen"
        case .guiRen: return "star.guiRen"
        case .suiPo: return "star.suiPo"
        case .yuePo: return "star.yuePo"
        case .riPo: return "star.riPo"
        case .sanSha: return "star.sanSha"
        case .wuGui: return "star.wuGui"
        case .baiHu: return "star.baiHu"
        case .xuanWu: return "star.xuanWu"
        case .gouChen: return "star.gouChen"
        case .tengShe: return "star.tengShe"
        case .hongLuan: return "star.hongLuan"
        case .tianKu: return "star.tianKu"
        case .sangMen: return "star.sangMen"
        case .diaoKe: return "star.diaoKe"
        }
    }
}

// MARK: - Activity Localization

extension Activity {
    /// Localized name based on current language
    public func localizedName(for language: AppLanguage = Localization.detectSystemLanguage()) -> String {
        switch language {
        case .english:
            return rawValue
        case .simplifiedChinese, .traditionalChinese:
            return chineseName
        }
    }

    /// Localization key
    public var localizationKey: String {
        "activity.\(rawValue.replacingOccurrences(of: " ", with: ""))"
    }
}

// MARK: - SolarTerm Localization

extension SolarTerm {
    /// Localized name based on current language
    public func localizedName(for language: AppLanguage = Localization.detectSystemLanguage()) -> String {
        switch language {
        case .english:
            return name
        case .simplifiedChinese, .traditionalChinese:
            return chineseName
        }
    }
}

// MARK: - SelectionRecommendation Localization

extension SelectionRecommendation {
    /// Localized name
    public func localizedName(for language: AppLanguage = Localization.detectSystemLanguage()) -> String {
        localizationKey.localized(for: language)
    }

    /// Localization key
    public var localizationKey: String {
        switch self {
        case .excellent: return "recommendation.excellent"
        case .good: return "recommendation.good"
        case .neutral: return "recommendation.neutral"
        case .caution: return "recommendation.caution"
        case .avoid: return "recommendation.avoid"
        }
    }
}
