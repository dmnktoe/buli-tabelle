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
    static func compute(from matches: [OLMatch], upTo spieltag: Int, mode: TableMode = .gesamt) -> [TableRow] {
        var teams: [Int: OLTeam] = [:]
        for m in matches {
            teams[m.team1.teamId] = m.team1
            teams[m.team2.teamId] = m.team2
        }
        var stats: [Int: TableRow] = teams.mapValues { TableRow(team: $0) }

        // Chronologisch werten, damit die Formkurve die zeitliche Reihenfolge trifft.
        let played = matches
            .filter { $0.matchIsFinished && $0.group.groupOrderID <= spieltag }
            .sorted { a, b in
                if a.group.groupOrderID != b.group.groupOrderID {
                    return a.group.groupOrderID < b.group.groupOrderID
                }
                return (a.matchDateTime ?? "") < (b.matchDateTime ?? "")
            }
        for m in played {
            guard let r = m.finalResult,
                  let p1 = r.pointsTeam1,
                  let p2 = r.pointsTeam2 else { continue }
            if mode != .auswaerts {
                stats[m.team1.teamId]?.add(goalsFor: p1, against: p2)
            }
            if mode != .heim {
                stats[m.team2.teamId]?.add(goalsFor: p2, against: p1)
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
}
