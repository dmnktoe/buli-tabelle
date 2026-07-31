import Foundation

/// Erzeugt exportierbare Repräsentationen der Tabelle. Rein & testbar – ohne UI.
enum TableExporter {
    static let csvHeader = "Platz;Mannschaft;SP;S;U;N;Tore;Gegentore;Diff;Punkte"

    /// Semikolon-getrennte Werte (Excel-freundlich).
    static func csv(_ rows: [TableRow]) -> String {
        var lines = [csvHeader]
        for r in rows {
            lines.append(
                "\(r.position);\(r.team.teamName);\(r.sp);\(r.s);\(r.u);\(r.n);"
                    + "\(r.tore);\(r.gegentore);\(r.diff);\(r.pkt)"
            )
        }
        return lines.joined(separator: "\n")
    }

    /// Menschlich lesbare, spaltenweise ausgerichtete Texttabelle – zum Teilen
    /// in Chats/E-Mails und für die Zwischenablage.
    static func plainText(title: String, rows: [TableRow]) -> String {
        guard !rows.isEmpty else { return title }

        func rpad(_ s: String, _ width: Int) -> String {
            s.count >= width ? String(s.prefix(width))
                             : s + String(repeating: " ", count: width - s.count)
        }
        func lpad(_ s: String, _ width: Int) -> String {
            s.count >= width ? s : String(repeating: " ", count: width - s.count) + s
        }

        let nameWidth = min(22, max(10, rows.map { $0.team.teamName.count }.max() ?? 10))
        var lines = [title, ""]
        lines.append("\(rpad("#", 3)) \(rpad("Mannschaft", nameWidth)) \(lpad("Sp", 3)) \(lpad("Pkt", 4)) \(lpad("Diff", 5))")
        for r in rows {
            let pos = rpad(lpad("\(r.position)", 2) + ".", 3)
            let diff = (r.diff > 0 ? "+" : "") + "\(r.diff)"
            lines.append("\(pos) \(rpad(r.team.teamName, nameWidth)) \(lpad("\(r.sp)", 3)) \(lpad("\(r.pkt)", 4)) \(lpad(diff, 5))")
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Pokal

    /// Paarungen einer K.-o.-Runde als Text. Der Sieger steht in Großbuchstaben,
    /// damit er ohne Formatierung erkennbar bleibt.
    static func plainText(title: String, round: CupRound) -> String {
        guard round.isDrawn else { return title + "\n\nDie Auslosung steht noch aus." }

        func rpad(_ s: String, _ width: Int) -> String {
            s.count >= width ? String(s.prefix(width))
                             : s + String(repeating: " ", count: width - s.count)
        }
        func lpad(_ s: String, _ width: Int) -> String {
            s.count >= width ? s : String(repeating: " ", count: width - s.count) + s
        }

        let names = round.matches.flatMap { [$0.team1.teamName, $0.team2.teamName] }
        let width = min(24, max(10, names.map(\.count).max() ?? 10))

        var lines = [title, ""]
        for m in round.matches {
            let home = m.cupWinner == .team1 ? m.team1.teamName.uppercased() : m.team1.teamName
            let away = m.cupWinner == .team2 ? m.team2.teamName.uppercased() : m.team2.teamName
            let note = m.cupDecisionNote.map { " (\($0))" } ?? ""
            lines.append("\(lpad(home, width))  \(m.cupScoreText)  \(rpad(away, width))\(note)")
        }
        return lines.joined(separator: "\n")
    }

    /// Eigenständiges HTML-Dokument einer K.-o.-Runde im XP-Look.
    static func html(title: String, round: CupRound, footerNote: String) -> String {
        guard round.isDrawn else {
            return document(title: title,
                            body: "<p>Die Auslosung steht noch aus.</p>",
                            footerNote: footerNote)
        }

        let rowsHTML = round.matches.enumerated().map { i, m in
            let bg = i % 2 == 0 ? "#FFFFFF" : "#F4F4F4"
            func cell(_ team: OLTeam, _ side: CupSide, align: String) -> String {
                let bold = m.cupWinner == side
                let name = escape(team.teamName)
                return "<td align=\"\(align)\">\(bold ? "<b>\(name)</b>" : name)</td>"
            }
            let note = m.cupDecisionNote.map { " <small>\(escape($0))</small>" } ?? ""
            return """
            <tr bgcolor="\(bg)">\(cell(m.team1, .team1, align: "right"))\
            <td align="center">\(escape(m.cupScoreText))\(note)</td>\
            \(cell(m.team2, .team2, align: "left"))</tr>
            """
        }.joined(separator: "\n")

        let body = """
        <table border="1" cellspacing="0" cellpadding="4" style="border-collapse: collapse; background: white;">
        <tr bgcolor="#000000" style="color: white;"><th align="right">Heim</th><th>Ergebnis</th><th align="left">Gast</th></tr>
        \(rowsHTML)
        </table>
        """
        return document(title: title, body: body, footerNote: footerNote)
    }

    private static func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    private static func document(title: String, body: String, footerNote: String) -> String {
        """
        <!DOCTYPE html>
        <html lang="de"><head><meta charset="utf-8"><title>\(escape(title))</title></head>
        <body style="font-family: Tahoma, Verdana, sans-serif; font-size: 12px; background: #ECE9D8;">
        <h2>\(escape(title))</h2>
        \(body)
        <p style="color: #716F64;">\(escape(footerNote))</p>
        </body></html>
        """
    }

    /// Eigenständiges HTML-Dokument im XP-Look.
    static func html(title: String, rows: [TableRow], footerNote: String) -> String {
        let rowsHTML = rows.map { r in
            let bg = r.position % 2 == 0 ? "#F4F4F4" : "#FFFFFF"
            return """
            <tr bgcolor="\(bg)"><td align="right">\(r.position)</td><td>\(r.team.teamName)</td>\
            <td align="right">\(r.sp)</td><td align="right">\(r.s)</td><td align="right">\(r.u)</td>\
            <td align="right">\(r.n)</td><td align="right">\(r.tore):\(r.gegentore)</td>\
            <td align="right">\(r.diff)</td><td align="right"><b>\(r.pkt)</b></td></tr>
            """
        }.joined(separator: "\n")

        return """
        <!DOCTYPE html>
        <html lang="de"><head><meta charset="utf-8"><title>\(title)</title></head>
        <body style="font-family: Tahoma, Verdana, sans-serif; font-size: 12px; background: #ECE9D8;">
        <h2>\(title)</h2>
        <table border="1" cellspacing="0" cellpadding="4" style="border-collapse: collapse; background: white;">
        <tr bgcolor="#000000" style="color: white;"><th>Platz</th><th align="left">Mannschaft</th>
        <th>SP</th><th>S</th><th>U</th><th>N</th><th>Tore</th><th>Diff</th><th>Pkt</th></tr>
        \(rowsHTML)
        </table>
        <p style="color: #716F64;">\(footerNote)</p>
        </body></html>
        """
    }
}
