import SwiftUI
import AppKit

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

    /// Farbe, die dem System zwischen Hell- und Dunkelmodus folgt.
    ///
    /// Glas lebt davon, dass Farben auf hellem und dunklem Untergrund gleich
    /// gut sitzen – deshalb hat hier jeder Ton zwei Varianten.
    static func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            return NSColor(hex: isDark ? dark : light)
        })
    }
}

extension NSColor {
    convenience init(hex: UInt32) {
        self.init(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

/// Design-Tokens der Oberfläche: Farbe, Geometrie, Bewegung.
///
/// Flächen kommen als Material aus `GlassKit`, alles Übrige aus diesem Typ –
/// so bleibt der Look an einer Stelle einstellbar.
enum Theme {

    // MARK: - Marke

    /// Bundesliga-Rot als Akzent; im Dunkelmodus heller, damit es auf dunklem
    /// Glas nicht absäuft.
    static let accent = Color.adaptive(light: 0xC8102E, dark: 0xFF4F6B)
    static let accentDeep = Color.adaptive(light: 0x8E0B20, dark: 0xC8102E)

    /// Verlauf für hervorgehobene Knöpfe.
    static var accentGradient: LinearGradient {
        LinearGradient(colors: [accent, accentDeep], startPoint: .top, endPoint: .bottom)
    }

    /// Goldton für den Lieblingsverein.
    static let favorite = Color.adaptive(light: 0xD79A0B, dark: 0xFFC94D)

    // MARK: - Zonen & Ergebnisse

    static let zoneChampions = Color.adaptive(light: 0x1C6BF0, dark: 0x5C9CFF)
    static let zoneEuropa = Color.adaptive(light: 0xE07B1F, dark: 0xFFA94D)
    static let zoneConference = Color.adaptive(light: 0x1F9E6B, dark: 0x4ED6A0)
    static let zonePromotion = Color.adaptive(light: 0x1F9E6B, dark: 0x4ED6A0)
    static let zonePlayoff = Color.adaptive(light: 0xC79A16, dark: 0xF0C24B)
    static let zoneRelegation = Color.adaptive(light: 0xD03B2C, dark: 0xFF6B5A)

    static let win = Color.adaptive(light: 0x22A05B, dark: 0x3FD183)
    static let draw = Color.adaptive(light: 0x9AA0A6, dark: 0x8E949B)
    static let loss = Color.adaptive(light: 0xD64431, dark: 0xFF6B5A)

    // MARK: - Linien & Füllungen

    /// Feine Trennlinie auf Glas.
    static var hairline: Color { Color.primary.opacity(0.08) }
    /// Füllung für Zeilen unter dem Zeiger.
    static var hover: Color { Color.primary.opacity(0.06) }

    // MARK: - Geometrie

    enum Radius {
        static let panel: CGFloat = 18
        static let card: CGFloat = 14
        static let control: CGFloat = 10
        static let row: CGFloat = 8
    }

    // MARK: - Bewegung

    /// Weiche Feder für Auswahl, Ein- und Ausklappen.
    static let spring = Animation.spring(response: 0.34, dampingFraction: 0.82)
    /// Kurzes Feedback für Hover und Druck.
    static let quick = Animation.easeOut(duration: 0.14)

    // MARK: - Aufnahmemodus

    /// `cacheDisplay(in:to:)` zeichnet keine Echtzeit-Blur-Ebenen mit. Für den
    /// automatisierten Screenshot treten deshalb deckende Ersatzflächen an die
    /// Stelle der Materialien, damit das Bild dem echten Fenster entspricht.
    static let capturing = ProcessInfo.processInfo.environment["BULI_SCREENSHOT"] != nil
}

extension Font {
    /// Fließtext und Beschriftungen in der Systemschrift.
    static func ui(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }

    /// Zahlen in der Tabelle: gerundet und mit gleich breiten Ziffern, damit
    /// Spalten beim Blättern nicht springen.
    static func stat(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded).monospacedDigit()
    }

    /// Titel und Überschriften.
    static func display(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}
