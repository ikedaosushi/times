import SwiftUI
import SwiftData

struct DailySummaryView: View {
    let channel: Channel?
    @Binding var showRightPanel: Bool
    @Query private var settingsArray: [UserSettings]
    @State private var cachedGrouped: [(Date, [Post])] = []

    private var settings: UserSettings {
        settingsArray.first ?? UserSettings()
    }

    private func recompute() {
        guard let channel else {
            cachedGrouped = []
            return
        }
        let topLevel = channel.sortedPosts
        let grouped = Dictionary(grouping: topLevel) { post in
            settings.logicalDate(for: post.createdAt)
        }
        cachedGrouped = grouped.sorted { $0.key > $1.key }
    }

    var body: some View {
        HStack(spacing: 0) {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showRightPanel = false
                    }
                }

            panelContent
        }
        .onAppear { recompute() }
    }

    private var panelContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("日ごとのまとめ")
                    .font(.title3.bold())
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showRightPanel = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(cachedGrouped, id: \.0) { date, posts in
                        DaySummaryCard(date: date, posts: posts)
                    }
                }
                .padding(.top, 8)
            }

            Spacer()
        }
        .frame(width: 300)
        .background(.background)
    }
}

// MARK: - Day Summary Card

private struct DaySummaryCard: View {
    let date: Date
    let posts: [Post]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(formatDate(date))
                .font(.subheadline.bold())
                .foregroundStyle(.primary)

            statsRow

            ForEach(posts.prefix(3), id: \.id) { post in
                HStack(spacing: 6) {
                    Text(post.createdAt, format: .dateTime.hour().minute())
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .frame(width: 36, alignment: .leading)
                    Text(post.text)
                        .font(.caption)
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                }
            }
            if posts.count > 3 {
                Text("他\(posts.count - 3)件")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 42)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatItem(value: posts.count, label: "投稿")

            let totalReplies = posts.reduce(0) { $0 + $1.replyCount }
            if totalReplies > 0 {
                StatItem(value: totalReplies, label: "返信")
            }

            let imageCount = posts.filter { $0.imageData != nil }.count
            if imageCount > 0 {
                StatItem(value: imageCount, label: "写真")
            }
        }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日 (E)"
        return formatter
    }()

    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "今日" }
        if calendar.isDateInYesterday(date) { return "昨日" }
        return Self.dateFormatter.string(from: date)
    }
}

private struct StatItem: View {
    let value: Int
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(value)")
                .font(.title3.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
