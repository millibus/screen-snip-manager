import AppKit
import SwiftUI

final class SearchOverlayWindow: NSPanel {
    private let hostingView: NSHostingView<SearchOverlayView>
    private let refreshTrigger = OverlayRefreshTrigger()

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
        contentView = hostingView
    }

    func show() {
        refreshTrigger.refresh()
        center()
        makeKeyAndOrderFront(nil)
    }

    func hide() {
        orderOut(nil)
    }

    func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }
}
