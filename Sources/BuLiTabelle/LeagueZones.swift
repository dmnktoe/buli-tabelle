import SwiftUI

/// Auf- und Abstiegsbereiche einer Tabelle.
///
/// Früher war die Zone nur eine Hintergrundfarbe. Als eigener Typ trägt sie
/// jetzt auch ihren Namen – der Balken links in der Zeile und die Legende
/// unter der Tabelle greifen auf dieselbe Quelle zu.
enum LeagueZone: Hashable {
    case champions
    case europa
    case conference
    case promotion
    case promotionPlayoff
    case relegationPlayoff
    case relegation

    var color: Color {
        switch self {
        case .champions: return Theme.zoneChampions
        case .europa: return Theme.zoneEuropa
        case .conference: return Theme.zoneConference
        case .promotion: return Theme.zonePromotion
        case .promotionPlayoff, .relegationPlayoff: return Theme.zonePlayoff
        case .relegation: return Theme.zoneRelegation
        }
    }

    var label: String {
        switch self {
        case .champions: return "Champions League"
        case .europa: return "Europa League"
        case .conference: return "Conference League"
        case .promotion: return "Aufstieg"
        case .promotionPlayoff: return "Aufstiegsrelegation"
        case .relegationPlayoff: return "Relegation"
        case .relegation: return "Abstieg"
        }
    }
}

extension Liga {
    /// Zone einer Platzierung – `nil` außerhalb jeder Zone oder wenn die Liga
    /// zu wenige Teams für sinnvolle Zonen hat.
    func zone(position: Int, teamCount: Int) -> LeagueZone? {
        guard teamCount > 4 else { return nil }
        switch self {
        case .dfb:
            return nil  // K.-o.-Wettbewerb ohne Tabelle und damit ohne Zonen
        case .bl1:
            if position <= 4 { return .champions }
            if position == 5 { return .europa }
            if position == 6 { return .conference }
            if position == teamCount - 2 { return .relegationPlayoff }
            if position > teamCount - 2 { return .relegation }
        case .bl2:
            if position <= 2 { return .promotion }
            if position == 3 { return .promotionPlayoff }
            if position == teamCount - 2 { return .relegationPlayoff }
            if position > teamCount - 2 { return .relegation }
        case .bl3:
            if position <= 2 { return .promotion }
            if position == 3 { return .promotionPlayoff }
            if position > teamCount - 4 { return .relegation }
        }
        return nil
    }

    /// Farbe der Zone für eine Platzierung – `nil` außerhalb jeder Zone.
    func zoneColor(position: Int, teamCount: Int) -> Color? {
        zone(position: position, teamCount: teamCount)?.color
    }

    /// Alle Zonen der Liga in Tabellenreihenfolge – Grundlage der Legende.
    func zones(teamCount: Int) -> [LeagueZone] {
        guard teamCount > 4 else { return [] }
        var seen: [LeagueZone] = []
        for position in 1...teamCount {
            if let zone = zone(position: position, teamCount: teamCount), !seen.contains(zone) {
                seen.append(zone)
            }
        }
        return seen
    }
}
