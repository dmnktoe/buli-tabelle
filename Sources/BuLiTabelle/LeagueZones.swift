import SwiftUI

extension Liga {
    /// Farbe der Auf-/Abstiegszone für eine Platzierung – `nil` außerhalb jeder Zone
    /// oder wenn die Liga zu wenige Teams für sinnvolle Zonen hat.
    func zoneColor(position: Int, teamCount: Int) -> Color? {
        guard teamCount > 4 else { return nil }
        switch self {
        case .bl1:
            if position <= 4 { return XP.zoneCL }
            if position == 5 { return XP.zoneEL }
            if position == 6 { return XP.zoneECL }
            if position == teamCount - 2 { return XP.zoneRelegation }
            if position > teamCount - 2 { return XP.zoneAbstieg }
        case .bl2:
            if position <= 2 { return XP.zoneCL }
            if position == 3 { return XP.zoneEL }
            if position == teamCount - 2 { return XP.zoneRelegation }
            if position > teamCount - 2 { return XP.zoneAbstieg }
        case .bl3:
            if position <= 2 { return XP.zoneCL }
            if position == 3 { return XP.zoneEL }
            if position > teamCount - 4 { return XP.zoneAbstieg }
        }
        return nil
    }
}
