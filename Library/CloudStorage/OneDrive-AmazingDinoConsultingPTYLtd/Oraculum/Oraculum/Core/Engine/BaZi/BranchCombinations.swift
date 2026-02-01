//
//  BranchCombinations.swift
//  Oraculum
//
//  Branch Combinations (地支合化) - Fundamental BaZi relationship system
//  Implements: 三合 (Three Harmonies), 三会 (Three Meetings), 六合 (Six Combinations), 冲刑破害
//

import Foundation

// MARK: - Three Harmonies (三合)

/// Three Harmonies - When three specific branches combine to form an element
/// These create the strongest elemental frames
public enum ThreeHarmony: String, Sendable, CaseIterable {
    case woodFrame = "wood_frame"      // 寅午戌合火局 (Yin-Wu-Xu form Fire)
    case fireFrame = "fire_frame"      // 巳酉丑合金局 (Si-You-Chou form Metal)
    case metalFrame = "metal_frame"    // 申子辰合水局 (Shen-Zi-Chen form Water)
    case waterFrame = "water_frame"    // 亥卯未合木局 (Hai-Mao-Wei form Wood)

    /// Chinese name
    public var chineseName: String {
        switch self {
        case .woodFrame: return "寅午戌合火局"
        case .fireFrame: return "巳酉丑合金局"
        case .metalFrame: return "申子辰合水局"
        case .waterFrame: return "亥卯未合木局"
        }
    }

    /// The resulting element when the harmony is complete
    public var resultingElement: FiveElement {
        switch self {
        case .woodFrame: return .fire   // 寅午戌 produces Fire
        case .fireFrame: return .metal  // 巳酉丑 produces Metal
        case .metalFrame: return .water // 申子辰 produces Water
        case .waterFrame: return .wood  // 亥卯未 produces Wood
        }
    }

    /// The three branches that form this harmony
    public var branches: Set<EarthlyBranch> {
        switch self {
        case .woodFrame: return [.yin, .wu, .xu]
        case .fireFrame: return [.si, .you, .chou]
        case .metalFrame: return [.shen, .zi, .chen]
        case .waterFrame: return [.hai, .mao, .wei]
        }
    }

    /// The center branch (most important for the harmony)
    public var centerBranch: EarthlyBranch {
        switch self {
        case .woodFrame: return .wu
        case .fireFrame: return .you
        case .metalFrame: return .zi
        case .waterFrame: return .mao
        }
    }

    /// Check if given branches form this complete harmony
    public func isComplete(in branches: [EarthlyBranch]) -> Bool {
        let branchSet = Set(branches)
        return self.branches.isSubset(of: branchSet)
    }

    /// Check for partial harmony (two of three branches present)
    public func partialMatch(in branches: [EarthlyBranch]) -> Set<EarthlyBranch>? {
        let branchSet = Set(branches)
        let intersection = self.branches.intersection(branchSet)
        return intersection.count == 2 ? intersection : nil
    }
}

// MARK: - Three Meetings (三会)

/// Three Meetings - When three consecutive seasonal branches meet
/// These form the strongest seasonal element combinations
public enum ThreeMeeting: String, Sendable, CaseIterable {
    case springMeeting = "spring"   // 寅卯辰会木局 (Yin-Mao-Chen - Spring Wood)
    case summerMeeting = "summer"   // 巳午未会火局 (Si-Wu-Wei - Summer Fire)
    case autumnMeeting = "autumn"   // 申酉戌会金局 (Shen-You-Xu - Autumn Metal)
    case winterMeeting = "winter"   // 亥子丑会水局 (Hai-Zi-Chou - Winter Water)

    /// Chinese name
    public var chineseName: String {
        switch self {
        case .springMeeting: return "寅卯辰会木局"
        case .summerMeeting: return "巳午未会火局"
        case .autumnMeeting: return "申酉戌会金局"
        case .winterMeeting: return "亥子丑会水局"
        }
    }

    /// The resulting element
    public var resultingElement: FiveElement {
        switch self {
        case .springMeeting: return .wood
        case .summerMeeting: return .fire
        case .autumnMeeting: return .metal
        case .winterMeeting: return .water
        }
    }

    /// The three branches
    public var branches: Set<EarthlyBranch> {
        switch self {
        case .springMeeting: return [.yin, .mao, .chen]
        case .summerMeeting: return [.si, .wu, .wei]
        case .autumnMeeting: return [.shen, .you, .xu]
        case .winterMeeting: return [.hai, .zi, .chou]
        }
    }

