import AppKit
import Carbon
import Foundation

/// Registers a global hotkey using Carbon API. Key and modifiers are read from UserDefaults.
final class HotKeyService {
    private var eventHandler: EventHandlerRef?
    private var hotKeyRef: EventHotKeyRef?
    private let signature: OSType = 0x434C_4D47 // "CLMG"
    private let id: UInt32 = 1
    var onHotKey: (() -> Void)?

    private var currentModifiers: UInt32 {
        let raw = UserDefaults.standard.object(forKey: UserDefaultsKeys.hotkeyModifiers) as? Int ?? UserDefaultsKeys.hotkeyModifiersDefault
        return UInt32(truncatingIfNeeded: raw)
    }

    private var currentKeyCode: UInt32 {
        UInt32(UserDefaults.standard.integer(forKey: UserDefaultsKeys.hotkeyKeyCode))
    }

    func register() {
        unregister()
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userData) -> OSStatus in
                guard let userData else { return OSStatus(eventNotHandledErr) }
                let service = Unmanaged<HotKeyService>.fromOpaque(userData).takeUnretainedValue()
                DispatchQueue.main.async { service.onHotKey?() }
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )
        guard status == noErr else { return }

        let hotKeyID = EventHotKeyID(signature: signature, id: id)
        let regStatus = RegisterEventHotKey(
            currentKeyCode,
            currentModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        if regStatus != noErr {
            if let handler = eventHandler {
                RemoveEventHandler(handler)
                eventHandler = nil
            }
        }
    }

    /// Call after user changes hotkey in preferences to re-register with new key.
    func reregister() {
        register()
    }

    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
    }

    deinit {
        unregister()
    }

    /// Human-readable string for modifiers + key code (e.g. "⌘⇧V").
    static func displayString(modifiers: Int, keyCode: UInt32) -> String {
        var parts: [String] = []
        let m = UInt32(modifiers)
        if (m & UInt32(cmdKey)) != 0 { parts.append("⌘") }
        if (m & UInt32(shiftKey)) != 0 { parts.append("⇧") }
        if (m & UInt32(optionKey)) != 0 { parts.append("⌥") }
        if (m & UInt32(controlKey)) != 0 { parts.append("⌃") }
        if let char = keyCodeToCharacter(keyCode) {
            parts.append(String(char))
        } else {
            parts.append("Key \(keyCode)")
        }
        return parts.joined()
    }
}

private func keyCodeToCharacter(_ keyCode: UInt32) -> Character? {
    let map: [UInt32: Character] = [
        UInt32(kVK_ANSI_A): "A", UInt32(kVK_ANSI_B): "B", UInt32(kVK_ANSI_C): "C", UInt32(kVK_ANSI_D): "D",
        UInt32(kVK_ANSI_E): "E", UInt32(kVK_ANSI_F): "F", UInt32(kVK_ANSI_G): "G", UInt32(kVK_ANSI_H): "H",
        UInt32(kVK_ANSI_I): "I", UInt32(kVK_ANSI_J): "J", UInt32(kVK_ANSI_K): "K", UInt32(kVK_ANSI_L): "L",
        UInt32(kVK_ANSI_M): "M", UInt32(kVK_ANSI_N): "N", UInt32(kVK_ANSI_O): "O", UInt32(kVK_ANSI_P): "P",
        UInt32(kVK_ANSI_Q): "Q", UInt32(kVK_ANSI_R): "R", UInt32(kVK_ANSI_S): "S", UInt32(kVK_ANSI_T): "T",
        UInt32(kVK_ANSI_U): "U", UInt32(kVK_ANSI_V): "V", UInt32(kVK_ANSI_W): "W", UInt32(kVK_ANSI_X): "X",
        UInt32(kVK_ANSI_Y): "Y", UInt32(kVK_ANSI_Z): "Z",
        UInt32(kVK_Space): "␣", UInt32(kVK_Return): "↵", UInt32(kVK_Escape): "⎋",
        UInt32(kVK_Tab): "⇥", UInt32(kVK_Delete): "⌫", UInt32(kVK_ForwardDelete): "⌦"
    ]
    return map[keyCode]
}
