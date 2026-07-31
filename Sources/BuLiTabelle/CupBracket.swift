import Foundation

/// Seite einer K.-o.-Partie.
enum CupSide: Equatable {
    case team1, team2
}

extension OLMatch {
    /// Das Ergebnis, das eine K.-o.-Partie entschieden hat.
    ///
    /// OpenLigaDB liefert je nach Saison mehrere Einträge pro Spiel — Halbzeit,
    /// Endergebnis und bei Bedarf Verlängerung bzw. Elfmeterschießen. Im Pokal
    /// kann das reguläre „Endergebnis“ unentschieden sein, obwohl die Partie
    /// längst entschieden ist. Deshalb gewinnt hier der Eintrag mit eindeutigem
    /// Sieger und dem höchsten Ergebnistyp; erst danach greift `finalResult`.
    var cupDecidingResult: OLResult? {
        let decisive = matchResults.filter {
            guard let a = $0.pointsTeam1, let b = $0.pointsTeam2 else { return false }
            return a != b
        }
        let best = decisive.max { ($0.resultTypeID ?? 0) < ($1.resultTypeID ?? 0) }
        return best ?? finalResult
    }

    /// Sieger der Partie – `nil`, solange sie nicht entschieden ist.
    var cupWinner: CupSide? {
        guard matchIsFinished,
              let r = cupDecidingResult,
              let p1 = r.pointsTeam1, let p2 = r.pointsTeam2,
              p1 != p2
        else { return nil }
        return p1 > p2 ? .team1 : .team2
    }

    /// „n. V.“ oder „i. E.“, falls die Partie erst dort entschieden wurde.
    var cupDecisionNote: String? {
        let name = (cupDecidingResult?.resultName ?? "").lowercased()
        if name.contains("elfmeter") { return "i. E." }
        if name.contains("verlängerung") || name.contains("verlaengerung") { return "n. V." }
        return nil
    }

    /// „2 : 1“ bzw. „– : –“, solange nicht gespielt.
    var cupScoreText: String {
        guard matchIsFinished,
              let r = cupDecidingResult,
              let p1 = r.pointsTeam1, let p2 = r.pointsTeam2
        else { return "– : –" }
        return "\(p1) : \(p2)"
    }
}

/// Eine Pokalrunde mit ihren Partien.
struct CupRound: Identifiable {
    let order: Int
    let name: String
    let matches: [OLMatch]

    var id: Int { order }

    /// Eine Runde ohne Partien ist noch nicht ausgelost.
    var isDrawn: Bool { !matches.isEmpty }
    var playedCount: Int { matches.filter(\.matchIsFinished).count }
    var isComplete: Bool { isDrawn && playedCount == matches.count }

    var progressText: String {
        guard isDrawn else { return "Auslosung steht aus" }
        if isComplete { return "abgeschlossen" }
        return "\(playedCount) von \(matches.count) Spielen gespielt"
    }

    /// Mannschaften, die diese Runde überstanden haben.
    var advancingTeams: [OLTeam] {
        matches.compactMap { match in
            switch match.cupWinner {
            case .team1: return match.team1
            case .team2: return match.team2
            case nil: return nil
            }
        }
    }
}

/// Baut aus den Spielen einer Pokalsaison die Runden.
///
/// Der Pokal ist rundenbasiert und wird zwischen den Runden ausgelost: Spätere
/// Runden existieren in den Daten oft schon als Gruppe, aber ohne Partien.
enum CupBracket {
    static func rounds(from matches: [OLMatch]) -> [CupRound] {
        let grouped = Dictionary(grouping: matches, by: { $0.group.groupOrderID })
        return grouped.keys.sorted().map { order in
            let inRound = (grouped[order] ?? []).sorted {
                ($0.matchDateTime ?? "") < ($1.matchDateTime ?? "")
            }
            return CupRound(
                order: order,
                name: name(groupName: inRound.first?.group.groupName,
                           order: order,
                           matchCount: inRound.count),
                matches: inRound
            )
        }
    }

    /// Rundenname: bevorzugt der Gruppenname aus der API. Fehlt er, wird er aus
    /// der Zahl der Partien abgeleitet — das ist robuster als eine feste
    /// Zuordnung über den Index, weil ältere Saisons abweichend viele Runden
    /// haben können.
    static func name(groupName: String?, order: Int, matchCount: Int) -> String {
        let trimmed = groupName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmed.isEmpty { return trimmed }
        switch matchCount {
        case 1: return "Finale"
        case 2: return "Halbfinale"
        case 4: return "Viertelfinale"
        case 8: return "Achtelfinale"
        default: return "\(order). Runde"
        }
    }

    /// Kurzform für enge Auswahlfelder: „Achtelfinale“ bleibt, „1. Runde“ auch,
    /// aber überlange API-Namen werden gekürzt.
    static func shortName(_ name: String) -> String {
        name.count <= 16 ? name : String(name.prefix(15)) + "…"
    }
}
