import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var settingsArray: [UserSettings]

    private var settings: UserSettings {
        if let existing = settingsArray.first {
            return existing
        }
        let newSettings = UserSettings()
        modelContext.insert(newSettings)
        return newSettings
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("1日の区切り") {
                    Picker("切り替わり時刻", selection: Binding(
                        get: { settings.dayBoundaryHour },
                        set: { settings.dayBoundaryHour = $0 }
                    )) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text("\(hour):00").tag(hour)
                        }
                    }

                    Text("この時刻より前の投稿は前日として扱われます")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("タグ管理") {
                    NavigationLink("タグ一覧") {
                        TagManagementView()
                    }
                    NavigationLink("イベントタグ一覧") {
                        EventTagManagementView()
                    }
                }

                Section("AI設定") {
                    SecureField("Gemini APIキー（任意）", text: Binding(
                        get: { settings.geminiAPIKey },
                        set: { settings.geminiAPIKey = $0 }
                    ))
                    .textContentType(.password)
                    .autocorrectionDisabled()

                    Text("デフォルトのAPIキーが組み込まれています。独自キーで上書きしたい場合のみ入力してください")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("情報") {
                    HStack {
                        Text("バージョン")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Tag Management

struct TagManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Tag.name) private var tags: [Tag]

    var body: some View {
        List {
            ForEach(tags, id: \.id) { tag in
                HStack {
                    Image(systemName: tag.icon)
                        .foregroundStyle(tag.color)
                        .frame(width: 24)
                    Text(tag.name)
                    Spacer()
                    Text("\((tag.posts ?? []).count)件")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    modelContext.delete(tags[index])
                }
            }
        }
        .navigationTitle("タグ一覧")
    }
}

// MARK: - Event Tag Management

struct EventTagManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \EventTag.createdAt) private var eventTags: [EventTag]

    var body: some View {
        List {
            Section("アクティブ") {
                ForEach(eventTags.filter { $0.isActive }, id: \.id) { eventTag in
                    HStack {
                        Image(systemName: "bookmark.fill")
                            .foregroundStyle(eventTag.color)
                        Text(eventTag.name)
                        Spacer()
                        Text("\((eventTag.posts ?? []).count)件")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .swipeActions {
                        Button("終了") {
                            eventTag.close()
                        }
                        .tint(.orange)
                    }
                }
            }

            Section("終了") {
                ForEach(eventTags.filter { !$0.isActive }, id: \.id) { eventTag in
                    HStack {
                        Image(systemName: "bookmark")
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading) {
                            Text(eventTag.name)
                            if let endDate = eventTag.endDate {
                                Text("\(eventTag.startDate, format: .dateTime.month().day()) 〜 \(endDate, format: .dateTime.month().day())")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Text("\((eventTag.posts ?? []).count)件")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete { indexSet in
                    let inactive = eventTags.filter { !$0.isActive }
                    for index in indexSet {
                        modelContext.delete(inactive[index])
                    }
                }
            }
        }
        .navigationTitle("イベントタグ")
    }
}
