import SwiftUI
import SwiftData

/// 财富宝库 – 神圣陈列架（Deep Spotlight 深色展柜主题）
struct VaultView: View {
    @Query(sort: \SuccessEntry.timestamp, order: .reverse) private var entries: [SuccessEntry]
    @State private var selectedPouch: PouchType? = nil
    @State private var lightBeam = false

    var body: some View {
        ZStack {
            // ── Deep Spotlight 背景 ───────────────────────────────
            AppBackground()

            // ── 三道竖向射灯光柱（覆盖在背景上，与三只锦囊对应）──
            lightColumns

            VStack(spacing: 0) {
                header
                    .padding(.top, 60)
                    .padding(.horizontal, 28)

                totalWealthBadge
                    .padding(.top, 16)

                Spacer()

                shelfLayout
                    .padding(.horizontal, 20)

                Spacer()

                levelLegend
                    .padding(.horizontal, 24)
                    .padding(.bottom, 100)
            }
        }
        .sheet(item: $selectedPouch) { pouch in
            PouchDetailView(pouchType: pouch, entries: entriesFor(pouch))
        }
    }

    // MARK: - Sub-views

    private var lightColumns: some View {
        HStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { _ in
                Spacer()
                Rectangle()
                    .fill(LinearGradient(
                        colors: [Color.liquidGold.opacity(lightBeam ? 0.06 : 0.01), .clear],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .frame(width: 80)
                    .blur(radius: 18)
                Spacer()
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
                lightBeam = true
            }
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("财富宝库")
                .font(.custom("Songti SC", size: 28))
                .fontWeight(.semibold)
                .foregroundStyle(LinearGradient(
                    colors: [.liquidGold, .liquidGoldDark],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
            Text("The Vault of Abundance")
                .font(.custom("New York", size: 12))
                .tracking(3)
                .foregroundColor(.mutedGold)
        }
    }

    private var totalWealthBadge: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { _ in GoldCoinChip(diameter: 12) }
            Text("生命资产总值：\(entries.count) 枚金币")
                .font(.custom("Songti SC", size: 13))
                .foregroundColor(.offWhite.opacity(0.75))
                .tracking(1)
            ForEach(0..<3, id: \.self) { _ in GoldCoinChip(diameter: 12) }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.07))
                .overlay(Capsule().strokeBorder(Color.liquidGold.opacity(0.3), lineWidth: 1))
        )
    }

    private var shelfLayout: some View {
        VStack(spacing: 36) {
            PouchShelfCard(type: .career, count: careerCount,
                           level: PouchLevel.level(for: careerCount))
                .onTapGesture { selectedPouch = .career }

            HStack(spacing: 24) {
                PouchShelfCard(type: .love, count: loveCount,
                               level: PouchLevel.level(for: loveCount))
                    .onTapGesture { selectedPouch = .love }

                PouchShelfCard(type: .growth, count: growthCount,
                               level: PouchLevel.level(for: growthCount))
                    .onTapGesture { selectedPouch = .growth }
            }
        }
    }

    private var levelLegend: some View {
        HStack(spacing: 0) {
            ForEach([PouchLevel.sprout, .accumulate, .abundant, .overflow], id: \.rawValue) { lvl in
                VStack(spacing: 3) {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.liquidGold.opacity(lvl.glowIntensity),
                                     Color.liquidGoldDark.opacity(lvl.glowIntensity * 0.6)],
                            startPoint: .top, endPoint: .bottom
                        ))
                        .frame(width: 6, height: 6)
                    Text("Lv\(lvl.rawValue)")
                        .font(.custom("New York", size: 9))
                        .foregroundColor(.mutedGold)
                    Text(lvl.name)
                        .font(.custom("Songti SC", size: 9))
                        .foregroundColor(.mutedGold.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.liquidGold.opacity(0.18), lineWidth: 1))
        )
    }

    // MARK: - Helpers

    private func entriesFor(_ type: PouchType) -> [SuccessEntry] {
        entries.filter { $0.pouchType == type.rawValue }
    }

    private var careerCount: Int { entriesFor(.career).count }
    private var loveCount:   Int { entriesFor(.love).count }
    private var growthCount: Int { entriesFor(.growth).count }
}

// MARK: - PouchShelfCard

struct PouchShelfCard: View {
    let type: PouchType
    let count: Int
    let level: PouchLevel

    @State private var pressed = false

    private var nextMessage: String {
        guard let next = level.nextThreshold else { return "已达终极形态 ✦" }
        return "再存 \(next - count) 枚升至 \(PouchLevel(rawValue: level.rawValue + 1)?.name ?? "") 级"
    }

    var body: some View {
        ZStack {
            // 深色磨砂底板
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white.opacity(0.055))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .strokeBorder(
                            LinearGradient(
                                colors: [type.glowColor.opacity(0.45), type.primaryColor.opacity(0.12)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: type.glowColor.opacity(level.glowIntensity * 0.35),
                        radius: 20, x: 0, y: 8)

            HStack(spacing: 20) {
                PouchCardView(type: type, level: level, count: count)
                    .scaleEffect(0.72)
                    .frame(width: 90, height: 110)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Text(type.displayName)
                            .font(.custom("Songti SC", size: 16))
                            .fontWeight(.semibold)
                            .foregroundColor(.offWhite)
                        Spacer()
                        levelBadge
                    }
                    Text("\(count) 枚金币")
                        .font(.custom("New York", size: 22))
                        .fontWeight(.bold)
                        .foregroundStyle(LinearGradient.goldSheen)

                    Text(nextMessage)
                        .font(.custom("Songti SC", size: 11))
                        .foregroundColor(.mutedGold)
                        .tracking(0.5)

                    ProgressBar(type: type, count: count, level: level)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.mutedGold.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .scaleEffect(pressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: pressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded   { _ in pressed = false }
        )
    }

    private var levelBadge: some View {
        Text("Lv\(level.rawValue) · \(level.name)")
            .font(.custom("New York", size: 10))
            .tracking(1)
            .foregroundStyle(LinearGradient.goldSheen)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(Color.liquidGold.opacity(0.10))
                    .overlay(Capsule().strokeBorder(Color.liquidGold.opacity(0.38), lineWidth: 1))
            )
    }
}

// MARK: - ProgressBar

struct ProgressBar: View {
    let type: PouchType; let count: Int; let level: PouchLevel

    private var progress: Double {
        guard let next = level.nextThreshold else { return 1.0 }
        return Double(count - prevThreshold) / Double(next - prevThreshold)
    }

    private var prevThreshold: Int {
        switch level {
        case .sprout: 0; case .accumulate: 6; case .abundant: 16; case .overflow: 31
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.1)).frame(height: 4)
                Capsule()
                    .fill(LinearGradient(
                        colors: [type.primaryColor, type.glowColor],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .frame(width: geo.size.width * min(progress, 1.0), height: 4)
            }
        }
        .frame(height: 4)
    }
}

#Preview {
    VaultView()
        .modelContainer(for: SuccessEntry.self, inMemory: true)
        .environment(\.colorScheme, .dark)
}
