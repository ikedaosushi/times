import SwiftUI
import SwiftData

struct ChannelSidebarView: View {
    @Binding var selectedChannel: Channel?
    @Binding var showLeftPanel: Bool
    @Binding var showBookmarks: Bool
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Channel.sortOrder) private var channels: [Channel]
    @State private var showNewChannel = false
    @State private var newChannelName = ""
    @State private var showSettings = false
    @State private var channelToRename: Channel?
    @State private var renameText = ""
    @State private var channelToDelete: Channel?

    var body: some View {
        HStack(spacing: 0) {
            sidebarContent
            dismissArea
        }
        .alert("新しいチャンネル", isPresented: $showNewChannel) {
            TextField("チャンネル名", text: $newChannelName)
            Button("キャンセル", role: .cancel) { newChannelName = "" }
            Button("作成") {
                guard !newChannelName.isEmpty else { return }
                let channel = Channel(name: newChannelName, sortOrder: channels.count)
                modelContext.insert(channel)
                newChannelName = ""
            }
        }
        .alert("チャンネル名を変更", isPresented: Binding(
            get: { channelToRename != nil },
            set: { if !$0 { channelToRename = nil } }
        )) {
            TextField("チャンネル名", text: $renameText)
            Button("キャンセル", role: .cancel) { channelToRename = nil }
            Button("変更") {
                guard !renameText.isEmpty, let channel = channelToRename else { return }
                channel.name = renameText
                channelToRename = nil
            }
        }
        .alert("チャンネルを削除", isPresented: Binding(
            get: { channelToDelete != nil },
            set: { if !$0 { channelToDelete = nil } }
        )) {
            Button("キャンセル", role: .cancel) { channelToDelete = nil }
            Button("削除", role: .destructive) {
                guard let channel = channelToDelete else { return }
                if selectedChannel?.id == channel.id {
                    selectedChannel = channels.first(where: { $0.id != channel.id })
                }
                modelContext.delete(channel)
                channelToDelete = nil
            }
        } message: {
            Text("「\(channelToDelete?.name ?? "")」を削除しますか？チャンネル内の投稿もすべて削除されます。")
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    private var sidebarContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("times")
                    .font(.title2.bold())
                Spacer()
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    // ブックマーク
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showBookmarks = true
                            selectedChannel = nil
                            showLeftPanel = false
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "bookmark.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                                .frame(width: 16)
                            Text("ブックマーク")
                                .font(.body)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(showBookmarks ? Color.orange.opacity(0.1) : Color.clear)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)

                    Text("チャンネル")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 4)

                    ForEach(channels, id: \.id) { channel in
                        ChannelRow(
                            channel: channel,
                            isSelected: selectedChannel?.id == channel.id
                        ) {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                selectedChannel = channel
                                showBookmarks = false
                                showLeftPanel = false
                            }
                        }
                        .contextMenu {
                            Button {
                                renameText = channel.name
                                channelToRename = channel
                            } label: {
                                Label("名前を変更", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                channelToDelete = channel
                            } label: {
                                Label("削除", systemImage: "trash")
                            }
                        }
                    }

                    Button {
                        showNewChannel = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.caption)
                                .frame(width: 16)
                            Text("チャンネルを追加")
                                .font(.body)
                        }
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()
        }
        .frame(width: 280)
        .background(.background)
    }

    private var dismissArea: some View {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showLeftPanel = false
                }
            }
    }
}

// MARK: - Channel Row (lightweight)

private struct ChannelRow: View {
    let channel: Channel
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: channel.icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 16)
                Text(channel.name)
                    .font(.body)
                Spacer()
                if let date = channel.latestActivityDate {
                    Text(date, format: .dateTime.month().day())
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}
