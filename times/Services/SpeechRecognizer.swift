import Speech
import AVFoundation

@MainActor
@Observable
final class SpeechRecognizer {
    var transcript = ""
    var isRecording = false
    var errorMessage: String?

    private var audioEngine: AVAudioEngine?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            isRecording = true
            transcript = ""
            errorMessage = nil
            Task { await startRecording() }
        }
    }

    private func startRecording() async {
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        guard speechStatus == .authorized else {
            errorMessage = "音声認識の権限が必要です"
            isRecording = false
            return
        }

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "オーディオセッションの設定に失敗しました"
            isRecording = false
            return
        }

        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP")),
              recognizer.isAvailable else {
            errorMessage = "音声認識が利用できません"
            isRecording = false
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.recognitionRequest = request

        let engine = AVAudioEngine()
        self.audioEngine = engine

        let inputNode = engine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        do {
            try engine.start()
        } catch {
            errorMessage = "オーディオエンジンの開始に失敗しました"
            cleanup()
            isRecording = false
            return
        }

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            let isFinal = result?.isFinal ?? false
            let transcriptText = result?.bestTranscription.formattedString
            Task { @MainActor in
                guard let self else { return }
                if let transcriptText {
                    self.transcript = transcriptText
                }
                if error != nil || isFinal {
                    self.finishRecording()
                }
            }
        }
    }

    func stopRecording() {
        guard isRecording else { return }
        recognitionRequest?.endAudio()
        cleanup()
        isRecording = false
    }

    /// Called when recognition finishes naturally (final result or error).
    /// Does not cancel the task since we're inside its callback.
    private func finishRecording() {
        guard isRecording else { return }
        cleanup()
        isRecording = false
    }

    private func cleanup() {
        let engine = audioEngine
        let task = recognitionTask
        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil

        engine?.stop()
        engine?.inputNode.removeTap(onBus: 0)
        task?.cancel()
    }
}
