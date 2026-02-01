//
//  Activity.swift
//  Oraculum
//
//  Activity types for date selection
//

import Foundation

/// Categories of activities for date selection
public enum ActivityCategory: String, CaseIterable, Sendable, Codable {
    case business = "Business"
    case personal = "Personal"
    case ceremony = "Ceremony"
    case construction = "Construction"
    case travel = "Travel"
    case medical = "Medical"
    case legal = "Legal"
}

/// Types of activities for auspicious date selection
public enum Activity: String, CaseIterable, Sendable, Codable, Hashable, Identifiable {
    // Business Activities
    case signContract = "Sign Contract"
    case negotiation = "Negotiation"
    case openBusiness = "Open Business"
    case launchProduct = "Launch Product"
    case investMoney = "Investment"
    case closeDeal = "Close Deal"
    case hireEmployee = "Hire Employee"
    case startPartnership = "Start Partnership"

    // Personal Activities
    case marriage = "Marriage"
    case engagement = "Engagement"
    case moveHouse = "Move House"
    case startJob = "Start New Job"
    case askForRaise = "Ask for Raise"
    case importantMeeting = "Important Meeting"

    // Ceremony Activities
    case funeral = "Funeral"
    case ancestorWorship = "Ancestor Worship"
    case groundbreaking = "Groundbreaking"
    case grandOpening = "Grand Opening"

    // Construction Activities
    case startConstruction = "Start Construction"
    case renovation = "Renovation"
    case demolition = "Demolition"
    case installDoor = "Install Door/Gate"

    // Travel Activities
    case longTravel = "Long Journey"
    case businessTrip = "Business Trip"
    case relocation = "Relocation"

    // Medical Activities
    case surgery = "Surgery"
    case startTreatment = "Start Treatment"
    case checkup = "Health Checkup"

    // Legal Activities
    case lawsuit = "Lawsuit"
    case signLegalDoc = "Sign Legal Documents"
    case courtAppearance = "Court Appearance"

    public var id: String { rawValue }

    /// Activity category
    public var category: ActivityCategory {
        switch self {
        case .signContract, .negotiation, .openBusiness, .launchProduct,
             .investMoney, .closeDeal, .hireEmployee, .startPartnership:
            return .business
        case .marriage, .engagement, .moveHouse, .startJob,
             .askForRaise, .importantMeeting:
            return .personal
        case .funeral, .ancestorWorship, .groundbreaking, .grandOpening:
            return .ceremony
        case .startConstruction, .renovation, .demolition, .installDoor:
            return .construction
        case .longTravel, .businessTrip, .relocation:
            return .travel
        case .surgery, .startTreatment, .checkup:
            return .medical
        case .lawsuit, .signLegalDoc, .courtAppearance:
            return .legal
        }
    }

    /// Chinese name for the activity
    public var chineseName: String {
        switch self {
        case .signContract: return "簽約"
        case .negotiation: return "談判"
        case .openBusiness: return "開業"
        case .launchProduct: return "發布產品"
        case .investMoney: return "投資"
        case .closeDeal: return "成交"
        case .hireEmployee: return "招聘"
        case .startPartnership: return "合作"
        case .marriage: return "嫁娶"
        case .engagement: return "訂婚"
        case .moveHouse: return "搬家"
        case .startJob: return "就職"
        case .askForRaise: return "加薪"
        case .importantMeeting: return "重要會議"
        case .funeral: return "殯葬"
        case .ancestorWorship: return "祭祀"
        case .groundbreaking: return "動土"
        case .grandOpening: return "開張"
        case .startConstruction: return "興建"
        case .renovation: return "裝修"
        case .demolition: return "拆卸"
        case .installDoor: return "安門"
        case .longTravel: return "遠行"
        case .businessTrip: return "出差"
        case .relocation: return "遷移"
        case .surgery: return "手術"
        case .startTreatment: return "治療"
        case .checkup: return "體檢"
        case .lawsuit: return "訴訟"
        case .signLegalDoc: return "簽署法律文件"
        case .courtAppearance: return "出庭"
        }
    }

    /// Favorable Day Officers for this activity
    public var favorableDayOfficers: [DayOfficer] {
        switch self {
        case .signContract, .closeDeal, .negotiation:
            return [.cheng, .kai, .ding]
        case .openBusiness, .grandOpening:
            return [.kai, .cheng, .man]
        case .launchProduct:
            return [.kai, .cheng, .jian]
        case .investMoney:
            return [.man, .cheng, .shou]
        case .hireEmployee, .startPartnership:
            return [.kai, .cheng, .ding]
        case .marriage, .engagement:
            return [.cheng, .kai, .ding, .man]
        case .moveHouse:
            return [.kai, .cheng, .ding]
        case .startJob:
            return [.jian, .kai, .cheng]
        case .askForRaise:
            return [.cheng, .kai, .man]
        case .importantMeeting:
            return [.cheng, .ding, .kai]
        case .funeral:
            return [.bi, .chu]
        case .ancestorWorship:
            return [.ding, .cheng, .kai]
        case .groundbreaking, .startConstruction:
            return [.jian, .kai, .ding]
        case .renovation:
            return [.chu, .ding, .cheng]
        case .demolition:
            return [.po, .chu]
        case .installDoor:
            return [.kai, .cheng, .ding]
        case .longTravel, .businessTrip, .relocation:
            return [.kai, .cheng]
        case .surgery, .startTreatment:
            return [.chu, .kai]
        case .checkup:
            return [.kai, .ding]
        case .lawsuit, .signLegalDoc, .courtAppearance:
            return [.cheng, .zhi, .ding]
        }
    }

    /// Unfavorable Day Officers for this activity
    public var unfavorableDayOfficers: [DayOfficer] {
        switch self {
        case .signContract, .closeDeal:
            return [.po, .bi]
        case .openBusiness, .grandOpening:
            return [.po, .bi, .wei]
        case .marriage, .engagement:
            return [.po, .bi, .wei, .chu]
        case .funeral:
            return [.kai, .cheng]
        case .demolition:
            return [.jian, .cheng]
        default:
            return [.po, .wei]
        }
    }
}
