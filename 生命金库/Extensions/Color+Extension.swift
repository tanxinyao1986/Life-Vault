import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }

    // MARK: – Design System · Oriental Luminous Abundance

    /// 暖珍珠白 – 舞台光源中心
    static let warmPearl    = Color(hex: "E8DFD0")
    /// 深古铜 – 舞台边缘阴影
    static let antiqueBronze = Color(hex: "8B7D6B")
    /// 流光金 – 主高亮
    static let liquidGold    = Color(hex: "FFD700")
    /// 暗金 – 金属渐变末端
    static let liquidGoldDark = Color(hex: "DAA520")
    /// 朱砂红 – 事业/财富锦囊
    static let cinnabarRed   = Color(hex: "C41E3A")
    /// 深枣红 – 朱砂红渐变末端
    static let deepCrimson   = Color(hex: "7B0E1E")
    /// 宝石蓝 – 智慧/成长锦囊
    static let sapphireBlue  = Color(hex: "0F52BA")
    /// 深宝蓝 – 蓝色渐变末端
    static let deepSapphire  = Color(hex: "082D66")
    /// 玫瑰金 – 爱/关系锦囊
    static let roseGold      = Color(hex: "C8856A")
    /// 深玫瑰 – 玫瑰金渐变末端
    static let deepRose      = Color(hex: "8B4A3A")
    /// 深咖啡 – 正文字色（浅色背景时使用）
    static let darkRoast     = Color(hex: "2F2621")

    // MARK: – Deep Spotlight Theme (dark background)

    /// 展柜底色 – 近乎纯黑的深咖
    static let vaultBase      = Color(hex: "0D0906")
    /// 展柜中层
    static let vaultMid       = Color(hex: "1A120B")
    /// 聚光中心暖琥珀
    static let spotlightAmber = Color(hex: "D4AF37")
    /// 主文字 – 暖米白（深色背景）
    static let offWhite       = Color(hex: "F0E6D3")
    /// 次要文字 – 哑光金（深色背景）
    static let mutedGold      = Color(hex: "A89060")
}

// MARK: – Gradient Presets

extension LinearGradient {
    static let goldSheen = LinearGradient(
        colors: [Color(hex: "FFE55C"), .liquidGold, .liquidGoldDark],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let ambientStage = LinearGradient(
        colors: [Color.warmPearl, Color(hex: "D4C4A8"), Color.antiqueBronze],
        startPoint: .top,
        endPoint: .bottom
    )
}
