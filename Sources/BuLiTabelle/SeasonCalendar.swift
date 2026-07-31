import Foundation

/// Ableitungen rund um Bundesliga-Saisons. Eine Saison läuft von August bis Mai
/// und wird über ihr Startjahr benannt (z. B. 2025 == „2025/26").
enum SeasonCalendar {
    /// Erste über OpenLigaDB spieltagsgenau verfügbare Saison.
    static let firstSeason = 2004

    /// Die aktuell „laufende" Saison – ab August zählt bereits das neue Jahr.
    static func ongoingSeason(now: Date = Date()) -> Int {
        let cal = Calendar.current
        let y = cal.component(.year, from: now)
        let m = cal.component(.month, from: now)
        return m >= 8 ? y : y - 1
    }

    /// Standard-Saison beim Programmstart – ab Juli schon die kommende Spielzeit.
    static func defaultSeason(now: Date = Date()) -> Int {
        let cal = Calendar.current
        let y = cal.component(.year, from: now)
        let m = cal.component(.month, from: now)
        return m >= 7 ? y : y - 1
    }

    /// Auswählbare Saisons, neueste zuerst (eine über die laufende hinaus für Vorschauen).
    static func selectable(now: Date = Date()) -> [Int] {
        let latest = ongoingSeason(now: now) + 1
        return Array((firstSeason...latest).reversed())
    }

    /// Lange Schreibweise, z. B. „2025 / 2026".
    static func longString(_ season: Int) -> String {
        String(format: "%d / %d", season, season + 1)
    }

    /// Kurze Schreibweise, z. B. „25/26".
    static func shortString(_ season: Int) -> String {
        String(format: "%02d/%02d", season % 100, (season + 1) % 100)
    }
}
