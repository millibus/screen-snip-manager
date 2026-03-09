import XCTest
@testable import ClipboardManager

final class ClipboardStoreTests: XCTestCase {

    private var store: ClipboardStore!
    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        store = ClipboardStore(dbPath: tempDir.appendingPathComponent("test.sqlite").path)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    func testDedupeRefreshesExpiryAndSensitivity() {
        let hash = "abc123"
        let expiresOld = Date().addingTimeInterval(10)
        store.insertEntry(contentType: .text, textContent: "first", imageData: nil, hash: hash, expiresAt: expiresOld, isSensitive: true)

        var entries = store.fetchEntries(limit: 10)
        XCTAssertEqual(entries.count, 1)
        XCTAssertNotNil(entries[0].expiresAt)
        XCTAssertEqual(entries[0].expiresAt!.timeIntervalSince1970, expiresOld.timeIntervalSince1970, accuracy: 1)
        XCTAssertTrue(entries[0].isSensitive)

        let expiresNew = Date().addingTimeInterval(300)
        store.insertEntry(contentType: .text, textContent: "first", imageData: nil, hash: hash, expiresAt: expiresNew, isSensitive: false)

        entries = store.fetchEntries(limit: 10)
        XCTAssertEqual(entries.count, 1)
        XCTAssertNotNil(entries[0].expiresAt)
        XCTAssertEqual(entries[0].expiresAt!.timeIntervalSince1970, expiresNew.timeIntervalSince1970, accuracy: 1)
        XCTAssertFalse(entries[0].isSensitive)
    }

    func testExpiredEntriesExcludedFromFetch() {
        let hash = "expireme"
        let past = Date().addingTimeInterval(-60)
        store.insertEntry(contentType: .text, textContent: "gone", imageData: nil, hash: hash, expiresAt: past, isSensitive: false)

        let entries = store.fetchEntries(limit: 10)
        XCTAssertEqual(entries.count, 0)
    }

    func testPinnedEntryRetained() {
        store.insertEntry(contentType: .text, textContent: "pinned", imageData: nil, hash: "pin1")
        let entries = store.fetchEntries(limit: 10)
        XCTAssertEqual(entries.count, 1)
        store.setPinned(entryId: entries[0].id, pinned: true)
        let after = store.fetchEntries(limit: 10)
        XCTAssertTrue(after[0].isPinned)
    }
}
