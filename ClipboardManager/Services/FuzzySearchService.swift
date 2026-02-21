import Foundation

/// Lightweight fuzzy search (Fuse.js-style): query characters must appear in order in the target.
/// Scores by proximity and prefer earlier matches.
final class FuzzySearchService {
    static let shared = FuzzySearchService()

    /// Debounce interval for search (ms) — used by callers when wiring search.
    static let debounceMs: Int = 120

    private init() {}

    /// Returns entries that fuzzy-match the query, sorted by score (best first).
    /// Empty query returns all entries in original order.
    func search(_ entries: [ClipboardEntry], query: String) -> [ClipboardEntry] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return entries }
        let pattern = Array(q.lowercased())
        var scored: [(ClipboardEntry, Double)] = []
        for entry in entries {
            let text = entry.preview
            if let score = fuzzyScore(pattern: pattern, in: text) {
                scored.append((entry, score))
            }
        }
        return scored.sorted { $0.1 > $1.1 }.map(\.0)
    }

    /// Score for pattern matching text (higher = better). Returns nil if no match.
    private func fuzzyScore(pattern: [Character], in text: String) -> Double? {
        let lower = text.lowercased()
        let chars = Array(lower)
        guard !pattern.isEmpty, pattern.count <= chars.count else { return nil }
        var pi = 0
        var lastMatchIndex = -1
        var consecutiveBonus = 0.0
        var totalScore = 0.0
        for (i, c) in chars.enumerated() {
            if pi >= pattern.count { break }
            if c == pattern[pi] {
                let distance = (lastMatchIndex >= 0) ? (i - lastMatchIndex) : 0
                var score = 1.0
                if distance == 1 {
                    consecutiveBonus += 2.0
                    score += consecutiveBonus
                } else {
                    consecutiveBonus = 0
                    if distance > 0 { score -= Double(distance) * 0.05 }
                }
                if i == 0 || chars[i - 1] == " " || chars[i - 1] == "\n" {
                    score += 1.5
                }
                totalScore += score
                lastMatchIndex = i
                pi += 1
            }
        }
        guard pi == pattern.count else { return nil }
        return totalScore
    }
}
