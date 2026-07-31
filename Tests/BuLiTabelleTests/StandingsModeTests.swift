import XCTest
@testable import BuLiTabelle

final class StandingsModeTests: XCTestCase {

    private func team(_ id: Int, _ name: String) -> OLTeam {
        OLTeam(teamId: id, teamName: name, shortName: nil, teamIconUrl: nil)
    }

    private func match(day: Int, _ t1: OLTeam, _ t2: OLTeam, _ g1: Int, _ g2: Int) -> OLMatch {
        OLMatch(
            matchID: day * 1000 + t1.teamId,
            matchDateTime: "2025-08-01T15:30:00",
            group: OLGroup(groupOrderID: day, groupName: "\(day). Spieltag"),
            team1: t1, team2: t2,
            matchResults: [OLResult(resultTypeID: 2, resultName: "Endergebnis", pointsTeam1: g1, pointsTeam2: g2)],
            matchIsFinished: true
        )
    }

    // MARK: - Heim/Auswärts

    func testHomeTableCountsOnlyHomeGames() {
        let a = team(1, "Alpha"), b = team(2, "Beta")
        let matches = [
            match(day: 1, a, b, 2, 0), // A daheim gewinnt
            match(day: 2, b, a, 1, 1), // B daheim remis
        ]
        let heim = Standings.compute(from: matches, upTo: 34, mode: .heim)
        let byId = Dictionary(uniqueKeysWithValues: heim.map { ($0.team.teamId, $0) })
        XCTAssertEqual(byId[1]?.sp, 1, "Nur A's Heimspiel zählt")
        XCTAssertEqual(byId[1]?.pkt, 3)
        XCTAssertEqual(byId[2]?.sp, 1, "Nur B's Heimspiel zählt")
        XCTAssertEqual(byId[2]?.pkt, 1)
        XCTAssertEqual(heim.first?.team.teamId, 1, "A führt die Heimtabelle an")
    }

    func testAwayTableCountsOnlyAwayGames() {
        let a = team(1, "Alpha"), b = team(2, "Beta")
        let matches = [
            match(day: 1, a, b, 2, 0), // B auswärts verliert
            match(day: 2, b, a, 1, 1), // A auswärts remis
        ]
        let auswaerts = Standings.compute(from: matches, upTo: 34, mode: .auswaerts)
        let byId = Dictionary(uniqueKeysWithValues: auswaerts.map { ($0.team.teamId, $0) })
        XCTAssertEqual(byId[1]?.pkt, 1, "A holt auswärts einen Punkt")
        XCTAssertEqual(byId[2]?.pkt, 0, "B verliert auswärts")
        XCTAssertEqual(byId[1]?.sp, 1)
        XCTAssertEqual(byId[2]?.sp, 1)
    }

    func testGesamtEqualsHomePlusAway() {
        let a = team(1, "Alpha"), b = team(2, "Beta")
        let matches = [
            match(day: 1, a, b, 2, 0),
            match(day: 2, b, a, 1, 1),
        ]
        let gesamt = Standings.compute(from: matches, upTo: 34, mode: .gesamt)
        let byId = Dictionary(uniqueKeysWithValues: gesamt.map { ($0.team.teamId, $0) })
        XCTAssertEqual(byId[1]?.sp, 2)
        XCTAssertEqual(byId[1]?.pkt, 4, "Sieg + Remis")
        XCTAssertEqual(byId[2]?.pkt, 1)
    }

    // MARK: - Formkurve

    func testFormIsChronologicalLastFive() {
        let a = team(1, "Alpha")
        let matches = [
            match(day: 1, a, team(2, "T2"), 2, 0), // W
            match(day: 2, a, team(3, "T3"), 0, 1), // L
            match(day: 3, a, team(4, "T4"), 1, 1), // D
            match(day: 4, a, team(5, "T5"), 3, 1), // W
            match(day: 5, a, team(6, "T6"), 2, 0), // W
            match(day: 6, a, team(7, "T7"), 0, 2), // L
        ]
        let table = Standings.compute(from: matches, upTo: 34)
        let alpha = table.first { $0.team.teamId == 1 }
        XCTAssertEqual(alpha?.form, [.loss, .draw, .win, .win, .loss],
                       "Letzte fünf Ergebnisse chronologisch, ältestes zuerst")
    }

    func testFormRespectsSpieltagCutoff() {
        let a = team(1, "Alpha")
        let matches = [
            match(day: 1, a, team(2, "T2"), 2, 0), // W
            match(day: 2, a, team(3, "T3"), 0, 1), // L (nach Cutoff)
        ]
        let table = Standings.compute(from: matches, upTo: 1)
        let alpha = table.first { $0.team.teamId == 1 }
        XCTAssertEqual(alpha?.form, [.win], "Spiele nach dem gewählten Spieltag zählen nicht")
    }
}
