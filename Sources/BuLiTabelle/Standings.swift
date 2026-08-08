import Foundation

/// Blickwinkel auf die Tabelle: gesamt, nur Heimspiele oder nur Auswärtsspiele.
enum TableMode: String, CaseIterable, Identifiable {
    case gesamt, heim, auswaerts

    var id: String { rawValue }

    var display: String {
        switch self {
        case .gesamt: return "Gesamt"
        case .heim: return "Heim"
        case .auswaerts: return "Auswärts"
        }
    }
}

enum Standings {
    /// Berechnet die Tabelle bis einschließlich `spieltag`.
    ///
    /// `live` enthält die laufenden Spiele (Spiel-ID → aktueller Spielstand).
    /// Sie werden wie abgepfiffene Partien gewertet, die betroffenen Zeilen aber
    /// als `isLive` markiert. Ist die Liste leer, kommt exakt die offizielle
    /// Tabelle heraus.
    static func compute(
        from matches: [OLMatch],
        upTo spieltag: Int,
        mode: TableMode = .gesamt,
        live: [Int: LiveScore] = [:]
    ) -> [TableRow] {
        var teams: [Int: OLTeam] = [:]
        for m in matches {
            teams[m.team1.teamId] = m.team1
            teams[m.team2.teamId] = m.team2
        }
        var stats: [Int: TableRow] = teams.mapValues { TableRow(team: $0) }

        // Chronologisch werten, damit die Formkurve die zeitliche Reihenfolge trifft.
        let played = matches
            .filter { $0.group.groupOrderID <= spieltag }
            .filter { $0.matchIsFinished || live[$0.matchID] != nil }
            .sorted { a, b in
                if a.group.groupOrderID != b.group.groupOrderID {
                    return a.group.groupOrderID < b.group.groupOrderID
                }
                return (a.matchDateTime ?? "") < (b.matchDateTime ?? "")
            }
        for m in played {
            // Abgepfiffen schlägt laufend: Für ein beendetes Spiel zählt das
            // Endergebnis, auch wenn noch ein Zwischenstand herumliegt.
            let score: LiveScore
            let isLive: Bool
            if m.matchIsFinished, let final = m.finalScore {
                score = final
                isLive = false
            } else if let running = live[m.matchID] {
                score = running
                isLive = true
            } else {
                continue
            }
            if mode != .auswaerts {
                stats[m.team1.teamId]?.add(goalsFor: score.team1, against: score.team2, live: isLive)
            }
            if mode != .heim {
                stats[m.team2.teamId]?.add(goalsFor: score.team2, against: score.team1, live: isLive)
            }
        }

        var list = stats.values.map { row -> TableRow in
            var r = row
            r.form = Array(r.form.suffix(5))
            return r
        }.sorted { a, b in
            if a.pkt != b.pkt { return a.pkt > b.pkt }
            if a.diff != b.diff { return a.diff > b.diff }
            if a.tore != b.tore { return a.tore > b.tore }
            return a.team.teamName.localizedStandardCompare(b.team.teamName) == .orderedAscending
        }
        for i in list.indices { list[i].position = i + 1 }
        return list
    }

    /// Trägt in die Live-Tabelle ein, wie viele Plätze jede Mannschaft
    /// gegenüber der offiziellen Tabelle gerade gutmacht oder verliert.
    static func withMovement(_ live: [TableRow], against official: [TableRow]) -> [TableRow] {
        var positions: [Int: Int] = [:]
        for row in official { positions[row.id] = row.position }
        return live.map { row in
            var updated = row
            updated.movement = (positions[row.id] ?? row.position) - row.position
            return updated
        }
    }
}
