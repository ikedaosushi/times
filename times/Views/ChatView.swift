import SwiftUI
import SwiftData

struct ChatView: View {
    @Bindable var channel: Channel
    @Binding var showLeftPanel: Bool
    @Binding var showRightPanel: Bool
    @Environment(\.modelContext) private var modelContext
    @State private var selectedThreadPost: Post?
    @State private var editingPost: Post?
    @State private var deletingPost: Post?
    @State private var scrollProxy: ScrollViewProxy?
    @State private var cachedGroupedByDate: [(Date, [Post])] = []
    @State private var aiGeneratingPost: Post?
    @State private var aiErrorMessage: String?
    @State private var showSearch = false
    @State private var tagEditingPost: Post?

    @Query private var settingsArray: [UserSettings]
    private var settings: UserSettings {
        settingsArray.first ?? UserSettings()
    }

    @State private var lastKnownPostCount: Int = 0

    private var topLevelPostCount: Int {
        channel.topLevelPostCount
    }

    private func recomputeGroupedByDate() {
        let topLevel = channel.sortedPosts
        let grouped = Dictionary(grouping: topLevel) { post in
            settings.logicalDate(for: post.createdAt)
        }
        cachedGroupedByDate = grouped.sorted { $0.key < $1.key }
        lastKnownPostCount = topLevel.count
    }

    private func scrollToBottom(animated: Bool = false) {
        if let lastPost = cachedGroupedByDate.last?.1.last {
            if animated {
                withAnimation(.easeOut(duration: 0.2)) {
                    scrollProxy?.scrollTo(lastPost.id, anchor: .bottom)
                }
            } else {
                scrollProxy?.scrollTo(lastPost.id, anchor: .bottom)
            }
        }
    }

    private func recomputeAndScroll() {
        recomputeGroupedByDate()
        scrollToBottom(animated: false)
    }

    var body: some View {
        VStack(spacing: 0) {
            chatNavBar
            Divider()
            messageList
            ChatInputBox(channel: channel, onSend: {
                recomputeAndScroll()
            })
            .padding(.top, 8)
        }
        .onAppear {
            recomputeAndScroll()
        }
        .onChange(of: topLevelPostCount) { oldCount, newCount in
            guard oldCount != newCount else { return }
            recomputeAndScroll()
        }
        .onChange(of: channel.id) { _, _ in
            recomputeAndScroll()
        }
        .sheet(isPresented: $showSearch) {
            SearchView()
        }
        .sheet(item: $selectedThreadPost) { post in
            NavigationStack {
                ThreadView(parentPost: post, channel: channel)
            }
        }
        .sheet(item: $editingPost) { post in
            PostEditView(post: post)
        }
        .sheet(item: $tagEditingPost) { post in
            NavigationStack {
                TagPickerView(
                    selectedTags: Binding(
                        get: { post.tags ?? [] },
                        set: { post.tags = $0 }
                    )
                )
            }
        }
        .overlay {
            if aiGeneratingPost != nil {
                Color.black.opacity(0.1)
                    .ignoresSafeArea()
                    .overlay {
                        ProgressView("AIがコメント生成中...")
                            .padding()
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .allowsHitTesting(false)
            }
        }
        .alert("エラー", isPresented: Binding(
            get: { aiErrorMessage != nil },
            set: { if !$0 { aiErrorMessage = nil } }
        )) {
            Button("OK") { aiErrorMessage = nil }
        } message: {
            if let msg = aiErrorMessage {
                Text(msg)
            }
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
                    recomputeGroupedByDate()
                }
            }
        } message: {
            if let post = deletingPost {
                Text("「\(post.text.prefix(30))」を削除しますか？")
            }
        }
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(cachedGroupedByDate.enumerated()), id: \.element.0) { dateIndex, pair in
                        let (date, posts) = pair
                        DateSeparator(date: date)
                            .padding(.top, 4)
                            .padding(.bottom, 2)
                        ForEach(Array(posts.enumerated()), id: \.element.id) { index, post in
                            let prevPost: Post? = {
                                if index > 0 { return posts[index - 1] }
                                if dateIndex > 0 { return cachedGroupedByDate[dateIndex - 1].1.last }
                                return nil
                            }()
                            ChatMessageCell(
                                post: post,
                                previousTime: prevPost?.createdAt,
                                previousTagIDs: prevPost?.tags?.map { Set($0.map(\.id)) },
                                previousLocationName: prevPost?.locationName,
                                onThreadTap: { selectedThreadPost = post },
                                onEdit: { editingPost = post },
                                onDelete: { deletingPost = post },
                                onAIComment: { generateAIComment(for: post) },
                                onBookmarkToggle: { post.isBookmarked.toggle() },
                                onTagEdit: { tagEditingPost = post }
                            )
                            .id(post.id)
                            .padding(.horizontal, 16)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .defaultScrollAnchor(.bottom)
            .onAppear { scrollProxy = proxy }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)) { _ in
                scrollToBottom(animated: true)
            }
        }
    }

    private func generateAIComment(for post: Post) {
        let customKey = settings.geminiAPIKey
        aiGeneratingPost = post
        let postText = post.text
        Task {
            do {
                let comment = try await AIService.shared.generateComment(for: postText, apiKey: customKey.isEmpty ? nil : customKey)
                let reply = Post(text: "🤖 \(comment)")
                reply.channel = channel
                reply.parentPost = post
                modelContext.insert(reply)
                aiGeneratingPost = nil
            } catch {
                aiGeneratingPost = nil
                aiErrorMessage = error.localizedDescription
            }
        }
    }

    private var chatNavBar: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showLeftPanel = true
                }
            } label: {
                Image(systemName: "sidebar.left")
                    .font(.title3)
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "number")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(channel.name)
                    .font(.headline)
            }

            Spacer()

            Button {
                showSearch = true
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.title3)
            }

            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showRightPanel = true
                }
            } label: {
                Image(systemName: "calendar.badge.clock")
                    .font(.title3)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.background)
    }
}

// MARK: - Date Separator

struct DateSeparator: View {
    let date: Date

    var body: some View {
        HStack {
            line
            Text(formattedDate)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(.background)
                        .overlay(Capsule().stroke(Color.secondary.opacity(0.3), lineWidth: 1))
                )
            line
        }
    }

    private var line: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.2))
            .frame(height: 1)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日 (E)"
        return formatter
    }()

    private var formattedDate: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "今日"
        } else if calendar.isDateInYesterday(date) {
            return "昨日"
        } else {
            return Self.dateFormatter.string(from: date)
        }
    }
}
