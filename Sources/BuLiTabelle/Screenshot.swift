import AppKit

/// Nimmt das Hauptfenster scharf (2×) auf und setzt es – je nach Stil – mittig
/// auf einen generierten 16:9-Hintergrund im XP-Look. Gesteuert über Umgebungs-
/// variablen, damit CI/`swift run` das Bild ohne Bildschirmaufnahme erzeugen können:
///
/// - `BULI_SCREENSHOT`        Zielpfad der PNG-Datei (aktiviert die Aufnahme).
/// - `BULI_SCREENSHOT_SCALE`  Renderfaktor, Standard `2` (Retina-scharf).
/// - `BULI_SCREENSHOT_BG`     `xp` (Luna-Blau, Standard) · `gray` · `none` (nur Fenster).
enum ScreenshotComposer {
    static func scheduleIfRequested() {
        guard let path = ProcessInfo.processInfo.environment["BULI_SCREENSHOT"] else { return }
        let env = ProcessInfo.processInfo.environment
        let scale = env["BULI_SCREENSHOT_SCALE"].flatMap(Double.init).map { CGFloat($0) } ?? 2
        let style = env["BULI_SCREENSHOT_BG"] ?? "xp"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            guard let window = NSApp.windows.first(where: { $0.frame.width > 500 }),
                  let frameView = window.contentView?.superview else { return }
            capture(frameView, to: URL(fileURLWithPath: path), scale: scale, style: style)
        }
    }

    static func capture(_ view: NSView, to url: URL, scale: CGFloat, style: String) {
        guard view.bounds.width > 0, view.bounds.height > 0,
              let shot = snapshot(of: view, scale: scale) else { return }
        let result = style == "none" ? shot : compose(window: shot, style: style, scale: scale)
        try? result?.representation(using: .png, properties: [:])?.write(to: url)
    }

    // MARK: - Fenster-Snapshot (2×)

    private static func snapshot(of view: NSView, scale: CGFloat) -> NSBitmapImageRep? {
        let bounds = view.bounds
        guard let rep = bitmap(width: bounds.width, height: bounds.height, scale: scale) else { return nil }
        rep.size = bounds.size
        view.cacheDisplay(in: bounds, to: rep)
        return rep
    }

    // MARK: - Komposition auf 16:9-Hintergrund

    private static func compose(window rep: NSBitmapImageRep, style: String, scale: CGFloat) -> NSBitmapImageRep? {
        let windowSize = rep.size
        // Rand ums Fenster, dann kleinste 16:9-Leinwand, die Fenster + Rand fasst.
        let margin = max(windowSize.width, windowSize.height) * 0.14
        var canvasW = windowSize.width + margin * 2
        var canvasH = canvasW * 9 / 16
        if canvasH < windowSize.height + margin * 2 {
            canvasH = windowSize.height + margin * 2
            canvasW = canvasH * 16 / 9
        }

        guard let canvas = bitmap(width: canvasW, height: canvasH, scale: scale) else { return nil }
        canvas.size = CGSize(width: canvasW, height: canvasH)
        guard let ctx = NSGraphicsContext(bitmapImageRep: canvas) else { return nil }

        let previous = NSGraphicsContext.current
        NSGraphicsContext.current = ctx
        defer {
            ctx.flushGraphics()
            NSGraphicsContext.current = previous
        }

        drawBackground(style: style, in: NSRect(x: 0, y: 0, width: canvasW, height: canvasH))

        let origin = NSPoint(x: ((canvasW - windowSize.width) / 2).rounded(),
                             y: ((canvasH - windowSize.height) / 2).rounded())
        let windowRect = NSRect(origin: origin, size: windowSize)

        ctx.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
        shadow.shadowOffset = NSSize(width: 0, height: -margin * 0.12) // AppKit ist y-up: negativ = nach unten
        shadow.shadowBlurRadius = margin * 0.4
        shadow.set()

        let image = NSImage(size: windowSize)
        image.addRepresentation(rep)
        image.draw(in: windowRect, from: .zero, operation: .sourceOver, fraction: 1)
        ctx.restoreGraphicsState()

        return canvas
    }

    private static func drawBackground(style: String, in rect: NSRect) {
        let colors: [NSColor]
        if style == "gray" {
            colors = [NSColor(srgbRed: 0.94, green: 0.94, blue: 0.95, alpha: 1),
                      NSColor(srgbRed: 0.82, green: 0.83, blue: 0.86, alpha: 1)]
        } else { // "xp" – helle Luna-Blau-Anmutung, passend zur Titelleiste
            colors = [NSColor(srgbRed: 0.85, green: 0.91, blue: 0.99, alpha: 1),
                      NSColor(srgbRed: 0.60, green: 0.73, blue: 0.92, alpha: 1),
                      NSColor(srgbRed: 0.40, green: 0.55, blue: 0.83, alpha: 1)]
        }
        NSGradient(colors: colors)?.draw(in: rect, angle: -90) // erste Farbe oben
    }

    private static func bitmap(width: CGFloat, height: CGFloat, scale: CGFloat) -> NSBitmapImageRep? {
        let pxW = Int((width * scale).rounded())
        let pxH = Int((height * scale).rounded())
        guard pxW > 0, pxH > 0 else { return nil }
        return NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: pxW, pixelsHigh: pxH,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
        )
    }
}
