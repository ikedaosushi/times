import SwiftUI
import SwiftData
import PhotosUI

struct ThreadView: View {
    let parentPost: Post
    let channel: Channel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var editingPost: Post?
    @State private var deletingPost: Post?

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                List {
                    Section {
                        ThreadMessageCell(post: parentPost, isParent: true, onEdit: {
                            editingPost = parentPost
                        }, onDelete: nil)
                            .id(parentPost.id)
                            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                            .listRowSeparator(.hidden)
                    }
                    let sortedReplies = parentPost.sortedReplies
                    if !sortedReplies.isEmpty {
                        Section {
                            ForEach(Array(sortedReplies.enumerated()), id: \.element.id) { index, reply in
                                let prevPost: Post? = index > 0 ? sortedReplies[index - 1] : parentPost
                                ThreadMessageCell(post: reply, isParent: false, previousTime: prevPost?.createdAt, onEdit: {
                                    editingPost = reply
                                }, onDelete: {
                                    deletingPost = reply
                                })
                                    .id(reply.id)
                                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                                    .listRowSeparator(.hidden)
                            }
                        } header: {
                            HStack {
                                Rectangle()
                                    .fill(Color.secondary.opacity(0.2))
                                    .frame(height: 1)
                                Text("\(sortedReplies.count)件の返信")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .layoutPriority(1)
                                Rectangle()
                                    .fill(Color.secondary.opacity(0.2))
                                    .frame(height: 1)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .onChange(of: (parentPost.replies ?? []).count) { _, _ in
                    if let lastReply = parentPost.sortedReplies.last {  // re-sort needed here for new replies
                        withAnimation {
                            proxy.scrollTo(lastReply.id, anchor: .bottom)
                        }
                    }
                }
            }

            // Reply input
            VStack(spacing: 0) {
                if let imageData, let image = cachedSwiftUIImage(from: imageData, cacheKey: "thread-reply-preview") {
                    HStack {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 80)
                            .cornerRadius(8)
                        Button {
                            self.imageData = nil
                            self.selectedPhoto = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                }
                VStack(spacing: 0) {
                    TextField("返信を入力...", text: $text, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(1...4)
                        .font(.body)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                        .onSubmit { sendReply() }
                    HStack(spacing: 12) {
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Image(systemName: "photo")
                                .font(.body)
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                        .onChange(of: selectedPhoto) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    imageData = data
                                }
                            }
                        }
                        Spacer()
                        Button(action: sendReply) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title2)
                                .foregroundStyle(!text.isEmpty || imageData != nil ? .blue : Color.secondary.opacity(0.3))
                        }
                        .buttonStyle(.plain)
                        .disabled(text.isEmpty && imageData == nil)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
                .background(Color(.systemGray6))
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 12, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 12))
                .overlay(
                    UnevenRoundedRectangle(topLeadingRadius: 12, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 12)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
            }
            .background(.background)
            .padding(.top, 8)
        }
        .navigationTitle("スレッド")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") { dismiss() }
            }
        }
        .sheet(item: $editingPost) { post in
            PostEditView(post: post)
        }
        .alert("返信を削除", isPresented: Binding(
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

    private func sendReply() {
        guard !text.isEmpty || imageData != nil else { return }
        let replyText = text
        let replyImageData = imageData

        text = ""
        imageData = nil
        selectedPhoto = nil

        let reply = Post(text: replyText, imageData: replyImageData)
        reply.channel = channel
        reply.parentPost = parentPost
        modelContext.insert(reply)
    }
}

// MARK: - Thread Message Cell

struct ThreadMessageCell: View {
    let post: Post
    let isParent: Bool
    var previousTime: Date?
    let onEdit: () -> Void
    let onDelete: (() -> Void)?

    private var shouldShowTime: Bool {
        guard let previousTime else { return true }
        let calendar = Calendar.current
        return calendar.component(.hour, from: post.createdAt) != calendar.component(.hour, from: previousTime)
            || calendar.component(.minute, from: post.createdAt) != calendar.component(.minute, from: previousTime)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(post.createdAt, format: .dateTime.hour().minute())
                .font(.caption)
                .foregroundStyle(.tertiary)
                .opacity(shouldShowTime ? 1 : 0)
                .frame(width: 40, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                if !post.text.isEmpty {
                    Text(post.text)
                        .font(isParent ? .body.bold() : .body)
                }
                if let imageData = post.imageData,
                   let image = cachedSwiftUIImage(from: imageData, cacheKey: post.id.uuidString) {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 300, maxHeight: 300)
                        .cornerRadius(8)
                }
                if post.ogpTitle != nil || post.urlString != nil {
                    OGPPreviewCard(post: post)
                }
            }
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing) {
            if let onDelete {
                Button(role: .destructive, action: onDelete) {
                    Label("削除", systemImage: "trash")
                }
            }
        }
        .swipeActions(edge: .leading) {
            Button(action: onEdit) {
                Label("編集", systemImage: "pencil")
            }
            .tint(.orange)
        }
        .contextMenu {
            Button(action: onEdit) {
                Label("編集", systemImage: "pencil")
            }
            if let onDelete {
                Button(role: .destructive, action: onDelete) {
                    Label("削除", systemImage: "trash")
                }
            }
        }
    }
}
