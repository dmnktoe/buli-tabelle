import XCTest
@testable import BuLiTabelle

final class CupBracketTests: XCTestCase {

    private func team(_ id: Int, _ name: String) -> OLTeam {
        OLTeam(teamId: id, teamName: name, shortName: nil, teamIconUrl: nil)
    }

    private func match(
        id: Int,
        round: Int,
        groupName: String? = nil,
        _ t1: OLTeam,
        _ t2: OLTeam,
        results: [OLResult],
        finished: Bool = true,
        date: String = "2026-08-15T20:30:00"
    ) -> OLMatch {
        OLMatch(
            matchID: id,
            matchDateTime: date,
            group: OLGroup(groupOrderID: round, groupName: groupName),
            team1: t1, team2: t2,
            matchResults: results,
            matchIsFinished: finished
        )
    }

    private func result(_ type: Int, _ name: String, _ a: Int?, _ b: Int?) -> OLResult {
        OLResult(resultTypeID: type, resultName: name, pointsTeam1: a, pointsTeam2: b)
    }

    // MARK: - Sieger

    func testWinnerFromRegularResult() {
        let m = match(id: 1, round: 1, team(1, "A"), team(2, "B"),
                      results: [result(2, "Endergebnis", 3, 1)])
        XCTAssertEqual(m.cupWinner, .team1)
        XCTAssertEqual(m.cupScoreText, "3 : 1")
        XCTAssertNil(m.cupDecisionNote)
    }

    /// Nach Verlängerung entschieden: Das reguläre Endergebnis ist unentschieden,
    /// erst der spätere Eintrag benennt den Sieger.
    func testWinnerAfterExtraTime() {
        let m = match(id: 2, round: 2, team(1, "A"), team(2, "B"), results: [
            result(1, "Halbzeit", 0, 0),
            result(2, "Endergebnis", 1, 1),
            result(3, "Ergebnis nach Verlängerung", 2, 1),
        ])
        XCTAssertEqual(m.cupWinner, .team1)
        XCTAssertEqual(m.cupScoreText, "2 : 1")
        XCTAssertEqual(m.cupDecisionNote, "n. V.")
    }

    /// Elfmeterschießen: Ohne die Sonderbehandlung stünde hier ein Remis und
    /// niemand käme weiter.
    func testWinnerAfterPenalties() {
        let m = match(id: 3, round: 3, team(1, "A"), team(2, "B"), results: [
            result(2, "Endergebnis", 2, 2),
            result(4, "Ergebnis nach Elfmeterschießen", 5, 6),
        ])
        XCTAssertEqual(m.cupWinner, .team2)
        XCTAssertEqual(m.cupScoreText, "5 : 6")
        XCTAssertEqual(m.cupDecisionNote, "i. E.")
    }

    func testUnplayedMatchHasNoWinner() {
        let m = match(id: 4, round: 1, team(1, "A"), team(2, "B"),
                      results: [], finished: false)
        XCTAssertNil(m.cupWinner)
        XCTAssertEqual(m.cupScoreText, "– : –")
    }

    // MARK: - Runden

    func testGroupsMatchesIntoRoundsInOrder() {
        let ms = [
            match(id: 10, round: 2, groupName: "2. Runde", team(1, "A"), team(2, "B"),
                  results: [result(2, "Endergebnis", 1, 0)]),
            match(id: 11, round: 1, groupName: "1. Runde", team(3, "C"), team(4, "D"),
                  results: [result(2, "Endergebnis", 0, 2)]),
        ]
        let rounds = CupBracket.rounds(from: ms)
        XCTAssertEqual(rounds.map(\.order), [1, 2])
        XCTAssertEqual(rounds.map(\.name), ["1. Runde", "2. Runde"])
    }

