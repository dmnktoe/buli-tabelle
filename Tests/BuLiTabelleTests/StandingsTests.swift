import XCTest
@testable import BuLiTabelle

final class StandingsTests: XCTestCase {

    private func team(_ id: Int, _ name: String) -> OLTeam {
        OLTeam(teamId: id, teamName: name, shortName: nil, teamIconUrl: nil)
    }

    private func match(
        day: Int, _ t1: OLTeam, _ t2: OLTeam, _ g1: Int?, _ g2: Int?, finished: Bool = true
    ) -> OLMatch {
        let results: [OLResult] = (g1 != nil && g2 != nil)
            ? [OLResult(resultTypeID: 2, resultName: "Endergebnis", pointsTeam1: g1, pointsTeam2: g2)]
            : []
        return OLMatch(
            matchID: day * 1000 + t1.teamId,
            matchDateTime: "2025-08-01T15:30:00",
            group: OLGroup(groupOrderID: day, groupName: "\(day). Spieltag"),
            team1: t1, team2: t2,
            matchResults: results,
            matchIsFinished: finished
        )
    }

    func testPointsWinDrawLoss() {
        let a = team(1, "Alpha"), b = team(2, "Beta"), c = team(3, "Gamma")
        let table = Standings.compute(
            from: [
                match(day: 1, a, b, 2, 0),
                match(day: 1, b, c, 1, 1),
            ],
            upTo: 1
        )
        let byId = Dictionary(uniqueKeysWithValues: table.map { ($0.team.teamId, $0) })
        XCTAssertEqual(byId[1]?.pkt, 3, "Sieg = 3 Punkte")
        XCTAssertEqual(byId[1]?.s, 1)
        XCTAssertEqual(byId[2]?.pkt, 1, "Niederlage + Remis = 1 Punkt")
        XCTAssertEqual(byId[2]?.n, 1)
        XCTAssertEqual(byId[2]?.u, 1)
        XCTAssertEqual(byId[3]?.pkt, 1, "Remis = 1 Punkt")
    }

    func testSortingAndPositions() {
        let a = team(1, "Alpha"), b = team(2, "Beta"), c = team(3, "Gamma")
        let table = Standings.compute(
            from: [
                match(day: 1, a, b, 3, 0),
                match(day: 1, c, b, 1, 0),
            ],
            upTo: 1
        )
        XCTAssertEqual(table.map(\.position), [1, 2, 3], "Plätze fortlaufend ab 1")
        XCTAssertEqual(table[0].team.teamId, 1, "Gleiche Punkte → bessere Tordifferenz zuerst")
        XCTAssertEqual(table[1].team.teamId, 3)
        XCTAssertEqual(table[2].team.teamId, 2, "Schlechteste Differenz zuletzt")
    }

    func testTiebreakerByGoalsThenName() {
        let a = team(1, "Zeta"), b = team(2, "Beta"), x = team(9, "Filler1"), y = team(8, "Filler2")
        let table = Standings.compute(
            from: [
                match(day: 1, a, x, 3, 2),
                match(day: 1, b, y, 1, 0),
            ],
            upTo: 1
        )
        XCTAssertEqual(table[0].team.teamId, 1, "Mehr geschossene Tore rankt höher")
        XCTAssertEqual(table[1].team.teamId, 2)
    }

    func testUnfinishedAndFutureMatchesIgnored() {
        let a = team(1, "Alpha"), b = team(2, "Beta")
        let table = Standings.compute(
            from: [
                match(day: 1, a, b, 2, 0),
                match(day: 2, a, b, 5, 0),
                match(day: 1, a, b, nil, nil, finished: false)
            ],
            upTo: 1
        )
        let byId = Dictionary(uniqueKeysWithValues: table.map { ($0.team.teamId, $0) })
        XCTAssertEqual(byId[1]?.sp, 1, "Nur das eine gewertete Spiel zählt")
        XCTAssertEqual(byId[1]?.tore, 2, "Zukünftiger 5:0 darf nicht einfließen")
    }

    func testEmptyInput() {
        XCTAssertTrue(Standings.compute(from: [], upTo: 34).isEmpty)
    }
}
