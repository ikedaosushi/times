import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Tag.name) private var allTags: [Tag]
    @State private var searchText = ""
    @State private var selectedTag: Tag?
    @State private var searchScope: SearchScope = .all
    @State private var selectedThreadPost: Post?
    @State private var filteredPosts: [Post] = []
    @State private var searchTask: Task<Void, Never>?

    enum SearchScope: String, CaseIterable {
        case all = "すべて"
        case text = "テキスト"
        case location = "場所"
    }

    private func debouncedSearch() {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            updateFilteredPosts()
        }
    }

    private func updateFilteredPosts() {
        let query = searchText.localizedLowercase
        let hasQuery = !searchText.isEmpty

        // DB側でトップレベル投稿のみフィルター + テキスト検索
        var descriptor: FetchDescriptor<Post>

        if hasQuery {
            switch searchScope {
            case .all:
                let predicate = #Predicate<Post> { post in
                    post.parentPost == nil && (
                        post.text.localizedStandardContains(query)
                        || (post.locationName?.localizedStandardContains(query) ?? false)
                        || (post.ogpTitle?.localizedStandardContains(query) ?? false)
                    )
                }
                descriptor = FetchDescriptor<Post>(predicate: predicate, sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
            case .text:
                let predicate = #Predicate<Post> { post in
                    post.parentPost == nil && post.text.localizedStandardContains(query)
                }
                descriptor = FetchDescriptor<Post>(predicate: predicate, sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
            case .location:
                let predicate = #Predicate<Post> { post in
                    post.parentPost == nil && (post.locationName?.localizedStandardContains(query) ?? false)
                }
                descriptor = FetchDescriptor<Post>(predicate: predicate, sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
            }
        } else {
            let predicate = #Predicate<Post> { post in
                post.parentPost == nil
            }
            descriptor = FetchDescriptor<Post>(predicate: predicate, sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        }

        guard var posts = try? modelContext.fetch(descriptor) else { return }

        // タグフィルターはリレーションのためメモリ側で処理（件数は既にDB側で絞り込み済み）
        if let tag = selectedTag {
            posts = posts.filter { post in
                post.tags?.contains(where: { $0.id == tag.id }) ?? false
            }
        }

        filteredPosts = posts
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                tagFilterBar
                Divider()
                searchResults
            }
            .navigationTitle("検索")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
            .searchable(text: $searchText, prompt: "投稿を検索...")
            .searchScopes($searchScope) {
                ForEach(SearchScope.allCases, id: \.self) { scope in
                    Text(scope.rawValue).tag(scope)
                }
            }
            .onAppear { updateFilteredPosts() }
            .onChange(of: searchText) { _, _ in debouncedSearch() }
            .onChange(of: selectedTag?.id) { _, _ in updateFilteredPosts() }
            .onChange(of: searchScope) { _, _ in updateFilteredPosts() }
        }
        .sheet(item: $selectedThreadPost) { post in
            if let channel = post.channel {
                NavigationStack {
                    ThreadView(parentPost: post, channel: channel)
                }
            }
        }
    }

    private var tagFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                tagChip(label: "すべて", icon: "tag", isSelected: selectedTag == nil) {
                    selectedTag = nil
                }
                ForEach(allTags, id: \.id) { tag in
                    tagChip(
                        label: tag.name,
                        icon: tag.icon,
                        color: tag.color,
                        isSelected: selectedTag?.id == tag.id
                    ) {
                        selectedTag = selectedTag?.id == tag.id ? nil : tag
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private func tagChip(label: String, icon: String, color: Color = .secondary, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(label)
                    .font(.caption)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? color.opacity(0.2) : Color(.systemGray6))
            .foregroundStyle(isSelected ? color : .secondary)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? color.opacity(0.5) : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var searchResults: some View {
        Group {
            if filteredPosts.isEmpty {
                ContentUnavailableView.search(text: searchText.isEmpty ? (selectedTag?.name ?? "") : searchText)
            } else {
                List(filteredPosts, id: \.id) { post in
                    SearchResultRow(post: post)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedThreadPost = post
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                .listStyle(.plain)
            }
        }
    }
}

// MARK: - Search Result Row

private struct SearchResultRow: View {
    let post: Post

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                if let channelName = post.channel?.name {
                    HStack(spacing: 2) {
                        Image(systemName: "number")
                            .font(.caption2)
                        Text(channelName)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.blue)
                }

                Text(post.createdAt, format: .dateTime.year().month().day().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if post.replyCount > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.caption2)
                        Text("\(post.replyCount)")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
            }

            if !post.text.isEmpty {
                Text(post.text)
                    .font(.body)
                    .lineLimit(3)
            }

            HStack(spacing: 8) {
                if let tags = post.tags, !tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(tags, id: \.id) { tag in
                            TagBadge(tag: tag)
                        }
                    }
                }

                if post.imageData != nil {
                    HStack(spacing: 2) {
                        Image(systemName: "photo")
                            .font(.caption2)
                        Text("画像")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }

                if let locationName = post.locationName {
                    HStack(spacing: 2) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                        Text(locationName)
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
    }
}
