//
//  LunarStar.swift
//  Oraculum
//
//  Lunar Stars (神煞) for auspiciousness calculation
//

import Foundation

/// Categories of Lunar Stars
public enum LunarStarCategory: String, Sendable, Codable {
    case auspicious = "吉神"
    case inauspicious = "凶神"
    case neutral = "中性"
}

/// Lunar Stars (神煞) that affect day selection
public enum LunarStar: String, CaseIterable, Sendable, Codable, Hashable {
    // Major Auspicious Stars
    case tianDe = "天德"          // Heavenly Virtue - +30 pts, nullifies bad stars
    case yueDe = "月德"           // Monthly Virtue - +25 pts
    case tianDeHe = "天德合"      // Heavenly Virtue Combination - +20 pts
    case yueDheHe = "月德合"      // Monthly Virtue Combination - +15 pts
    case tianXi = "天喜"          // Heavenly Joy - +15 pts
    case tianYi = "天醫"          // Heavenly Doctor - +15 pts for medical
    case luShen = "祿神"          // Prosperity Star - +15 pts for wealth
    case guiRen = "貴人"          // Noble Person - +20 pts

    // Major Inauspicious Stars
    case suiPo = "歲破"           // Year Breaker - INSTANT FAIL (-100 pts)
    case yuePo = "月破"           // Month Breaker - -50 pts
    case riPo = "日破"            // Day Breaker - -40 pts
    case sanSha = "三煞"          // Three Killings - -30 pts
    case wuGui = "五鬼"           // Five Ghosts - -25 pts
    case baiHu = "白虎"           // White Tiger - -20 pts
    case xuanWu = "玄武"          // Black Tortoise - -15 pts
    case gouChen = "勾陳"         // Hook Spirit - -15 pts
    case tengShe = "螣蛇"         // Flying Serpent - -10 pts

    // Conditional Stars
    case hongLuan = "紅鸞"        // Red Phoenix - +20 pts for marriage
    case tianKu = "天哭"          // Heavenly Weeping - -10 pts
    case sangMen = "喪門"         // Mourning Gate - -15 pts
    case diaoKe = "弔客"          // Mourning Visitor - -10 pts

    /// Chinese name
    public var chineseName: String {
        rawValue
    }

    /// Category of the star
    public var category: LunarStarCategory {
        switch self {
        case .tianDe, .yueDe, .tianDeHe, .yueDheHe, .tianXi, .tianYi, .luShen, .guiRen, .hongLuan:
            return .auspicious
        case .suiPo, .yuePo, .riPo, .sanSha, .wuGui, .baiHu, .xuanWu, .gouChen, .tengShe, .sangMen, .diaoKe:
            return .inauspicious
        case .tianKu:
            return .neutral
        }
    }

    /// Base score impact
    public var baseScoreImpact: Int {
        switch self {
        case .tianDe: return 30
        case .yueDe: return 25
        case .tianDeHe: return 20
        case .yueDheHe: return 15
        case .tianXi: return 15
        case .tianYi: return 15
        case .luShen: return 15
        case .guiRen: return 20
        case .suiPo: return -100  // Instant fail
        case .yuePo: return -50
        case .riPo: return -40
        case .sanSha: return -30
        case .wuGui: return -25
        case .baiHu: return -20
        case .xuanWu: return -15
        case .gouChen: return -15
        case .tengShe: return -10
        case .hongLuan: return 20
        case .tianKu: return -10
        case .sangMen: return -15
        case .diaoKe: return -10
        }
    }

    /// Whether this star can be nullified by Heavenly Virtue
    public var canBeNullified: Bool {
        switch self {
        case .suiPo:
            return false  // Year Breaker cannot be nullified
        default:
            return category == .inauspicious
        }
    }

    /// Description of the star's effect
    public var effectDescription: String {
        switch self {
        case .tianDe:
            return "Heavenly Virtue - Supreme blessing that nullifies most negative influences"
        case .yueDe:
            return "Monthly Virtue - Strong protective blessing for the month"
        case .tianDeHe:
            return "Heavenly Virtue Harmony - Extension of Heavenly Virtue's protection"
        case .yueDheHe:
            return "Monthly Virtue Harmony - Extension of Monthly Virtue's protection"
        case .tianXi:
            return "Heavenly Joy - Brings celebrations and happy events"
        case .tianYi:
            return "Heavenly Doctor - Excellent for medical treatments and health matters"
        case .luShen:
            return "Prosperity Star - Enhances wealth and financial activities"
        case .guiRen:
            return "Noble Person - Attracts helpful people and support"
        case .suiPo:
            return "Year Breaker - CRITICAL: Direct clash with the year. Avoid major activities."
        case .yuePo:
            return "Month Breaker - Clash with the month. Major activities not recommended."
        case .riPo:
            return "Day Breaker - Clash with the day. Proceed with caution."
        case .sanSha:
            return "Three Killings - Harmful influence from three directions"
        case .wuGui:
            return "Five Ghosts - Risk of unexpected troubles and betrayal"
        case .baiHu:
            return "White Tiger - Risk of injury, bloodshed, or legal issues"
        case .xuanWu:
            return "Black Tortoise - Risk of theft, deception, or loss"
        case .gouChen:
            return "Hook Spirit - Risk of entanglement in disputes"
        case .tengShe:
            return "Flying Serpent - Risk of accidents and sudden changes"
        case .hongLuan:
            return "Red Phoenix - Excellent for marriage and romantic matters"
        case .tianKu:
            return "Heavenly Weeping - Emotional sensitivity, not ideal for celebrations"
        case .sangMen:
            return "Mourning Gate - Avoid celebrations and joyful events"
        case .diaoKe:
            return "Mourning Visitor - Similar to Mourning Gate, avoid new beginnings"
        }
    }
}

