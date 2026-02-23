import SwiftUI
import Combine

// MARK: - FavoriteEntry & Store

struct FavoriteEntry: Codable, Identifiable {
    var id:       String
    var author:   String
    var pouchName: String
    var content:  String
    var savedAt:  Date
}

class FavoritesStore: ObservableObject {
    static let shared = FavoritesStore()

    /// 免费用户收藏上限
    static let freeLimit = 8

    @Published private(set) var entries: [FavoriteEntry] = []
    private let storageKey = "communityFavorites"

    init() { load() }

    /// 从 RemotePost 添加收藏；返回 false 表示已达免费上限
    @discardableResult
    func add(remotePost post: RemotePost) -> Bool {
        let sid = post.id.uuidString
        guard !isFavorited(sid) else { return true }
        let isPro = UserDefaults.standard.bool(forKey: "isPro")
        guard isPro || entries.count < FavoritesStore.freeLimit else { return false }
        entries.insert(FavoriteEntry(
            id: sid, author: post.nickname,
            pouchName: post.vaultName, content: post.content,
            savedAt: Date()
        ), at: 0)
        save()
        return true
    }

    func isFavorited(_ id: String) -> Bool { entries.contains { $0.id == id } }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([FavoriteEntry].self, from: data) {
            entries = saved
        }
    }
}

// MARK: - CommunityView

struct CommunityView: View {
    @StateObject private var viewModel      = CommunityViewModel()
    @StateObject private var favoritesStore = FavoritesStore.shared
    @State private var showFavorites        = false
    @State private var showPaywall          = false
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var gridColumns: [GridItem] {
        sizeClass == .regular
            ? [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]
            : [GridItem(.flexible())]
    }

    // 昨日金币 / 金币共振：基于日期种子的模拟数字，每日固定
    private var yesterdayCoinValue: String {
        let cal = Calendar.current
        let y   = cal.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let n   = (cal.ordinality(of: .day, in: .year, for: y) ?? 1) * 1337 % 12_000 + 30_000
        return formatWan(n)
    }
    private var globalResonanceValue: String {
        let cal = Calendar.current
        let y   = cal.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let n   = (cal.ordinality(of: .day, in: .year, for: y) ?? 1) * 971 % 6_000 + 10_000
        return formatWan(n)
    }
    private func formatWan(_ n: Int) -> String {
        n >= 10_000 ? String.loc("%.1f万", Double(n) / 10_000) : "\(n)"
    }

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                header
                    .padding(.top, 60)
                    .padding(.horizontal, 24)

                energyStats
                    .padding(.top, 14)
                    .padding(.horizontal, 24)
                    .frame(maxWidth: sizeClass == .regular ? 560 : .infinity)

