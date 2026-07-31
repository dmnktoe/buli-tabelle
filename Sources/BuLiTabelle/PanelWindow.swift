import SwiftUI
import AppKit

/// Randloses, durchsichtiges Fenster – die sichtbare Form gibt allein das
/// Glaspanel im Inhalt vor (abgerundete Ecken, Kante, Material).
final class GlassPanelWindow: NSWindow {
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

    /// Wird beim Druck auf Escape ausgelöst.
    var onCancel: () -> Void = {}

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func cancelOperation(_ sender: Any?) {
        onCancel()
    }
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
        let window = GlassPanelWindow()
        let closer = PanelCloser()
        closer.action = { [weak self, weak window] in
            window?.close()
            self?.windows[id] = nil
        }
        window.onCancel = { closer.close() }
        let host = NSHostingView(rootView: content(closer))
        window.contentView = host
        window.setContentSize(host.fittingSize)
        window.center()
        windows[id] = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
