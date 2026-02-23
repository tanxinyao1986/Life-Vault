import Foundation
import SwiftData

@Model
final class SuccessEntry {
    var id:                  UUID   = UUID()
    var content:             String = ""
    var timestamp:           Date   = Date()
    var pouchType:           String = ""   // PouchType.rawValue
    var isSharedToCommunity: Bool   = false
    var communityLikes:      Int    = 0

    init(content: String, pouchType: String) {
        self.id        = UUID()
        self.content   = content
        self.timestamp = Date()
        self.pouchType = pouchType
    }
}
