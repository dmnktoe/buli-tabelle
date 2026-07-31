import Foundation

/// Zentrale Datumsformatierung für OpenLigaDB-Anstoßzeiten.
enum MatchDate {
    private static let parser: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        // Fixed-Format-Maschinendatum: POSIX-Locale, unabhängig von Regionseinstellungen.
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private static let display: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EE dd.MM. HH:mm"
        f.locale = Locale(identifier: "de_DE")
        return f
    }()

    /// Wandelt einen ISO-Anstoß-String in „Sa 30.08. 15:30" um; leer, wenn nicht parsebar.
    static func kickoff(_ raw: String?) -> String {
        guard let raw, let date = parser.date(from: raw) else { return "" }
        return display.string(from: date)
    }
}

extension OLMatch {
    /// Formatierte Anstoßzeit für die Anzeige.
    var kickoffText: String { MatchDate.kickoff(matchDateTime) }
}
