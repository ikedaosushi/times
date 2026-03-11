import Foundation

actor AIService {
    static let shared = AIService()

    private init() {}

    func generateComment(for postText: String, apiKey: String? = nil) async throws -> String {
        let key = apiKey?.isEmpty == false ? apiKey! : Secrets.geminiAPIKey
        guard !key.isEmpty else {
            throw AIServiceError.noAPIKey
        }

        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(key)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        [
                            "text": """
                            あなたはフレンドリーなコメンテーターです。ユーザーの投稿に対して、共感的で短い日本語のコメントを1〜2文で返してください。絵文字を適度に使ってください。

                            投稿: \(postText)
                            """
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "maxOutputTokens": 200,
                "temperature": 0.8
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw AIServiceError.apiError(statusCode: httpResponse.statusCode)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let candidates = json?["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            throw AIServiceError.invalidResponse
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum AIServiceError: LocalizedError {
    case noAPIKey
    case invalidResponse
    case apiError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "Gemini APIキーが設定されていません。設定画面から入力してください。"
        case .invalidResponse:
            return "AIからの応答を解析できませんでした。"
        case .apiError(let statusCode):
            return "APIエラー (ステータスコード: \(statusCode))"
        }
    }
}
