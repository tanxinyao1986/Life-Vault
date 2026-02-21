import SwiftUI

/// 3D 旋转金币 – 主交互按钮
/// 呼吸光效 + Y 轴倾斜 + 上下悬浮 + 流光扫过
struct GoldCoinView: View {
    var size: CGFloat = 150

    @State private var tiltY     = 0.0
    @State private var floatY:   CGFloat = 0
    @State private var glowScale = 1.0
    @State private var shimmer   = false

    var body: some View {
        ZStack {
            // ── 1. 背光光晕 ──────────────────────────────────────
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.liquidGold.opacity(0.35), .clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: size * 0.75
                    )
                )
                .frame(width: size * 1.5, height: size * 1.5)
                .scaleEffect(glowScale)
                .blur(radius: 12)

            // ── 2. 金币本体 ──────────────────────────────────────
            ZStack {
                // 底层渐变（正面）
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "FFFDE7"),
                                Color(hex: "FFD700"),
                                Color(hex: "F9A825"),
                                Color(hex: "E65100")
                            ],
                            center: UnitPoint(x: 0.32, y: 0.25),
                            startRadius: 4,
                            endRadius: size * 0.55
                        )
                    )

                // 底部阴影层（模拟球面光影）
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, Color(hex: "7B3F00").opacity(0.28)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // 外环 – AngularGradient 模拟金属边缘
                Circle()
                    .strokeBorder(
                        AngularGradient(
                            colors: [
                                Color(hex: "FFFDE7"),
                                Color(hex: "F9A825"),
                                Color(hex: "B8860B"),
                                Color(hex: "F9A825"),
                                Color(hex: "FFFDE7")
                            ],
                            center: .center
                        ),
                        lineWidth: size * 0.042
                    )

                // 内环装饰
                Circle()
                    .strokeBorder(Color(hex: "DAA520").opacity(0.45), lineWidth: 1.5)
                    .padding(size * 0.12)

                // 福字
                Text("福")
                    .font(.custom("Songti SC", size: size * 0.42))
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "4E342E"), Color(hex: "6D4C41")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color.liquidGold.opacity(0.4), radius: 4)

                // 流光扫过
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.white.opacity(shimmer ? 0.55 : 0.0),
                        Color.clear
                    ],
                    startPoint: UnitPoint(x: shimmer ? 1.2 : -0.4, y: 0),
                    endPoint:   UnitPoint(x: shimmer ? 1.6 : 0.0,  y: 1)
                )
                .clipShape(Circle())
            }
            .frame(width: size, height: size)
            .rotation3DEffect(
                .degrees(tiltY),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.22
            )
            .shadow(color: Color.liquidGoldDark.opacity(0.55), radius: 18, x: 0, y: 10)
        }
        .offset(y: floatY)
        .onAppear { startAnimations() }
    }

    private func startAnimations() {
        withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
            tiltY = 22
        }
        withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
            floatY = -11
        }
        withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
            glowScale = 1.18
        }
        // 流光每 4s 扫一次
        withAnimation(.linear(duration: 1.0).delay(1.5).repeatForever(autoreverses: false)) {
            shimmer = true
        }
    }
}

#Preview {
    ZStack {
        Color.antiqueBronze.ignoresSafeArea()
        GoldCoinView(size: 160)
    }
}
