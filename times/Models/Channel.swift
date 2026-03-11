import Foundation
import SwiftData

@Model
final class Channel {
    var id: UUID = UUID()
    var name: String = ""
    var icon: String = "number"
    var sortOrder: Int = 0
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \Post.channel)
    var posts: [Post]? = []

    var topLevelPosts: [Post] {
        (posts ?? []).filter { $0.isTopLevel }
    }

    var topLevelPostCount: Int {
        (posts ?? []).reduce(0) { count, post in
            post.isTopLevel ? count + 1 : count
        }
    }

    var sortedPosts: [Post] {
        topLevelPosts.sorted { $0.createdAt < $1.createdAt }
    }

    var latestActivityDate: Date? {
        (posts ?? []).lazy
            .filter { $0.isTopLevel }
            .map(\.createdAt)
            .max()
    }

    init(name: String, icon: String = "number", sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.sortOrder = sortOrder
        self.createdAt = Date()
        self.posts = []
    }
}
