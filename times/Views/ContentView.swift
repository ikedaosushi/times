import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Channel.sortOrder) private var channels: [Channel]
    @State private var selectedChannel: Channel?
    @State private var showLeftPanel = false
    @State private var showRightPanel = false
    @State private var showBookmarks = false
    @State private var initialized = false

    var body: some View {
        ZStack {
            if showBookmarks {
                BookmarkView(showLeftPanel: $showLeftPanel)
            } else if let channel = selectedChannel {
                ChatView(channel: channel, showLeftPanel: $showLeftPanel, showRightPanel: $showRightPanel)
            } else {
                Color(.systemBackground)
            }

            if showLeftPanel {
                ChannelSidebarView(
                    selectedChannel: $selectedChannel,
                    showLeftPanel: $showLeftPanel,
                    showBookmarks: $showBookmarks
                )
                .transition(.move(edge: .leading))
            }

            if showRightPanel {
                DailySummaryView(
                    channel: selectedChannel,
                    showRightPanel: $showRightPanel
                )
                .transition(.move(edge: .trailing))
            }
        }
        .onChange(of: channels.count) { _, _ in
            if !initialized && !channels.isEmpty {
                selectedChannel = channels.first
                initialized = true
            }
        }
        .onAppear {
            ensureDefaultChannels()
            if !channels.isEmpty {
                selectedChannel = channels.first
                initialized = true
            }
        }
    }

    private func ensureDefaultChannels() {
        guard channels.isEmpty else { return }
        let main = Channel(name: "main", icon: "number", sortOrder: 0)
        let sub = Channel(name: "sub", icon: "number", sortOrder: 1)
        modelContext.insert(main)
        modelContext.insert(sub)
        try? modelContext.save()
    }
}
