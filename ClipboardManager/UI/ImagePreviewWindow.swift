import AppKit
import SwiftUI

final class ImagePreviewWindow: NSWindow {
    convenience init(image: NSImage, title: String = "Image Preview") {
        let imageSize = image.size
        guard let screen = NSScreen.main else {
            self.init(contentRect: .zero, styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
            return
        }

        let maxW = screen.visibleFrame.width * 0.8
        let maxH = screen.visibleFrame.height * 0.8
        let scale = min(maxW / imageSize.width, maxH / imageSize.height, 1.0)
        let windowSize = NSSize(width: imageSize.width * scale, height: imageSize.height * scale)

        let contentRect = NSRect(
            x: screen.visibleFrame.midX - windowSize.width / 2,
            y: screen.visibleFrame.midY - windowSize.height / 2,
            width: windowSize.width,
            height: windowSize.height
        )

        self.init(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        self.title = title
        isReleasedWhenClosed = false

        let hostingView = NSHostingView(rootView:
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(minWidth: 100, minHeight: 100)
        )
        contentView = hostingView
    }

    /// Show the preview without activating the app, so the frontmost app (and auto-paste target) is unchanged.
    func showWindow() {
        orderFrontRegardless()
    }
}
