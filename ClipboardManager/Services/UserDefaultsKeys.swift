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

    static var autoPasteOnSelectDefault: Bool { false }
    static var storeSensitiveDataDefault: Bool { true }
    static var sensitiveExpirySecondsDefault: Int { 60 }
    static var maxHistoryDefault: Int { 500 }
    /// Default: Cmd+Shift+V
    static var hotkeyModifiersDefault: Int { Int(cmdKey | shiftKey) }
    static var hotkeyKeyCodeDefault: UInt32 { UInt32(kVK_ANSI_V) }
}
