import SwiftUI
import SwiftData

struct TagEditView: View {
    @Bindable var tag: Tag
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false

    private let colorOptions: [(name: String, hex: String)] = [
        ("ブルー", "007AFF"),
        ("レッド", "FF3B30"),
        ("オレンジ", "FF6B35"),
        ("イエロー", "FFD700"),
        ("グリーン", "4CAF50"),
        ("ティール", "00BCD4"),
        ("パープル", "9C27B0"),
        ("ピンク", "E91E63"),
        ("ブラウン", "795548"),
        ("ダークブルー", "4A90D9"),
        ("ディープオレンジ", "FF5722"),
        ("ダークブラウン", "8B4513"),
    ]


    var body: some View {
        Form {
            Section("名前") {
                TextField("タグ名", text: $tag.name)
            }

            Section("カラー") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                    ForEach(colorOptions, id: \.hex) { option in
                        Circle()
                            .fill(Color(hex: option.hex) ?? .blue)
                            .frame(width: 36, height: 36)
                            .overlay {
                                if tag.colorHex == option.hex {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .onTapGesture {
                                tag.colorHex = option.hex
                            }
                    }
                }
                .padding(.vertical, 4)
            }

            Section {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    HStack {
                        Spacer()
                        Text("タグを削除")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("タグを編集")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("このタグを削除しますか？", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("削除", role: .destructive) {
                modelContext.delete(tag)
                dismiss()
            }
            Button("キャンセル", role: .cancel) {}
        }
    }
}
