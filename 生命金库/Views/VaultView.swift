import SwiftUI
import SwiftData

// MARK: - VaultView

struct VaultView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Query(sort: \SuccessEntry.timestamp, order: .reverse) private var entries: [SuccessEntry]

    @State private var selectedIndex: Int = 0
    @State private var detailPouch: PouchType? = nil
    @State private var showPaywall = false

    @AppStorage("isPro") private var isPro = false

    @AppStorage("pouchName_career") private var careerName  = String(localized: "事业·财富")
    @AppStorage("pouchName_love")   private var loveName    = String(localized: "爱·关系")
    @AppStorage("pouchName_growth") private var growthName  = String(localized: "成长·智慧")

    @AppStorage("pouchIcon_career") private var careerIcon  = "briefcase.fill"
    @AppStorage("pouchIcon_love")   private var loveIcon    = "heart.fill"
    @AppStorage("pouchIcon_growth") private var growthIcon  = "leaf.fill"

    private let pouches = PouchType.allCases

    var body: some View {
        ZStack {
            AppBackground()
            GoldRainView().opacity(0.50)
            movingSpotlight   // 跟随选中项的背景光束

            VStack(spacing: 0) {
                headerSection
                    .padding(.top, 56)

                CoverFlowStage(
                    selectedIndex: $selectedIndex,
                    detailPouch: $detailPouch,
                    countFor: countFor(_:),
                    nameFor: nameFor(_:),
                    isPro: isPro,
                    onShowPaywall: { showPaywall = true }
                )
                .padding(.top, 12)

                Spacer(minLength: 0)

                CatalogNavBar(
                    selectedIndex: $selectedIndex,
                    countFor: countFor(_:),
                    nameFor: nameFor(_:),
                    iconFor: iconFor(_:)
                )
                .frame(maxWidth: sizeClass == .regular ? 600 : .infinity)
                .padding(.bottom, 96)
            }
        }
        .sheet(item: $detailPouch) { pouch in
            PouchDetailView(pouchType: pouch)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    // MARK: Sub-views

    private var headerSection: some View {
        VStack(spacing: 6) {
            Text("财富宝库")
                .font(.custom("Songti SC", size: 26))
                .fontWeight(.semibold)
                .foregroundStyle(LinearGradient(
                    colors: [.liquidGold, .liquidGoldDark],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
            Text("THE VAULT OF ABUNDANCE")
                .font(.custom("New York", size: 9))
                .tracking(3.5)
                .foregroundColor(.mutedGold)

            HStack(spacing: 5) {
                Image(systemName: "sparkles")
                    .font(.system(size: 10))
                    .foregroundColor(.liquidGold)
                Text(String.loc("生命资产总值：%lld 枚金币", entries.count))
                    .font(.custom("Songti SC", size: 12))
                    .foregroundColor(.offWhite.opacity(0.75))
                    .tracking(0.8)
            }
            .padding(.horizontal, 14).padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.07))
                    .overlay(Capsule().strokeBorder(Color.liquidGold.opacity(0.28), lineWidth: 1))
            )
        }
    }

    /// 大面积柔光，随选中项左右移动
    private var movingSpotlight: some View {
        GeometryReader { geo in
            let maxOffset = sizeClass == .regular ? 220.0 : geo.size.width * 0.34
            let cx = geo.size.width / 2 + CGFloat(selectedIndex - 1) * maxOffset
            RadialGradient(
                colors: [Color.liquidGold.opacity(0.10), .clear],
                center: UnitPoint(x: cx / geo.size.width, y: 0.32),
                startRadius: 0,
                endRadius: geo.size.width * 0.72
            )
            .ignoresSafeArea()
            .animation(.spring(response: 0.55, dampingFraction: 0.8), value: selectedIndex)
        }
    }

    private func countFor(_ type: PouchType) -> Int { entriesFor(type).count }
    private func entriesFor(_ type: PouchType) -> [SuccessEntry] {
        entries.filter { $0.pouchType == type.rawValue }
    }

    private func nameFor(_ type: PouchType) -> String {
        switch type {
        case .career: careerName
        case .love: loveName
        case .growth: growthName
        }
    }

    private func iconFor(_ type: PouchType) -> String {
        switch type {
        case .career: careerIcon
        case .love: loveIcon
        case .growth: growthIcon
        }
    }
}

// MARK: - CoverFlowStage

private struct CoverFlowStage: View {
    @Binding var selectedIndex: Int
    @Binding var detailPouch: PouchType?
    let countFor: (PouchType) -> Int
    let nameFor: (PouchType) -> String
    let isPro: Bool
    var onShowPaywall: () -> Void

    @State private var dragOffset: CGFloat = 0
    @Environment(\.horizontalSizeClass) private var sizeClass

