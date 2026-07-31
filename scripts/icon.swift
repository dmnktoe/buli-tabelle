import AppKit

// Ersatz-Icon, falls kein `Resources/AppIconSource.png` vorliegt: eine Tabelle
// als Glaskarte auf markenrotem Grund – dieselbe Sprache wie die App selbst.

let size: CGFloat = 512
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()

let plate = NSRect(x: 26, y: 26, width: size - 52, height: size - 52)
NSBezierPath(roundedRect: plate, xRadius: 112, yRadius: 112).addClip()

let accentTop = NSColor(srgbRed: 0.847, green: 0.106, blue: 0.227, alpha: 1)
let accentMid = NSColor(srgbRed: 0.784, green: 0.063, blue: 0.180, alpha: 1)
let accentBottom = NSColor(srgbRed: 0.557, green: 0.043, blue: 0.125, alpha: 1)

let upper = NSRect(x: plate.minX, y: plate.midY, width: plate.width, height: plate.height / 2)
let lower = NSRect(x: plate.minX, y: plate.minY, width: plate.width, height: plate.height / 2)
NSGradient(starting: accentTop, ending: accentMid)?.draw(in: upper, angle: -90)
NSGradient(starting: accentMid, ending: accentBottom)?.draw(in: lower, angle: -90)

let card = NSRect(x: 104, y: 116, width: 304, height: 280)
let cardShape = NSBezierPath(roundedRect: card, xRadius: 34, yRadius: 34)
let rowHeight: CGFloat = 46
let headHeight = card.height - 5 * rowHeight

NSGraphicsContext.current?.saveGraphicsState()
cardShape.addClip()

// Glaskarte: heller Verlauf statt deckendem Weiß.
NSGradient(starting: NSColor(white: 1, alpha: 0.97),
           ending: NSColor(white: 1, alpha: 0.86))?.draw(in: card, angle: -90)

let head = NSRect(x: card.minX, y: card.maxY - headHeight, width: card.width, height: headHeight)
let headInk = NSColor(white: 0.42, alpha: 1)
headInk.setFill()
for (x, w) in [(card.minX + 26, CGFloat(40)), (card.minX + 84, CGFloat(90)), (card.maxX - 66, CGFloat(40))] {
    NSBezierPath(roundedRect: NSRect(x: x, y: head.midY - 4, width: w, height: 8),
                 xRadius: 4, yRadius: 4).fill()
}

let zoneChampions = NSColor(srgbRed: 0.110, green: 0.420, blue: 0.941, alpha: 1)
let zonePlayoff = NSColor(srgbRed: 0.780, green: 0.604, blue: 0.086, alpha: 1)
let zoneRelegation = NSColor(srgbRed: 0.816, green: 0.231, blue: 0.173, alpha: 1)
let separator = NSColor(white: 0, alpha: 0.08)
let barInk = NSColor(white: 0.24, alpha: 1)

let rowZones: [NSColor?] = [zoneChampions, nil, nil, zonePlayoff, zoneRelegation]

for (index, zone) in rowZones.enumerated() {
    let row = NSRect(x: card.minX,
                     y: head.minY - CGFloat(index + 1) * rowHeight,
                     width: card.width,
                     height: rowHeight)

    if index < rowZones.count - 1 {
        separator.setFill()
        NSRect(x: row.minX + 20, y: row.minY, width: row.width - 40, height: 2).fill()
    }

    // Zonenbalken am linken Rand statt flächiger Einfärbung.
    if let zone {
        zone.setFill()
        NSBezierPath(roundedRect: NSRect(x: row.minX + 14, y: row.midY - 13, width: 6, height: 26),
                     xRadius: 3, yRadius: 3).fill()
    }

    barInk.setFill()
    NSBezierPath(ovalIn: NSRect(x: row.minX + 32, y: row.midY - 7, width: 14, height: 14)).fill()
    NSBezierPath(roundedRect: NSRect(x: row.minX + 60, y: row.midY - 6, width: 118, height: 12),
                 xRadius: 6, yRadius: 6).fill()
    NSBezierPath(roundedRect: NSRect(x: row.maxX - 62, y: row.midY - 6, width: 40, height: 12),
                 xRadius: 6, yRadius: 6).fill()
}

NSGraphicsContext.current?.restoreGraphicsState()

// Lichtkante der Glaskarte.
NSColor(white: 1, alpha: 0.9).setStroke()
let edge = NSBezierPath(roundedRect: card.insetBy(dx: 1, dy: 1), xRadius: 33, yRadius: 33)
edge.lineWidth = 2
edge.stroke()

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    fputs("Icon-Rendering fehlgeschlagen\n", stderr)
    exit(1)
}
try png.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
