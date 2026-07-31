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

struct OLMatch: Decodable, Identifiable {
    let matchID: Int
    let matchDateTime: String?
    let group: OLGroup
    let team1: OLTeam
    let team2: OLTeam
    let matchResults: [OLResult]
    let matchIsFinished: Bool

    var id: Int { matchID }

    enum CodingKeys: String, CodingKey {
        case matchID = "matchid"
        case matchDateTime = "matchdatetime"
        case group
        case team1
        case team2
        case matchResults = "matchresults"
        case matchIsFinished = "matchisfinished"
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

    var diff: Int { tore - gegentore }
    var pkt: Int { s * 3 + u }
    var id: Int { team.teamId }

    mutating func add(goalsFor: Int, against: Int) {
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
    case bl1, bl2, bl3

    var id: String { rawValue }

    var display: String {
        switch self {
        case .bl1: return "1. Bundesliga"
        case .bl2: return "2. Bundesliga"
        case .bl3: return "3. Liga"
        }
    }

    var short: String {
        switch self {
        case .bl1: return "1. LIGA"
        case .bl2: return "2. LIGA"
        case .bl3: return "3. LIGA"
        }
    }
}
