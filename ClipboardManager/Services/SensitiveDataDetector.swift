import Foundation

/// Heuristics to detect likely passwords or tokens; used to skip storage or apply short expiry.
/// Conservative to avoid false positives: URLs, JSON, and code snippets are not treated as sensitive.
final class SensitiveDataDetector {
    static let shared = SensitiveDataDetector()

    private init() {}

    /// Minimum length to consider as candidate sensitive.
    private let minLength = 16

    /// Returns true if the text looks like a password/token and should be treated as sensitive.
    func isSensitive(_ text: String) -> Bool {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard t.count >= minLength else { return false }

        // Exclude content that looks like URLs, JSON, or code (common clipboard content).
        if looksLikeNormalClipboardContent(t) { return false }

        // Known token / secret prefixes and formats.
        if matchesKnownPatterns(t) { return true }

        // Single-line token-like string: no spaces/newlines, mixed chars, 32+ length.
        let hasLetter = t.contains { $0.isLetter }
        let hasDigit = t.contains { $0.isNumber }
        let hasSymbol = t.contains { !$0.isLetter && !$0.isNumber && !$0.isWhitespace }
        if t.count >= 32, hasLetter && (hasDigit || hasSymbol), !t.contains(" "), !t.contains("\n") {
            return true
        }

        return false
    }

    /// Avoid treating URLs, JSON, code, or prose as sensitive.
    private func looksLikeNormalClipboardContent(_ text: String) -> Bool {
        if text.contains("://") || text.lowercased().hasPrefix("http") { return true }
        if text.contains("\n") || text.contains("  ") { return true }
        if text.hasPrefix("{") && text.contains("\"") { return true }
        if text.hasPrefix("<") && text.contains(">") { return true }
        return false
    }

    private func matchesKnownPatterns(_ text: String) -> Bool {
        // bcrypt hash
        if text.hasPrefix("$2") && text.count >= 50 { return true }
        // JWT (base64 header); do not match arbitrary JSON.
        if text.hasPrefix("eyJ") { return true }
        // Modern API tokens
        if text.hasPrefix("ghp_") || text.hasPrefix("gho_") { return true }
        if text.hasPrefix("xoxb-") || text.hasPrefix("xoxp-") { return true }
        if text.hasPrefix("AKIA") && text.count == 20 { return true }
        // Long hex token
        if text.count >= 32, text.allSatisfy({ $0.isHexDigit || $0.isWhitespace }) { return true }
        return false
    }
}
