//
//  Item.swift
//  PortFree
//
//  Created by JIANGJINGZHE on 22/4/2026.
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
