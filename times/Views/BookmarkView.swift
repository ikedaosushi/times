import SwiftUI
import SwiftData

struct BookmarkView: View {
    @Binding var showLeftPanel: Bool
    @Environment(\.modelContext) private var modelContext

    @Query(filter: #Predicate<Post> { $0.isBookmarked },
           sort: \Post.createdAt, order: .reverse)
    private var bookmarkedPosts: [Post]

    @State private var selectedThreadPost: Post?
    @State private var editingPost: Post?
    @State private var deletingPost: Post?

    var body: some View {
        VStack(spacing: 0) {
            navBar
            Divider()
            if bookmarkedPosts.isEmpty {
                emptyState
            } else {
                bookmarkList
            }
        }
        .sheet(item: $selectedThreadPost) { post in
            if let channel = post.channel {
                NavigationStack {
                    ThreadView(parentPost: post, channel: channel)
                }
            }
        }
        .sheet(item: $editingPost) { post in
            PostEditView(post: post)
        }
        .alert("投稿を削除", isPresented: Binding(
            get: { deletingPost != nil },
            set: { if !$0 { deletingPost = nil } }
        )) {
            Button("キャンセル", role: .cancel) { deletingPost = nil }
            Button("削除", role: .destructive) {
                if let post = deletingPost {
                    modelContext.delete(post)
                    deletingPost = nil
                }
            }
        } message: {
            if let post = deletingPost {
                Text("「\(post.text.prefix(30))」を削除しますか？")
            }
        }
    }

    private var navBar: some View {
        HStack {
            Button {
                showLeftPanel = true
            } label: {
                Image(systemName: "sidebar.left")
                    .font(.title3)
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "bookmark.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                Text("ブックマーク")
                    .font(.headline)
            }

            Spacer()

            // Spacer for symmetry
            Image(systemName: "sidebar.left")
                .font(.title3)
                .hidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.background)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "bookmark")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            Text("ブックマークした投稿がありません")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var bookmarkList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(bookmarkedPosts, id: \.id) { post in
                    VStack(alignment: .leading, spacing: 4) {
                        if let channelName = post.channel?.name {
                            HStack(spacing: 4) {
                                Image(systemName: "number")
                                    .font(.caption2)
                                Text(channelName)
                                    .font(.caption)
                            }
                            .foregroundStyle(.secondary)
                            .padding(.leading, 48)
                        }

                        ChatMessageCell(
                            post: post,
                            onThreadTap: { selectedThreadPost = post },
                            onEdit: { editingPost = post },
                            onDelete: { deletingPost = post },
                            onAIComment: { },
                            onBookmarkToggle: {
                                post.isBookmarked.toggle()
                            }
                        )
                    }
                    .padding(.horizontal, 16)

                    Divider()
                        .padding(.leading, 64)
                }
            }
        }
    }
}