/// Calculator for Lunar Stars present on a given day
public actor LunarStarsCalculator {

    public init() {}

    /// Calculates which Lunar Stars are present on a given day
    /// - Parameters:
    ///   - yearBranch: The Earthly Branch of the year
    ///   - monthBranch: The Earthly Branch of the month
    ///   - dayBranch: The Earthly Branch of the day
    /// - Returns: Array of Lunar Stars present on this day
    public func calculate(
        yearBranch: EarthlyBranch,
        monthBranch: EarthlyBranch,
        dayBranch: EarthlyBranch
    ) -> [LunarStar] {
        var stars: [LunarStar] = []

        // Check Year Breaker (歲破) - Day Branch clashes with Year Branch
        if dayBranch == yearBranch.clash {
            stars.append(.suiPo)
        }

        // Check Month Breaker (月破) - Day Branch clashes with Month Branch
        if dayBranch == monthBranch.clash {
            stars.append(.yuePo)
        }

        // Check Heavenly Virtue (天德) - Based on month
        if let tianDeDay = tianDeDayBranch(for: monthBranch), dayBranch == tianDeDay {
            stars.append(.tianDe)
        }

        // Check Monthly Virtue (月德) - Based on month
        if let yueDeBranch = yueDeDayBranch(for: monthBranch), dayBranch == yueDeBranch {
            stars.append(.yueDe)
        }

        // Check Three Killings (三煞) - Based on year branch
        if sanShaDayBranches(for: yearBranch).contains(dayBranch) {
            stars.append(.sanSha)
        }

        // Add more star calculations as needed...

        return stars
    }

    /// Determines the Heavenly Virtue (天德) branch for a given month
    /// 天德 follows specific patterns based on the month branch
    private func tianDeDayBranch(for monthBranch: EarthlyBranch) -> EarthlyBranch? {
        // Tian De (天德) is associated with specific stems, not branches directly
        // For branch-based matching, we use a simplified approximation
        // Traditional rule: Tian De is based on the month's associated stem
        switch monthBranch {
        case .yin: return .you      // 寅月天德在酉
        case .mao: return .shen     // 卯月天德在申
        case .chen: return .hai     // 辰月天德在亥
        case .si: return .shen      // 巳月天德在申
        case .wu: return .hai       // 午月天德在亥
        case .wei: return .zi       // 未月天德在子
        case .shen: return .chou    // 申月天德在丑
        case .you: return .yin      // 酉月天德在寅
        case .xu: return .mao       // 戌月天德在卯
        case .hai: return .chen     // 亥月天德在辰
        case .zi: return .si        // 子月天德在巳
        case .chou: return .wu      // 丑月天德在午
        }
    }

    /// Determines the Monthly Virtue (月德) branch for a given month
    /// 月德 follows specific patterns based on the month branch
    private func yueDeDayBranch(for monthBranch: EarthlyBranch) -> EarthlyBranch? {
        // Yue De (月德) is traditionally based on the "Three Harmony" principle
        // Each month's Yue De falls on specific branches
        switch monthBranch {
        case .yin, .wu, .xu: return .shen    // 寅午戌月德在申
        case .hai, .mao, .wei: return .hai   // 亥卯未月德在亥
        case .shen, .zi, .chen: return .yin  // 申子辰月德在寅
        case .si, .you, .chou: return .si    // 巳酉丑月德在巳
        }
    }

    /// Determines which day branches have Three Killings for a given year
    private func sanShaDayBranches(for yearBranch: EarthlyBranch) -> [EarthlyBranch] {
        // Three Killings based on year branch group
        switch yearBranch {
        case .shen, .zi, .chen:  // Water frame
            return [.si, .wu, .wei]
        case .hai, .mao, .wei:   // Wood frame
            return [.shen, .you, .xu]
        case .yin, .wu, .xu:     // Fire frame
            return [.hai, .zi, .chou]
        case .si, .you, .chou:   // Metal frame
            return [.yin, .mao, .chen]
        }
    }
}
