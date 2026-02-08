//
//  Item.swift
//  SpellingGenius
//
//  Created by John Cieslik-Bridgen on 2026-02-08.
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
