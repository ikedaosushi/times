import SwiftUI
import SwiftData

struct TagFilterView: View {
    let tag: Tag
    @Environment(\.dismiss) private var dismiss

    private var sortedPosts: [Post] {
        (tag.posts ?? []).sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        NavigationStack {
            List(sortedPosts, id: \.id) { post in
                VStack(alignment: .leading, spacing: 4) {
                    Text(post.createdAt, format: .dateTime.year().month().day().hour().minute())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if !post.text.isEmpty {
                        Text(post.text)
                            .font(.body)
                            .lineLimit(3)
                    }
                    if post.imageData != nil {
                        HStack(spacing: 4) {
                            Image(systemName: "photo")
                                .font(.caption2)
                            Text("画像あり")
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }
                    if let locationName = post.locationName {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.caption2)
                            Text(locationName)
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("#\(tag.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
            .overlay {
                if sortedPosts.isEmpty {
                    ContentUnavailableView("投稿なし", systemImage: "tag", description: Text("このタグの投稿はまだありません"))
                }
            }
        }
    }
}
