import Foundation

struct AnyKey: CodingKey {
    var stringValue: String
    var intValue: Int?
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { self.intValue = intValue; self.stringValue = "\(intValue)" }
}

extension JSONDecoder {
    static var openLigaDB: JSONDecoder {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .custom { keys in
            AnyKey(stringValue: keys.last!.stringValue.lowercased())!
        }
        return d
    }
}

struct OLTeam: Decodable, Hashable {
    let teamId: Int
    let teamName: String
    let shortName: String?
    let teamIconUrl: String?

    enum CodingKeys: String, CodingKey {
        case teamId = "teamid"
        case teamName = "teamname"
        case shortName = "shortname"
        case teamIconUrl = "teamiconurl"
    }

    /// Kurzname, wenn vorhanden – sonst der volle Name. Für kompakte Zeilen & Icon-Fallbacks.
    var displayShort: String { shortName ?? teamName }
}

struct OLGroup: Decodable {
    let groupOrderID: Int
    let groupName: String?

    enum CodingKeys: String, CodingKey {
        case groupOrderID = "grouporderid"
        case groupName = "groupname"
    }
}

struct OLResult: Decodable {
    let resultTypeID: Int?
    let resultName: String?
    let pointsTeam1: Int?
    let pointsTeam2: Int?

    enum CodingKeys: String, CodingKey {
        case resultTypeID = "resulttypeid"
        case resultName = "resultname"
        case pointsTeam1 = "pointsteam1"
        case pointsTeam2 = "pointsteam2"
    }
}

/// Ein einzelner Treffer. Während ein Spiel läuft, ist die Torliste die einzige
/// Quelle für den Spielstand – ein „Endergebnis“ trägt die API erst nach dem
/// Abpfiff nach, ein Halbzeitergebnis frühestens zur Pause.
struct OLGoal: Decodable {
    let goalID: Int?
    let scoreTeam1: Int?
    let scoreTeam2: Int?
    let matchMinute: Int?
    let goalGetterName: String?
    let isPenalty: Bool?
    let isOwnGoal: Bool?

    enum CodingKeys: String, CodingKey {
        case goalID = "goalid"
        case scoreTeam1 = "scoreteam1"
        case scoreTeam2 = "scoreteam2"
        case matchMinute = "matchminute"
        case goalGetterName = "goalgettername"
        case isPenalty = "ispenalty"
        case isOwnGoal = "isowngoal"
    }

    /// Reihenfolge innerhalb einer Partie: Spielminute vor laufender Nummer.
    var order: (Int, Int) { (matchMinute ?? 0, goalID ?? 0) }
}

struct OLMatch: Decodable, Identifiable {
    let matchID: Int
    let matchDateTime: String?
    let group: OLGroup
    let team1: OLTeam
    let team2: OLTeam
    let matchResults: [OLResult]
    let matchIsFinished: Bool
    /// Anstoß in UTC. Optional, weil ältere Antworten nur die deutsche Ortszeit
    /// kennen – vorhanden ist sie die verlässlichere Quelle für „läuft gerade“.
    var matchDateTimeUTC: String?
    /// Einzelne Treffer, sofern die API sie mitliefert.
    var goals: [OLGoal]?

    var id: Int { matchID }

    enum CodingKeys: String, CodingKey {
        case matchID = "matchid"
        case matchDateTime = "matchdatetime"
        case group
        case team1
        case team2
        case matchResults = "matchresults"
        case matchIsFinished = "matchisfinished"
        case matchDateTimeUTC = "matchdatetimeutc"
        case goals
    }

    var finalResult: OLResult? {
        matchResults.first {
            $0.resultTypeID == 2 || $0.resultName?.lowercased().contains("endergebnis") == true
        } ?? matchResults.last
    }
}

struct OLGoalGetter: Decodable, Identifiable {
    let goalGetterID: Int?
    let goalGetterName: String?
    let goalCount: Int?

    var id: String { "\(goalGetterID ?? 0)-\(goalGetterName ?? "?")" }

    enum CodingKeys: String, CodingKey {
        case goalGetterID = "goalgetterid"
        case goalGetterName = "goalgettername"
        case goalCount = "goalcount"
    }
}

enum MatchOutcome: Equatable {
    case win, draw, loss
}

struct TableRow: Identifiable {
    var position: Int = 0
    let team: OLTeam
    var sp = 0
    var s = 0
    var u = 0
    var n = 0
    var tore = 0
    var gegentore = 0
    /// Ergebnisse der gewerteten Spiele in chronologischer Reihenfolge (ältestes zuerst).
    var form: [MatchOutcome] = []
    /// Die Mannschaft spielt gerade – ihr laufendes Spiel steckt in dieser Zeile.
    var isLive = false
    /// Plätze, die die Zeile gegenüber der offiziellen Tabelle gutgemacht hat
    /// (positiv) bzw. verloren hat (negativ). Ohne Live-Tabelle immer `0`.
    var movement = 0

    var diff: Int { tore - gegentore }
    var pkt: Int { s * 3 + u }
    var id: Int { team.teamId }

    mutating func add(goalsFor: Int, against: Int, live: Bool = false) {
        if live { isLive = true }
        sp += 1
        tore += goalsFor
        gegentore += against
        if goalsFor > against {
            s += 1
            form.append(.win)
        } else if goalsFor == against {
            u += 1
            form.append(.draw)
        } else {
            n += 1
            form.append(.loss)
        }
    }
}

enum Liga: String, CaseIterable, Identifiable {
    case bl1, bl2, bl3, dfb

    var id: String { rawValue }

    var display: String {
        switch self {
        case .bl1: return "1. Bundesliga"
        case .bl2: return "2. Bundesliga"
        case .bl3: return "3. Liga"
        case .dfb: return "DFB-Pokal"
        }
    }

    var short: String {
        switch self {
        case .bl1: return "1. LIGA"
        case .bl2: return "2. LIGA"
        case .bl3: return "3. LIGA"
        case .dfb: return "POKAL"
        }
    }

    /// K.-o.-Wettbewerb statt Liga: Runden mit Auslosung, keine Tabelle.
    var isCup: Bool { self == .dfb }

    /// „Spieltag“ heißt im Pokal „Runde“.
    var periodNoun: String { isCup ? "Runde" : "Spieltag" }
}
