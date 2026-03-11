import SwiftUI
import SwiftData

struct TagPickerView: View {
    @Binding var selectedTags: [Tag]
    @Binding var selectedEventTag: EventTag?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Tag.name) private var allTags: [Tag]
    @Query(sort: \EventTag.createdAt) private var allEventTags: [EventTag]
    @State private var showNewTag = false
    @State private var newTagName = ""
    @State private var showNewEventTag = false
    @State private var newEventTagName = ""

    var body: some View {
        NavigationStack {
            List {
                // Event Tags section
                Section("イベントタグ") {
                    ForEach(allEventTags.filter { $0.isActive }, id: \.id) { eventTag in
                        Button {
                            if selectedEventTag?.id == eventTag.id {
                                selectedEventTag = nil
                            } else {
                                selectedEventTag = eventTag
                            }
                        } label: {
                            HStack {
                                Image(systemName: "bookmark.fill")
                                    .foregroundStyle(eventTag.color)
                                Text(eventTag.name)
                                Spacer()
                                if selectedEventTag?.id == eventTag.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button("終了", role: .destructive) {
                                eventTag.close()
                            }
                        }
                    }
                    Button {
                        showNewEventTag = true
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                            Text("新しいイベントタグ")
                        }
                        .foregroundStyle(.secondary)
                    }
                }

                // Tags section
                Section("タグ") {
                    ForEach(allTags, id: \.id) { tag in
                        Button {
                            if selectedTags.contains(where: { $0.id == tag.id }) {
                                selectedTags.removeAll { $0.id == tag.id }
                            } else {
                                selectedTags.append(tag)
                            }
                        } label: {
                            HStack {
                                Image(systemName: tag.icon)
                                    .foregroundStyle(tag.color)
                                    .frame(width: 24)
                                Text(tag.name)
                                Spacer()
                                if selectedTags.contains(where: { $0.id == tag.id }) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                    Button {
                        showNewTag = true
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                            Text("新しいタグ")
                        }
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("タグを選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") { dismiss() }
                }
            }
            .onAppear {
                ensureDefaultTags()
            }
            .alert("新しいタグ", isPresented: $showNewTag) {
                TextField("タグ名", text: $newTagName)
                Button("キャンセル", role: .cancel) { newTagName = "" }
                Button("作成") {
                    guard !newTagName.isEmpty else { return }
                    let tag = Tag(name: newTagName)
                    modelContext.insert(tag)
                    newTagName = ""
                }
            }
            .alert("新しいイベントタグ", isPresented: $showNewEventTag) {
                TextField("イベント名", text: $newEventTagName)
                Button("キャンセル", role: .cancel) { newEventTagName = "" }
                Button("作成") {
                    guard !newEventTagName.isEmpty else { return }
                    let eventTag = EventTag(name: newEventTagName)
                    modelContext.insert(eventTag)
                    newEventTagName = ""
                }
            }
        }
    }

    private func ensureDefaultTags() {
        guard allTags.isEmpty else { return }
        for preset in Tag.presets {
            let tag = Tag(name: preset.name, colorHex: preset.colorHex, icon: preset.icon)
            modelContext.insert(tag)
        }
    }
}
