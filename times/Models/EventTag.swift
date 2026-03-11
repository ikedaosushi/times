import Foundation
import SwiftUI
import SwiftData

@Model
final class EventTag {
    var id: UUID = UUID()
    var name: String = ""
    var colorHex: String = "007AFF"
    var startDate: Date = Date()
    var endDate: Date?
    var isActive: Bool = true
    var createdAt: Date = Date()

    @Relationship(deleteRule: .nullify, inverse: \Post.eventTag)
    var posts: [Post]? = []

    var color: Color {
        Color(hex: colorHex) ?? .blue
    }

    var sortedPosts: [Post] {
        (posts ?? []).sorted { $0.createdAt < $1.createdAt }
    }

    init(name: String, colorHex: String = "007AFF") {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.startDate = Date()
        self.isActive = true
        self.createdAt = Date()
        self.posts = []
    }

    func close() {
        isActive = false
        endDate = Date()
    }
}
