//
//  NayinCalculator.swift
//  Oraculum
//
//  Nayin (纳音) Five Elements - A parallel elemental system in BaZi
//  Each of the 60 Jiazi has a specific Nayin element with poetic imagery
//

import Foundation

// MARK: - Nayin Type

/// The 30 Nayin types (60 Jiazi / 2 = 30 unique Nayin)
public enum NayinType: String, Sendable, CaseIterable, Codable {
    // Metal (金) - 6 types
    case seaGold = "sea_gold"               // 海中金 - Gold in the Sea
    case swordEdgeGold = "sword_edge_gold"  // 剑锋金 - Sword Edge Gold
    case whiteLaGold = "white_la_gold"      // 白蜡金 - White Wax Gold
    case sandGold = "sand_gold"             // 沙中金 - Gold in Sand
    case goldFoil = "gold_foil"             // 金箔金 - Gold Foil
    case chainsGold = "chains_gold"         // 钗钏金 - Hairpin & Bracelet Gold

    // Wood (木) - 6 types
    case mulberryWood = "mulberry_wood"     // 桑柘木 - Mulberry Wood
    case pineWood = "pine_wood"             // 松柏木 - Pine & Cypress Wood
    case deadWood = "dead_wood"             // 大林木 - Forest Wood
    case willowWood = "willow_wood"         // 杨柳木 - Willow Wood
    case pomegranateWood = "pomegranate"    // 石榴木 - Pomegranate Wood
    case flatWood = "flat_wood"             // 平地木 - Flatland Wood

    // Water (水) - 6 types
    case streamWater = "stream_water"       // 涧下水 - Stream Water
    case springWater = "spring_water"       // 泉中水 - Spring Water
    case longRiverWater = "river_water"     // 长流水 - Long River Water
    case skyRiverWater = "sky_water"        // 天河水 - Sky River Water
    case bigSeaWater = "sea_water"          // 大海水 - Great Sea Water
    case wellWater = "well_water"           // 井泉水 - Well Spring Water

    // Fire (火) - 6 types
    case thunderFire = "thunder_fire"       // 霹雳火 - Thunder Fire
    case furnaceFire = "furnace_fire"       // 炉中火 - Furnace Fire
    case lampFire = "lamp_fire"             // 覆灯火 - Covered Lamp Fire
    case skyFire = "sky_fire"               // 天上火 - Heavenly Fire
    case mountainFire = "mountain_fire"     // 山下火 - Mountain Fire
    case mountainTopFire = "top_fire"       // 山头火 - Mountain Top Fire

    // Earth (土) - 6 types
    case wallEarth = "wall_earth"           // 壁上土 - Wall Earth
    case cityWallEarth = "city_earth"       // 城头土 - City Wall Earth
    case roadEarth = "road_earth"           // 路旁土 - Roadside Earth
    case bigPostEarth = "post_earth"        // 大驿土 - Post Station Earth
    case sandEarth = "sand_earth"           // 沙中土 - Sand Earth
    case houseEarth = "house_earth"         // 屋上土 - Rooftop Earth

    /// Chinese name
    public var chineseName: String {
        switch self {
        case .seaGold: return "海中金"
        case .swordEdgeGold: return "剑锋金"
        case .whiteLaGold: return "白蜡金"
        case .sandGold: return "沙中金"
        case .goldFoil: return "金箔金"
        case .chainsGold: return "钗钏金"
        case .mulberryWood: return "桑柘木"
        case .pineWood: return "松柏木"
        case .deadWood: return "大林木"
        case .willowWood: return "杨柳木"
        case .pomegranateWood: return "石榴木"
        case .flatWood: return "平地木"
        case .streamWater: return "涧下水"
        case .springWater: return "泉中水"
        case .longRiverWater: return "长流水"
        case .skyRiverWater: return "天河水"
        case .bigSeaWater: return "大海水"
        case .wellWater: return "井泉水"
        case .thunderFire: return "霹雳火"
        case .furnaceFire: return "炉中火"
        case .lampFire: return "覆灯火"
        case .skyFire: return "天上火"
        case .mountainFire: return "山下火"
        case .mountainTopFire: return "山头火"
        case .wallEarth: return "壁上土"
        case .cityWallEarth: return "城头土"
        case .roadEarth: return "路旁土"
        case .bigPostEarth: return "大驿土"
        case .sandEarth: return "沙中土"
        case .houseEarth: return "屋上土"
        }
    }

