import SwiftUI
import AppKit

/// Kleines Deutschland-Fähnchen (schwarz-rot-gold) für Titel-/Kopfleisten.
struct MiniFlagIcon: View {
    var body: some View {
        VStack(spacing: 0) {
            Color.black
            XP.flagRed
            XP.flagYellow
        }
        .frame(width: 16, height: 13)
        .overlay(Rectangle().strokeBorder(Color.white.opacity(0.8), lineWidth: 1))
    }
}

struct LeaguePlate: View {
    let liga: Liga
    let season: String

    var body: some View {
        VStack(spacing: 0) {
            Text(liga.short)
                .font(.tahoma(13, bold: true))
                .foregroundStyle(.black)
            Text(season)
                .font(.tahoma(10))
                .foregroundStyle(XP.darkShadow)
        }
        .lineLimit(1)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .bevel(sunken: true)
    }
}

extension NSImage {
    /// Menüleisten-Symbol: gezeichnetes Deutschland-Fähnchen.
    static let menuBarFlag: NSImage = {
        let size = NSSize(width: 18, height: 12)
        let image = NSImage(size: size, flipped: false) { rect in
            let h = rect.height / 3
            NSColor.black.setFill()
            NSRect(x: rect.minX, y: rect.minY + 2 * h, width: rect.width, height: h).fill()
            NSColor(srgbRed: 0.933, green: 0.110, blue: 0.145, alpha: 1).setFill()
            NSRect(x: rect.minX, y: rect.minY + h, width: rect.width, height: h).fill()
            NSColor(srgbRed: 1.0, green: 0.902, blue: 0.0, alpha: 1).setFill()
            NSRect(x: rect.minX, y: rect.minY, width: rect.width, height: h).fill()
            NSColor.white.withAlphaComponent(0.85).setStroke()
            let border = NSBezierPath(rect: rect.insetBy(dx: 0.5, dy: 0.5))
            border.lineWidth = 1
            border.stroke()
            return true
        }
        image.isTemplate = false
        return image
    }()
}
