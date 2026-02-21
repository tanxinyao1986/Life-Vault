import SwiftUI

/// 锦囊卡片 – 根据 PouchLevel 动态呈现 4 种形态
/// Level 1 萌芽：精致空丝绸袋
/// Level 2 积累：半满，微光透出
/// Level 3 丰盛：鼓胀，金币隐约可见
/// Level 4 溢出：袋口大开，金币喷涌，光芒四射
struct PouchCardView: View {
    let type: PouchType
    let level: PouchLevel
    let count: Int

    @State private var glowPulse = false
    @State private var overflowAnim = false
    @State private var breathe = false

    private let baseSize: CGFloat = 110

    // 袋身高度随等级膨胀
    private var bodyHeight: CGFloat {
        let base: CGFloat = 80
        return base + CGFloat(level.rawValue - 1) * 14
    }
    private var bodyWidth: CGFloat {
        let base: CGFloat = 72
        return base + CGFloat(level.rawValue - 1) * 10
    }

    var body: some View {
        ZStack(alignment: .top) {
            // ── 背景光晕 ──────────────────────────────────────────
            glowLayer

            // ── 锦囊本体 ──────────────────────────────────────────
            VStack(spacing: 0) {
                // 袋口
                pouchOpening
                // 袋身
                pouchBody
            }
            .scaleEffect(breathe ? 1.02 : 0.99)

            // ── 溢出金币（Level 4）──────────────────────────────
            if level == .overflow {
                overflowCoins
                    .offset(y: -30)
            }

            // ── 积累透出的光点（Level 2+）───────────────────────
            if level >= .accumulate {
                glimmerDots
            }
        }
        .frame(width: baseSize + 20, height: baseSize + 50)
        .onAppear { startAnimations() }
    }

    // MARK: - Sub-views

