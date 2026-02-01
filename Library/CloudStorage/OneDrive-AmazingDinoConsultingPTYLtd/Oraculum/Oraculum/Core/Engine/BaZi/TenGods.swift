//
//  TenGods.swift
//  Oraculum
//
//  Ten Gods (十神) - fundamental BaZi relationship system
//

import Foundation

/// The Ten Gods (十神) represent relationships between elements in BaZi
/// They describe how other elements relate to the Day Master
public enum TenGod: String, CaseIterable, Sendable, Codable {
    // Same element as Day Master
    case bijian = "Bijian"         // 比肩 - Companion (same element, same polarity)
    case jiecai = "Jiecai"         // 劫财 - Rob Wealth (same element, different polarity)

    // Element that produces Day Master
    case zhengyin = "Zhengyin"     // 正印 - Direct Resource (produces, different polarity)
    case pianyin = "Pianyin"       // 偏印 - Indirect Resource (produces, same polarity)

    // Element that Day Master produces
    case shangguan = "Shangguan"   // 伤官 - Hurting Officer (produced, different polarity)
    case shishen = "Shishen"       // 食神 - Eating God (produced, same polarity)

    // Element that Day Master controls
    case zhengcai = "Zhengcai"     // 正财 - Direct Wealth (controlled, different polarity)
    case piancai = "Piancai"       // 偏财 - Indirect Wealth (controlled, same polarity)

    // Element that controls Day Master
    case zhengguan = "Zhengguan"   // 正官 - Direct Officer (controls, different polarity)
    case qisha = "Qisha"           // 七杀 - Seven Killings (controls, same polarity)

    /// Chinese name
    public var chineseName: String {
        switch self {
        case .bijian: return "比肩"
        case .jiecai: return "劫财"
        case .zhengyin: return "正印"
        case .pianyin: return "偏印"
        case .shangguan: return "伤官"
        case .shishen: return "食神"
        case .zhengcai: return "正财"
        case .piancai: return "偏财"
        case .zhengguan: return "正官"
        case .qisha: return "七杀"
        }
    }

    /// English description
    public var englishName: String {
        switch self {
        case .bijian: return "Companion"
        case .jiecai: return "Rob Wealth"
        case .zhengyin: return "Direct Resource"
        case .pianyin: return "Indirect Resource"
        case .shangguan: return "Hurting Officer"
        case .shishen: return "Eating God"
        case .zhengcai: return "Direct Wealth"
        case .piancai: return "Indirect Wealth"
        case .zhengguan: return "Direct Officer"
        case .qisha: return "Seven Killings"
        }
    }

    /// Whether this is one of the Four Auspicious Gods (四吉神)
    public var isAuspicious: Bool {
        switch self {
        case .zhengcai, .zhengguan, .zhengyin, .shishen:
            return true
        default:
            return false
        }
    }

    /// Whether this supports Day Master strength
    public var supportsDayMaster: Bool {
        switch self {
        case .bijian, .jiecai, .zhengyin, .pianyin:
            return true
        default:
            return false
        }
    }

    /// Whether this drains/controls Day Master
    public var drainsDayMaster: Bool {
        switch self {
        case .shangguan, .shishen, .zhengcai, .piancai, .zhengguan, .qisha:
            return true
        default:
            return false
        }
    }

    /// Strength contribution to Day Master (positive = supports, negative = drains)
    public var strengthContribution: Double {
        switch self {
        case .bijian: return 1.0       // Full support
        case .jiecai: return 0.8       // Strong support
        case .zhengyin: return 0.7     // Resource support
        case .pianyin: return 0.6      // Indirect resource
        case .shishen: return -0.3     // Mild drain
        case .shangguan: return -0.4   // Moderate drain
        case .piancai: return -0.4     // Moderate drain
        case .zhengcai: return -0.5    // Stronger drain
        case .zhengguan: return -0.6   // Control
        case .qisha: return -0.8       // Strong control
        }
    }

    /// Determines the Ten God relationship between two stems
    public static func relationship(dayMaster: HeavenlyStem, other: HeavenlyStem) -> TenGod {
        let dmElement = dayMaster.element
        let otherElement = other.element
        let samePolarity = dayMaster.polarity == other.polarity

        if dmElement == otherElement {
            return samePolarity ? .bijian : .jiecai
        } else if dmElement.producedBy == otherElement {
            return samePolarity ? .pianyin : .zhengyin
        } else if dmElement.produces == otherElement {
            return samePolarity ? .shishen : .shangguan
        } else if dmElement.controls == otherElement {
            return samePolarity ? .piancai : .zhengcai
        } else { // dmElement.controlledBy == otherElement
            return samePolarity ? .qisha : .zhengguan
        }
    }

    /// Determines the Ten God for a branch's primary hidden stem
    public static func relationshipForBranch(dayMaster: HeavenlyStem, branch: EarthlyBranch) -> TenGod {
        guard let primaryHiddenStem = branch.hiddenStems.first else {
            // Fallback - use branch's primary element
            let branchElement = branch.primaryElement
            let samePolarity = dayMaster.polarity == branch.polarity

            if dayMaster.element == branchElement {
                return samePolarity ? .bijian : .jiecai
            } else if dayMaster.element.producedBy == branchElement {
                return samePolarity ? .pianyin : .zhengyin
            } else if dayMaster.element.produces == branchElement {
                return samePolarity ? .shishen : .shangguan
            } else if dayMaster.element.controls == branchElement {
                return samePolarity ? .piancai : .zhengcai
            } else {
                return samePolarity ? .qisha : .zhengguan
            }
        }
        return relationship(dayMaster: dayMaster, other: primaryHiddenStem)
    }
}
