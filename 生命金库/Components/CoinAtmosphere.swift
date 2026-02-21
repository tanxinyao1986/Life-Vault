import SwiftUI

// MARK: - CoinHaloView
// 呼吸光晕：金色径向渐变，scale 1.0↔1.2，周期 3s

struct CoinHaloView: View {
    /// 金币可见半径（pt），光晕尺寸随此值等比缩放。默认 110 与原始 220pt 金币匹配。
    var coinRadius: CGFloat = 110

    @State private var breathe = false

    var body: some View {
        // 基准设计时 coinRadius = 110
        let s = coinRadius / 110

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
                        startRadius: 20 * s,
                        endRadius: 145 * s
                    )
                )
                .frame(width: 300 * s, height: 300 * s)
                .blur(radius: 18 * s)
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
                        endRadius: 95 * s
                    )
                )
                .frame(width: 210 * s, height: 210 * s)
                .blur(radius: 8 * s)
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

// MARK: - GoldRainView
// 全屏金币雨：40 颗金粒子从屏幕顶部不规则降落至底部
// 使用 Canvas + TimelineView 保证 60fps 且无额外状态开销

struct GoldRainView: View {

    private struct CoinSpec {
        let xFrac:       Double   // 水平位置（屏幕宽度百分比 0–1）
        let cycleTime:   Double   // 单次下落周期（秒）
        let phaseOffset: Double   // 初始相位偏移（0–1），错开出现时机
        let size:        CGFloat  // 粒子直径（大=近，小=远，营造景深）
        let driftAmp:    CGFloat  // 左右飘移幅度（pt）
        let driftFreq:   Double   // 飘移正弦频率（完整周期数）
        let maxOpacity:  Double   // 峰值透明度
    }