    func testRoundNameFallsBackToMatchCount() {
        XCTAssertEqual(CupBracket.name(groupName: nil, order: 6, matchCount: 1), "Finale")
        XCTAssertEqual(CupBracket.name(groupName: "", order: 5, matchCount: 2), "Halbfinale")
        XCTAssertEqual(CupBracket.name(groupName: "   ", order: 4, matchCount: 4), "Viertelfinale")
        XCTAssertEqual(CupBracket.name(groupName: nil, order: 3, matchCount: 8), "Achtelfinale")
        XCTAssertEqual(CupBracket.name(groupName: nil, order: 1, matchCount: 32), "1. Runde")
    }

    func testApiGroupNameWinsOverHeuristic() {
        XCTAssertEqual(CupBracket.name(groupName: "Achtelfinale", order: 3, matchCount: 4),
                       "Achtelfinale")
    }

    func testRoundProgressAndAdvancingTeams() {
        let a = team(1, "A"), b = team(2, "B"), c = team(3, "C"), d = team(4, "D")
        let ms = [
            match(id: 20, round: 1, groupName: "1. Runde", a, b,
                  results: [result(2, "Endergebnis", 2, 0)]),
            match(id: 21, round: 1, groupName: "1. Runde", c, d,
                  results: [], finished: false),
        ]
        let round = CupBracket.rounds(from: ms)[0]
        XCTAssertTrue(round.isDrawn)
        XCTAssertFalse(round.isComplete)
        XCTAssertEqual(round.playedCount, 1)
        XCTAssertEqual(round.progressText, "1 von 2 Spielen gespielt")
        XCTAssertEqual(round.advancingTeams.map(\.teamName), ["A"])
    }

    func testUndrawnRoundIsEmptyNotBroken() {
        let round = CupRound(order: 4, name: "Viertelfinale", matches: [])
        XCTAssertFalse(round.isDrawn)
        XCTAssertFalse(round.isComplete)
        XCTAssertEqual(round.progressText, "Auslosung steht aus")
        XCTAssertTrue(round.advancingTeams.isEmpty)
    }

    // MARK: - Liga-Eigenschaften

    func testCupFlags() {
        XCTAssertTrue(Liga.dfb.isCup)
        XCTAssertEqual(Liga.dfb.periodNoun, "Runde")
        XCTAssertEqual(Liga.dfb.rawValue, "dfb")
        for liga in [Liga.bl1, .bl2, .bl3] {
            XCTAssertFalse(liga.isCup)
            XCTAssertEqual(liga.periodNoun, "Spieltag")
        }
    }

    func testCupHasNoZoneColors() {
        for position in 1...8 {
            XCTAssertNil(Liga.dfb.zoneColor(position: position, teamCount: 64))
        }
    }

    // MARK: - Export

    func testPlainTextMarksWinnerInUppercase() {
        let m = match(id: 30, round: 6, groupName: "Finale", team(1, "Alpha"), team(2, "Beta"),
                      results: [result(2, "Endergebnis", 2, 1)])
        let round = CupBracket.rounds(from: [m])[0]
        let text = TableExporter.plainText(title: "Finale", round: round)
        XCTAssertTrue(text.contains("ALPHA"), text)
        XCTAssertTrue(text.contains("Beta"), text)
        XCTAssertTrue(text.contains("2 : 1"), text)
    }

    func testHtmlEscapesTeamNames() {
        let m = match(id: 31, round: 1, groupName: "1. Runde",
                      team(1, "A & B"), team(2, "C <FC>"),
                      results: [result(2, "Endergebnis", 1, 0)])
        let round = CupBracket.rounds(from: [m])[0]
        let html = TableExporter.html(title: "1. Runde", round: round, footerNote: "Test")
        XCTAssertTrue(html.contains("A &amp; B"), html)
        XCTAssertTrue(html.contains("C &lt;FC&gt;"), html)
        XCTAssertFalse(html.contains("<FC>"), html)
    }

    func testUndrawnRoundExportsNotice() {
        let round = CupRound(order: 4, name: "Viertelfinale", matches: [])
        XCTAssertTrue(TableExporter.plainText(title: "VF", round: round)
            .contains("Auslosung steht noch aus"))
        XCTAssertTrue(TableExporter.html(title: "VF", round: round, footerNote: "x")
            .contains("Auslosung steht noch aus"))
    }
}
