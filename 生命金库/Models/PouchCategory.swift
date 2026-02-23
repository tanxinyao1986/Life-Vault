import SwiftUI

// MARK: - PouchType

enum PouchType: String, CaseIterable, Identifiable {
    case career = "career"
    case love   = "love"
    case growth = "growth"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .career: String(localized: "事业·财富")
        case .love:   String(localized: "爱·关系")
        case .growth: String(localized: "成长·智慧")
        }
    }

    var subtitle: String {
        switch self {
        case .career: String(localized: "Career & Wealth")
        case .love:   String(localized: "Love & Relations")
        case .growth: String(localized: "Growth & Wisdom")
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

    /// SF Symbol 图标名（用于选择器等 UI）
    var iconName: String {
        switch self {
        case .career: "briefcase.fill"
        case .love:   "heart.fill"
        case .growth: "leaf.fill"
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

    /// isPro = false 时免费用户最高封顶 LV3（abundant）
    static func level(for count: Int, isPro: Bool = false) -> PouchLevel {
        switch count {
        case 0...50:    return .sprout
        case 51...100:  return .accumulate
        case 101...200: return .abundant
        default:        return isPro ? .overflow : .abundant
        }
    }

    /// 免费用户是否触达 LV4 锁定状态（count > 200 且未订阅）
    static func isLV4Locked(count: Int, isPro: Bool) -> Bool {
        !isPro && count > 200
    }

    var name: String {
        switch self {
        case .sprout:     String(localized: "萌芽")
        case .accumulate: String(localized: "积累")
        case .abundant:   String(localized: "丰盛")
        case .overflow:   String(localized: "溢出")
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
        case .sprout:     51
        case .accumulate: 101
        case .abundant:   201
        case .overflow:   nil
        }
    }

    /// 等级图片名（对应 Bundle 中的 01.png / 02.png / 03.png / 04.png）
    var imageName: String { String(format: "%02d", rawValue) }

    /// 上一级阈值（用于进度计算）
    var prevThreshold: Int {
        switch self {
        case .sprout:     0
        case .accumulate: 51
        case .abundant:   101
        case .overflow:   201
        }
    }

    /// 升级进度 0–1
    func progress(for count: Int) -> Double {
        guard let next = nextThreshold else { return 1.0 }
        let span = next - prevThreshold
        guard span > 0 else { return 1.0 }
        return min(Double(count - prevThreshold) / Double(span), 1.0)
    }
}
