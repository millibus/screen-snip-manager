import Carbon
import Foundation

enum UserDefaultsKeys {
    static let autoPasteOnSelect = "autoPasteOnSelect"
    /// If true, store sensitive-looking content with short expiry; if false, skip storing it.
    static let storeSensitiveData = "storeSensitiveData"
    /// Expiry in seconds for sensitive entries (default 60).
    static let sensitiveExpirySeconds = "sensitiveExpirySeconds"
    /// Maximum number of clipboard entries to keep (oldest non-pinned removed when exceeded).
    static let maxHistory = "maxHistory"
    /// Carbon modifier flags (Int) for global hotkey.
    static let hotkeyModifiers = "hotkeyModifiers"
    /// Carbon virtual key code (UInt32) for global hotkey.
    /// Note: Stored and read as Int via integer(forKey:)
    static let hotkeyKeyCode = "hotkeyKeyCode"
    /// API key for Gemini AI.
    static let geminiAPIKey = "geminiAPIKey"

    static var autoPasteOnSelectDefault: Bool { false }
    /// Default false so normal clipboard content is not silently expired; users can opt in to store sensitive-looking items with short expiry.
    static var storeSensitiveDataDefault: Bool { false }
    static var sensitiveExpirySecondsDefault: Int { 60 }
    static var maxHistoryDefault: Int { 500 }
    /// Default: Cmd+Shift+V
    static var hotkeyModifiersDefault: Int { Int(cmdKey | shiftKey) }
    static var hotkeyKeyCodeDefault: UInt32 { UInt32(kVK_ANSI_V) }
    static var geminiAPIKeyDefault: String { "" }
}

enum GeminiError: Error, LocalizedError {
    case missingAPIKey
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey: return "Gemini API key is not configured in Preferences."
        case .invalidURL: return "Invalid API URL."
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        case .invalidResponse: return "Invalid response from Gemini API."
        case .apiError(let message): return "Gemini API Error: \(message)"
        }
    }
}

class GeminiService {
    static let shared = GeminiService()
    
    private let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent"
    
    func generateUICode(from imageData: Data, apiKey: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw GeminiError.missingAPIKey
        }
        
        guard let url = URL(string: "\(endpoint)?key=\(apiKey)") else {
            throw GeminiError.invalidURL
        }
        
        let base64Image = imageData.base64EncodedString()
        
        let prompt = "Act as an expert frontend engineer. Generate valid, responsive HTML using Tailwind CSS classes that accurately recreates the provided UI screenshot. Do not include markdown formatting or explanations, just the code."
        
        let parameters: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt],
                        [
                            "inlineData": [
                                "mimeType": "image/png",
                                "data": base64Image
                            ]
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.2
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw GeminiError.apiError("Status \(httpResponse.statusCode): \(errorText)")
        }
        
        let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        guard let candidates = jsonResponse?["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              var text = firstPart["text"] as? String else {
            throw GeminiError.invalidResponse
        }
        
        // Strip markdown backticks if Gemini includes them
        if text.hasPrefix("```html") {
            text = String(text.dropFirst(7))
        } else if text.hasPrefix("```") {
            text = String(text.dropFirst(3))
        }
        if text.hasSuffix("```") {
            text = String(text.dropLast(3))
        }
        
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
