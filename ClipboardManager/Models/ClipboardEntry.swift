import Foundation

enum ContentType: String, Codable {
    case text
    case image
}

struct ClipboardEntry: Identifiable {
    var id: Int64
    var contentType: ContentType
    var textContent: String?
    var imageData: Data?
    var hash: String
    var createdAt: Date
    var expiresAt: Date?
    var isPinned: Bool
    var isSensitive: Bool
    var tags: String?

    var preview: String {
        switch contentType {
        case .text:
            let t = textContent ?? ""
            return t.count > 80 ? String(t.prefix(80)) + "…" : t
        case .image:
            return "🖼 Image"
        }
    }
}
