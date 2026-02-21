import SwiftUI

// MARK: - CoinHaloView
// 呼吸光晕：金色径向渐变，scale 1.0↔1.2，周期 3s

struct CoinHaloView: View {
    @State private var breathe = false

    var body: some View {
        ZStack {
            // 外层柔化光晕
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "FFD700").opacity(0.30),
                            Color(hex: "FFD700").opacity(0.08),
                            .clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 145
                    )
                )
                .frame(width: 300, height: 300)
                .blur(radius: 18)
                .scaleEffect(breathe ? 1.20 : 1.00)

            // 内层紧贴金币的紧密光晕
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "FFD700").opacity(0.45),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 95
                    )
                )
                .frame(width: 210, height: 210)
                .blur(radius: 8)
                .scaleEffect(breathe ? 1.12 : 0.95)
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 3.0)
                .repeatForever(autoreverses: true)
            ) { breathe = true }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - GoldDustView
// 上浮金尘：TimelineView + Canvas，零状态开销，流畅 60fps
// 16 颗粒子，各自随机速度/位置/相位，从金币区域缓缓上浮散逸

struct GoldDustView: View {
    // 粒子参数（确定性，不依赖 random()，避免每次重绘随机变化）
    private struct DustSpec {
        let xOffset: CGFloat   // 相对中心横向偏移
        let cycleTime: Double  // 完整上升周期（秒）
        let phaseOffset: Double// 初始相位（0-1），错开起点
        let size: CGFloat      // 粒子直径
        let drift: CGFloat     // 上浮过程中的横向漂移幅度
    }

    private static let specs: [DustSpec] = [
        DustSpec(xOffset: -88, cycleTime: 4.2, phaseOffset: 0.00, size: 2.0, drift:  6),
        DustSpec(xOffset: -60, cycleTime: 3.8, phaseOffset: 0.31, size: 1.5, drift: -5),
        DustSpec(xOffset: -38, cycleTime: 5.0, phaseOffset: 0.62, size: 2.5, drift:  8),
        DustSpec(xOffset:  -8, cycleTime: 3.5, phaseOffset: 0.14, size: 1.8, drift: -4),
        DustSpec(xOffset:  18, cycleTime: 4.6, phaseOffset: 0.47, size: 2.2, drift:  7),
        DustSpec(xOffset:  44, cycleTime: 3.9, phaseOffset: 0.78, size: 1.5, drift: -6),
        DustSpec(xOffset:  72, cycleTime: 4.8, phaseOffset: 0.23, size: 2.0, drift:  5),
        DustSpec(xOffset:  96, cycleTime: 3.6, phaseOffset: 0.55, size: 1.8, drift: -7),
        DustSpec(xOffset: -75, cycleTime: 4.1, phaseOffset: 0.88, size: 1.5, drift:  4),
        DustSpec(xOffset: -22, cycleTime: 5.2, phaseOffset: 0.40, size: 2.8, drift: -5),
        DustSpec(xOffset:  30, cycleTime: 3.7, phaseOffset: 0.70, size: 1.5, drift:  6),
        DustSpec(xOffset:  58, cycleTime: 4.4, phaseOffset: 0.05, size: 2.2, drift: -8),
        DustSpec(xOffset: -50, cycleTime: 3.3, phaseOffset: 0.60, size: 1.8, drift:  5),
        DustSpec(xOffset:  10, cycleTime: 4.9, phaseOffset: 0.18, size: 2.0, drift: -4),
        DustSpec(xOffset:  82, cycleTime: 3.4, phaseOffset: 0.85, size: 1.5, drift:  7),
        DustSpec(xOffset: -15, cycleTime: 4.3, phaseOffset: 0.33, size: 2.5, drift: -6),
    ]

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let cx = size.width  / 2
                let cy = size.height / 2 + 60  // 从金币下方出发

                for spec in Self.specs {
                    // 当前相位（0→1 循环）
                    let raw = (t / spec.cycleTime + spec.phaseOffset)
                    let phase = raw - floor(raw)

                    // 上升：y 从 +80 到 -220（相对 cy）
                    let travel: CGFloat = 300
                    let y = cy + 80 - travel * CGFloat(phase)

                    // 横向漂移：正弦随相位缓缓摆动
                    let x = cx + spec.xOffset + spec.drift * CGFloat(sin(phase * .pi * 2))

                    // 透明度：淡入（phase<0.1）→ 持续 → 淡出（phase>0.75）
                    let opacity: Double
                    switch phase {
                    case 0..<0.12:  opacity = phase / 0.12 * 0.70
                    case 0.75..<1:  opacity = (1 - phase) / 0.25 * 0.70
                    default:        opacity = 0.70
                    }

                    ctx.opacity = opacity
                    let r = spec.size / 2
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: x - r, y: y - r,
                                               width: spec.size, height: spec.size)),
                        with: .color(Color(hex: "FFD700"))
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    ZStack {
        AppBackground()
        CoinHaloView()
        GoldDustView()
            .frame(width: 300, height: 400)
    }
}
