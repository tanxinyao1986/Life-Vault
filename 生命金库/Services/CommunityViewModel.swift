import Foundation
import Supabase

@MainActor
final class CommunityViewModel: ObservableObject {

    @Published var posts:        [RemotePost] = []
    @Published var isLoading:    Bool         = false
    @Published var likedIds:     Set<UUID>    = []
    @Published var favoritedIds: Set<UUID>    = []
    @Published var errorMsg:     String?      = nil

    private let manager = SupabaseManager.shared
    private var realtimeTask: Task<Void, Never>?

    deinit { realtimeTask?.cancel() }

    // MARK: - Load

    func loadAll() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let p = manager.fetchPosts()
            async let l = manager.fetchLikedPostIds()
            async let f = manager.fetchFavoritedPostIds()
            (posts, likedIds, favoritedIds) = try await (p, l, f)
        } catch {
            errorMsg = "网络异常，显示示例内容"
            if posts.isEmpty { posts = RemotePost.placeholders }
        }
    }

    // MARK: - Realtime

    /// 订阅 community_posts 新插入，实时追加到列表顶部
    func subscribeToNewPosts() {
        realtimeTask?.cancel()
        realtimeTask = Task { [weak self] in
            guard let self else { return }
            let channel = manager.client.channel("community-feed")
            let inserts = await channel.postgresChange(
                InsertAction.self,
                schema: "public",
                table: "community_posts"
            )
            await channel.subscribe()
            for await insert in inserts {
                guard !Task.isCancelled else { break }
                if let post = self.decode(insert.record) {
                    // 去重：自己刚发的帖子可能已在列表里
                    guard !self.posts.contains(where: { $0.id == post.id }) else { continue }
                    self.posts.insert(post, at: 0)
                }
            }
        }
    }

    // MARK: - Actions

    func like(postId: UUID) async {
        guard !likedIds.contains(postId) else { return }
        likedIds.insert(postId)
        // 乐观更新本地计数
        if let i = posts.firstIndex(where: { $0.id == postId }) {
            posts[i].likesCount += 1
        }
        try? await manager.likePost(postId)
    }

    func favorite(postId: UUID, post: RemotePost) async {
        guard !favoritedIds.contains(postId) else { return }
        favoritedIds.insert(postId)
        try? await manager.favoritePost(postId)
        // 同步写入本地收藏缓存
        FavoritesStore.shared.add(remotePost: post)
    }

    // MARK: - Helpers

    private func decode(_ record: [String: AnyJSON]) -> RemotePost? {
        guard let data = try? JSONEncoder().encode(record) else { return nil }
        return try? manager.decoder.decode(RemotePost.self, from: data)
    }
}

// MARK: - Placeholder fallback

extension RemotePost {
    static let placeholders: [RemotePost] = {
        let now = Date()
        return [
            RemotePost(id: UUID(), userId: UUID(), nickname: "木木",  vaultName: "事业·财富", content: "今天终于鼓起勇气给领导发了提案，被采纳了！",  likesCount: 128, createdAt: now),
            RemotePost(id: UUID(), userId: UUID(), nickname: "晴天",  vaultName: "成长·智慧", content: "连续三十天晨间冥想打卡，感觉能量满满",         likesCount: 87,  createdAt: now),
            RemotePost(id: UUID(), userId: UUID(), nickname: "星河",  vaultName: "爱·关系",   content: "主动和久未联系的朋友发消息，对方很开心",       likesCount: 212, createdAt: now),
            RemotePost(id: UUID(), userId: UUID(), nickname: "阿澄",  vaultName: "成长·智慧", content: "完成了自己搁置了两年的小说第一章",             likesCount: 341, createdAt: now),
            RemotePost(id: UUID(), userId: UUID(), nickname: "慧心",  vaultName: "爱·关系",   content: "今天没有情绪化回应，平静解决了一次冲突",       likesCount: 176, createdAt: now),
            RemotePost(id: UUID(), userId: UUID(), nickname: "小鱼",  vaultName: "事业·财富", content: "接到了第一个外包单子，哪怕金额很小我也很骄傲",  likesCount: 409, createdAt: now),
            RemotePost(id: UUID(), userId: UUID(), nickname: "阳光",  vaultName: "爱·关系",   content: "学会了做一道新菜，家人说很好吃",             likesCount: 93,  createdAt: now),
            RemotePost(id: UUID(), userId: UUID(), nickname: "微风",  vaultName: "成长·智慧", content: "今天准时起床，没有赖床，给自己鼓掌",           likesCount: 267, createdAt: now),
        ]
    }()
}