                if viewModel.isLoading && viewModel.posts.isEmpty {
                    Spacer()
                    ProgressView()
                        .tint(.liquidGold)
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: gridColumns, spacing: 14) {
                            ForEach(viewModel.posts) { post in
                                CommunityCard(
                                    post:        post,
                                    isLiked:     viewModel.likedIds.contains(post.id),
                                    isFavorited: viewModel.favoritedIds.contains(post.id) ||
                                                 favoritesStore.isFavorited(post.id.uuidString)
                                ) {
                                    await viewModel.like(postId: post.id)
                                } onFavorite: {
                                    let ok = await viewModel.favorite(postId: post.id, post: post)
                                    if !ok { showPaywall = true }
                                    return ok
                                }
                            }
                        }
                        .padding(.horizontal, sizeClass == .regular ? 24 : 16)
                        .padding(.top, 18)
                        Color.clear.frame(height: 90)
                    }
                }
            }
        }
        .task {
            await viewModel.loadAll()
        }
        .onReceive(NotificationCenter.default.publisher(for: .communityNeedsRefresh)) { _ in
            Task { await viewModel.loadAll() }
        }
        .sheet(isPresented: $showFavorites) {
            FavoritesView(store: favoritesStore)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView().environmentObject(StoreManager.shared)
        }
    }

    // MARK: - Sub-views

    private var background: some View {
        ZStack {
            AppBackground()
            GoldRainView().opacity(0.50)
            RadialGradient(
                colors: [Color.sapphireBlue.opacity(0.06), .clear],
                center: .center, startRadius: 0, endRadius: 350
            )
            .ignoresSafeArea()
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("能量广场")
                    .font(.custom("Songti SC", size: 26)).fontWeight(.semibold)
                    .foregroundStyle(LinearGradient(
                        colors: [.liquidGold, .liquidGoldDark],
                        startPoint: .leading, endPoint: .trailing))
                Text("Energy Square · 高频正向场域")
                    .font(.custom("New York", size: 11)).tracking(1).foregroundColor(.mutedGold)
            }
            Spacer()
            onlineBadge
        }
    }

    private var onlineBadge: some View {
        HStack(spacing: 5) {
            Circle().fill(Color.green).frame(width: 6, height: 6)
            Text("全球在线")
                .font(.custom("Songti SC", size: 11)).foregroundColor(.mutedGold)
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(
            Capsule().fill(Color.white.opacity(0.055))
                .overlay(Capsule().strokeBorder(Color.green.opacity(0.3), lineWidth: 1))
        )
    }

    private var energyStats: some View {
        HStack(spacing: 10) {
            EnergyStatChip(icon: "sun.max.fill",       value: yesterdayCoinValue,
                           label: "昨日金币",           color: Color(hex: "FF6B35"))
            EnergyStatChip(icon: "waveform.path.ecg",  value: globalResonanceValue,
                           label: "金币共振",           color: .liquidGold)
            EnergyStatChip(
                icon: "star.fill",
                value: favoritesStore.entries.isEmpty ? "·" : "\(favoritesStore.entries.count)",
                label: "我的金库收藏",
                color: .liquidGold,
                onTap: { showFavorites = true }
            )
        }
    }
}

// MARK: - CommunityCard

struct CommunityCard: View {
    let post:        RemotePost
    let isLiked:     Bool
    let isFavorited: Bool
    let onLike:      () async -> Void
    let onFavorite:  () async -> Bool

    @State private var favorited:     Bool
    @State private var favoriteCount: Int
    @State private var liked:         Bool
    @State private var likeCount:     Int
    @State private var toastText:     String = ""
    @State private var showToast:     Bool   = false

    private static let likeToasts: [String] = [
        String(localized: "世界爱着你！"), String(localized: "你真的太棒了！"), String(localized: "你的生命力在一点点长大！"),
        String(localized: "丰盛正在向你涌来！"), String(localized: "你是宇宙的礼物！"), String(localized: "你的能量感染了我！"),
        String(localized: "继续发光，你超厉害！"), String(localized: "愿你越来越好！"), String(localized: "满满的正能量！"),
        String(localized: "你在一点点变强！"), String(localized: "这份勇气太珍贵了！"), String(localized: "宇宙看见了你的努力！"),
        String(localized: "你的故事在激励着我！"), String(localized: "幸运总会眷顾努力的你！"), String(localized: "你让世界更美好了一点！"),
        String(localized: "感谢你把正能量分享出来！"), String(localized: "你值得所有美好！"), String(localized: "每一步都算数！"),
        String(localized: "你是自己最好的礼物！"), String(localized: "愿你每天都有小确幸！")
    ]

    init(post: RemotePost, isLiked: Bool, isFavorited: Bool,
         onLike: @escaping () async -> Void, onFavorite: @escaping () async -> Bool) {
        self.post       = post
        self.isLiked    = isLiked
        self.isFavorited = isFavorited
        self.onLike     = onLike
        self.onFavorite = onFavorite
        _liked         = State(initialValue: isLiked)
        _likeCount     = State(initialValue: post.likesCount)
        _favorited     = State(initialValue: isFavorited)
        _favoriteCount = State(initialValue: 0)
    }

