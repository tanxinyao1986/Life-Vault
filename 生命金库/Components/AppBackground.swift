import SwiftUI

// MARK: - AppBackground
// Deep Spotlight / Museum Display Case
// 层叠结构：深黑底色 → 中心暖琥珀聚光 → 四角压暗渐晕 → 颗粒噪点

struct AppBackground: View {
    var body: some View {
        ZStack {
            // ── 1. 展柜底色（几乎纯黑）─────────────────────────────
            Color.vaultBase
                .ignoresSafeArea()

            // ── 2. 中心聚光（分两层：宽泛暖光 + 核心白热亮斑）──────
            // 宽泛暖琥珀层
            RadialGradient(
                colors: [
                    Color.spotlightAmber.opacity(0.38),
                    Color(hex: "4A3020").opacity(0.45),
                    Color.clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 460
            )
            .ignoresSafeArea()

            // 核心高亮白热斑（营造"灯下最亮处"感）
            RadialGradient(
                colors: [
                    Color(hex: "E8DFD0").opacity(0.22),
                    Color.clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 180
            )
            .ignoresSafeArea()

            // ── 3. 四角压暗渐晕（径向，从中心透明到四角极暗）────────
            RadialGradient(
                colors: [
                    Color.clear,
                    Color.vaultBase.opacity(0.55),
                    Color.vaultBase.opacity(0.88)
                ],
                center: .center,
                startRadius: 160,
                endRadius: 520
            )
            .ignoresSafeArea()

            // ── 4. 颗粒噪点（防色阶断层，高级纸质感）────────────────
            GrainOverlay()
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
    }
}

// MARK: - GrainOverlay
// 使用确定性伪随机坐标，每次渲染结果一致，无性能开销

struct GrainOverlay: View {
    // 预生成 2400 个晶粒点（确定性，不依赖 Random.random）
    private static let grains: [(x: Int, y: Int, alpha: Double)] = {
        (0..<2400).map { i in
            let x = (i &* 1_619 &+ 7_919) % 430
            let y = (i &* 9_311 &+ 3_571) % 932
            let a = Double((i &* 41 &+ 13) % 6) / 100.0   // 0.00 … 0.05
            return (x, y, a)
        }
    }()

    var body: some View {
        Canvas { ctx, _ in
            for g in Self.grains {
                ctx.opacity = g.alpha
                ctx.fill(
                    Path(CGRect(x: CGFloat(g.x), y: CGFloat(g.y), width: 1.5, height: 1.5)),
                    with: .color(.white)
                )
            }
        }
        .opacity(0.85)   // 整体强度旋钮，调低更细腻
    }
}

#Preview {
    AppBackground()
}
