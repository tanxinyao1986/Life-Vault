import Foundation
import SwiftData

@Model
final class SuccessEntry {
    var id: UUID
    var content: String
    var timestamp: Date
    var pouchType: String          // PouchType.rawValue
    var isSharedToCommunity: Bool
    var communityLikes: Int

    init(content: String, pouchType: String) {
        self.id = UUID()
        self.content = content
        self.timestamp = Date()
        self.pouchType = pouchType
        self.isSharedToCommunity = false
        self.communityLikes = 0
    }
}