    private let pouches = PouchType.allCases
    private var cardW: CGFloat { sizeClass == .regular ? 300 : 240 }
    private var cardH: CGFloat { sizeClass == .regular ? 460 : 400 }
    private var spacing: CGFloat { sizeClass == .regular ? 32 : 24 }

    var body: some View {
        GeometryReader { geo in
            let centerX = (geo.size.width - cardW) / 2

            HStack(spacing: spacing) {
                ForEach(pouches.indices, id: \.self) { i in
                    let rawDist = CGFloat(i - selectedIndex) - dragOffset / (cardW + spacing)
                    let absDist = abs(rawDist)
                    let scale   = max(0.74, 1.0 - absDist * 0.22)
                    let opacity = max(0.38, 1.0 - absDist * 0.50)
                    let count    = countFor(pouches[i])
                    let level    = PouchLevel.level(for: count, isPro: isPro)
                    let lv4Lock  = PouchLevel.isLV4Locked(count: count, isPro: isPro)

                    PouchStageCard(
                        type: pouches[i],
                        count: count,
                        level: level,
                        name: nameFor(pouches[i]),
                        isCenter: i == selectedIndex,
                        lv4Locked: lv4Lock,
                        onLockTap: onShowPaywall
                    )
                    .frame(width: cardW, height: cardH)
                    .scaleEffect(scale, anchor: .center)
                    .opacity(opacity)
                    .onTapGesture {
                        if i == selectedIndex {
                            SoundManager.shared.play(.openPouchDetail)
                            detailPouch = pouches[i]
                        } else {
                            withAnimation(.spring(response: 0.40, dampingFraction: 0.80)) {
                                selectedIndex = i
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            SoundManager.shared.play(.switchPouch)
                        }
                    }
                }
            }
            .offset(x: centerX - CGFloat(selectedIndex) * (cardW + spacing) + dragOffset)
            .animation(.spring(response: 0.40, dampingFraction: 0.80), value: selectedIndex)
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { val in dragOffset = val.translation.width * 0.52 }
                    .onEnded { val in
                        let threshold = cardW * 0.25
                        withAnimation(.spring(response: 0.40, dampingFraction: 0.80)) {
                            if val.predictedEndTranslation.width < -threshold,
                               selectedIndex < pouches.count - 1 {
                                selectedIndex += 1
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                SoundManager.shared.play(.switchPouch)
                            } else if val.predictedEndTranslation.width > threshold,
                                      selectedIndex > 0 {
                                selectedIndex -= 1
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                SoundManager.shared.play(.switchPouch)
                            }
                            dragOffset = 0
                        }
                    }
            )
        }
        .frame(height: cardH)
    }
}

// MARK: - PouchStageCard（无卡片容器，聚光灯浮空风格）

private struct PouchStageCard: View {
    let type: PouchType
    let count: Int
    let level: PouchLevel
    let name: String
    let isCenter: Bool
    var lv4Locked: Bool = false
    var onLockTap: () -> Void = {}

    @State private var glowPulse = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            // ── 聚光灯 + 钱袋图片（无任何卡片边框）──────────────
            ZStack {
                // 聚光灯：白色径向渐变，照亮钱袋
                RadialGradient(
                    colors: [
                        Color.white.opacity(isCenter ? 0.22 : 0.08),
                        Color.liquidGold.opacity(isCenter ? 0.12 : 0.02),
                        .clear
                    ],
                    center: .center,
                    startRadius: 5,
                    endRadius: 115
                )
                .frame(width: 230, height: 230)
                .blur(radius: 22)

                // 钱袋图片
                pouchImage
                    .resizable()
                    .scaledToFit()
                    .frame(height: 210)
                    .shadow(
                        color: type.glowColor.opacity(glowPulse ? 0.50 : 0.15),
                        radius: glowPulse ? 28 : 10, x: 0, y: 8
                    )
            }

            Spacer(minLength: 18)

            // ── 环形进度条 ─────────────────────────────────────
            CircularProgressRing(
                progress: level.progress(for: count),
                level: level,
                color: type.glowColor
            )
            .frame(width: 54, height: 54)

            Spacer(minLength: 14)

            // ── 组别名称 ───────────────────────────────────────
            Text(name)
                .font(.custom("Songti SC", size: 19))
                .fontWeight(.semibold)
                .foregroundStyle(LinearGradient.goldSheen)
                .tracking(1)

            // ── 金币数量 ───────────────────────────────────────
            Text(String.loc("%lld 枚金币", count))
                .font(.custom("New York", size: 14))
                .foregroundColor(.offWhite.opacity(0.65))
                .padding(.top, 5)