    /// Check if complete
    public func isComplete(in branches: [EarthlyBranch]) -> Bool {
        let branchSet = Set(branches)
        return self.branches.isSubset(of: branchSet)
    }
}

// MARK: - Six Combinations (六合)

/// Six Combinations - Pairs of branches that combine
public enum SixCombination: String, Sendable, CaseIterable {
    case ziChou = "zi_chou"     // 子丑合土 (Zi-Chou form Earth)
    case yinHai = "yin_hai"     // 寅亥合木 (Yin-Hai form Wood)
    case maoXu = "mao_xu"       // 卯戌合火 (Mao-Xu form Fire)
    case chenYou = "chen_you"   // 辰酉合金 (Chen-You form Metal)
    case siShen = "si_shen"     // 巳申合水 (Si-Shen form Water)
    case wuWei = "wu_wei"       // 午未合火/土 (Wu-Wei form Fire/Earth)

    /// Chinese name
    public var chineseName: String {
        switch self {
        case .ziChou: return "子丑合土"
        case .yinHai: return "寅亥合木"
        case .maoXu: return "卯戌合火"
        case .chenYou: return "辰酉合金"
        case .siShen: return "巳申合水"
        case .wuWei: return "午未合"
        }
    }

    /// The resulting element (when transformation occurs)
    public var resultingElement: FiveElement {
        switch self {
        case .ziChou: return .earth
        case .yinHai: return .wood
        case .maoXu: return .fire
        case .chenYou: return .metal
        case .siShen: return .water
        case .wuWei: return .fire  // Can be Earth in some interpretations
        }
    }

    /// The two branches
    public var branches: (EarthlyBranch, EarthlyBranch) {
        switch self {
        case .ziChou: return (.zi, .chou)
        case .yinHai: return (.yin, .hai)
        case .maoXu: return (.mao, .xu)
        case .chenYou: return (.chen, .you)
        case .siShen: return (.si, .shen)
        case .wuWei: return (.wu, .wei)
        }
    }

    /// Check if these branches form this combination
    public func matches(_ branch1: EarthlyBranch, _ branch2: EarthlyBranch) -> Bool {
        let (b1, b2) = branches
        return (branch1 == b1 && branch2 == b2) || (branch1 == b2 && branch2 == b1)
    }

    /// Find combination between two branches
    public static func find(_ branch1: EarthlyBranch, _ branch2: EarthlyBranch) -> SixCombination? {
        for combination in SixCombination.allCases {
            if combination.matches(branch1, branch2) {
                return combination
            }
        }
        return nil
    }
}

// MARK: - Branch Clash (地支相冲)

/// Branch clashes - Opposite branches on the zodiac circle
public struct BranchClash: Sendable {
    public let branch1: EarthlyBranch
    public let branch2: EarthlyBranch

    /// Chinese name
    public var chineseName: String {
        "\(branch1.chineseName)\(branch2.chineseName)冲"
    }

    /// All six clashes
    public static let allClashes: [(EarthlyBranch, EarthlyBranch)] = [
        (.zi, .wu),    // 子午冲
        (.chou, .wei), // 丑未冲
        (.yin, .shen), // 寅申冲
        (.mao, .you),  // 卯酉冲
        (.chen, .xu),  // 辰戌冲
        (.si, .hai)    // 巳亥冲
    ]

    /// Check if two branches clash
    public static func isClash(_ branch1: EarthlyBranch, _ branch2: EarthlyBranch) -> Bool {
        for (b1, b2) in allClashes {
            if (branch1 == b1 && branch2 == b2) || (branch1 == b2 && branch2 == b1) {
                return true
            }
        }
        return false
    }
}

// MARK: - Branch Harm (地支相害)

/// Branch harms - Branches that harm each other
public struct BranchHarm: Sendable {
    public let branch1: EarthlyBranch
    public let branch2: EarthlyBranch

    /// Chinese name
    public var chineseName: String {
        "\(branch1.chineseName)\(branch2.chineseName)害"
    }

    /// All six harms
    public static let allHarms: [(EarthlyBranch, EarthlyBranch)] = [
        (.zi, .wei),   // 子未害
        (.chou, .wu),  // 丑午害
        (.yin, .si),   // 寅巳害
        (.mao, .chen), // 卯辰害
        (.shen, .hai), // 申亥害
        (.you, .xu)    // 酉戌害
    ]

