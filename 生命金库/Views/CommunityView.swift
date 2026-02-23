import SwiftUI
import SwiftData

// MARK: - FavoriteEntry & Store

struct FavoriteEntry: Codable, Identifiable {
    var id:           String
    var author:       String
    var pouchName:    String
    var content:      String
    var savedAt:      Date
}

class FavoritesStore: ObservableObject {
    static let shared = FavoritesStore()

    @Published private(set) var entries: [FavoriteEntry] = []
    private let storageKey = "communityFavorites"

    init() { load() }

    func add(post: CommunityPost) {
        guard !isFavorited(post.id) else { return }
        let entry = FavoriteEntry(
            id:        post.id,
            author:    post.isOwn ? "我" : post.author,
            pouchName: post.pouchType.displayName,
            content:   post.content,
            savedAt:   Date()
        )
        entries.insert(entry, at: 0)
        save()
    }

    func isFavorited(_ id: String) -> Bool {
        entries.contains { $0.id == id }
    }

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
    @Query(sort: \SuccessEntry.timestamp, order: .reverse) private var entries: [SuccessEntry]
    @StateObject private var favoritesStore = FavoritesStore.shared
    @State private var showFavorites = false

    private var communityPosts: [CommunityPost] {
        var posts: [CommunityPost] = []
        for e in entries.filter({ $0.isSharedToCommunity }) {
            posts.append(CommunityPost(
                id: e.id.uuidString, content: e.content,
                author: "我",
                pouchType: PouchType(rawValue: e.pouchType) ?? .career,
                likes: e.communityLikes, favorites: 0, isOwn: true
            ))
        }
        posts += CommunityPost.samples
        return posts
    }

    // 基于昨日日期种子生成固定模拟数字，每天变化
    private var yesterdayCoinValue: String {
        let cal = Calendar.current
        let yesterday = cal.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let day  = cal.ordinality(of: .day, in: .year, for: yesterday) ?? 1
        let year = cal.component(.year, from: yesterday)
        let n    = (day * 1337 + year * 53 + 28_000) % 12_000 + 30_000
        return formatWan(n)
    }

    private var globalResonanceValue: String {
        let cal = Calendar.current
        let yesterday = cal.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let day  = cal.ordinality(of: .day, in: .year, for: yesterday) ?? 1
        let year = cal.component(.year, from: yesterday)
        let n    = (day * 971 + year * 37 + 8_000) % 6_000 + 10_000
        return formatWan(n)
    }

