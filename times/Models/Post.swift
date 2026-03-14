import Foundation
import SwiftData
import CoreLocation

@Model
final class Post {
    var id: UUID = UUID()
    var text: String = ""
    @Attribute(.externalStorage)
    var imageData: Data?
    var urlString: String?
    var ogpTitle: String?
    var ogpDescription: String?
    var ogpImageURL: String?
    var latitude: Double?
    var longitude: Double?
    var locationName: String?
    var isBookmarked: Bool = false
    var createdAt: Date = Date()

    var channel: Channel?
    var parentPost: Post?

    @Relationship(deleteRule: .cascade, inverse: \Post.parentPost)
    var replies: [Post]? = []

    @Relationship(deleteRule: .nullify, inverse: \Tag.posts)
    var tags: [Tag]? = []

    var isTopLevel: Bool {
        parentPost == nil
    }

    var sortedReplies: [Post] {
        (replies ?? []).sorted { $0.createdAt < $1.createdAt }
    }

    var replyCount: Int {
        (replies ?? []).count
    }

    var hasLocation: Bool {
        latitude != nil && longitude != nil
    }

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(
        text: String,
        imageData: Data? = nil,
        urlString: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        locationName: String? = nil
    ) {
        self.id = UUID()
        self.text = text
        self.imageData = imageData
        self.urlString = urlString
        self.latitude = latitude
        self.longitude = longitude
        self.locationName = locationName
        self.createdAt = Date()
        self.replies = []
        self.tags = []
    }
}
