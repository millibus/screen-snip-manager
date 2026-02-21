import AppKit
import CryptoKit
import Foundation

final class PasteboardWatcher {
    private var timer: Timer?
    private var lastChangeCount: Int
    private let interval: TimeInterval = 0.5

    init() {
        lastChangeCount = NSPasteboard.general.changeCount
        timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            self?.checkPasteboard()
        }
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    deinit {
        timer?.invalidate()
    }

    private func checkPasteboard() {
        let current = NSPasteboard.general.changeCount
        guard current != lastChangeCount else { return }

        let string = NSPasteboard.general.string(forType: .string)
        let pasteboard = NSPasteboard.general
        let pngData = pasteboard.data(forType: .png)
        let tiffData = pasteboard.data(forType: .tiff)

        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }

            if let string = string {
                let hash = Self.sha256(string)
                let storeSensitive = UserDefaults.standard.object(forKey: UserDefaultsKeys.storeSensitiveData) as? Bool ?? UserDefaultsKeys.storeSensitiveDataDefault
                let expirySecs = UserDefaults.standard.object(forKey: UserDefaultsKeys.sensitiveExpirySeconds) as? Int ?? UserDefaultsKeys.sensitiveExpirySecondsDefault
                
                if SensitiveDataDetector.shared.isSensitive(string) {
                    if storeSensitive {
                        let expiresAt = Date().addingTimeInterval(TimeInterval(expirySecs))
                        ClipboardStore.shared.insertEntry(contentType: .text, textContent: string, imageData: nil, hash: hash, expiresAt: expiresAt, isSensitive: true)
                    }
                } else {
                    ClipboardStore.shared.insertEntry(contentType: .text, textContent: string, imageData: nil, hash: hash)
                }
            } else {
                var imageData: Data? = pngData
                if imageData == nil, let tiff = tiffData, let img = NSImage(data: tiff),
                   let tiffRep = img.tiffRepresentation, let rep = NSBitmapImageRep(data: tiffRep) {
                    imageData = rep.representation(using: .png, properties: [:])
                }
                
                if let data = imageData {
                    let hash = Self.sha256(data)
                    ClipboardStore.shared.insertEntry(contentType: .image, textContent: "Image", imageData: data, hash: hash)
                }
            }

            DispatchQueue.main.async {
                self.lastChangeCount = current
            }
        }
    }

    private static func sha256(_ data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }

    private static func sha256(_ string: String) -> String {
        sha256(Data(string.utf8))
    }
}