    private func formatWan(_ n: Int) -> String {
        if n >= 10_000 {
            let wan = Double(n) / 10_000.0
            return String(format: "%.1f万", wan)
        }
        return "\(n)"
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

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 14) {
                        ForEach(communityPosts) { post in
                            CommunityCard(post: post, favoritesStore: favoritesStore)
                        }
                        Color.clear.frame(height: 90)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 18)
                }
            }
        }
        .sheet(isPresented: $showFavorites) {
            FavoritesView(store: favoritesStore)
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
                    .font(.custom("Songti SC", size: 26))
                    .fontWeight(.semibold)
                    .foregroundStyle(LinearGradient(
                        colors: [.liquidGold, .liquidGoldDark],
                        startPoint: .leading, endPoint: .trailing
                    ))
                Text("Energy Square · 高频正向场域")
                    .font(.custom("New York", size: 11))
                    .tracking(1)
                    .foregroundColor(.mutedGold)
            }
            Spacer()
            onlineBadge
        }
    }

    private var onlineBadge: some View {
        HStack(spacing: 5) {
            Circle().fill(Color.green).frame(width: 6, height: 6)
            Text("1,288 在线")
                .font(.custom("Songti SC", size: 11))
                .foregroundColor(.mutedGold)
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(
            Capsule().fill(Color.white.opacity(0.055))
                .overlay(Capsule().strokeBorder(Color.green.opacity(0.3), lineWidth: 1))
        )
    }

    private var energyStats: some View {
        HStack(spacing: 10) {
            EnergyStatChip(
                icon: "sun.max.fill",
                value: yesterdayCoinValue,
                label: "昨日金币",
                color: Color(hex: "FF6B35")
            )
            EnergyStatChip(
                icon: "waveform.path.ecg",
                value: globalResonanceValue,
                label: "金币共振",
                color: .liquidGold
            )
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

// MARK: - Models

struct CommunityPost: Identifiable {
    let id: String
    let content: String
    let author: String
    let pouchType: PouchType
    var likes:     Int
    var favorites: Int
    var isOwn: Bool

    static let likeToasts: [String] = [
        "世界爱着你！",
        "你真的太棒了！",
        "你的生命力在一点点长大！",
        "丰盛正在向你涌来！",
        "你是宇宙的礼物！",
        "你的能量感染了我！",
        "继续发光，你超厉害！",
        "愿你越来越好！",
        "满满的正能量！",
        "你在一点点变强！",
        "这份勇气太珍贵了！",
        "宇宙看见了你的努力！",
        "你的故事在激励着我！",
        "幸运总会眷顾努力的你！",
        "你让世界更美好了一点！",
        "感谢你把正能量分享出来！",
        "你值得所有美好！",
        "每一步都算数！",
        "你是自己最好的礼物！",
        "愿你每天都有小确幸！"
    ]

    static let samples: [CommunityPost] = [
        CommunityPost(id: "s1", content: "今天终于鼓起勇气给领导发了提案，被采纳了！",  author: "木木", pouchType: .career, likes: 128, favorites: 43,  isOwn: false),
        CommunityPost(id: "s2", content: "连续三十天晨间冥想打卡，感觉能量满满",        author: "晴天", pouchType: .growth, likes: 87,  favorites: 0,   isOwn: false),
        CommunityPost(id: "s3", content: "主动和久未联系的朋友发消息，对方很开心",       author: "星河", pouchType: .love,   likes: 212, favorites: 76,  isOwn: false),
        CommunityPost(id: "s4", content: "完成了自己搁置了两年的小说第一章",           author: "阿澄", pouchType: .growth, likes: 341, favorites: 129, isOwn: false),
        CommunityPost(id: "s5", content: "今天没有情绪化回应，平静解决了一次冲突",       author: "慧心", pouchType: .love,   likes: 176, favorites: 58,  isOwn: false),
        CommunityPost(id: "s6", content: "接到了第一个外包单子，哪怕金额很小我也很骄傲",  author: "小鱼", pouchType: .career, likes: 409, favorites: 201, isOwn: false),
        CommunityPost(id: "s7", content: "学会了做一道新菜，家人说很好吃",            author: "阳光", pouchType: .love,   likes: 93,  favorites: 0,   isOwn: false),
        CommunityPost(id: "s8", content: "今天准时起床，没有赖床，给自己鼓掌",         author: "微风", pouchType: .growth, likes: 267, favorites: 88,  isOwn: false),
    ]
}

// MARK: - CommunityCard

struct CommunityCard: View {
    let post: CommunityPost
    @ObservedObject var favoritesStore: FavoritesStore

    @State private var favorited     = false
    @State private var favoriteCount = 0
    @State private var liked         = false
    @State private var likeCount     = 0
    @State private var toastText     = ""
    @State private var showToast     = false

    init(post: CommunityPost, favoritesStore: FavoritesStore) {
        self.post           = post
        self.favoritesStore = favoritesStore
        _favoriteCount      = State(initialValue: post.favorites)
        _likeCount          = State(initialValue: post.likes)
        _favorited          = State(initialValue: favoritesStore.isFavorited(post.id))
    }

    var body: some View {
        ZStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 12) {
                authorRow
                Text(post.content)
                    .font(.custom("Songti SC", size: 14))
                    .foregroundColor(.offWhite)
                    .lineSpacing(5)
                actionBar
            }
            .padding(16)
            .background(cardBackground)

            if showToast {
                Text(toastText)
                    .font(.custom("Songti SC", size: 13))
                    .foregroundColor(.liquidGold)
                    .padding(.horizontal, 14).padding(.vertical, 7)
                    .background(
                        Capsule().fill(Color.liquidGold.opacity(0.12))
                            .overlay(Capsule().strokeBorder(Color.liquidGold.opacity(0.45), lineWidth: 1))
                    )
                    .offset(y: -18)
                    .transition(.asymmetric(
                        insertion: .offset(y: 10).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
    }

    private var authorRow: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [post.pouchType.primaryColor.opacity(0.8), post.pouchType.secondaryColor],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                Text(String(post.author.prefix(1)))
                    .font(.custom("Songti SC", size: 14)).fontWeight(.semibold).foregroundColor(.white)
            }
            .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 1) {
                Text(post.isOwn ? "我（已投射）" : post.author)
                    .font(.custom("Songti SC", size: 13)).fontWeight(.medium).foregroundColor(.offWhite)
                Text(post.pouchType.displayName)
                    .font(.custom("New York", size: 10)).tracking(1)
                    .foregroundColor(post.pouchType.primaryColor.opacity(0.8))
            }
            Spacer()
            if likeCount > 200 {
                Image(systemName: "bolt.fill").font(.system(size: 10)).foregroundColor(.liquidGold)
            }
        }
    }

    private var actionBar: some View {
        HStack(spacing: 20) {
            Button { collectAction() } label: {
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

            Button { likeAction() } label: {
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
                        colors: [post.pouchType.glowColor.opacity((liked || favorited) ? 0.45 : 0.18), .clear],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ), lineWidth: 1.5
                )
            )
            .shadow(color: post.pouchType.glowColor.opacity((liked || favorited) ? 0.18 : 0.04),
                    radius: 12, x: 0, y: 4)
    }

    private func collectAction() {
        guard !favorited else { return }
        favorited = true
        favoriteCount += 1
        favoritesStore.add(post: post)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        showTemporaryToast("收藏为我的金库灵感")
    }

    private func likeAction() {
        guard !liked else { return }
        liked = true
        likeCount += 1
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        showTemporaryToast(CommunityPost.likeToasts.randomElement() ?? "世界爱着你！")
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
    let icon:  String
    let value: String
    let label: String
    let color: Color
    var onTap: (() -> Void)? = nil

    var body: some View {
        let content = VStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 14)).foregroundColor(color)
            Text(value)
                .font(.custom("New York", size: 14)).fontWeight(.bold).foregroundColor(.offWhite)
            Text(label)
                .font(.custom("Songti SC", size: 10)).foregroundColor(.mutedGold)
                .lineLimit(1).minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.055))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(color.opacity(0.2), lineWidth: 1))
        )

        if let onTap {
            Button(action: onTap) { content }
                .buttonStyle(.plain)
        } else {
            content
        }
    }
}

