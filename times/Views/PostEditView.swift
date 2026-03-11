import SwiftUI

struct PostEditView: View {
    @Bindable var post: Post
    @Environment(\.dismiss) private var dismiss
    @State private var editText: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("テキスト") {
                    TextField("投稿内容", text: $editText, axis: .vertical)
                        .lineLimit(3...10)
                }
            }
            .navigationTitle("編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        post.text = editText
                        dismiss()
                    }
                    .disabled(editText.isEmpty)
                }
            }
            .onAppear {
                editText = post.text
            }
        }
    }
}