    // 根据金库名称推断颜色主题（兼容自定义名称）
    private var pouchColor: Color {
        let n = post.vaultName
        if n.contains("事业") || n.contains("财富") { return .cinnabarRed }
        if n.contains("爱") || n.contains("关系")   { return .roseGold    }
        if n.contains("成长") || n.contains("智慧") { return .sapphireBlue }
        return .liquidGold
    }

    var body: some View {
        ZStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 12) {
                authorRow
                Text(post.content)
                    .font(.custom("Songti SC", size: 14))
                    .foregroundColor(.offWhite).lineSpacing(5)
                actionBar
            }
            .padding(16)
            .background(cardBackground)

            if showToast {
                Text(toastText)
                    .font(.custom("Songti SC", size: 13)).foregroundColor(.liquidGold)
                    .padding(.horizontal, 14).padding(.vertical, 7)
                    .background(
                        Capsule().fill(Color.liquidGold.opacity(0.12))
                            .overlay(Capsule().strokeBorder(Color.liquidGold.opacity(0.45), lineWidth: 1))
                    )
                    .offset(y: -18)
                    .transition(.asymmetric(
                        insertion: .offset(y: 10).combined(with: .opacity),
                        removal:   .opacity
                    ))
            }
        }
    }

    private var authorRow: some View {
        HStack(spacing: 8) {
            // 头像
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [pouchColor.opacity(0.8), pouchColor.opacity(0.4)],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                Text(String(post.nickname.prefix(1)))
                    .font(.custom("Songti SC", size: 14)).fontWeight(.semibold).foregroundColor(.white)
            }
            .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 1) {
                let isMine = post.userId == SupabaseManager.shared.currentUserId
                Text(isMine ? "我（全球公开）" : post.nickname)
                    .font(.custom("Songti SC", size: 13)).fontWeight(.medium).foregroundColor(.offWhite)
                Text(post.vaultName)
                    .font(.custom("New York", size: 10)).tracking(1).foregroundColor(pouchColor.opacity(0.8))
            }
            Spacer()
            if likeCount > 200 {
                Image(systemName: "bolt.fill").font(.system(size: 10)).foregroundColor(.liquidGold)
            }
        }
    }

    private var actionBar: some View {
        HStack(spacing: 20) {
            // 收藏
            Button {
                guard !favorited else { return }
                favorited = true
                favoriteCount += 1
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showTemporaryToast(String(localized: "收藏为我的金库灵感"))
                Task {
                    let ok = await onFavorite()
                    if !ok {
                        favorited = false
                        favoriteCount -= 1
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: favorited ? "star.fill" : "star")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(favorited ? .liquidGold : .mutedGold)
                    if favoriteCount > 0 {
                        Text("\(favoriteCount)")
                            .font(.custom("New York", size: 12))
                            .foregroundColor(favorited ? .liquidGold : .mutedGold)
                    }
                }
            }
            .buttonStyle(.plain)

            // 点赞
            Button {
                guard !liked else { return }
                liked = true
                likeCount += 1
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                SoundManager.shared.play(.like)
                showTemporaryToast(Self.likeToasts.randomElement() ?? String(localized: "世界爱着你！"))
                Task { await onLike() }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: liked ? "heart.fill" : "heart")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.liquidGold)
                    if likeCount > 0 {
                        Text("\(likeCount)")
                            .font(.custom("New York", size: 12))
                            .foregroundColor(liked ? .liquidGold : .mutedGold)
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(Color.white.opacity(0.055))
            .overlay(
                RoundedRectangle(cornerRadius: 18).strokeBorder(
                    LinearGradient(
                        colors: [pouchColor.opacity((liked || favorited) ? 0.45 : 0.18), .clear],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ), lineWidth: 1.5
                )
            )
            .shadow(color: pouchColor.opacity((liked || favorited) ? 0.18 : 0.04),
                    radius: 12, x: 0, y: 4)
    }

    private func showTemporaryToast(_ text: String) {
        toastText = text
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { showToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.3)) { showToast = false }
        }
    }
}

