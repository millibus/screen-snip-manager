import XCTest
@testable import ClipboardManager

final class FuzzySearchServiceTests: XCTestCase {
    private func makeTextEntry(id: Int64, text: String) -> ClipboardEntry {
        ClipboardEntry(
            id: id,
            contentType: .text,
            textContent: text,
            imageData: nil,
            hash: "h\(id)",
            createdAt: Date(),
            expiresAt: nil,
            isPinned: false,
            isSensitive: false,
            tags: nil
        )
    }

    func testSearchReturnsOriginalOrderForEmptyQuery() {
        let entries = [
            makeTextEntry(id: 1, text: "alpha"),
            makeTextEntry(id: 2, text: "beta"),
            makeTextEntry(id: 3, text: "gamma")
        ]

        let result = FuzzySearchService.shared.search(entries, query: "   ")

        XCTAssertEqual(result.map(\.id), entries.map(\.id))
    }

    func testSearchFindsFuzzyMatchesInScoreOrder() {
        let entries = [
            makeTextEntry(id: 1, text: "abc"),
            makeTextEntry(id: 2, text: "aXbYc"),
            makeTextEntry(id: 3, text: "a b c")
        ]

        let result = FuzzySearchService.shared.search(entries, query: "abc")

        XCTAssertEqual(result.map(\.id), [1, 3, 2], "Consecutive and word-boundary matches should rank higher")
    }

    func testSearchExcludesEntriesThatDoNotMatchPatternOrder() {
        let entries = [
            makeTextEntry(id: 1, text: "clipboard"),
            makeTextEntry(id: 2, text: "history"),
            makeTextEntry(id: 3, text: "boardclip")
        ]

        let result = FuzzySearchService.shared.search(entries, query: "cbd")

        XCTAssertEqual(result.map(\.id), [1], "Only entries with query characters in order should be returned")
    }
}
