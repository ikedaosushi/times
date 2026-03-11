import Foundation
import SwiftUI
import SwiftData

@Model
final class Tag {
    var id: UUID = UUID()
    var name: String = ""
    var colorHex: String = "007AFF"
    var icon: String = "tag"
    var createdAt: Date = Date()

    var posts: [Post]? = []

    var color: Color {
        Color(hex: colorHex) ?? .blue
    }

    init(name: String, colorHex: String = "007AFF", icon: String = "tag") {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.icon = icon
        self.createdAt = Date()
        self.posts = []
    }
}

// Default tag presets
extension Tag {
    static let presets: [(name: String, icon: String, colorHex: String)] = [
        ("レストラン", "fork.knife", "FF6B35"),
        ("カフェ", "cup.and.saucer.fill", "8B4513"),
        ("イベント", "star.fill", "FFD700"),
        ("仕事", "briefcase.fill", "4A90D9"),
        ("旅行", "airplane", "00BCD4"),
        ("買い物", "cart.fill", "4CAF50"),
        ("映画", "film", "9C27B0"),
        ("音楽", "music.note", "E91E63"),
        ("運動", "figure.run", "FF5722"),
        ("読書", "book.fill", "795548"),
    ]
}
