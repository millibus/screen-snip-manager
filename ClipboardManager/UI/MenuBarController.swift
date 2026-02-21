import AppKit
import Carbon
import SwiftUI

final class MenuBarController: NSObject {
    private var statusItem: NSStatusItem?
    private var overlayWindow: SearchOverlayWindow?
    private var menu: NSMenu?
    private var preferencesWindowController: PreferencesWindowController?

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Clipboard Manager")
        statusItem?.button?.action = #selector(MenuBarController.showMenu)
        statusItem?.button?.target = self

        overlayWindow = SearchOverlayWindow(onSelect: { [weak self] entry in
            self?.copyToPasteboard(entry)
            self?.overlayWindow?.hide()
            if UserDefaults.standard.bool(forKey: UserDefaultsKeys.autoPasteOnSelect) {
                self?.simulatePaste()
            }
        }, onDismiss: { [weak self] in
            self?.overlayWindow?.hide()
        })
        buildMenu()
    }

    private func buildMenu() {
        let m = NSMenu()
        let showItem = NSMenuItem(title: "Show Clipboard", action: #selector(MenuBarController.toggleOverlay), keyEquivalent: "")
        showItem.target = self
        m.addItem(showItem)
        m.addItem(NSMenuItem.separator())
        let prefsItem = NSMenuItem(title: "Preferences…", action: #selector(MenuBarController.showPreferences), keyEquivalent: ",")
        prefsItem.target = self
        m.addItem(prefsItem)
        let aboutItem = NSMenuItem(title: "About Clipboard Manager", action: #selector(MenuBarController.showAbout), keyEquivalent: "")
        aboutItem.target = self
        m.addItem(aboutItem)
        m.addItem(NSMenuItem.separator())
        let autoPasteItem = NSMenuItem(
            title: "Auto-paste on select",
            action: #selector(MenuBarController.toggleAutoPaste),
            keyEquivalent: ""
        )
        autoPasteItem.target = self
        autoPasteItem.state = UserDefaults.standard.bool(forKey: UserDefaultsKeys.autoPasteOnSelect) ? .on : .off
        m.addItem(autoPasteItem)
        let storeSensitiveItem = NSMenuItem(
            title: "Store sensitive data (short expiry)",
            action: #selector(MenuBarController.toggleStoreSensitive),
            keyEquivalent: ""
        )
        storeSensitiveItem.target = self
        storeSensitiveItem.state = (UserDefaults.standard.object(forKey: UserDefaultsKeys.storeSensitiveData) as? Bool) ?? UserDefaultsKeys.storeSensitiveDataDefault ? .on : .off
        m.addItem(storeSensitiveItem)
        m.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.target = NSApp
        m.addItem(quitItem)
        menu = m
    }

    @objc private func showMenu() {
        guard let button = statusItem?.button, let menu = menu else { return }
        menu.items.forEach { item in
            if item.title == "Auto-paste on select" {
                item.state = UserDefaults.standard.bool(forKey: UserDefaultsKeys.autoPasteOnSelect) ? .on : .off
            } else if item.title == "Store sensitive data (short expiry)" {
                item.state = ((UserDefaults.standard.object(forKey: UserDefaultsKeys.storeSensitiveData) as? Bool) ?? UserDefaultsKeys.storeSensitiveDataDefault) ? .on : .off
            }
        }
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height), in: button)
    }

    @objc func toggleOverlay() {
        overlayWindow?.toggle()
    }

    @objc private func showPreferences() {
        if preferencesWindowController == nil {
            preferencesWindowController = PreferencesWindowController()
        }
        preferencesWindowController?.show()
    }

    @objc private func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(options: [
            NSApplication.AboutPanelOptionKey.credits: NSAttributedString(
                string: "Menu bar clipboard history with search, pins, tags, and optional sensitive-data handling.",
                attributes: [.font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)]
            ),
        ])
    }

    @objc private func toggleAutoPaste() {
        let key = UserDefaultsKeys.autoPasteOnSelect
        let next = !UserDefaults.standard.bool(forKey: key)
        UserDefaults.standard.set(next, forKey: key)
    }

    @objc private func toggleStoreSensitive() {
        let key = UserDefaultsKeys.storeSensitiveData
        let current = UserDefaults.standard.object(forKey: key) as? Bool ?? UserDefaultsKeys.storeSensitiveDataDefault
        UserDefaults.standard.set(!current, forKey: key)
    }

    func showOverlay() {
        overlayWindow?.show()
    }

    func hideOverlay() {
        overlayWindow?.hide()
    }

    private func copyToPasteboard(_ entry: ClipboardEntry) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        switch entry.contentType {
        case .text:
            if let text = entry.textContent {
                pasteboard.setString(text, forType: .string)
            }
        case .image:
            if let data = entry.imageData, let image = NSImage(data: data) {
                pasteboard.writeObjects([image])
            }
        }
    }

    private func simulatePaste() {
        let work = DispatchWorkItem {
            guard let source = CGEventSource(stateID: .hidSystemState) else { return }
            let keyCode = CGKeyCode(kVK_ANSI_V)
            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
            keyDown?.flags = .maskCommand
            keyUp?.flags = .maskCommand
            if let kd = keyDown {
                kd.post(tap: .cghidEventTap)
            }
            if let ku = keyUp {
                ku.post(tap: .cghidEventTap)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: work)
    }
}