            // ── LV4 锁定提示（免费用户 200+ 枚）──────────────
            if lv4Locked {
                Button(action: onLockTap) {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                        Text("解锁 LV4 · 升级 Pro")
                            .font(.custom("Songti SC", size: 11))
                    }
                    .foregroundColor(.liquidGold.opacity(0.9))
                    .padding(.horizontal, 12).padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.liquidGold.opacity(0.10))
                            .overlay(Capsule().strokeBorder(Color.liquidGold.opacity(0.45), lineWidth: 1))
                    )
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
            }

            Spacer(minLength: 20)
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 2.5)
                .repeatForever(autoreverses: true)
            ) { glowPulse = true }
        }
    }

    /// 根据等级加载 01.png / 02.png / 03.png / 04.png
    private var pouchImage: Image {
        if let path = Bundle.main.path(forResource: level.imageName, ofType: "png"),
           let ui = UIImage(contentsOfFile: path) {
            return Image(uiImage: ui)
        }
        // 降级：用 SF Symbol 轮廓
        return Image(systemName: "bag.fill")
    }
}

// MARK: - CircularProgressRing

private struct CircularProgressRing: View {
    let progress: Double
    let level: PouchLevel
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.10), lineWidth: 2.5)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [color, color.opacity(0.40)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: progress)

            VStack(spacing: 1) {
                Text("Lv\(level.rawValue)")
                    .font(.custom("New York", size: 11))
                    .fontWeight(.semibold)
                    .foregroundColor(.liquidGold)
                Text(level.name)
                    .font(.custom("Songti SC", size: 8))
                    .foregroundColor(.mutedGold)
            }
        }
    }
}

// MARK: - CatalogNavBar（SF Symbol 图标 + 大字导航风格）

private struct CatalogNavBar: View {
    @Binding var selectedIndex: Int
    let countFor: (PouchType) -> Int
    let nameFor: (PouchType) -> String
    let iconFor: (PouchType) -> String

    private let pouches = PouchType.allCases

    var body: some View {
        VStack(spacing: 0) {
            // 顶部细分隔线
            Rectangle()
                .fill(Color.liquidGold.opacity(0.15))
                .frame(height: 0.5)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(pouches.indices, id: \.self) { i in
                        let isSelected = i == selectedIndex
                        let count      = countFor(pouches[i])

                        CatalogNavItem(
                            name: nameFor(pouches[i]),
                            iconName: iconFor(pouches[i]),
                            count: count,
                            isSelected: isSelected
                        )
                        .frame(width: 108)
                        .onTapGesture {
                            guard i != selectedIndex else { return }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.spring(response: 0.38, dampingFraction: 0.80)) {
                                selectedIndex = i
                            }
                            SoundManager.shared.play(.switchPouch)
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
            .padding(.top, 14)
            .padding(.bottom, 10)
        }
        .background(Color.clear)
    }
}

// MARK: - CatalogNavItem

private struct CatalogNavItem: View {
    let name: String
    let iconName: String
    let count: Int
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 7) {
            // ── 图标圆圈（小巧，约 36pt）─────────────────────────
            ZStack {
                Circle()
                    .fill(
                        isSelected
                            ? LinearGradient(
                                colors: [Color.liquidGold.opacity(0.22), Color.liquidGoldDark.opacity(0.12)],
                                startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(
                                colors: [Color.white.opacity(0.06)],
                                startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle().strokeBorder(
                            isSelected
                                ? Color.liquidGold.opacity(0.65)
                                : Color.white.opacity(0.10),
                            lineWidth: 1.2
                        )
                    )

                Image(systemName: iconName)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(
                        isSelected ? .liquidGold : Color(.systemGray2)
                    )
            }
            .scaleEffect(isSelected ? 1.06 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.70), value: isSelected)

            // ── 组别名称（主要文字，加大加粗）────────────────────
            Text(name)
                .font(.custom("Songti SC", size: 13))
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .offWhite : Color(.systemGray2))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)

            // ── 金币数（次要文字）─────────────────────────────────
            Text(String.loc("%lld 枚", count))
                .font(.custom("New York", size: 10))
                .foregroundColor(isSelected ? .liquidGold : Color(.systemGray3))
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Preview

#Preview {
    // 三个组别分别对应不同等级：
    //   事业·财富 → 3  条 → Lv1 萌芽  (01.png)
    //   爱·关系   → 55 条 → Lv2 积累  (02.png)
    //   成长·智慧 → 110条 → Lv3 丰盛  (03.png)
    let config    = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: SuccessEntry.self, configurations: config)
    let ctx       = container.mainContext

    for i in 0..<3   { ctx.insert(SuccessEntry(content: "事业成就 \(i)", pouchType: "career")) }
    for i in 0..<55  { ctx.insert(SuccessEntry(content: "爱的记录 \(i)", pouchType: "love"))   }
    for i in 0..<110 { ctx.insert(SuccessEntry(content: "成长点滴 \(i)", pouchType: "growth")) }

    return VaultView()
        .modelContainer(container)
        .environment(\.colorScheme, .dark)
}