    /// The base Five Element
    public var element: FiveElement {
        switch self {
        case .seaGold, .swordEdgeGold, .whiteLaGold, .sandGold, .goldFoil, .chainsGold:
            return .metal
        case .mulberryWood, .pineWood, .deadWood, .willowWood, .pomegranateWood, .flatWood:
            return .wood
        case .streamWater, .springWater, .longRiverWater, .skyRiverWater, .bigSeaWater, .wellWater:
            return .water
        case .thunderFire, .furnaceFire, .lampFire, .skyFire, .mountainFire, .mountainTopFire:
            return .fire
        case .wallEarth, .cityWallEarth, .roadEarth, .bigPostEarth, .sandEarth, .houseEarth:
            return .earth
        }
    }

    /// Strength of the Nayin (strong, medium, weak)
    /// Based on the imagery - e.g., Great Sea Water > Stream Water
    public var strength: Double {
        switch self {
        // Strong types
        case .swordEdgeGold, .bigSeaWater, .deadWood, .skyFire, .cityWallEarth:
            return 1.0
        // Medium-strong
        case .seaGold, .longRiverWater, .pineWood, .furnaceFire, .bigPostEarth:
            return 0.8
        // Medium
        case .whiteLaGold, .skyRiverWater, .mulberryWood, .mountainTopFire, .wallEarth:
            return 0.6
        // Medium-weak
        case .sandGold, .springWater, .willowWood, .mountainFire, .roadEarth:
            return 0.4
        // Weak types
        case .goldFoil, .chainsGold, .streamWater, .wellWater, .pomegranateWood, .flatWood,
             .thunderFire, .lampFire, .sandEarth, .houseEarth:
            return 0.3
        }
    }
}

// MARK: - Nayin Calculator

/// Calculates Nayin for pillars in the 60 Jiazi cycle
public struct NayinCalculator: Sendable {

    public init() {}

    /// The 60 Jiazi to Nayin mapping (grouped by pairs sharing the same Nayin)
    /// Format: Jiazi index -> NayinType
    private static let nayinTable: [Int: NayinType] = [
        // 甲子, 乙丑 - 海中金
        0: .seaGold, 1: .seaGold,
        // 丙寅, 丁卯 - 炉中火
        2: .furnaceFire, 3: .furnaceFire,
        // 戊辰, 己巳 - 大林木
        4: .deadWood, 5: .deadWood,
        // 庚午, 辛未 - 路旁土
        6: .roadEarth, 7: .roadEarth,
        // 壬申, 癸酉 - 剑锋金
        8: .swordEdgeGold, 9: .swordEdgeGold,

        // 甲戌, 乙亥 - 山头火
        10: .mountainTopFire, 11: .mountainTopFire,
        // 丙子, 丁丑 - 涧下水
        12: .streamWater, 13: .streamWater,
        // 戊寅, 己卯 - 城头土
        14: .cityWallEarth, 15: .cityWallEarth,
        // 庚辰, 辛巳 - 白蜡金
        16: .whiteLaGold, 17: .whiteLaGold,
        // 壬午, 癸未 - 杨柳木
        18: .willowWood, 19: .willowWood,

        // 甲申, 乙酉 - 泉中水
        20: .springWater, 21: .springWater,
        // 丙戌, 丁亥 - 屋上土
        22: .houseEarth, 23: .houseEarth,
        // 戊子, 己丑 - 霹雳火
        24: .thunderFire, 25: .thunderFire,
        // 庚寅, 辛卯 - 松柏木
        26: .pineWood, 27: .pineWood,
        // 壬辰, 癸巳 - 长流水
        28: .longRiverWater, 29: .longRiverWater,

        // 甲午, 乙未 - 沙中金
        30: .sandGold, 31: .sandGold,
        // 丙申, 丁酉 - 山下火
        32: .mountainFire, 33: .mountainFire,
        // 戊戌, 己亥 - 平地木
        34: .flatWood, 35: .flatWood,
        // 庚子, 辛丑 - 壁上土
        36: .wallEarth, 37: .wallEarth,
        // 壬寅, 癸卯 - 金箔金
        38: .goldFoil, 39: .goldFoil,

        // 甲辰, 乙巳 - 覆灯火
        40: .lampFire, 41: .lampFire,
        // 丙午, 丁未 - 天河水
        42: .skyRiverWater, 43: .skyRiverWater,
        // 戊申, 己酉 - 大驿土
        44: .bigPostEarth, 45: .bigPostEarth,
        // 庚戌, 辛亥 - 钗钏金
        46: .chainsGold, 47: .chainsGold,
        // 壬子, 癸丑 - 桑柘木
        48: .mulberryWood, 49: .mulberryWood,

        // 甲寅, 乙卯 - 大海水(原为大溪水)
        50: .bigSeaWater, 51: .bigSeaWater,
        // 丙辰, 丁巳 - 沙中土
        52: .sandEarth, 53: .sandEarth,
        // 戊午, 己未 - 天上火
        54: .skyFire, 55: .skyFire,
        // 庚申, 辛酉 - 石榴木
        56: .pomegranateWood, 57: .pomegranateWood,
        // 壬戌, 癸亥 - 大海水
        58: .bigSeaWater, 59: .bigSeaWater
    ]

