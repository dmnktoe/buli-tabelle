import AppKit

let size: CGFloat = 512
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()

let plate = NSRect(x: 26, y: 26, width: size - 52, height: size - 52)
NSBezierPath(roundedRect: plate, xRadius: 90, yRadius: 90).addClip()

let lunaTop = NSColor(srgbRed: 0.290, green: 0.549, blue: 0.969, alpha: 1)
let lunaMid = NSColor(srgbRed: 0.118, green: 0.337, blue: 0.784, alpha: 1)
let lunaBottom = NSColor(srgbRed: 0.086, green: 0.255, blue: 0.620, alpha: 1)

let upper = NSRect(x: plate.minX, y: plate.midY, width: plate.width, height: plate.height / 2)
let lower = NSRect(x: plate.minX, y: plate.minY, width: plate.width, height: plate.height / 2)
NSGradient(starting: lunaTop, ending: lunaMid)?.draw(in: upper, angle: -90)
NSGradient(starting: lunaMid, ending: lunaBottom)?.draw(in: lower, angle: -90)

let card = NSRect(x: 104, y: 116, width: 304, height: 280)
let rowHeight: CGFloat = 46
let headHeight = card.height - 5 * rowHeight

NSColor.white.setFill()
card.fill()

let head = NSRect(x: card.minX, y: card.maxY - headHeight, width: card.width, height: headHeight)
NSColor.black.setFill()
head.fill()

NSColor(white: 1, alpha: 0.85).setFill()
for (x, w) in [(card.minX + 22, CGFloat(46)), (card.minX + 82, CGFloat(96)), (card.maxX - 66, CGFloat(44))] {
    NSBezierPath(roundedRect: NSRect(x: x, y: head.midY - 5, width: w, height: 10),
                 xRadius: 5, yRadius: 5).fill()
}

let zoneCL = NSColor(srgbRed: 0.624, green: 0.910, blue: 0.624, alpha: 1)
let zoneRelegation = NSColor(srgbRed: 1.0, green: 0.784, blue: 0.839, alpha: 1)
let zoneAbstieg = NSColor(srgbRed: 1.0, green: 0.620, blue: 0.620, alpha: 1)
let separator = NSColor(srgbRed: 0.894, green: 0.886, blue: 0.847, alpha: 1)
let barInk = NSColor(white: 0.18, alpha: 1)

let rowFills: [NSColor] = [zoneCL, .white, .white, zoneRelegation, zoneAbstieg]

for (index, tint) in rowFills.enumerated() {
    let row = NSRect(x: card.minX,
                     y: head.minY - CGFloat(index + 1) * rowHeight,
                     width: card.width,
                     height: rowHeight)
    tint.setFill()
    row.fill()

    separator.setFill()
    NSRect(x: row.minX, y: row.minY, width: row.width, height: 2).fill()

    barInk.setFill()
    NSBezierPath(ovalIn: NSRect(x: row.minX + 22, y: row.midY - 7, width: 14, height: 14)).fill()
    NSBezierPath(roundedRect: NSRect(x: row.minX + 56, y: row.midY - 6, width: 122, height: 12),
                 xRadius: 6, yRadius: 6).fill()
    NSBezierPath(roundedRect: NSRect(x: row.maxX - 62, y: row.midY - 6, width: 40, height: 12),
                 xRadius: 6, yRadius: 6).fill()
}

NSColor(srgbRed: 0.443, green: 0.435, blue: 0.392, alpha: 1).setStroke()
let border = NSBezierPath(rect: card.insetBy(dx: 1, dy: 1))
border.lineWidth = 2
border.stroke()

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    fputs("Icon-Rendering fehlgeschlagen\n", stderr)
    exit(1)
}
try png.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
