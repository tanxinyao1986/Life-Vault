import SwiftUI
import SwiftData

/// 能量广场 – 半开放正向能量交换场
/// 瀑布流展示；只有正向反馈（金粉、祝福语、点赞）
struct CommunityView: View {
    @Query(sort: \SuccessEntry.timestamp, order: .reverse) private var entries: [SuccessEntry]
    @State private var showGoldRain   = false
    @State private var goldRainId     = UUID()
    @State private var waveSeed       = 0.0

    // 将用户已投射的日记 + 模拟社区内容混合展示
    private var communityPosts: [CommunityPost] {
        var posts: [CommunityPost] = []

        // 用户自己的投射记录
        for e in entries.filter({ $0.isSharedToCommunity }) {
            posts.append(CommunityPost(
                id: e.id.uuidString,
                content: e.content,
                author: "我",
                pouchType: PouchType(rawValue: e.pouchType) ?? .career,
                likes: e.communityLikes,
                isOwn: true
            ))
        }

        // 填充模拟社区用户（让广场不显空）
        posts += CommunityPost.samples

        return posts
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
                            CommunityCard(post: post) {
                                triggerGoldRain()
                            }
                        }
                        Color.clear.frame(height: 90)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 18)
                }
            }

            // 金粉雨特效
            if showGoldRain {
                GoldRainView(count: 20)
                    .id(goldRainId)
            }
        }
    }

    // MARK: - Sub-views

    private var background: some View {
        ZStack {
            AppBackground()
            RadialGradient(
                colors: [Color.sapphireBlue.opacity(0.06), .clear],
                center: .center, startRadius: 0, endRadius: 350
            )
            .ignoresSafeArea()
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
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
                // 在线用户假数据
                onlineBadge
            }
        }
    }

    private var onlineBadge: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(Color.green)
                .frame(width: 6, height: 6)
            Text("1,288 在线")
                .font(.custom("Songti SC", size: 11))
                .foregroundColor(.mutedGold)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.055))
                .overlay(Capsule().strokeBorder(Color.green.opacity(0.3), lineWidth: 1))
        )
    }

    private var energyStats: some View {
        HStack(spacing: 10) {
            EnergyStatChip(icon: "flame.fill",
                           value: "42,871",
                           label: "今日金币",
                           color: Color(hex: "FF6B35"))
            EnergyStatChip(icon: "sparkles",
                           value: "9,653",
                           label: "投射",
                           color: .liquidGold)
            EnergyStatChip(icon: "heart.fill",
                           value: "128K",
                           label: "祝福",
                           color: .cinnabarRed)
        }
    }

    // MARK: - Actions

    private func triggerGoldRain() {
        goldRainId = UUID()
        showGoldRain = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            showGoldRain = false
        }
    }
}

// MARK: - Models

struct CommunityPost: Identifiable {
    let id: String
    let content: String
    let author: String
    let pouchType: PouchType
    var likes: Int
    var isOwn: Bool

    static let blessings = [
        "✨ 宇宙支持你！",
        "撒金粉！",
        "你真的很棒！",
        "继续发光！",
        "丰盛属于你！"
    ]

    static let samples: [CommunityPost] = [
        CommunityPost(id: "s1", content: "今天终于鼓起勇气给领导发了提案，被采纳了！",         author: "木木", pouchType: .career, likes: 128, isOwn: false),
        CommunityPost(id: "s2", content: "连续三十天晨间冥想打卡，感觉能量满满",              author: "晴天",  pouchType: .growth, likes: 87, isOwn: false),
        CommunityPost(id: "s3", content: "主动和久未联系的朋友发消息，对方很开心",              author: "星河",  pouchType: .love,   likes: 212, isOwn: false),
        CommunityPost(id: "s4", content: "完成了自己搁置了两年的小说第一章",                   author: "阿澄",  pouchType: .growth, likes: 341, isOwn: false),
        CommunityPost(id: "s5", content: "今天没有情绪化回应，平静解决了一次冲突",              author: "慧心",  pouchType: .love,   likes: 176, isOwn: false),
        CommunityPost(id: "s6", content: "接到了第一个外包单子，哪怕金额很小我也很骄傲",        author: "小鱼",  pouchType: .career, likes: 409, isOwn: false),
        CommunityPost(id: "s7", content: "学会了做一道新菜，家人说很好吃",                    author: "阳光",  pouchType: .love,   likes: 93, isOwn: false),
        CommunityPost(id: "s8", content: "今天准时起床，没有赖床，给自己鼓掌",                 author: "微风",  pouchType: .growth, likes: 267, isOwn: false),
    ]
}

