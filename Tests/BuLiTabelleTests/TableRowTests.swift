import XCTest
@testable import BuLiTabelle

final class TableRowTests: XCTestCase {

    private let team = OLTeam(teamId: 1, teamName: "Test", shortName: nil, teamIconUrl: nil)

    func testAddWin() {
        var r = TableRow(team: team)
        r.add(goalsFor: 3, against: 1)
        XCTAssertEqual(r.sp, 1)
        XCTAssertEqual(r.s, 1)
        XCTAssertEqual(r.u, 0)
        XCTAssertEqual(r.n, 0)
        XCTAssertEqual(r.pkt, 3)
        XCTAssertEqual(r.diff, 2)
    }

    func testAddDraw() {
        var r = TableRow(team: team)
        r.add(goalsFor: 2, against: 2)
        XCTAssertEqual(r.u, 1)
        XCTAssertEqual(r.pkt, 1)
        XCTAssertEqual(r.diff, 0)
    }

    func testAddLoss() {
        var r = TableRow(team: team)
        r.add(goalsFor: 0, against: 2)
        XCTAssertEqual(r.n, 1)
        XCTAssertEqual(r.pkt, 0)
        XCTAssertEqual(r.diff, -2)
    }

    func testAccumulatesAcrossMatches() {
        var r = TableRow(team: team)
        r.add(goalsFor: 1, against: 0)
        r.add(goalsFor: 1, against: 1)
        r.add(goalsFor: 0, against: 3)
        XCTAssertEqual(r.sp, 3)
        XCTAssertEqual(r.tore, 2)
        XCTAssertEqual(r.gegentore, 4)
        XCTAssertEqual(r.diff, -2)
        XCTAssertEqual(r.pkt, 4, "3 (Sieg) + 1 (Remis) + 0 (Niederlage)")
    }
}
