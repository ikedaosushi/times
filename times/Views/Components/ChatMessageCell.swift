import SwiftUI

struct ChatMessageCell: View {
    let post: Post
    var previousTime: Date?
    var previousTagIDs: Set<UUID>?
    var previousEventTagID: UUID?
    var previousLocationName: String?
    let onThreadTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onAIComment: () -> Void
    let onBookmarkToggle: () -> Void

    private var shouldShowTime: Bool {
        guard let previousTime else { return true }
        let calendar = Calendar.current
        return calendar.component(.hour, from: post.createdAt) != calendar.component(.hour, from: previousTime)
            || calendar.component(.minute, from: post.createdAt) != calendar.component(.minute, from: previousTime)
    }

    private var shouldShowTags: Bool {
        guard let tags = post.tags, !tags.isEmpty else { return false }
        let currentIDs = Set(tags.map(\.id))
        guard let previousTagIDs else { return true }
        return currentIDs != previousTagIDs
    }

    private var shouldShowEventTag: Bool {
        guard let eventTag = post.eventTag else { return false }
        return eventTag.id != previousEventTagID
    }

    private var shouldShowLocation: Bool {
        guard let name = post.locationName, !name.isEmpty else { return false }
        return name != previousLocationName
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            mainContent
            threadIndicator
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .contextMenu {
            Button(action: onThreadTap) {
                Label("スレッドで返信", systemImage: "bubble.left.and.bubble.right")
            }
            Button(action: onAIComment) {
                Label("AIにコメントさせる", systemImage: "sparkles")
            }
            Button(action: onBookmarkToggle) {
                Label(
                    post.isBookmarked ? "ブックマーク解除" : "ブックマーク",
                    systemImage: post.isBookmarked ? "bookmark.slash" : "bookmark"
                )
            }
            Button(action: onEdit) {
                Label("編集", systemImage: "pencil")
            }
            Button(role: .destructive, action: onDelete) {
                Label("削除", systemImage: "trash")
            }
        }
    }

    private var mainContent: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(post.createdAt, format: .dateTime.hour().minute())
                .font(.caption)
                .foregroundStyle(.tertiary)
                .opacity(shouldShowTime ? 1 : 0)
                .frame(width: 40, alignment: .leading)

            VStack(alignment: .leading, spacing: 6) {
                tagsRow
                eventTagRow
                textRow
                imageRow
                ogpRow
                locationRow
            }
        }
    }

    @ViewBuilder
    private var tagsRow: some View {
        if shouldShowTags, let tags = post.tags {
            HStack(spacing: 4) {
                ForEach(tags, id: \.id) { tag in
                    TagBadge(tag: tag)
                }
            }
        }
    }

    @ViewBuilder
    private var eventTagRow: some View {
        if shouldShowEventTag, let eventTag = post.eventTag {
            HStack(spacing: 4) {
                Image(systemName: "bookmark.fill")
                    .font(.caption2)
                Text(eventTag.name)
                    .font(.caption)
            }
            .foregroundStyle(eventTag.color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(eventTag.color.opacity(0.1))
            .cornerRadius(4)
        }
    }

    @ViewBuilder
    private var textRow: some View {
        if !post.text.isEmpty {
            HStack(alignment: .top, spacing: 4) {
                Text(post.text)
                    .font(.body)
                if post.isBookmarked {
                    Image(systemName: "bookmark.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    @ViewBuilder
    private var imageRow: some View {
        if let imageData = post.imageData,
           let image = cachedSwiftUIImage(from: imageData, cacheKey: post.id.uuidString) {
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 300, maxHeight: 300)
                .cornerRadius(8)
        }
    }

    @ViewBuilder
    private var ogpRow: some View {
        if post.ogpTitle != nil || post.urlString != nil {
            OGPPreviewCard(post: post)
        }
    }

    @ViewBuilder
    private var locationRow: some View {
        if shouldShowLocation {
            HStack(spacing: 4) {
                Image(systemName: "location.fill")
                    .font(.caption2)
                Text(post.locationName!)
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var threadIndicator: some View {
        let count = post.replyCount
        if count > 0 {
            Button(action: onThreadTap) {
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.caption2)
                    Text("\(count)件の返信")
                        .font(.caption)
                    if let lastReply = post.replies?.max(by: { $0.createdAt < $1.createdAt }) {
                        Text(lastReply.createdAt, format: .dateTime.month().day().hour().minute())
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .foregroundStyle(.blue)
                .padding(.leading, 48)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Tag Badge

struct TagBadge: View {
    let tag: Tag

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: tag.icon)
                .font(.caption2)
            Text(tag.name)
                .font(.caption)
        }
        .foregroundStyle(tag.color)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(tag.color.opacity(0.12))
        .cornerRadius(4)
    }
}
