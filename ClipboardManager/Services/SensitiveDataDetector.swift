import Foundation

/// Heuristics to detect likely passwords or tokens; used to skip storage or apply short expiry.
final class SensitiveDataDetector {
    static let shared = SensitiveDataDetector()

    private init() {}

    /// Minimum length to consider as candidate sensitive (plan: 16+; also support 20+ for stricter).
    private let minLength = 16

    /// Returns true if the text looks like a password/token and should be treated as sensitive.
    func isSensitive(_ text: String) -> Bool {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard t.count >= minLength else { return false }

        // Common password-manager / token patterns
        if matchesKnownPatterns(t) { return true }

        // Long mixed alphanumeric + symbols
        let hasLetter = t.contains { $0.isLetter }
        let hasDigit = t.contains { $0.isNumber }
        let hasSymbol = t.contains { !$0.isLetter && !$0.isNumber && !$0.isWhitespace }
        if hasLetter && (hasDigit || hasSymbol) && t.count >= 20 {
            return true
        }

        return false
    }

    private func matchesKnownPatterns(_ text: String) -> Bool {
        // bcrypt hash
        if text.hasPrefix("$2") && text.count >= 50 { return true }
        // JWT / JSON-like token (starts with eyJ or {")
        if text.hasPrefix("eyJ") || (text.hasPrefix("{") && text.contains("\"") && text.count > 40) { return true }
        // Modern tokens
        if text.hasPrefix("ghp_") || text.hasPrefix("gho_") { return true } // GitHub
        if text.hasPrefix("xoxb-") || text.hasPrefix("xoxp-") { return true } // Slack
        if text.hasPrefix("AKIA") && text.count == 20 { return true } // AWS Access Key
        // Hex token (long hex string)
        if text.count >= 32, text.allSatisfy({ $0.isHexDigit || $0.isWhitespace }) { return true }
        return false
    }
}
