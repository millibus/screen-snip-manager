import XCTest
@testable import ClipboardManager

final class ClipboardEntryTests: XCTestCase {
    func testPreviewForTextIsTruncatedAtEightyCharacters() {
        let long = String(repeating: "x", count: 100)
        let entry = ClipboardEntry(
            id: 1,
            contentType: .text,
            textContent: long,
            imageData: nil,
            hash: "hash",
            createdAt: Date(),
            expiresAt: nil,
            isPinned: false,
            isSensitive: false,
            tags: nil
        )

        XCTAssertEqual(entry.preview.count, 81, "80 characters plus an ellipsis")
        XCTAssertTrue(entry.preview.hasSuffix("…"))
    }

    func testPreviewForImageUsesImageLabel() {
        let entry = ClipboardEntry(
            id: 2,
            contentType: .image,
            textContent: nil,
            imageData: Data([0x01]),
            hash: "hash2",
            createdAt: Date(),
            expiresAt: nil,
            isPinned: false,
            isSensitive: false,
            tags: nil
        )

        XCTAssertEqual(entry.preview, "🖼 Image")
    }
}