    @ViewBuilder private var glowLayer: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        type.glowColor.opacity(glowPulse ? level.glowIntensity * 0.7 : level.glowIntensity * 0.3),
                        .clear
                    ],
                    center: .center, startRadius: 5, endRadius: 70
                )
            )
            .frame(width: 140, height: 140)
            .blur(radius: 15)
            .offset(y: 20)
    }

    @ViewBuilder private var pouchOpening: some View {
        ZStack {
            // 袋口褶皱
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [type.primaryColor.opacity(0.7), type.secondaryColor.opacity(0.9)],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .frame(width: bodyWidth + (level == .overflow ? 16 : 4), height: level == .overflow ? 22 : 14)
                .overlay(
                    Capsule().strokeBorder(Color.liquidGold.opacity(0.5), lineWidth: 1)
                )

            // 金线束口绳
            Capsule()
                .fill(LinearGradient.goldSheen)
                .frame(width: bodyWidth * 0.7, height: 4)
                .offset(y: level == .overflow ? 5 : 1)

            // 绳结
            Circle()
                .fill(LinearGradient.goldSheen)
                .frame(width: 8, height: 8)
                .offset(y: level == .overflow ? 5 : 1)

            // 两侧流苏
            HStack(spacing: bodyWidth * 0.72) {
                tassle
                tassle
            }
            .offset(y: level == .overflow ? 10 : 6)
        }
        .zIndex(1)
    }

    private var tassle: some View {
        VStack(spacing: 1) {
            Circle().fill(Color.liquidGold).frame(width: 5, height: 5)
            ForEach(0..<3, id: \.self) { _ in
                Rectangle().fill(Color.liquidGold.opacity(0.7)).frame(width: 1.5, height: 5)
            }
        }
    }

    @ViewBuilder private var pouchBody: some View {
        ZStack {
            // 袋体
            RoundedRectangle(cornerRadius: bodyWidth * 0.45)
                .fill(
                    LinearGradient(
                        colors: [
                            type.primaryColor.opacity(0.95),
                            type.secondaryColor
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: bodyWidth, height: bodyHeight)
                .overlay(
                    // 丝绸反光
                    RoundedRectangle(cornerRadius: bodyWidth * 0.45)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.18), .clear, Color.white.opacity(0.06)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    // 金线刺绣边框
                    RoundedRectangle(cornerRadius: bodyWidth * 0.45)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.liquidGold.opacity(0.6), Color.liquidGoldDark.opacity(0.3)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: type.secondaryColor.opacity(0.4), radius: 8, x: 3, y: 5)

            // 纹样圆章
            ZStack {
                Circle()
                    .strokeBorder(Color.liquidGold.opacity(0.5), lineWidth: 1.5)
                    .frame(width: bodyWidth * 0.46, height: bodyWidth * 0.46)

                Text(type.patternSymbol)
                    .font(.system(size: bodyWidth * 0.22, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "FFFDE7"), .liquidGoldDark],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
            }

            // Level 3+ 隐约金币轮廓
            if level >= .abundant {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .strokeBorder(Color.liquidGold.opacity(0.25), lineWidth: 1)
                        .frame(width: 18, height: 18)
                        .offset(
                            x: CGFloat(i - 1) * 14,
                            y: bodyHeight * 0.22
                        )
                }
            }
        }
        .frame(height: bodyHeight)
    }

    @ViewBuilder private var overflowCoins: some View {
        let positions: [(x: CGFloat, y: CGFloat, r: Double)] = [
            (-18, -8, -15),  (0, -16, 5),   (18, -8, 20),
            (-12, -24, -25), (12, -24, 18), (-4, -34, 8),
            (4,  -42, -10),  (-20, -30, 30),(20, -30, -20),
            (0,  -50, 0),
        ]
        ZStack {
            ForEach(0..<min(level.particleCount, positions.count), id: \.self) { i in
                GoldCoinChip()
                    .offset(x: positions[i].x, y: positions[i].y + (overflowAnim ? -4 : 0))
                    .rotationEffect(.degrees(positions[i].r))
                    .animation(
                        .easeInOut(duration: 1.2 + Double(i) * 0.1).repeatForever(autoreverses: true),
                        value: overflowAnim
                    )
            }
        }
        .offset(y: CGFloat(bodyHeight) * 0.2)
    }

    @ViewBuilder private var glimmerDots: some View {
        ForEach(0..<level.particleCount, id: \.self) { i in
            let positions: [(x: CGFloat, y: CGFloat)] = [
                (bodyWidth * 0.3, bodyHeight * 0.1),
                (-bodyWidth * 0.25, bodyHeight * 0.2),
                (bodyWidth * 0.15, bodyHeight * 0.35),
                (-bodyWidth * 0.3, bodyHeight * 0.38),
                (bodyWidth * 0.28, bodyHeight * 0.28),
                (0, bodyHeight * 0.05),
                (-bodyWidth * 0.1, bodyHeight * 0.45),
            ]
            if i < positions.count {
                Circle()
                    .fill(Color.liquidGold.opacity(glowPulse ? 0.9 : 0.2))
                    .frame(width: 3, height: 3)
                    .offset(x: positions[i].x, y: positions[i].y - bodyHeight * 0.5 + 20)
                    .animation(
                        .easeInOut(duration: 1.5 + Double(i) * 0.3).repeatForever(autoreverses: true),
                        value: glowPulse
                    )
            }
        }
    }

    private func startAnimations() {
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            glowPulse = true
            overflowAnim = true
        }
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            breathe = true
        }
    }
}

// MARK: - Coin Chip (小金币片)

struct GoldCoinChip: View {
    var diameter: CGFloat = 16

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "FFFDE7"), Color.liquidGold, Color.liquidGoldDark],
                        center: UnitPoint(x: 0.3, y: 0.3),
                        startRadius: 1, endRadius: CGFloat(diameter)
                    )
                )
            Circle()
                .strokeBorder(Color(hex: "F9A825").opacity(0.6), lineWidth: 1)
        }
        .frame(width: diameter, height: diameter)
        .shadow(color: Color.liquidGold.opacity(0.6), radius: 3)
    }
}

#Preview {
    HStack(spacing: 20) {
        PouchCardView(type: .career, level: .sprout, count: 2)
        PouchCardView(type: .love, level: .abundant, count: 20)
        PouchCardView(type: .growth, level: .overflow, count: 35)
    }
    .padding(40)
    .background(Color.warmPearl)
}