    /// Calculate Nayin for a pillar
    public func calculate(pillar: Pillar) -> NayinType {
        let jiaziIndex = pillar.cycleIndex
        return Self.nayinTable[jiaziIndex] ?? .seaGold
    }

    /// Calculate all Nayin for a Four Pillars chart
    public func calculateChart(_ chart: FourPillarsChart) -> NayinChartResult {
        let yearNayin = calculate(pillar: chart.yearPillar)
        let monthNayin = calculate(pillar: chart.monthPillar)
        let dayNayin = calculate(pillar: chart.dayPillar)
        let hourNayin = calculate(pillar: chart.hourPillar)

        return NayinChartResult(
            yearNayin: yearNayin,
            monthNayin: monthNayin,
            dayNayin: dayNayin,
            hourNayin: hourNayin
        )
    }

    /// Check Nayin compatibility between two pillars
    public func compatibility(pillar1: Pillar, pillar2: Pillar) -> NayinCompatibility {
        let nayin1 = calculate(pillar: pillar1)
        let nayin2 = calculate(pillar: pillar2)

        return checkElementCompatibility(nayin1.element, nayin2.element)
    }

    /// Check Five Element compatibility
    private func checkElementCompatibility(_ e1: FiveElement, _ e2: FiveElement) -> NayinCompatibility {
        if e1 == e2 {
            return .same
        }
        if e1.produces == e2 || e2.produces == e1 {
            return .productive
        }
        if e1.controls == e2 || e2.controls == e1 {
            return .destructive
        }
        return .neutral
    }
}

// MARK: - Nayin Chart Result

/// Nayin elements for all four pillars
public struct NayinChartResult: Sendable {
    public let yearNayin: NayinType
    public let monthNayin: NayinType
    public let dayNayin: NayinType
    public let hourNayin: NayinType

    /// The dominant Nayin element in the chart
    public var dominantElement: FiveElement {
        var counts: [FiveElement: Int] = [:]
        counts[yearNayin.element, default: 0] += 1
        counts[monthNayin.element, default: 0] += 1
        counts[dayNayin.element, default: 0] += 1
        counts[hourNayin.element, default: 0] += 1

        return counts.max(by: { $0.value < $1.value })?.key ?? .earth
    }

    /// Combined Nayin strength
    public var totalStrength: Double {
        (yearNayin.strength + monthNayin.strength + dayNayin.strength + hourNayin.strength) / 4.0
    }

    /// Description
    public var description: String {
        "\(yearNayin.chineseName) \(monthNayin.chineseName) \(dayNayin.chineseName) \(hourNayin.chineseName)"
    }

    /// Check if chart has harmonious Nayin
    public var isHarmonious: Bool {
        // Check for productive relationships
        let elements = [yearNayin.element, monthNayin.element, dayNayin.element, hourNayin.element]
        var clashCount = 0

        for i in 0..<elements.count {
            for j in (i+1)..<elements.count {
                if elements[i].controls == elements[j] || elements[j].controls == elements[i] {
                    clashCount += 1
                }
            }
        }

        return clashCount <= 1
    }
}

// MARK: - Nayin Compatibility

/// Compatibility levels for Nayin elements
public enum NayinCompatibility: String, Sendable {
    case productive = "productive"   // 相生 - Elements produce each other
    case same = "same"               // 同类 - Same element
    case neutral = "neutral"         // 中性 - No direct relationship
    case destructive = "destructive" // 相克 - Elements clash

    public var chineseName: String {
        switch self {
        case .productive: return "相生"
        case .same: return "比和"
        case .neutral: return "中性"
        case .destructive: return "相克"
        }
    }

    public var score: Double {
        switch self {
        case .productive: return 1.0
        case .same: return 0.7
        case .neutral: return 0.4
        case .destructive: return 0.0
        }
    }
}

// Note: cycleIndex is already defined in Pillar.swift
