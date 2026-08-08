import Foundation

/// Ein Spielstand, wie er gerade auf der Anzeigetafel steht.
struct LiveScore: Equatable {
    let team1: Int
    let team2: Int

    var text: String { "\(team1) : \(team2)" }
}

/// Spielabschnitt eines laufenden Spiels.
enum LivePhase: Equatable {
    case firstHalf(Int)
    case halftime
    case secondHalf(Int)
    /// Nach der regulären Spielzeit: Nachspielzeit, Verlängerung, Elfmeterschießen.
    case beyondRegulation

    /// Kurzform für enge Spalten – „23.“, „HZ“, „90.+“.
    var label: String {
        switch self {
        case .firstHalf(let minute), .secondHalf(let minute): return "\(minute)."
        case .halftime: return "HZ"
        case .beyondRegulation: return "90.+"
        }
    }

    /// Ausgeschriebene Fassung für Statuszeile und Kurzhinweise.
    var description: String {
        switch self {
        case .firstHalf(let minute): return "1. Halbzeit, \(minute). Minute"
        case .halftime: return "Halbzeitpause"
        case .secondHalf(let minute): return "2. Halbzeit, \(minute). Minute"
        case .beyondRegulation: return "nach der regulären Spielzeit"
        }
    }
}

/// Schätzt aus Anstoßzeit und Uhrzeit, wo ein laufendes Spiel gerade steht.
///
/// OpenLigaDB liefert keine Spieluhr, nur Tore mit Minutenangabe. Die Minute
/// hier ist deshalb aus der Anstoßzeit hochgerechnet und kann um die Länge der
/// Nachspielzeit danebenliegen – für „läuft noch, ungefähr wie weit“ reicht das,
/// und die Anzeige weist im Hinweistext darauf hin.
enum LiveClock {
    static let halfMinutes = 45
    static let breakMinutes = 15

    /// So lange gilt ein angepfiffenes Spiel höchstens als „läuft“. Das Fenster
    /// ist die Notbremse für Partien, die die API nie als beendet meldet.
    static let leagueWindow: TimeInterval = 150 * 60
    /// Im Pokal können Verlängerung und Elfmeterschießen dazukommen.
    static let cupWindow: TimeInterval = 210 * 60

    /// Vorlauf, ab dem ein Spiel als „gleich geht's los“ gilt.
    static let leadTime: TimeInterval = 15 * 60

    static func phase(kickoff: Date, now: Date) -> LivePhase? {
        guard now >= kickoff else { return nil }
        let elapsed = Int(now.timeIntervalSince(kickoff) / 60)
        if elapsed < halfMinutes {
            return .firstHalf(elapsed + 1)
        }
        if elapsed < halfMinutes + breakMinutes {
            return .halftime
        }
        if elapsed < 2 * halfMinutes + breakMinutes {
            return .secondHalf(elapsed - breakMinutes + 1)
        }
        return .beyondRegulation
    }
}

extension Liga {
    /// Wie lange ein angepfiffenes Spiel dieser Liga als laufend gilt.
    var liveWindow: TimeInterval { isCup ? LiveClock.cupWindow : LiveClock.leagueWindow }
}

extension OLMatch {
    /// Anstoßzeitpunkt – bevorzugt die UTC-Angabe der API.
    var kickoffDate: Date? { MatchDate.kickoff(utc: matchDateTimeUTC, local: matchDateTime) }

    /// Läuft die Partie gerade? Angepfiffen, nicht abgepfiffen, im Zeitfenster.
    func isLive(at now: Date, window: TimeInterval = LiveClock.leagueWindow) -> Bool {
        guard !matchIsFinished, let kickoff = kickoffDate else { return false }
        return now >= kickoff && now < kickoff.addingTimeInterval(window)
    }

    /// Steht der Anstoß unmittelbar bevor?
    func isImminent(at now: Date, lead: TimeInterval = LiveClock.leadTime) -> Bool {
        guard !matchIsFinished, let kickoff = kickoffDate else { return false }
        return kickoff > now && kickoff.timeIntervalSince(now) <= lead
    }

