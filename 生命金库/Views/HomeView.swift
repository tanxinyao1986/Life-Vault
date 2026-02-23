import SwiftUI
import SwiftData

/// 首页 · 每日铸币
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Query(sort: \SuccessEntry.timestamp, order: .reverse) private var entries: [SuccessEntry]

    @AppStorage("isPro")                   private var isPro              = false
    @AppStorage("proMilestone30Shown")     private var milestone30Shown   = false

    @State private var showInput    = false
    @State private var showBurst    = false
    @State private var showPaywall  = false
    @State private var quoteIndex   = 0
    @State private var quoteVisible = true
    @State private var coinPressed  = false

    private let cosmicQuotes: [LocalizedStringKey] = [
        "你本身就是丰盛的源头",
        "每一个当下，都是宇宙赠予你的礼物",
        "你的能量，正在吸引你渴望的一切",
        "相信自己，相信过程，相信丰盛",
        "今天每一步，都在铺就明天的康庄大道",
        "你值得拥有一切美好，毫无保留",
        "感恩是最强大的显化工具",
        "你的成功，早已写在星河之中",
        "丰盛不是目的地，是你出发的地方",
        "此刻的你，已是奇迹"
    ]

    private var todayQuote: LocalizedStringKey {
        let c = Calendar.current.dateComponents([.month, .day], from: Date())
        return cosmicQuotes[((c.month ?? 1) * 31 + (c.day ?? 1)) % cosmicQuotes.count]
    }

    private var todayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = String(localized: "M月d日")
        return formatter.string(from: Date())
    }

    var body: some View {
        ZStack {
            // ── Deep Spotlight 背景 ───────────────────────────────
            AppBackground()

            // ── 全屏金币雨（从天而降）────────────────────────────
            GoldRainView().opacity(0.50)

            // ── 内容 ─────────────────────────────────────────────
            VStack(spacing: 0) {
                topBar
                    .padding(.top, 56)
                    .padding(.horizontal, 24)

                cosmicQuoteCard
                    .padding(.horizontal, 28)
                    .padding(.top, 20)

                Spacer()

                coinSection

                Spacer()

                statsRow
                    .padding(.horizontal, 20)
                    .padding(.bottom, 90)
            }
            .frame(maxWidth: sizeClass == .regular ? 640 : .infinity)

            // ── 金币爆炸特效 ─────────────────────────────────────
            if showBurst {
                CoinBurstEffect { showBurst = false }
            }
        }
        .sheet(isPresented: $showInput) { EntryInputView() }
        .sheet(isPresented: $showPaywall) { PaywallView().environmentObject(StoreManager.shared) }
        .onAppear {
            scheduleQuoteRotation()
            WidgetDataStore.updateFromEntries(entries)
        }
        .onChange(of: entries) { _, newValue in
            WidgetDataStore.updateFromEntries(newValue)
        }
        .onChange(of: entries.count) { _, newCount in
            if !isPro && !milestone30Shown && newCount >= 30 {
                milestone30Shown = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    showPaywall = true
                }
            }
        }
    }

    // MARK: - Sub-views

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(greetingText)
                    .font(.custom("Songti SC", size: 13))
                    .foregroundColor(.mutedGold)
                    .tracking(1)
                Text("生命金库")
                    .font(.custom("Songti SC", size: 22))
                    .fontWeight(.semibold)
                    .foregroundStyle(LinearGradient(
                        colors: [.liquidGold, .liquidGoldDark],
                        startPoint: .leading, endPoint: .trailing
                    ))
            }
            Spacer()
            ZStack {
                Capsule()
                    .fill(Color.white.opacity(0.07))
                    .overlay(Capsule().strokeBorder(Color.liquidGold.opacity(0.35), lineWidth: 1))
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 11))
                        .foregroundColor(.liquidGold)
                    Text(String.loc("今日 · %@", todayLabel))
                        .font(.custom("Songti SC", size: 12))
                        .foregroundColor(.offWhite)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
            .frame(height: 32)
        }
    }

    private var cosmicQuoteCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.liquidGold.opacity(0.45),
                                         Color.liquidGold.opacity(0.10),
                                         Color.liquidGold.opacity(0.25)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )

            VStack(spacing: 10) {
                HStack(spacing: 6) {
                    Rectangle().fill(LinearGradient.goldSheen).frame(width: 24, height: 1)
                    Text("宇宙信使")
                        .font(.custom("New York", size: 11))
                        .tracking(3)
                        .foregroundColor(.mutedGold)
                    Rectangle().fill(LinearGradient.goldSheen).frame(width: 24, height: 1)
                }

                Text(todayQuote)
                    .font(.custom("Songti SC", size: 17))
                    .fontWeight(.medium)
                    .foregroundColor(.offWhite)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .tracking(2)
                    .opacity(quoteVisible ? 1 : 0)
                    .animation(.easeInOut(duration: 0.4), value: quoteVisible)
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 20)
        }
    }

    private var coinSection: some View {
        VStack(spacing: 12) {
            // ── 金币区域：粒子 → 光晕 → GIF 动图，全部叠合 ──
            // ZStack 裁剪，防止光晕溢出遮挡上下文字
            ZStack {
                // 中层：呼吸光晕，coinRadius=70 与 150pt 宽 GIF 中约 68pt 可见半径匹配
                CoinHaloView(coinRadius: sizeClass == .regular ? 95 : 70)

                // 前层：透明背景旋转金币 GIF
                // 150 * (688/464) ≈ 222，保持原始宽高比
                AnimatedGIFView(name: "coin_spin")
                    .frame(width: sizeClass == .regular ? 200 : 150,
                           height: sizeClass == .regular ? 296 : 222)
                    .contentShape(Rectangle())
                    .onTapGesture { handleCoinTap() }
            }
            .frame(width: sizeClass == .regular ? 370 : 280,
                   height: sizeClass == .regular ? 310 : 230)
            .clipped()   // 严格裁剪，光晕不超出此区域

            HStack(spacing: 6) {
                Text("👆")
                    .font(.system(size: 14))
                    Text("轻触金币，铸造属于你的今日财富")
                        .font(.custom("Songti SC", size: 13))
                        .tracking(1.5)
                        .foregroundColor(.liquidGold.opacity(0.9))
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatPill(icon: "sun.max.fill",  label: "今日", value: String.loc("%lld枚", todayCount),     color: .liquidGold)
            StatPill(icon: "calendar",       label: "累计", value: String.loc("%lld天", cumulativeDays), color: Color(hex: "FF6B35"))
            StatPill(icon: "star.fill",     label: "总计", value: String.loc("%lld枚", entries.count),  color: Color(hex: "9B59B6"))
        }
    }

    // MARK: - Actions

    private func handleCoinTap() {
        SoundManager.shared.play(.coinTap)
        coinPressed = true
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            coinPressed = false; showBurst = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { showInput = true }
    }

    private func scheduleQuoteRotation() {
        Timer.scheduledTimer(withTimeInterval: 8, repeats: true) { _ in
            withAnimation { quoteVisible = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                quoteIndex = (quoteIndex + 1) % cosmicQuotes.count
                withAnimation { quoteVisible = true }
            }
        }
    }

    // MARK: - Computed

    private var greetingText: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12:  String(localized: "早安，能量觉醒时刻")
        case 12..<18: String(localized: "午后，积累丰盛时光")
        case 18..<20: String(localized: "傍晚，回望今日高光")
        case 20..<24: String(localized: "夜晚，收拢今日光芒")
        default:      String(localized: "星夜，感恩每一刻")
        }
    }

    private var todayCount: Int {
        entries.filter { Calendar.current.isDateInToday($0.timestamp) }.count
    }

    /// 累计铸币天数：有记录的不重复日历天数
    private var cumulativeDays: Int {
        let cal        = Calendar.current
        let uniqueDays = Set(entries.map { cal.startOfDay(for: $0.timestamp) })
        return uniqueDays.count
    }
}

