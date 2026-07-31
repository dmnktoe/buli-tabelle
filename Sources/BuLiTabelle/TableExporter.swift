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
