import SwiftUI
import SwiftData
import PhotosUI

struct ChatInputBox: View {
    let channel: Channel
    var onSend: () -> Void
    @Environment(\.modelContext) private var modelContext
    @State private var text = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var showTagPicker = false
    @State private var showLocationPicker = false
    @State private var selectedTags: [Tag] = []
    @State private var selectedEventTag: EventTag?
    @State private var locationName: String?
    @State private var latitude: Double?
    @State private var longitude: Double?
    @State private var speechRecognizer = SpeechRecognizer()
    @FocusState private var isTextFieldFocused: Bool

    private var canSend: Bool {
        !text.isEmpty || imageData != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            tagsBar
            locationBar
            imagePreview
            speechPreview
            inputArea
        }
        .background(.background)
        .sheet(isPresented: $showTagPicker) {
            TagPickerView(selectedTags: $selectedTags, selectedEventTag: $selectedEventTag)
        }
        .sheet(isPresented: $showLocationPicker) {
            LocationPickerView(locationName: $locationName, latitude: $latitude, longitude: $longitude)
        }
        .onChange(of: speechRecognizer.isRecording) { oldValue, newValue in
            if oldValue && !newValue && !speechRecognizer.transcript.isEmpty {
                if !text.isEmpty && !text.hasSuffix(" ") && !text.hasSuffix("\n") {
                    text += " "
                }
                text += speechRecognizer.transcript
                speechRecognizer.transcript = ""
            }
        }
        .alert("音声入力エラー", isPresented: .init(
            get: { speechRecognizer.errorMessage != nil },
            set: { if !$0 { speechRecognizer.errorMessage = nil } }
        )) {
            Button("OK") { speechRecognizer.errorMessage = nil }
        } message: {
            Text(speechRecognizer.errorMessage ?? "")
        }
    }

    @ViewBuilder
    private var tagsBar: some View {
        if !selectedTags.isEmpty || selectedEventTag != nil {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    if let eventTag = selectedEventTag {
                        eventTagChip(eventTag)
                    }
                    ForEach(selectedTags, id: \.id) { tag in
                        tagChip(tag)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
        }
    }

    private func eventTagChip(_ eventTag: EventTag) -> some View {
        HStack(spacing: 2) {
            Image(systemName: "bookmark.fill")
                .font(.caption2)
            Text(eventTag.name)
                .font(.caption)
            Button {
                selectedEventTag = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
            }
        }
        .foregroundStyle(eventTag.color)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(eventTag.color.opacity(0.12), in: Capsule())
    }

    private func tagChip(_ tag: Tag) -> some View {
        HStack(spacing: 2) {
            Image(systemName: tag.icon)
                .font(.caption2)
            Text(tag.name)
                .font(.caption)
            Button {
                selectedTags.removeAll { $0.id == tag.id }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
            }
        }
        .foregroundStyle(tag.color)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(tag.color.opacity(0.12), in: Capsule())
    }

    @ViewBuilder
    private var locationBar: some View {
        if let locationName {
            HStack(spacing: 4) {
                Image(systemName: "location.fill")
                    .font(.caption2)
                    .foregroundStyle(.blue)
                Text(locationName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button {
                    self.locationName = nil
                    self.latitude = nil
                    self.longitude = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(.blue.opacity(0.06))
        }
    }

    @ViewBuilder
    private var imagePreview: some View {
        if let imageData, let image = cachedSwiftUIImage(from: imageData, cacheKey: "input-preview") {
            HStack {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 120)
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
    }

    @ViewBuilder
    private var speechPreview: some View {
        if speechRecognizer.isRecording {
            HStack(spacing: 6) {
                Circle()
                    .fill(.red)
                    .frame(width: 8, height: 8)
                Text(speechRecognizer.transcript.isEmpty ? "聞き取り中..." : speechRecognizer.transcript)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Spacer()
                Button {
                    speechRecognizer.stopRecording()
                } label: {
                    Image(systemName: "stop.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.red.opacity(0.06))
        }
    }

    private var inputArea: some View {
        VStack(spacing: 0) {
            TextField("投稿する...", text: $text, axis: .vertical)
                .focused($isTextFieldFocused)
                .textFieldStyle(.plain)
                .lineLimit(1...6)
                .font(.body)
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 10)
                .onKeyPress(.return, phases: .down) { keyPress in
                    if keyPress.modifiers.contains(.shift) {
                        return .ignored // Shift+Return → 改行
                    }
                    send()
                    return .handled // Return → 送信
                }
                .onAppear { isTextFieldFocused = true }

            toolBar
        }
        .background(Color(.systemGray6))
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 12, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 12))
        .overlay(
            UnevenRoundedRectangle(topLeadingRadius: 12, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 12)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }

    private var toolBar: some View {
        HStack(spacing: 12) {
            Button { showTagPicker = true } label: {
                Image(systemName: "tag")
                    .font(.body)
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)

            Button { showLocationPicker = true } label: {
                Image(systemName: "location")
                    .font(.body)
                    .foregroundStyle(locationName != nil ? Color.blue : Color.secondary.opacity(0.3))
            }
            .buttonStyle(.plain)

            Button { speechRecognizer.toggleRecording() } label: {
                Image(systemName: speechRecognizer.isRecording ? "stop.fill" : "mic")
                    .font(speechRecognizer.isRecording ? .caption : .body)
                    .foregroundStyle(speechRecognizer.isRecording ? AnyShapeStyle(.red) : AnyShapeStyle(.tertiary))
                    .symbolEffect(.pulse, isActive: speechRecognizer.isRecording)
            }
            .buttonStyle(.plain)

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

            Button(action: send) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(canSend ? .blue : Color.secondary.opacity(0.3))
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    private func send() {
        guard canSend else { return }
        let postText = text
        let postImageData = imageData
        let postTags = selectedTags
        let postEventTag = selectedEventTag
        let postLocationName = locationName
        let postLatitude = latitude
        let postLongitude = longitude

        // テキストと画像だけクリア（タグ・位置情報は外すまで継続）
        text = ""
        imageData = nil
        selectedPhoto = nil

        let post = Post(
            text: postText,
            imageData: postImageData,
            latitude: postLatitude,
            longitude: postLongitude,
            locationName: postLocationName
        )
        post.channel = channel
        post.tags = postTags
        post.eventTag = postEventTag

        if let url = detectURL(in: postText) {
            post.urlString = url.absoluteString
            Task {
                await OGPService.fetchOGP(for: post, url: url)
            }
        }

        modelContext.insert(post)
        onSend()
    }

    private static let urlDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)

    private func detectURL(in text: String) -> URL? {
        let range = NSRange(text.startIndex..., in: text)
        let match = Self.urlDetector?.firstMatch(in: text, range: range)
        return match?.url
    }
}
