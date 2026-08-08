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

    /// Für `matchDateTimeUTC` („2026-08-08T13:30:00Z“).
    private static let utcParser: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    /// Dieselbe Angabe, falls sie ausnahmsweise Sekundenbruchteile mitbringt.
    private static let utcParserWithFraction: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let display: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EE dd.MM. HH:mm"
        f.locale = Locale(identifier: "de_DE")
        return f
    }()

    private static let clock: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.locale = Locale(identifier: "de_DE")
        return f
    }()

    private static let clockWithSeconds: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        f.locale = Locale(identifier: "de_DE")
        return f
    }()

    /// Anstoßzeitpunkt einer Partie.
    ///
    /// Die UTC-Angabe der API ist eindeutig und hat deshalb Vorrang; `matchDateTime`
    /// ist deutsche Ortszeit ohne Zeitzone und wird nur als Rückfallebene gelesen.
    static func kickoff(utc: String?, local: String?) -> Date? {
        if let utc, !utc.isEmpty {
            if let date = utcParser.date(from: utc) { return date }
            if let date = utcParserWithFraction.date(from: utc) { return date }
        }
        guard let local else { return nil }
        return parser.date(from: local)
    }

    /// „Sa 30.08. 15:30“
    static func dayAndTime(_ date: Date) -> String { display.string(from: date) }

    /// „15:30“
    static func time(_ date: Date) -> String { clock.string(from: date) }

    /// „15:30:07“ – für den Zeitstempel der letzten Live-Aktualisierung.
    static func timeWithSeconds(_ date: Date) -> String { clockWithSeconds.string(from: date) }
}

extension OLMatch {
    /// Formatierte Anstoßzeit für die Anzeige.
    var kickoffText: String {
        guard let date = kickoffDate else { return "" }
        return MatchDate.dayAndTime(date)
    }
}
