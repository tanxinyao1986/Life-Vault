import Foundation
import Supabase

// MARK: - Remote Models

struct RemotePost: Codable, Identifiable {
    var id:         UUID
    var userId:     UUID
    var nickname:   String
    var vaultName:  String
    var content:    String
    var likesCount: Int
    var createdAt:  Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId    = "user_id"
        case nickname
        case vaultName = "vault_name"
        case content
        case likesCount = "likes_count"
        case createdAt  = "created_at"
    }
}

// MARK: - Insert Payloads（显式 CodingKeys 确保蛇形列名匹配 Supabase）

private struct NewPostPayload: Encodable {
    let userId:     UUID
    let nickname:   String
    let vaultName:  String
    let content:    String
    let likesCount: Int = 0

    enum CodingKeys: String, CodingKey {
        case userId    = "user_id"
        case nickname
        case vaultName = "vault_name"
        case content
        case likesCount = "likes_count"
    }
}

private struct LikePayload: Encodable {
    let postId: UUID
    let userId: UUID

    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case userId = "user_id"
    }
}

private struct FavoritePayload: Encodable {
    let postId: UUID
    let userId: UUID

    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case userId = "user_id"
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let communityNeedsRefresh = Notification.Name("communityNeedsRefresh")
    static let communityShareFailed  = Notification.Name("communityShareFailed")
}

// MARK: - SupabaseManager

@MainActor
final class SupabaseManager {
    static let shared = SupabaseManager()

    let client = SupabaseClient(
        supabaseURL: URL(string: "https://rmvcwpvjyvsyyiunsoxe.supabase.co")!,
        supabaseKey: "sb_publishable_uq1lslc22VIac5vMoDERKQ_Buo-AKxQ",
        options: SupabaseClientOptions(
            auth: .init(emitLocalSessionAsInitialSession: true)
        )
    )

    /// 用于解码 Supabase 实时事件 record（snake_case → camelCase，ISO8601 日期）
    let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy  = .convertFromSnakeCase
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    var currentUserId: UUID? { client.auth.currentUser?.id }

    private init() {}

    // MARK: - Auth

    /// App 启动时调用：有 session 则复用，没有则匿名登录
    func signInIfNeeded() async {
        do {
            _ = try await client.auth.session
        } catch {
            do {
                try await client.auth.signInAnonymously()
            } catch {
                print("[Supabase] 匿名登录失败: \(String(describing: error))")
            }
        }
    }

    // MARK: - Posts

    func fetchPosts(limit: Int = 60) async throws -> [RemotePost] {
        try await client
            .from("community_posts")
            .select()
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    func sharePost(content: String, vaultName: String) async throws {
        // 若未登录则先尝试匿名登录一次
        if currentUserId == nil {
            await signInIfNeeded()
        }
        guard let userId = currentUserId else {
            throw SupabaseError.notAuthenticated
        }
        let nickname = UserDefaults.standard.string(forKey: "username")
            ?? String(localized: "生命金库用户")
        let payload = NewPostPayload(
            userId: userId, nickname: nickname,
            vaultName: vaultName, content: content
        )
        try await client.from("community_posts").insert(payload).execute()
    }

    enum SupabaseError: LocalizedError {
        case notAuthenticated
        var errorDescription: String? { "用户未登录，无法发布到社区" }
    }

    // MARK: - Likes

    func fetchLikedPostIds() async throws -> Set<UUID> {
        guard let userId = currentUserId else { return [] }
        struct Row: Decodable {
            var postId: UUID
            enum CodingKeys: String, CodingKey { case postId = "post_id" }
        }
        let rows: [Row] = try await client
            .from("post_likes")
            .select("post_id")
            .eq("user_id", value: userId)
            .execute()
            .value
        return Set(rows.map { $0.postId })
    }

    func likePost(_ postId: UUID) async throws {
        guard let userId = currentUserId else { return }
        try await client
            .from("post_likes")
            .insert(LikePayload(postId: postId, userId: userId))
            .execute()
    }

    // MARK: - Favorites

    func fetchFavoritedPostIds() async throws -> Set<UUID> {
        guard let userId = currentUserId else { return [] }
        struct Row: Decodable {
            var postId: UUID
            enum CodingKeys: String, CodingKey { case postId = "post_id" }
        }
        let rows: [Row] = try await client
            .from("post_favorites")
            .select("post_id")
            .eq("user_id", value: userId)
            .execute()
            .value
        return Set(rows.map { $0.postId })
    }

    func favoritePost(_ postId: UUID) async throws {
        guard let userId = currentUserId else { return }
        try await client
            .from("post_favorites")
            .insert(FavoritePayload(postId: postId, userId: userId))
            .execute()
    }
}