    /// Check if two branches harm each other
    public static func isHarm(_ branch1: EarthlyBranch, _ branch2: EarthlyBranch) -> Bool {
        for (b1, b2) in allHarms {
            if (branch1 == b1 && branch2 == b2) || (branch1 == b2 && branch2 == b1) {
                return true
            }
        }
        return false
    }
}

// MARK: - Branch Punishment (地支相刑)

/// Branch punishments - Three main punishment types
public enum BranchPunishment: String, Sendable, CaseIterable {
    case ungrateful = "ungrateful"     // 无恩之刑: 寅刑巳, 巳刑申, 申刑寅
    case bullying = "bullying"         // 恃势之刑: 丑刑戌, 戌刑未, 未刑丑
    case uncivilized = "uncivilized"   // 无礼之刑: 子刑卯, 卯刑子
    case selfPunishment = "self"       // 自刑: 辰辰, 午午, 酉酉, 亥亥

    /// Chinese name
    public var chineseName: String {
        switch self {
        case .ungrateful: return "无恩之刑"
        case .bullying: return "恃势之刑"
        case .uncivilized: return "无礼之刑"
        case .selfPunishment: return "自刑"
        }
    }

    /// Severity (1-3)
    public var severity: Int {
        switch self {
        case .ungrateful: return 3   // Most severe
        case .bullying: return 2
        case .uncivilized: return 2
        case .selfPunishment: return 1
        }
    }

    /// Check punishment type between branches
    public static func check(_ branches: [EarthlyBranch]) -> [BranchPunishment] {
        var punishments: [BranchPunishment] = []
        let branchSet = Set(branches)

        // Ungrateful: 寅巳申
        let ungratefulSet: Set<EarthlyBranch> = [.yin, .si, .shen]
        if ungratefulSet.intersection(branchSet).count >= 2 {
            punishments.append(.ungrateful)
        }

        // Bullying: 丑戌未
        let bullyingSet: Set<EarthlyBranch> = [.chou, .xu, .wei]
        if bullyingSet.intersection(branchSet).count >= 2 {
            punishments.append(.bullying)
        }

        // Uncivilized: 子卯
        if branchSet.contains(.zi) && branchSet.contains(.mao) {
            punishments.append(.uncivilized)
        }

        // Self punishment: 辰辰, 午午, 酉酉, 亥亥
        let selfPunishBranches: [EarthlyBranch] = [.chen, .wu, .you, .hai]
        for branch in selfPunishBranches {
            if branches.filter({ $0 == branch }).count >= 2 {
                punishments.append(.selfPunishment)
                break
            }
        }

        return punishments
    }
}

// MARK: - Branch Destruction (地支相破)

/// Branch destructions
public struct BranchDestruction: Sendable {
    /// All six destructions
    public static let allDestructions: [(EarthlyBranch, EarthlyBranch)] = [
        (.zi, .you),   // 子酉破
        (.wu, .mao),   // 午卯破
        (.yin, .hai),  // 寅亥破
        (.shen, .si),  // 申巳破
        (.chen, .chou),// 辰丑破
        (.xu, .wei)    // 戌未破
    ]

    /// Check if two branches destruct
    public static func isDestruction(_ branch1: EarthlyBranch, _ branch2: EarthlyBranch) -> Bool {
        for (b1, b2) in allDestructions {
            if (branch1 == b1 && branch2 == b2) || (branch1 == b2 && branch2 == b1) {
                return true
            }
        }
        return false
    }
}

// MARK: - Branch Combination Analyzer

/// Comprehensive analyzer for all branch combinations
public struct BranchCombinationAnalyzer: Sendable {

    public init() {}

    /// Analysis result
    public struct AnalysisResult: Sendable {
        public let threeHarmonies: [ThreeHarmony]
        public let partialHarmonies: [(ThreeHarmony, Set<EarthlyBranch>)]
        public let threeMeetings: [ThreeMeeting]
        public let sixCombinations: [SixCombination]
        public let clashes: [(EarthlyBranch, EarthlyBranch)]
        public let harms: [(EarthlyBranch, EarthlyBranch)]
        public let punishments: [BranchPunishment]
        public let destructions: [(EarthlyBranch, EarthlyBranch)]

