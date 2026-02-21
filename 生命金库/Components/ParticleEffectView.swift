import SwiftUI

// MARK: - Coin Burst (金币入袋粒子爆炸)

struct CoinBurstEffect: View {
    var origin: CGPoint = CGPoint(x: 0, y: 0)
    var onFinish: (() -> Void)?

    @State private var particles: [BurstParticle] = []
    @State private var fired = false

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2 + origin.x,
                                 y: geo.size.height / 2 + origin.y)
            ZStack {
                ForEach(particles) { p in
                    BurstParticleView(particle: p, fired: fired)
                        .position(center)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            particles = BurstParticle.generate(count: 32)
            withAnimation(.easeOut(duration: 0.75)) { fired = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                onFinish?()
            }
        }
    }
}

struct BurstParticleView: View {
    let particle: BurstParticle
    let fired: Bool

    var body: some View {
        Circle()
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size)
            .offset(
                x: fired ? particle.endX : 0,
                y: fired ? particle.endY : 0
            )
            .opacity(fired ? 0 : particle.opacity)
            .scaleEffect(fired ? 0.1 : 1.0)
    }
}

struct BurstParticle: Identifiable {
    let id = UUID()
    let size: CGFloat
    let endX: CGFloat
    let endY: CGFloat
    let opacity: Double
    let color: Color

    static func generate(count: Int) -> [BurstParticle] {
        (0..<count).map { i in
            let angle = Double(i) / Double(count) * 2 * .pi
            let distance = CGFloat.random(in: 60...180)
            let colors: [Color] = [.liquidGold, Color(hex: "FFE55C"), .liquidGoldDark, Color(hex: "FFFDE7")]
            return BurstParticle(
                size: CGFloat.random(in: 4...12),
                endX: cos(angle) * distance,
                endY: sin(angle) * distance,
                opacity: Double.random(in: 0.7...1.0),
                color: colors[i % colors.count]
            )
        }
    }
}

// MARK: - Ambient Sparkles (常驻环境粒子，首页使用)

struct AmbientSparkles: View {
    let count: Int = 18

    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { i in
                SparkleParticle(index: i)
            }
        }
        .allowsHitTesting(false)
    }
}

private struct SparkleParticle: View {
    let index: Int
    @State private var visible = false

    private static let xPositions: [CGFloat] = [
        -155, -130, -100, -70, -40, -10, 20, 55, 85, 115, 148,
        -145, -75, -15, 45, 100, 140, -55, 30
    ]
    private static let yPositions: [CGFloat] = [
        -280, -210, -145, -90, -50, -10, 35, 80, 130, 185, 240,
        -240, -160, -75, 15, 65, 125, 190, 250
    ]
    private static let sizes: [CGFloat] = [
        3, 5, 2.5, 6, 4, 3, 5.5, 2, 4.5, 3.5, 5, 2.5, 4, 3, 5, 2, 4.5, 3.5, 5
    ]
    private static let delays: [Double] = [
        0.0, 0.3, 0.6, 0.9, 1.2, 0.15, 0.45, 0.75, 1.05, 1.35,
        0.2, 0.5, 0.8, 1.1, 0.1, 0.4, 0.7, 1.0, 1.3
    ]

    var body: some View {
        Circle()
            .fill(Color.liquidGold)
            .frame(
                width:  Self.sizes[index % Self.sizes.count],
                height: Self.sizes[index % Self.sizes.count]
            )
            .opacity(visible ? 0.7 : 0.05)
            .offset(
                x: Self.xPositions[index % Self.xPositions.count],
                y: Self.yPositions[index % Self.yPositions.count]
            )
            .onAppear {
                let delay = Self.delays[index % Self.delays.count]
                withAnimation(
                    .easeInOut(duration: Double.random(in: 1.8...3.2))
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) { visible = true }
            }
    }
}