// MARK: - FavoritesView

struct FavoritesView: View {
    @ObservedObject var store: FavoritesStore
    @Environment(\.dismiss) private var dismiss

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "M月d日 HH:mm"
        return f
    }()

    var body: some View {
        ZStack {
            AppBackground()
            GoldRainView().opacity(0.50)

            VStack(spacing: 0) {
                // 顶栏
                HStack {
                    Spacer()
                    Text("我的金库收藏")
                        .font(.custom("Songti SC", size: 17))
                        .fontWeight(.medium)
                        .foregroundStyle(LinearGradient.goldSheen)
                    Spacer()
                    Button { dismiss() } label: {
                        ZStack {
                            Circle().fill(.ultraThinMaterial).frame(width: 32, height: 32)
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.offWhite)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

                if store.entries.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(store.entries) { entry in
                                FavoriteCard(entry: entry, formatter: dateFormatter)
                            }
                            Color.clear.frame(height: 40)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                    }
                }
            }
        }
        .presentationCornerRadius(28)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "star")
                .font(.system(size: 40)).foregroundColor(.mutedGold)
            Text("还没有收藏")
                .font(.custom("Songti SC", size: 16)).foregroundColor(.mutedGold)
            Text("在能量广场点击 ☆ 收藏打动你的日记")
                .font(.custom("Songti SC", size: 13)).foregroundColor(.mutedGold)
                .multilineTextAlignment(.center).padding(.horizontal, 40)
            Spacer()
            Spacer()
        }
    }
}

// MARK: - FavoriteCard

struct FavoriteCard: View {
    let entry:     FavoriteEntry
    let formatter: DateFormatter

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 作者 + 金库
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.liquidGold.opacity(0.5), Color.liquidGoldDark.opacity(0.3)],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                    Text(String(entry.author.prefix(1)))
                        .font(.custom("Songti SC", size: 12)).fontWeight(.semibold).foregroundColor(.white)
                }
                .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 1) {
                    Text(entry.author)
                        .font(.custom("Songti SC", size: 12)).fontWeight(.medium).foregroundColor(.offWhite)
                    Text(entry.pouchName)
                        .font(.custom("New York", size: 9)).tracking(1).foregroundColor(.mutedGold)
                }
                Spacer()
                Text(formatter.string(from: entry.savedAt))
                    .font(.custom("New York", size: 10)).foregroundColor(.mutedGold)
            }

            // 日记内容
            Text(entry.content)
                .font(.custom("Songti SC", size: 14))
                .foregroundColor(.offWhite)
                .lineSpacing(4)

            // 金色底线装饰
            Rectangle()
                .fill(LinearGradient.goldSheen)
                .frame(height: 0.5)
                .opacity(0.3)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.055))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.liquidGold.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    CommunityView()
        .modelContainer(for: SuccessEntry.self, inMemory: true)
}