    // 40 颗粒子，覆盖全屏宽度，速度/相位/尺寸各不相同
    private static let specs: [CoinSpec] = [
        // ── 第一批（均匀铺满宽度）───────────────────────────
        CoinSpec(xFrac: 0.03, cycleTime: 5.2, phaseOffset: 0.00, size: 4.0, driftAmp: 14, driftFreq: 0.8, maxOpacity: 0.62),
        CoinSpec(xFrac: 0.10, cycleTime: 4.5, phaseOffset: 0.23, size: 2.4, driftAmp: 20, driftFreq: 1.2, maxOpacity: 0.44),
        CoinSpec(xFrac: 0.18, cycleTime: 6.1, phaseOffset: 0.47, size: 3.6, driftAmp: 11, driftFreq: 0.6, maxOpacity: 0.54),
        CoinSpec(xFrac: 0.25, cycleTime: 4.8, phaseOffset: 0.70, size: 2.0, driftAmp: 18, driftFreq: 1.4, maxOpacity: 0.40),
        CoinSpec(xFrac: 0.32, cycleTime: 5.6, phaseOffset: 0.15, size: 4.5, driftAmp: 10, driftFreq: 0.9, maxOpacity: 0.68),
        CoinSpec(xFrac: 0.39, cycleTime: 4.2, phaseOffset: 0.38, size: 2.8, driftAmp: 22, driftFreq: 1.1, maxOpacity: 0.50),
        CoinSpec(xFrac: 0.46, cycleTime: 6.5, phaseOffset: 0.62, size: 3.2, driftAmp: 13, driftFreq: 0.7, maxOpacity: 0.58),
        CoinSpec(xFrac: 0.53, cycleTime: 4.0, phaseOffset: 0.85, size: 2.2, driftAmp: 19, driftFreq: 1.3, maxOpacity: 0.42),
        CoinSpec(xFrac: 0.60, cycleTime: 5.8, phaseOffset: 0.10, size: 4.2, driftAmp: 12, driftFreq: 0.8, maxOpacity: 0.60),
        CoinSpec(xFrac: 0.67, cycleTime: 4.6, phaseOffset: 0.33, size: 2.6, driftAmp: 21, driftFreq: 1.0, maxOpacity: 0.47),
        CoinSpec(xFrac: 0.74, cycleTime: 6.0, phaseOffset: 0.57, size: 3.8, driftAmp: 12, driftFreq: 0.5, maxOpacity: 0.59),
        CoinSpec(xFrac: 0.81, cycleTime: 4.3, phaseOffset: 0.80, size: 2.3, driftAmp: 17, driftFreq: 1.2, maxOpacity: 0.43),
        CoinSpec(xFrac: 0.88, cycleTime: 5.4, phaseOffset: 0.05, size: 3.0, driftAmp: 15, driftFreq: 0.9, maxOpacity: 0.53),
        CoinSpec(xFrac: 0.95, cycleTime: 4.7, phaseOffset: 0.28, size: 2.1, driftAmp: 20, driftFreq: 1.1, maxOpacity: 0.42),
        // ── 第二批（填补间隙）───────────────────────────────
        CoinSpec(xFrac: 0.07, cycleTime: 5.9, phaseOffset: 0.52, size: 3.5, driftAmp: 13, driftFreq: 0.7, maxOpacity: 0.56),
        CoinSpec(xFrac: 0.14, cycleTime: 4.4, phaseOffset: 0.75, size: 2.7, driftAmp: 18, driftFreq: 1.3, maxOpacity: 0.48),
        CoinSpec(xFrac: 0.21, cycleTime: 6.3, phaseOffset: 0.18, size: 4.0, driftAmp: 11, driftFreq: 0.6, maxOpacity: 0.62),
        CoinSpec(xFrac: 0.29, cycleTime: 4.9, phaseOffset: 0.42, size: 2.2, driftAmp: 23, driftFreq: 1.0, maxOpacity: 0.40),
        CoinSpec(xFrac: 0.36, cycleTime: 5.5, phaseOffset: 0.65, size: 3.7, driftAmp: 10, driftFreq: 0.8, maxOpacity: 0.58),
        CoinSpec(xFrac: 0.43, cycleTime: 4.1, phaseOffset: 0.88, size: 2.5, driftAmp: 20, driftFreq: 1.4, maxOpacity: 0.45),
        CoinSpec(xFrac: 0.50, cycleTime: 6.2, phaseOffset: 0.11, size: 4.3, driftAmp: 9,  driftFreq: 0.5, maxOpacity: 0.65),
        CoinSpec(xFrac: 0.57, cycleTime: 4.7, phaseOffset: 0.34, size: 2.1, driftAmp: 22, driftFreq: 1.2, maxOpacity: 0.39),
        CoinSpec(xFrac: 0.64, cycleTime: 5.7, phaseOffset: 0.58, size: 3.4, driftAmp: 14, driftFreq: 0.9, maxOpacity: 0.55),
        CoinSpec(xFrac: 0.71, cycleTime: 4.2, phaseOffset: 0.81, size: 2.8, driftAmp: 19, driftFreq: 1.1, maxOpacity: 0.46),
        CoinSpec(xFrac: 0.78, cycleTime: 6.4, phaseOffset: 0.04, size: 3.9, driftAmp: 10, driftFreq: 0.7, maxOpacity: 0.61),
        CoinSpec(xFrac: 0.85, cycleTime: 4.5, phaseOffset: 0.27, size: 2.4, driftAmp: 21, driftFreq: 1.3, maxOpacity: 0.43),
        CoinSpec(xFrac: 0.92, cycleTime: 5.3, phaseOffset: 0.50, size: 3.1, driftAmp: 13, driftFreq: 0.6, maxOpacity: 0.52),
        // ── 第三批（大小混搭，强化景深）─────────────────────
        CoinSpec(xFrac: 0.02, cycleTime: 6.8, phaseOffset: 0.72, size: 5.0, driftAmp: 8,  driftFreq: 0.4, maxOpacity: 0.72),
        CoinSpec(xFrac: 0.11, cycleTime: 3.9, phaseOffset: 0.20, size: 1.8, driftAmp: 25, driftFreq: 1.6, maxOpacity: 0.34),
        CoinSpec(xFrac: 0.34, cycleTime: 7.0, phaseOffset: 0.44, size: 5.2, driftAmp: 7,  driftFreq: 0.3, maxOpacity: 0.75),
        CoinSpec(xFrac: 0.48, cycleTime: 3.7, phaseOffset: 0.67, size: 1.6, driftAmp: 24, driftFreq: 1.7, maxOpacity: 0.31),
        CoinSpec(xFrac: 0.62, cycleTime: 6.6, phaseOffset: 0.90, size: 4.8, driftAmp: 8,  driftFreq: 0.4, maxOpacity: 0.68),
        CoinSpec(xFrac: 0.76, cycleTime: 4.0, phaseOffset: 0.13, size: 1.9, driftAmp: 22, driftFreq: 1.4, maxOpacity: 0.37),
        CoinSpec(xFrac: 0.90, cycleTime: 6.9, phaseOffset: 0.36, size: 4.6, driftAmp: 9,  driftFreq: 0.5, maxOpacity: 0.64),
        CoinSpec(xFrac: 0.20, cycleTime: 3.6, phaseOffset: 0.59, size: 1.7, driftAmp: 26, driftFreq: 1.8, maxOpacity: 0.32),
        CoinSpec(xFrac: 0.44, cycleTime: 5.0, phaseOffset: 0.83, size: 3.3, driftAmp: 16, driftFreq: 1.0, maxOpacity: 0.51),
        CoinSpec(xFrac: 0.69, cycleTime: 6.7, phaseOffset: 0.06, size: 4.7, driftAmp: 7,  driftFreq: 0.3, maxOpacity: 0.70),
        CoinSpec(xFrac: 0.84, cycleTime: 3.8, phaseOffset: 0.29, size: 2.2, driftAmp: 23, driftFreq: 1.5, maxOpacity: 0.36),
        CoinSpec(xFrac: 0.27, cycleTime: 5.1, phaseOffset: 0.53, size: 3.6, driftAmp: 14, driftFreq: 0.8, maxOpacity: 0.55),
        CoinSpec(xFrac: 0.55, cycleTime: 6.0, phaseOffset: 0.76, size: 4.1, driftAmp: 11, driftFreq: 0.6, maxOpacity: 0.60),
    ]

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                let t = timeline.date.timeIntervalSinceReferenceDate