// MARK: - StatPill

struct StatPill: View {
    let icon: String; let label: String; let value: String; let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 16)).foregroundColor(color)
            Text(value)
                .font(.custom("New York", size: 18)).fontWeight(.semibold)
                .foregroundStyle(LinearGradient(colors: [color, color.opacity(0.7)],
                                               startPoint: .top, endPoint: .bottom))
            Text(label)
                .font(.custom("Songti SC", size: 11))
                .foregroundColor(.mutedGold)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(color.opacity(0.28), lineWidth: 1))
        )
    }
}

// MARK: - EntryRow

struct EntryRowView: View {
    let entry: SuccessEntry
    private var pouch: PouchType { PouchType(rawValue: entry.pouchType) ?? .career }

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(LinearGradient(colors: [pouch.primaryColor, pouch.secondaryColor],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: 3, height: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.content)
                    .font(.custom("Songti SC", size: 14))
                    .foregroundColor(.offWhite)
                    .lineLimit(2)
                Text("\(entry.timestamp.formatted(date: .abbreviated, time: .shortened)) · \(pouch.displayName)")
                    .font(.custom("Songti SC", size: 11))
                    .foregroundColor(.mutedGold)
            }
            Spacer()
            GoldCoinChip(diameter: 20)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.liquidGold.opacity(0.15), lineWidth: 1))
        )
    }
}

// MARK: - Button Style

struct CoinPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: SuccessEntry.self, inMemory: true)
        .environment(\.colorScheme, .dark)
}
