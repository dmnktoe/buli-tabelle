import SwiftUI
import AppKit

final class RetroPanelWindow: NSWindow {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 240),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        isMovableByWindowBackground = true
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        isReleasedWhenClosed = false
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class PanelCloser {
    var action: () -> Void = {}
    func close() { action() }
}

@MainActor
final class PanelWindows {
    private var windows: [String: NSWindow] = [:]

    func show<Content: View>(_ id: String, @ViewBuilder content: (PanelCloser) -> Content) {
        if let existing = windows[id] {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let window = RetroPanelWindow()
        let closer = PanelCloser()
        closer.action = { [weak self, weak window] in
            window?.close()
            self?.windows[id] = nil
        }
        let host = NSHostingView(rootView: content(closer))
        window.contentView = host
        window.setContentSize(host.fittingSize)
        window.center()
        windows[id] = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
