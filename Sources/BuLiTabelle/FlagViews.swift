import SwiftUI
import AppKit

/// Kleines Ball-Symbol für Titel- und Kopfleisten – weiß auf dem blauen Verlauf.
struct MiniBallIcon: View {
    var size: CGFloat = 14

    var body: some View {
        Image(nsImage: .soccerBall)
            .renderingMode(.template)
            .resizable()
            .interpolation(.high)
            .frame(width: size, height: size)
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.4), radius: 0, x: 1, y: 1)
    }
}

struct LeaguePlate: View {
    let liga: Liga
    let season: String

    var body: some View {
        VStack(spacing: 0) {
            Text(liga.short)
                .font(.tahoma(13, bold: true))
                .foregroundStyle(XP.bundesligaRed)
            Text(season)
                .font(.tahoma(10))
                .foregroundStyle(XP.darkShadow)
        }
        .lineLimit(1)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .overlay(alignment: .bottom) { XP.bundesligaRed.frame(height: 2) }
        .bevel(sunken: true)
    }
}

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
