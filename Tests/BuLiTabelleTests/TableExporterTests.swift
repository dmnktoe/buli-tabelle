import XCTest
@testable import BuLiTabelle

final class TableExporterTests: XCTestCase {

    private func sampleRow() -> TableRow {
        var r = TableRow(team: OLTeam(teamId: 1, teamName: "Alpha", shortName: "ALP", teamIconUrl: nil))
        r.position = 1
        r.add(goalsFor: 2, against: 0)
        return r
    }

    func testCSVHeaderAndRow() {
        let csv = TableExporter.csv([sampleRow()])
        let lines = csv.split(separator: "\n").map(String.init)
        XCTAssertEqual(lines.first, TableExporter.csvHeader)
        XCTAssertEqual(lines.count, 2)
        XCTAssertEqual(lines[1], "1;Alpha;1;1;0;0;2;0;2;3")
    }

    func testCSVEmptyIsHeaderOnly() {
        XCTAssertEqual(TableExporter.csv([]), TableExporter.csvHeader)
    }

    func testPlainTextHasTitleHeaderAndRow() {
        let text = TableExporter.plainText(title: "Testtabelle", rows: [sampleRow()])
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        XCTAssertEqual(lines.first, "Testtabelle")
        XCTAssertTrue(lines.contains { $0.contains("Mannschaft") && $0.contains("Pkt") },
                      "Kopfzeile mit Spaltenüberschriften vorhanden")
        XCTAssertTrue(lines.contains { $0.contains("1.") && $0.contains("Alpha") && $0.contains("+2") },
                      "Datenzeile mit Platz, Verein und signierter Differenz")
    }

    func testPlainTextEmptyIsJustTitle() {
        XCTAssertEqual(TableExporter.plainText(title: "Leer", rows: []), "Leer")
    }

    func testHTMLContainsTitleTeamAndPoints() {
        let html = TableExporter.html(
            title: "Testtabelle",
            rows: [sampleRow()],
            footerNote: "Fußzeile"
        )
        XCTAssertTrue(html.contains("<title>Testtabelle</title>"))
        XCTAssertTrue(html.contains("Alpha"))
        XCTAssertTrue(html.contains("<b>3</b>"), "Punkte werden fett ausgegeben")
        XCTAssertTrue(html.contains("Fußzeile"))
    }
}
