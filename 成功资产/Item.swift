//
//  Item.swift
//  成功资产
//
//  Created by 昕尧 on 2026/2/20.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