    func phase(at now: Date) -> LivePhase? {
        guard let kickoff = kickoffDate else { return nil }
        return LiveClock.phase(kickoff: kickoff, now: now)
    }

    /// Spielstand aus der Torliste: der jüngste Treffer trägt den Zwischenstand.
    /// Fehlt die Torliste, hilft ein bereits gemeldetes (Halbzeit-)Ergebnis.
    var runningScore: LiveScore? {
        let scored = (goals ?? []).filter { ($0.scoreTeam1 ?? -1) >= 0 && ($0.scoreTeam2 ?? -1) >= 0 }
        if let latest = scored.max(by: { $0.order < $1.order }),
           let a = latest.scoreTeam1, let b = latest.scoreTeam2 {
            return LiveScore(team1: a, team2: b)
        }
        if let reported = matchResults.last,
           let a = reported.pointsTeam1, let b = reported.pointsTeam2 {
            return LiveScore(team1: a, team2: b)
        }
        return nil
    }

    /// Laufender Spielstand, solange die Partie läuft. Ohne gemeldeten Treffer
    /// steht es nach dem Anpfiff 0:0 – kein Grund, die Zeile leer zu lassen.
    func liveScore(at now: Date, window: TimeInterval = LiveClock.leagueWindow) -> LiveScore? {
        guard isLive(at: now, window: window) else { return nil }
        return runningScore ?? LiveScore(team1: 0, team2: 0)
    }

    /// Endstand einer abgepfiffenen Partie.
    var finalScore: LiveScore? {
        guard matchIsFinished,
              let r = finalResult,
              let a = r.pointsTeam1, let b = r.pointsTeam2
        else { return nil }
        return LiveScore(team1: a, team2: b)
    }

    /// Der zuletzt gemeldete Treffer – für „TOR durch …“ in der Mitteilung.
    var latestGoal: OLGoal? {
        (goals ?? []).max { $0.order < $1.order }
    }
}

/// Was gerade läuft – aus den geladenen Spielen und der Uhrzeit abgeleitet.
struct LiveOverview {
    let now: Date
    let running: [OLMatch]
    let imminent: [OLMatch]

    static let idle = LiveOverview(now: .distantPast, running: [], imminent: [])

    /// Es läuft mindestens ein Spiel.
    var isActive: Bool { !running.isEmpty }

    /// Es lohnt sich, nachzusehen: Es läuft etwas oder der Anpfiff steht bevor.
    var isWatching: Bool { !running.isEmpty || !imminent.isEmpty }

    /// Spieltage bzw. Runden, die für eine Aktualisierung infrage kommen.
    var periods: [Int] {
        Set((running + imminent).map { $0.group.groupOrderID }).sorted()
    }

    /// Kopfzeile der Live-Leiste.
    var headline: String {
        if running.count == 1, let match = running.first {
            let pairing = "\(match.team1.displayShort) – \(match.team2.displayShort)"
            guard let phase = match.phase(at: now) else { return pairing }
            return "\(pairing) · \(phase.description)"
        }
        if running.count > 1 {
            return "\(running.count) Spiele laufen"
        }
        if let next = imminent.min(by: { ($0.kickoffDate ?? .distantFuture) < ($1.kickoffDate ?? .distantFuture) }),
           let kickoff = next.kickoffDate {
            return "Anpfiff um \(MatchDate.time(kickoff)) Uhr"
        }
        return "Keine laufenden Spiele"
    }

    static func make(from matches: [OLMatch], liga: Liga, now: Date) -> LiveOverview {
        let window = liga.liveWindow
        let byKickoff: (OLMatch, OLMatch) -> Bool = {
            ($0.kickoffDate ?? .distantFuture) < ($1.kickoffDate ?? .distantFuture)
        }
        return LiveOverview(
            now: now,
            running: matches.filter { $0.isLive(at: now, window: window) }.sorted(by: byKickoff),
            imminent: matches.filter { $0.isImminent(at: now) }.sorted(by: byKickoff)
        )
    }
}
