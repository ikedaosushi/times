import SwiftUI
import SwiftData

struct TagPickerView: View {
    @Binding var selectedTags: [Tag]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Tag.name) private var allTags: [Tag]
    @State private var showNewTag = false
    @State private var newTagName = ""

    var body: some View {
        NavigationStack {
            List {
                Section("タグ") {
                    ForEach(allTags.filter { $0.isActive }, id: \.id) { tag in
                        Button {
                            if selectedTags.contains(where: { $0.id == tag.id }) {
                                selectedTags.removeAll { $0.id == tag.id }
                            } else {
                                selectedTags.append(tag)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "bookmark.fill")
                                    .foregroundStyle(tag.color)
                                Text(tag.name)
                                Spacer()
                                if selectedTags.contains(where: { $0.id == tag.id }) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button("終了") {
                                tag.close()
                            }
                            .tint(.orange)
                            Button(role: .destructive) {
                                selectedTags.removeAll { $0.id == tag.id }
                                modelContext.delete(tag)
                            } label: {
                                Label("削除", systemImage: "trash")
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
        }
    }
}
