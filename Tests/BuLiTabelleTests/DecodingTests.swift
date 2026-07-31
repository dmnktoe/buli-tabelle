import XCTest
@testable import BuLiTabelle

final class DecodingTests: XCTestCase {

    private func decode(_ json: String) throws -> OLMatch {
        try JSONDecoder.openLigaDB.decode(OLMatch.self, from: Data(json.utf8))
    }

    func testDecodesCamelCase() throws {
        let m = try decode(#"""
        {
          "matchID": 1,
          "matchDateTime": "2025-08-01T15:30:00",
          "group": { "groupOrderID": 1, "groupName": "1. Spieltag" },
          "team1": { "teamId": 10, "teamName": "FC Bayern", "shortName": "FCB", "teamIconUrl": null },
          "team2": { "teamId": 20, "teamName": "Borussia Dortmund", "shortName": null, "teamIconUrl": null },
          "matchResults": [
            { "resultTypeID": 2, "resultName": "Endergebnis", "pointsTeam1": 3, "pointsTeam2": 1 }
          ],
          "matchIsFinished": true
        }
        """#)
        XCTAssertEqual(m.matchID, 1)
        XCTAssertEqual(m.group.groupOrderID, 1)
        XCTAssertEqual(m.team1.teamName, "FC Bayern")
        XCTAssertEqual(m.team1.shortName, "FCB")
        XCTAssertTrue(m.matchIsFinished)
    }

    func testDecodesPascalCase() throws {
        let m = try decode(#"""
        {
          "MatchID": 7,
          "MatchDateTime": "2010-08-20T20:30:00",
          "Group": { "GroupOrderID": 3, "GroupName": "3. Spieltag" },
          "Team1": { "TeamId": 10, "TeamName": "FC Bayern", "ShortName": "FCB", "TeamIconUrl": null },
          "Team2": { "TeamId": 20, "TeamName": "Schalke 04", "ShortName": null, "TeamIconUrl": null },
          "MatchResults": [
            { "ResultTypeID": 2, "ResultName": "Endergebnis", "PointsTeam1": 2, "PointsTeam2": 2 }
          ],
          "MatchIsFinished": true
        }
        """#)
        XCTAssertEqual(m.matchID, 7)
        XCTAssertEqual(m.group.groupOrderID, 3)
        XCTAssertEqual(m.team1.teamName, "FC Bayern")
        XCTAssertEqual(m.team2.teamName, "Schalke 04")
    }

    func testDecodesArray() throws {
        let json = #"""
        [
          { "matchID": 1, "group": { "groupOrderID": 1 },
            "team1": { "teamId": 1, "teamName": "A" }, "team2": { "teamId": 2, "teamName": "B" },
            "matchResults": [], "matchIsFinished": false }
        ]
        """#
        let matches = try JSONDecoder.openLigaDB.decode([OLMatch].self, from: Data(json.utf8))
        XCTAssertEqual(matches.count, 1)
        XCTAssertNil(matches[0].team1.shortName, "Fehlende optionale Felder → nil")
        XCTAssertFalse(matches[0].matchIsFinished)
    }

    func testFinalResultPrefersEndergebnis() throws {
        let m = try decode(#"""
        {
          "matchID": 1, "group": { "groupOrderID": 1 },
          "team1": { "teamId": 1, "teamName": "A" }, "team2": { "teamId": 2, "teamName": "B" },
          "matchResults": [
            { "resultTypeID": 1, "resultName": "Halbzeit",   "pointsTeam1": 1, "pointsTeam2": 0 },
            { "resultTypeID": 2, "resultName": "Endergebnis", "pointsTeam1": 3, "pointsTeam2": 1 }
          ],
          "matchIsFinished": true
        }
        """#)
        XCTAssertEqual(m.finalResult?.pointsTeam1, 3)
        XCTAssertEqual(m.finalResult?.pointsTeam2, 1)
    }

    func testFinalResultRegardlessOfOrder() throws {
        let m = try decode(#"""
        {
          "matchID": 1, "group": { "groupOrderID": 1 },
          "team1": { "teamId": 1, "teamName": "A" }, "team2": { "teamId": 2, "teamName": "B" },
          "matchResults": [
            { "resultTypeID": 2, "resultName": "Endergebnis", "pointsTeam1": 0, "pointsTeam2": 0 },
            { "resultTypeID": 1, "resultName": "Halbzeit",   "pointsTeam1": 0, "pointsTeam2": 0 }
          ],
          "matchIsFinished": true
        }
        """#)
        XCTAssertEqual(m.finalResult?.resultTypeID, 2)
    }
}