// MARK: - CommunityCard

struct CommunityCard: View {
    let post: CommunityPost
    var onBless: () -> Void

    @State private var liked        = false
    @State private var likeCount    = 0
    @State private var blessingText = ""
    @State private var showBlessing = false

    init(post: CommunityPost, onBless: @escaping () -> Void) {
        self.post = post
        self.onBless = onBless
        _likeCount = State(initialValue: post.likes)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 12) {
                // 作者行
                HStack(spacing: 8) {
                    authorAvatar
                    VStack(alignment: .leading, spacing: 1) {
                        Text(post.isOwn ? "我（已投射）" : post.author)
                            .font(.custom("Songti SC", size: 13))
                            .fontWeight(.medium)
                            .foregroundColor(.offWhite)
                        Text(post.pouchType.displayName)
                            .font(.custom("New York", size: 10))
                            .tracking(1)
                            .foregroundColor(post.pouchType.primaryColor.opacity(0.8))
                    }
                    Spacer()
                    // 发光点（高能量标识）
                    if likeCount > 200 {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.liquidGold)
                    }
                }

                // 正文
                Text(post.content)
                    .font(.custom("Songti SC", size: 14))
                    .foregroundColor(.offWhite)
                    .lineSpacing(5)

                // 反馈栏
                HStack(spacing: 16) {
                    // 撒金粉
                    Button { bless() } label: {
                        HStack(spacing: 5) {
                            Image(systemName: liked ? "star.fill" : "star")
                                .font(.system(size: 13))
                                .foregroundColor(liked ? .liquidGold : .mutedGold)
                            Text("\(likeCount)")
                                .font(.custom("New York", size: 12))
                                .foregroundColor(.mutedGold)
                        }
                    }
                    .buttonStyle(.plain)

                    // 预设祝福
                    ForEach(["✨", "💛", "🌟"], id: \.self) { emoji in
                        Button {
                            sendBlessing(emoji)
                        } label: {
                            Text(emoji)
                                .font(.system(size: 18))
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()

                    // 颜色类型标
                    Capsule()
                        .fill(post.pouchType.primaryColor.opacity(0.15))
                        .overlay(
                            Capsule().strokeBorder(post.pouchType.primaryColor.opacity(0.35), lineWidth: 1)
                        )
                        .frame(width: 8, height: 8)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.055))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        post.pouchType.glowColor.opacity(liked ? 0.5 : 0.2),
                                        .clear
                                    ],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(
                        color: post.pouchType.glowColor.opacity(liked ? 0.2 : 0.05),
                        radius: 12, x: 0, y: 4
                    )
            )

            // 飘出的祝福文字
            if showBlessing {
                Text(blessingText)
                    .font(.custom("Songti SC", size: 13))
                    .foregroundColor(.liquidGold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.liquidGold.opacity(0.15))
                            .overlay(Capsule().strokeBorder(Color.liquidGold.opacity(0.4), lineWidth: 1))
                    )
                    .offset(x: -8, y: -36)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private var authorAvatar: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(
                    colors: [post.pouchType.primaryColor.opacity(0.8), post.pouchType.secondaryColor],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
            Text(String(post.author.prefix(1)))
                .font(.custom("Songti SC", size: 14))
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .frame(width: 34, height: 34)
    }

    private func bless() {
        guard !liked else { return }
        liked = true
        likeCount += 1
        onBless()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func sendBlessing(_ text: String) {
        blessingText = CommunityPost.blessings.randomElement() ?? text
        withAnimation(.spring(response: 0.4)) { showBlessing = true }
        UISelectionFeedbackGenerator().selectionChanged()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { showBlessing = false }
        }
    }
}

// MARK: - EnergyStatChip

struct EnergyStatChip: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
            Text(value)
                .font(.custom("New York", size: 14))
                .fontWeight(.bold)
                .foregroundColor(.offWhite)
            Text(label)
                .font(.custom("Songti SC", size: 10))
                .foregroundColor(.mutedGold)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.055))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    CommunityView()
        .modelContainer(for: SuccessEntry.self, inMemory: true)
}
