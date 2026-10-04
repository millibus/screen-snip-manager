import Foundation

enum GeminiError: Error, LocalizedError {
    case missingAPIKey
    case invalidAPIKey
    case invalidModel
    case networkError
    case invalidResponse
    case apiError(Int)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: return "Gemini API key is not configured in Preferences."
        case .invalidAPIKey: return "Gemini API key contains invalid characters."
        case .invalidModel: return "Enter a Gemini model ID in Preferences, without a URL or path."
        case .networkError: return "Could not connect to Gemini. Check your connection and try again."
        case .invalidResponse: return "Invalid or empty response from Gemini API."
        case .apiError(let status): return "Gemini request failed (HTTP \(status)). Check your model, API access and quota."
        }
    }
}

final class GeminiService {
    // Stable image-input/text-output model verified in Google's model docs on 2026-10-04.
    static let defaultModel = "gemini-3.8-flash"
    static let shared = GeminiService()
    private let session: URLSession

    init(session: URLSession = URLSession(configuration: .ephemeral)) {
        self.session = session
    }

    func generateUICode(from imageData: Data, apiKey: String, model: String = defaultModel) async throws -> String {
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { throw GeminiError.missingAPIKey }
        guard key.unicodeScalars.allSatisfy({ !CharacterSet.controlCharacters.contains($0) }) else {
            throw GeminiError.invalidAPIKey
        }

        let modelID = model.trimmingCharacters(in: .whitespacesAndNewlines)
        let selectedModel = modelID.isEmpty ? Self.defaultModel : modelID
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-")
        guard selectedModel.hasPrefix("gemini-"), selectedModel.count <= 128,
              selectedModel.unicodeScalars.allSatisfy({ allowed.contains($0) }) else {
            throw GeminiError.invalidModel
        }
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(selectedModel):generateContent")!
        let parameters: [String: Any] = [
            "contents": [["parts": [
                ["text": "Act as an expert frontend engineer. Generate valid, responsive HTML using Tailwind CSS classes that accurately recreates the provided UI screenshot. Do not include markdown formatting or explanations, just the code."],
                ["inlineData": ["mimeType": "image/png", "data": imageData.base64EncodedString()]]
            ]]],
            "generationConfig": ["temperature": 0.2]
        ]
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(key, forHTTPHeaderField: "x-goog-api-key")
        request.httpBody = try JSONSerialization.data(withJSONObject: parameters)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            if Task.isCancelled { throw CancellationError() }
            // Do not expose raw transport descriptions or provider bodies in the UI.
            throw GeminiError.networkError
        }
        guard let httpResponse = response as? HTTPURLResponse else { throw GeminiError.invalidResponse }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw GeminiError.apiError(httpResponse.statusCode)
        }
        guard let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]] else {
            throw GeminiError.invalidResponse
        }
        var text = parts.filter { ($0["thought"] as? Bool) != true }
            .compactMap { $0["text"] as? String }.joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("```html") { text = String(text.dropFirst(7)) }
        else if text.hasPrefix("```") { text = String(text.dropFirst(3)) }
        if text.hasSuffix("```") { text = String(text.dropLast(3)) }
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw GeminiError.invalidResponse }
        return text
    }
}
