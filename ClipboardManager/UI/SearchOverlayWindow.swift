import AppKit
import SwiftUI

final class SearchOverlayWindow: NSPanel {
    private let hostingView: NSHostingView<SearchOverlayView>
    private let refreshTrigger = OverlayRefreshTrigger()
    private var clickMonitor: Any?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    init(onSelect: @escaping (ClipboardEntry) -> Void, onDismiss: @escaping () -> Void) {
        let overlayView = SearchOverlayView(refreshTrigger: refreshTrigger, onSelect: onSelect, onDismiss: onDismiss)
        hostingView = NSHostingView(rootView: overlayView)
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        level = .floating
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isMovableByWindowBackground = true
        hasShadow = true
        contentView = hostingView
    }

    func show() {
        refreshTrigger.refresh()
        center()
        makeKeyAndOrderFront(nil)
        if let existing = clickMonitor {
            NSEvent.removeMonitor(existing)
        }
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self, self.isVisible else { return }
            self.hide()
        }
    }

    func hide() {
        if let monitor = clickMonitor {
            NSEvent.removeMonitor(monitor)
            clickMonitor = nil
        }
        orderOut(nil)
    }

    override func cancelOperation(_ sender: Any?) {
        hide()
    }

    func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }
}
