import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

/// Windows-XP-„Luna"-Palette und geteilte Stil-Bausteine.
enum XP {
    static let face = Color(hex: 0xECE9D8)
    static let shadow = Color(hex: 0xACA899)
    static let darkShadow = Color(hex: 0x716F64)
    static let highlight = Color.white

    static let titleTop = Color(hex: 0x4A8CF7)
    static let titleMid = Color(hex: 0x1E56C8)
    static let titleBottom = Color(hex: 0x16419E)

    static let linkBlue = Color(hex: 0x0000EE)
    static let spieltagGreen = Color(hex: 0x008000)

    static let zoneCL = Color(hex: 0x9FE89F)
    static let zoneEL = Color(hex: 0xC4F0C4)
    static let zoneECL = Color(hex: 0xE2F8E2)
    static let zoneRelegation = Color(hex: 0xFFC8D6)
    static let zoneAbstieg = Color(hex: 0xFF9E9E)

    static let selectionFill = Color(hex: 0xFFF3C2)
    static let selectionBorder = Color(hex: 0xE0A000)
    static let favoriteFill = Color(hex: 0xFFF6DC)

    static let flagRed = Color(hex: 0xEE1C25)
    static let flagYellow = Color(hex: 0xFFE600)

    static let btnInfoGreen = Color(hex: 0xC4EFC0)
    static let btnBugPink = Color(hex: 0xFFC0CF)

    /// Blauer Luna-Verlauf für Titel-/Kopfleisten.
    static let titleGradient = LinearGradient(
        colors: [titleTop, titleMid, titleBottom],
        startPoint: .top, endPoint: .bottom
    )
}

extension Font {
    /// Tahoma (mit macOS mitgeliefert), mit System-Fallback falls nicht vorhanden.
    static func tahoma(_ size: CGFloat, bold: Bool = false) -> Font {
        let name = bold ? "Tahoma-Bold" : "Tahoma"
        if NSFont(name: name, size: size) != nil {
            return .custom(name, size: size)
        }
        return .system(size: size, weight: bold ? .bold : .regular)
    }
}
