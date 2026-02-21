import AppKit
import Carbon
import SwiftUI

struct PreferencesView: View {
    @AppStorage(UserDefaultsKeys.autoPasteOnSelect) private var autoPasteOnSelect = UserDefaultsKeys.autoPasteOnSelectDefault
    @AppStorage(UserDefaultsKeys.storeSensitiveData) private var storeSensitiveData = UserDefaultsKeys.storeSensitiveDataDefault
    @AppStorage(UserDefaultsKeys.sensitiveExpirySeconds) private var sensitiveExpirySeconds = UserDefaultsKeys.sensitiveExpirySecondsDefault
    @AppStorage(UserDefaultsKeys.maxHistory) private var maxHistory = UserDefaultsKeys.maxHistoryDefault

    @State private var hotkeyDisplay: String = ""
    @State private var isRecordingHotkey = false
    @State private var localMonitor: Any?

    var body: some View {
        Form {
            Section("General") {
                Toggle("Auto-paste on select", isOn: $autoPasteOnSelect)
                    .help("After choosing an entry, simulate ⌘V to paste into the frontmost app.")
                HStack {
                    Text("Max history")
                    Spacer()
                    Stepper(value: $maxHistory, in: 100...10_000, step: 100) {
                        Text("\(maxHistory)")
                            .frame(minWidth: 50, alignment: .trailing)
                    }
                    .onChange(of: maxHistory) { _, newValue in
                        maxHistory = min(10_000, max(100, newValue))
                    }
                }
                .help("Maximum number of entries to keep. Oldest non-pinned entries are removed when exceeded.")
            }

            Section("Hotkey") {
                HStack {
                    Text("Show overlay")
                    Spacer()
                    Text(hotkeyDisplay)
                        .foregroundStyle(.secondary)
                        .font(.system(.body, design: .monospaced))
                    Button(isRecordingHotkey ? "Press key…" : "Change") {
                        if isRecordingHotkey {
                            stopRecordingHotkey()
                        } else {
                            startRecordingHotkey()
                        }
                    }
                }
                .onAppear {
                    updateHotkeyDisplay()
                }
            }

            Section("Sensitive data") {
                Toggle("Store sensitive data (short expiry)", isOn: $storeSensitiveData)
                    .help("When on, content that looks like passwords/tokens is stored with a short expiry. When off, such content is not stored.")
                if storeSensitiveData {
                    HStack {
                        Text("Sensitive expiry (seconds)")
                        Spacer()
                        TextField("", value: $sensitiveExpirySeconds, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                            .onChange(of: sensitiveExpirySeconds) { _, newValue in
                                sensitiveExpirySeconds = min(86400, max(10, newValue))
                            }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 340)
        .onDisappear {
            stopRecordingHotkey()
        }
        .onReceive(NotificationCenter.default.publisher(for: .hotkeyRecordingEnded)) { _ in
            isRecordingHotkey = false
            updateHotkeyDisplay()
            stopRecordingHotkey()
        }
    }

    private func updateHotkeyDisplay() {
        let mods = UserDefaults.standard.object(forKey: UserDefaultsKeys.hotkeyModifiers) as? Int ?? UserDefaultsKeys.hotkeyModifiersDefault
        let code = UInt32(UserDefaults.standard.integer(forKey: UserDefaultsKeys.hotkeyKeyCode))
        hotkeyDisplay = HotKeyService.displayString(modifiers: mods, keyCode: code)
    }

    private func startRecordingHotkey() {
        isRecordingHotkey = true
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let mods = Int(event.modifierFlags.carbonFlags)
            let code = UInt32(event.keyCode)
            
            DispatchQueue.main.async {
                UserDefaults.standard.set(mods, forKey: UserDefaultsKeys.hotkeyModifiers)
                UserDefaults.standard.set(Int(code), forKey: UserDefaultsKeys.hotkeyKeyCode)
                NotificationCenter.default.post(name: .hotkeyDidChange, object: nil)
                NotificationCenter.default.post(name: .hotkeyRecordingEnded, object: nil)
            }
            return nil
        }
    }

    private func stopRecordingHotkey() {
        isRecordingHotkey = false
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }
}

extension Notification.Name {
    static let hotkeyDidChange = Notification.Name("hotkeyDidChange")
    static let hotkeyRecordingEnded = Notification.Name("hotkeyRecordingEnded")
}

extension NSEvent.ModifierFlags {
    var carbonFlags: UInt32 {
        var flags: UInt32 = 0
        if contains(.command) { flags |= UInt32(cmdKey) }
        if contains(.shift) { flags |= UInt32(shiftKey) }
        if contains(.option) { flags |= UInt32(optionKey) }
        if contains(.control) { flags |= UInt32(controlKey) }
        if contains(.capsLock) { flags |= UInt32(alphaLock) }
        return flags
    }
}