// MARK: - EnergyStatChip

struct EnergyStatChip: View {
    let icon: String; let value: String; let label: String; let color: Color
    var onTap: (() -> Void)? = nil

    var body: some View {
        let chip = VStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 14)).foregroundColor(color)
            Text(value).font(.custom("New York", size: 14)).fontWeight(.bold).foregroundColor(.offWhite)
            Text(label).font(.custom("Songti SC", size: 10)).foregroundColor(.mutedGold)
                .lineLimit(1).minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.055))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(color.opacity(0.2), lineWidth: 1))
        )

        if let onTap { Button(action: onTap) { chip }.buttonStyle(.plain) }
        else { chip }
    }
}

// MARK: - FavoritesView

struct FavoritesView: View {
    @ObservedObject var store: FavoritesStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass

    private let df: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = String(localized: "M月d日 HH:mm"); return f
    }()

    var body: some View {
        ZStack {
            AppBackground()
            GoldRainView().opacity(0.50)
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Text("我的金库收藏")
                        .font(.custom("Songti SC", size: 17)).fontWeight(.medium)
                        .foregroundStyle(LinearGradient.goldSheen)
                    Spacer()
                    Button { dismiss() } label: {
                        ZStack {
                            Circle().fill(.ultraThinMaterial).frame(width: 32, height: 32)
                            Image(systemName: "xmark").font(.system(size: 12, weight: .semibold)).foregroundColor(.offWhite)
                        }
                    }
                }
                .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 16)

                if store.entries.isEmpty {
                    Spacer()
                    Image(systemName: "star").font(.system(size: 40)).foregroundColor(.mutedGold)
                    Text("还没有收藏").font(.custom("Songti SC", size: 16)).foregroundColor(.mutedGold).padding(.top, 12)
                    Text("在能量广场点击 ☆ 收藏打动你的日记")
                        .font(.custom("Songti SC", size: 13)).foregroundColor(.mutedGold)
                        .multilineTextAlignment(.center).padding(.horizontal, 40).padding(.top, 6)
                    Spacer(); Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(store.entries) { e in
                                FavoriteCard(entry: e, formatter: df)
                            }
                            Color.clear.frame(height: 40)
                        }
                        .padding(.horizontal, 16)
                        .frame(maxWidth: sizeClass == .regular ? 680 : .infinity)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                    }
                }
            }
        }
        .presentationCornerRadius(28)
    }
}

struct FavoriteCard: View {
    let entry: FavoriteEntry; let formatter: DateFormatter
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ZStack {
                    Circle().fill(LinearGradient(
                        colors: [Color.liquidGold.opacity(0.5), Color.liquidGoldDark.opacity(0.3)],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    Text(String(entry.author.prefix(1)))
                        .font(.custom("Songti SC", size: 12)).fontWeight(.semibold).foregroundColor(.white)
                }
                .frame(width: 28, height: 28)
                VStack(alignment: .leading, spacing: 1) {
                    Text(entry.author).font(.custom("Songti SC", size: 12)).fontWeight(.medium).foregroundColor(.offWhite)
                    Text(entry.pouchName).font(.custom("New York", size: 9)).tracking(1).foregroundColor(.mutedGold)
                }
                Spacer()
                Text(formatter.string(from: entry.savedAt)).font(.custom("New York", size: 10)).foregroundColor(.mutedGold)
            }
            Text(entry.content).font(.custom("Songti SC", size: 14)).foregroundColor(.offWhite).lineSpacing(4)
            Rectangle().fill(LinearGradient.goldSheen).frame(height: 0.5).opacity(0.3)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.055))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.liquidGold.opacity(0.2), lineWidth: 1))
        )
    }
}

#Preview {
    CommunityView()
}
