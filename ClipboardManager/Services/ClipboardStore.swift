import Foundation
import GRDB

final class ClipboardStore {
    private var dbQueue: DatabaseQueue?

    static let shared = ClipboardStore()

    private init() {
        do {
            let url = try fileURL()
            dbQueue = try DatabaseQueue(path: url.path)
            try migrator.migrate(dbQueue!)
        } catch {
            print("ClipboardStore init error: \(error)")
        }
    }

    private func fileURL() throws -> URL {
        let fm = FileManager.default
        let dir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("ClipboardManager", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent("clipboard.sqlite")
    }

    private var migrator: DatabaseMigrator {
        var m = DatabaseMigrator()
        m.registerMigration("v1") { db in
            try db.execute(sql: """
                CREATE TABLE clipboard_entries (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  content_type TEXT NOT NULL,
                  text_content TEXT,
                  image_data BLOB,
                  hash TEXT UNIQUE NOT NULL,
                  created_at REAL NOT NULL,
                  expires_at REAL,
                  is_pinned INTEGER DEFAULT 0,
                  is_sensitive INTEGER DEFAULT 0,
                  tags TEXT
                )
                """)
            try db.execute(sql: "CREATE INDEX idx_entries_created ON clipboard_entries(created_at DESC)")
            try db.execute(sql: "CREATE INDEX idx_entries_hash ON clipboard_entries(hash)")
        }
        return m
    }

    func insertEntry(contentType: ContentType, textContent: String?, imageData: Data?, hash: String, expiresAt: Date? = nil, isSensitive: Bool = false) {
        guard let db = dbQueue else { return }
        let maxHistory = UserDefaults.standard.object(forKey: UserDefaultsKeys.maxHistory) as? Int ?? UserDefaultsKeys.maxHistoryDefault
        do {
            try db.write { db in
                // Deduplicate: if hash exists, update created_at
                let existing = try Int64.fetchOne(db, sql: "SELECT id FROM clipboard_entries WHERE hash = ?", arguments: [hash])
                if let id = existing {
                    try db.execute(sql: "UPDATE clipboard_entries SET created_at = ? WHERE id = ?", arguments: [Date().timeIntervalSince1970, id])
                    return
                }
                let exp: Double? = expiresAt?.timeIntervalSince1970
                try db.execute(sql: """
                    INSERT INTO clipboard_entries (content_type, text_content, image_data, hash, created_at, expires_at, is_pinned, is_sensitive)
                    VALUES (?, ?, ?, ?, ?, ?, 0, ?)
                    """, arguments: [contentType.rawValue, textContent, imageData, hash, Date().timeIntervalSince1970, exp, isSensitive ? 1 : 0])
                try trimToMaxEntries(db: db, maxHistory: maxHistory)
            }
        } catch {
            print("insertEntry error: \(error)")
        }
    }

    func fetchImageData(for entryId: Int64) -> Data? {
        guard let db = dbQueue else { return nil }
        do {
            return try db.read { db in
                try Data.fetchOne(db, sql: "SELECT image_data FROM clipboard_entries WHERE id = ?", arguments: [entryId])
            }
        } catch {
            print("fetchImageData error: \(error)")
            return nil
        }
    }

    func fetchEntries(limit: Int = 100) -> [ClipboardEntry] {
        guard let db = dbQueue else { return [] }
        let now = Date().timeIntervalSince1970
        do {
            return try db.read { db in
                let rows = try Row.fetchAll(db, sql: """
                    SELECT id, content_type, text_content, image_data, hash, created_at, expires_at, is_pinned, is_sensitive, tags
                    FROM clipboard_entries
                    WHERE (expires_at IS NULL OR expires_at > ?)
                    ORDER BY is_pinned DESC, created_at DESC
                    LIMIT ?
                    """, arguments: [now, limit])
                return rows.map { row in
                    let expiresAtRaw: Double? = row["expires_at"]
                    return ClipboardEntry(
                        id: row["id"] ?? 0,
                        contentType: ContentType(rawValue: row["content_type"] ?? "text") ?? .text,
                        textContent: row["text_content"],
                        imageData: row["image_data"],
                        hash: row["hash"] ?? "",
                        createdAt: Date(timeIntervalSince1970: row["created_at"] ?? 0),
                        expiresAt: expiresAtRaw.map { Date(timeIntervalSince1970: $0) },
                        isPinned: (row["is_pinned"] as Int64?) == 1,
                        isSensitive: (row["is_sensitive"] as Int64?) == 1,
                        tags: row["tags"]
                    )
                }
            }
        } catch {
            print("fetchEntries error: \(error)")
            return []
        }
    }

    func fetchEntriesWithoutImageData(limit: Int = 100) -> [ClipboardEntry] {
        guard let db = dbQueue else { return [] }
        let now = Date().timeIntervalSince1970
        do {
            return try db.read { db in
                let rows = try Row.fetchAll(db, sql: """
                    SELECT id, content_type, text_content, hash, created_at, expires_at, is_pinned, is_sensitive, tags
                    FROM clipboard_entries
                    WHERE (expires_at IS NULL OR expires_at > ?)
                    ORDER BY is_pinned DESC, created_at DESC
                    LIMIT ?
                    """, arguments: [now, limit])
                return rows.map { row in
                    let expiresAtRaw: Double? = row["expires_at"]
                    return ClipboardEntry(
                        id: row["id"] ?? 0,
                        contentType: ContentType(rawValue: row["content_type"] ?? "text") ?? .text,
                        textContent: row["text_content"],
                        imageData: nil, // Omit image data
                        hash: row["hash"] ?? "",
                        createdAt: Date(timeIntervalSince1970: row["created_at"] ?? 0),
                        expiresAt: expiresAtRaw.map { Date(timeIntervalSince1970: $0) },
                        isPinned: (row["is_pinned"] as Int64?) == 1,
                        isSensitive: (row["is_sensitive"] as Int64?) == 1,
                        tags: row["tags"]
                    )
                }
            }
        } catch {
            print("fetchEntriesWithoutImageData error: \(error)")
            return []
        }
    }

    /// Removes entries whose expires_at is in the past. Call periodically from app lifecycle.
    func deleteExpiredEntries() {
        guard let db = dbQueue else { return }
        let now = Date().timeIntervalSince1970
        do {
            try db.write { db in
                try db.execute(sql: "DELETE FROM clipboard_entries WHERE expires_at IS NOT NULL AND expires_at <= ?", arguments: [now])
            }
        } catch {
            print("deleteExpiredEntries error: \(error)")
        }
    }

    func setPinned(entryId: Int64, pinned: Bool) {
        guard let db = dbQueue else { return }
        do {
            try db.write { db in
                try db.execute(sql: "UPDATE clipboard_entries SET is_pinned = ? WHERE id = ?", arguments: [pinned ? 1 : 0, entryId])
            }
        } catch {
            print("setPinned error: \(error)")
        }
    }

    func setTags(entryId: Int64, tags: [String]) {
        guard let db = dbQueue else { return }
        let value = tags.isEmpty ? nil : tags.joined(separator: ",")
        do {
            try db.write { db in
                try db.execute(sql: "UPDATE clipboard_entries SET tags = ? WHERE id = ?", arguments: [value, entryId])
            }
        } catch {
            print("setTags error: \(error)")
        }
    }

    func addTag(entryId: Int64, tag: String) {
        guard let db = dbQueue else { return }
        let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            try db.write { db in
                let row = try Row.fetchOne(db, sql: "SELECT tags FROM clipboard_entries WHERE id = ?", arguments: [entryId])
                let existing = (row?["tags"] as String?).map { $0.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) } } ?? []
                var set = Set(existing)
                set.insert(trimmed)
                let newTags = set.sorted().joined(separator: ",")
                try db.execute(sql: "UPDATE clipboard_entries SET tags = ? WHERE id = ?", arguments: [newTags, entryId])
            }
        } catch {
            print("addTag error: \(error)")
        }
    }

    /// Removes oldest non-pinned, non-expired entries so total count does not exceed max history preference.
    private func trimToMaxEntries(db: Database, maxHistory: Int) throws {
        let now = Date().timeIntervalSince1970
        let count = try Int.fetchOne(db, sql: """
            SELECT COUNT(*) FROM clipboard_entries
            WHERE (expires_at IS NULL OR expires_at > ?)
            """, arguments: [now]) ?? 0
        guard count > maxHistory else { return }
        let toRemove = count - maxHistory
        try db.execute(sql: """
            DELETE FROM clipboard_entries WHERE id IN (
                SELECT id FROM clipboard_entries
                WHERE (expires_at IS NULL OR expires_at > ?) AND is_pinned = 0
                ORDER BY created_at ASC
                LIMIT ?
            )
            """, arguments: [now, toRemove])
    }

    func entries(matching query: String?) -> [ClipboardEntry] {
        guard let q = query?.trimmingCharacters(in: .whitespacesAndNewlines), !q.isEmpty else {
            return fetchEntries()
        }
        guard let db = dbQueue else { return [] }
        let now = Date().timeIntervalSince1970
        let likeQuery = "%\(q)%"
        do {
            return try db.read { db in
                let rows = try Row.fetchAll(db, sql: """
                    SELECT id, content_type, text_content, image_data, hash, created_at, expires_at, is_pinned, is_sensitive, tags
                    FROM clipboard_entries
                    WHERE (expires_at IS NULL OR expires_at > ?)
                      AND text_content LIKE ?
                    ORDER BY is_pinned DESC, created_at DESC
                    LIMIT 100
                    """, arguments: [now, likeQuery])
                return rows.map { row in
                    let expiresAtRaw: Double? = row["expires_at"]
                    return ClipboardEntry(
                        id: row["id"] ?? 0,
                        contentType: ContentType(rawValue: row["content_type"] ?? "text") ?? .text,
                        textContent: row["text_content"],
                        imageData: row["image_data"],
                        hash: row["hash"] ?? "",
                        createdAt: Date(timeIntervalSince1970: row["created_at"] ?? 0),
                        expiresAt: expiresAtRaw.map { Date(timeIntervalSince1970: $0) },
                        isPinned: (row["is_pinned"] as Int64?) == 1,
                        isSensitive: (row["is_sensitive"] as Int64?) == 1,
                        tags: row["tags"]
                    )
                }
            }
        } catch {
            print("entries(matching:) error: \(error)")
            return []
        }
    }
}