        /// Net strength modification from combinations
        /// Positive = supporting, Negative = weakening
        public var strengthModifier: Double {
            var modifier = 0.0

            // Complete harmonies add significant strength
            modifier += Double(threeHarmonies.count) * 15.0
            // Partial harmonies add moderate strength
            modifier += Double(partialHarmonies.count) * 8.0
            // Complete meetings add major strength
            modifier += Double(threeMeetings.count) * 20.0
            // Six combinations add moderate strength
            modifier += Double(sixCombinations.count) * 5.0

            // Clashes reduce strength
            modifier -= Double(clashes.count) * 10.0
            // Harms reduce strength moderately
            modifier -= Double(harms.count) * 5.0
            // Punishments reduce strength
            for punishment in punishments {
                modifier -= Double(punishment.severity) * 5.0
            }
            // Destructions reduce strength slightly
            modifier -= Double(destructions.count) * 3.0

            return modifier
        }

        /// Whether combinations are overall positive
        public var isPositive: Bool {
            strengthModifier > 0
        }

        /// Summary description
        public var summary: String {
            var parts: [String] = []
            if !threeHarmonies.isEmpty {
                parts.append("三合: \(threeHarmonies.map { $0.chineseName }.joined(separator: ", "))")
            }
            if !threeMeetings.isEmpty {
                parts.append("三会: \(threeMeetings.map { $0.chineseName }.joined(separator: ", "))")
            }
            if !sixCombinations.isEmpty {
                parts.append("六合: \(sixCombinations.map { $0.chineseName }.joined(separator: ", "))")
            }
            if !clashes.isEmpty {
                parts.append("相冲: \(clashes.count)组")
            }
            if !punishments.isEmpty {
                parts.append("相刑: \(punishments.map { $0.chineseName }.joined(separator: ", "))")
            }
            return parts.isEmpty ? "无特殊组合" : parts.joined(separator: "; ")
        }
    }

    /// Analyze all branch combinations in a chart
    public func analyze(branches: [EarthlyBranch]) -> AnalysisResult {
        // Find Three Harmonies
        var threeHarmonies: [ThreeHarmony] = []
        var partialHarmonies: [(ThreeHarmony, Set<EarthlyBranch>)] = []
        for harmony in ThreeHarmony.allCases {
            if harmony.isComplete(in: branches) {
                threeHarmonies.append(harmony)
            } else if let partial = harmony.partialMatch(in: branches) {
                partialHarmonies.append((harmony, partial))
            }
        }

        // Find Three Meetings
        var threeMeetings: [ThreeMeeting] = []
        for meeting in ThreeMeeting.allCases {
            if meeting.isComplete(in: branches) {
                threeMeetings.append(meeting)
            }
        }

        // Find Six Combinations
        var sixCombinations: [SixCombination] = []
        for i in 0..<branches.count {
            for j in (i+1)..<branches.count {
                if let combination = SixCombination.find(branches[i], branches[j]) {
                    if !sixCombinations.contains(combination) {
                        sixCombinations.append(combination)
                    }
                }
            }
        }

        // Find Clashes
        var clashes: [(EarthlyBranch, EarthlyBranch)] = []
        for i in 0..<branches.count {
            for j in (i+1)..<branches.count {
                if BranchClash.isClash(branches[i], branches[j]) {
                    clashes.append((branches[i], branches[j]))
                }
            }
        }

        // Find Harms
        var harms: [(EarthlyBranch, EarthlyBranch)] = []
        for i in 0..<branches.count {
            for j in (i+1)..<branches.count {
                if BranchHarm.isHarm(branches[i], branches[j]) {
                    harms.append((branches[i], branches[j]))
                }
            }
        }

        // Find Punishments
        let punishments = BranchPunishment.check(branches)

        // Find Destructions
        var destructions: [(EarthlyBranch, EarthlyBranch)] = []
        for i in 0..<branches.count {
            for j in (i+1)..<branches.count {
                if BranchDestruction.isDestruction(branches[i], branches[j]) {
                    destructions.append((branches[i], branches[j]))
                }
            }
        }

        return AnalysisResult(
            threeHarmonies: threeHarmonies,
            partialHarmonies: partialHarmonies,
            threeMeetings: threeMeetings,
            sixCombinations: sixCombinations,
            clashes: clashes,
            harms: harms,
            punishments: punishments,
            destructions: destructions
        )
    }

    /// Analyze combinations between user chart and a date
    public func analyzeInteraction(
        userBranches: [EarthlyBranch],
        dateBranch: EarthlyBranch
    ) -> AnalysisResult {
        // Combine user branches with the date branch
        var combinedBranches = userBranches
        combinedBranches.append(dateBranch)
        return analyze(branches: combinedBranches)
    }
}
