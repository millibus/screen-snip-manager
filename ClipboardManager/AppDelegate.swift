import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private var hotKeyService: HotKeyService?
    private var pasteboardWatcher: PasteboardWatcher?
    private var expiryCleanupTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        registerDefaultPreferences()

        // Single instance: if another instance is already running, activate it and quit this launch
        if let bundleId = Bundle.main.bundleIdentifier {
            let running = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId)
            let others = running.filter { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }
            if let existing = others.first {
                existing.activate(options: [])
                NSApp.terminate(nil)
                return
            }
        }

        _ = ClipboardStore.shared
        pasteboardWatcher = PasteboardWatcher()
        menuBarController = MenuBarController()
        menuBarController?.setup()

        hotKeyService = HotKeyService()
        hotKeyService?.onHotKey = { [weak self] in
            self?.menuBarController?.toggleOverlay()
        }
        hotKeyService?.register()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(AppDelegate.hotkeyDidChange),
            name: .hotkeyDidChange,
            object: nil
        )

        expiryCleanupTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            ClipboardStore.shared.deleteExpiredEntries()
        }

        NSApp.setActivationPolicy(.accessory)
    }

    func applicationWillTerminate(_ notification: Notification) {
        expiryCleanupTimer?.invalidate()
        hotKeyService?.unregister()
    }

    private func registerDefaultPreferences() {
        UserDefaults.standard.register(defaults: [
            UserDefaultsKeys.hotkeyModifiers: UserDefaultsKeys.hotkeyModifiersDefault,
            UserDefaultsKeys.hotkeyKeyCode: Int(UserDefaultsKeys.hotkeyKeyCodeDefault),
            UserDefaultsKeys.maxHistory: UserDefaultsKeys.maxHistoryDefault,
            UserDefaultsKeys.autoPasteOnSelect: UserDefaultsKeys.autoPasteOnSelectDefault,
            UserDefaultsKeys.storeSensitiveData: UserDefaultsKeys.storeSensitiveDataDefault,
            UserDefaultsKeys.sensitiveExpirySeconds: UserDefaultsKeys.sensitiveExpirySecondsDefault,
        ])
    }

    @objc private func hotkeyDidChange() {
        hotKeyService?.reregister()
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls where url.scheme?.lowercased() == "clipboardmanager" {
            if url.host == nil || url.host == "show" || url.path == "/show" || url.path == "" {
                menuBarController?.showOverlay()
                break
            }
        }
    }
}
