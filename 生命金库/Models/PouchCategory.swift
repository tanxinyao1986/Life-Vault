import SwiftUI

// MARK: - PouchType

enum PouchType: String, CaseIterable, Identifiable {
    case career = "career"
    case love   = "love"
    case growth = "growth"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .career: "事业·财富"
        case .love:   "爱·关系"
        case .growth: "成长·智慧"
        }
    }

    var subtitle: String {
        switch self {
        case .career: "Career & Wealth"
        case .love:   "Love & Relations"
        case .growth: "Growth & Wisdom"
        }
    }

    /// 主色（锦囊本体）
    var primaryColor: Color {
        switch self {
        case .career: .cinnabarRed
        case .love:   .roseGold
        case .growth: .sapphireBlue
        }
    }

    /// 渐变末端色（阴影侧）
    var secondaryColor: Color {
        switch self {
        case .career: .deepCrimson
        case .love:   .deepRose
        case .growth: .deepSapphire
        }
    }

    /// 光晕颜色
    var glowColor: Color {
        switch self {
        case .career: Color(hex: "FF6B6B")
        case .love:   Color(hex: "F4A67A")
        case .growth: Color(hex: "5B9BD5")
        }
    }

    /// 纹样符号（云纹/回纹风格）
    var patternSymbol: String {
        switch self {
        case .career: "✦"
        case .love:   "◈"
        case .growth: "⊕"
        }
    }
}

// MARK: - PouchLevel

enum PouchLevel: Int, Comparable {
    case sprout     = 1   //  0–5   枚：萌芽 – 精致空丝绸袋
    case accumulate = 2   //  6–15  枚：积累 – 半满，微光透出
    case abundant   = 3   // 16–30  枚：丰盛 – 鼓胀，金币隐约
    case overflow   = 4   // 31+    枚：溢出 – 袋口大开，光芒四射

    static func < (lhs: PouchLevel, rhs: PouchLevel) -> Bool { lhs.rawValue < rhs.rawValue }

    static func level(for count: Int) -> PouchLevel {
        switch count {
        case 0...5:   .sprout
        case 6...15:  .accumulate
        case 16...30: .abundant
        default:      .overflow
        }
    }

    var name: String {
        switch self {
        case .sprout:     "萌芽"
        case .accumulate: "积累"
        case .abundant:   "丰盛"
        case .overflow:   "溢出"
        }
    }

    /// 锦囊饱满度 0–1
    var fillRatio: Double {
        switch self {
        case .sprout:     0.05
        case .accumulate: 0.42
        case .abundant:   0.75
        case .overflow:   1.0
        }
    }

    /// 光晕强度 0–1
    var glowIntensity: Double {
        switch self {
        case .sprout:     0.15
        case .accumulate: 0.40
        case .abundant:   0.70
        case .overflow:   1.00
        }
    }

    /// 粒子数量
    var particleCount: Int {
        switch self {
        case .sprout:     0
        case .accumulate: 3
        case .abundant:   7
        case .overflow:   14
        }
    }

    /// 下一级所需记录数
    var nextThreshold: Int? {
        switch self {
        case .sprout:     6
        case .accumulate: 16
        case .abundant:   31
        case .overflow:   nil
        }
    }
}
