import SwiftUI
import AppKit

extension NSImage {
    /// Fußball als Template-Image: macOS färbt es selbst passend zur hellen oder
    /// dunklen Menüleiste. Vektor-PDF, damit jede Auflösung scharf bleibt.
    static let soccerBall: NSImage = {
        let image = Bundle.main.url(forResource: "MenuBarBall", withExtension: "pdf")
            .flatMap { NSImage(contentsOf: $0) } ?? ringFallback()
        image.size = NSSize(width: 15, height: 15)
        image.isTemplate = true
        return image
    }()

    /// Ohne App-Bundle (etwa bei `swift run`) gibt es keine Ressourcen –
    /// dann wenigstens ein schlichter Ring statt eines leeren Platzhalters.
    private static func ringFallback() -> NSImage {
        NSImage(size: NSSize(width: 15, height: 15), flipped: false) { rect in
            NSColor.black.setStroke()
            let ring = NSBezierPath(ovalIn: rect.insetBy(dx: 1.5, dy: 1.5))
            ring.lineWidth = 1.5
            ring.stroke()
            return true
        }
    }
}