                for spec in Self.specs {
                    let raw   = t / spec.cycleTime + spec.phaseOffset
                    let phase = raw - floor(raw)   // 0→1 循环

                    // ── 纵向：从屏幕顶部略上方降落到底部略下方 ──
                    let travel = size.height + 24
                    let y      = -12 + travel * CGFloat(phase)

                    // ── 横向：正弦不规则漂移 ──────────────────────
                    let baseX = size.width * CGFloat(spec.xFrac)
                    let x     = baseX + spec.driftAmp * CGFloat(
                        sin(phase * spec.driftFreq * .pi * 2)
                    )

                    // ── 透明度：顶部淡入（5%）/ 底部淡出（8%）────
                    let opacity: Double
                    switch phase {
                    case 0..<0.05:  opacity = (phase / 0.05)  * spec.maxOpacity
                    case 0.92..<1:  opacity = ((1 - phase) / 0.08) * spec.maxOpacity
                    default:        opacity = spec.maxOpacity
                    }

                    ctx.opacity = opacity

                    // ── 绘制小金币（轻微椭圆感，模拟侧面透视）────
                    let r  = spec.size / 2
                    let ry = r * 0.72   // 略扁，像从侧面看到的硬币
                    ctx.fill(
                        Path(ellipseIn: CGRect(
                            x: x - r, y: y - ry,
                            width: spec.size, height: spec.size * 0.72
                        )),
                        with: .color(Color(hex: "FFD700"))
                    )

                    // ── 高光点（仅较大粒子）──────────────────────
                    if spec.size >= 3.5 {
                        ctx.opacity = opacity * 0.55
                        let hr = r * 0.28
                        ctx.fill(
                            Path(ellipseIn: CGRect(
                                x: x - r * 0.3, y: y - ry * 0.55,
                                width: hr * 2, height: hr
                            )),
                            with: .color(Color(hex: "FFFDE7"))
                        )
                    }
                }
            }
        }
        .ignoresSafeArea()
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
