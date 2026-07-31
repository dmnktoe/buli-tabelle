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

    /// Eigenständiges HTML-Dokument einer K.-o.-Runde.
    static func html(title: String, round: CupRound, footerNote: String) -> String {
        guard round.isDrawn else {
            return document(title: title,
                            body: "<p class=\"empty\">Die Auslosung steht noch aus.</p>",
                            footerNote: footerNote)
        }

        let rowsHTML = round.matches.map { m in
            func cell(_ team: OLTeam, _ side: CupSide, align: String) -> String {
                let name = escape(team.teamName)
                let classes = [align, m.cupWinner == side ? "win" : nil]
                    .compactMap { $0 }.joined(separator: " ")
                return "<td class=\"\(classes)\">\(name)</td>"
            }
            let note = m.cupDecisionNote.map { " <small>\(escape($0))</small>" } ?? ""
            return """
            <tr>\(cell(m.team1, .team1, align: "right"))\
            <td class="center score">\(escape(m.cupScoreText))\(note)</td>\
            \(cell(m.team2, .team2, align: "left"))</tr>
            """
        }.joined(separator: "\n")

        let body = """
        <table>
        <thead><tr><th class="right">Heim</th><th class="center">Ergebnis</th><th class="left">Gast</th></tr></thead>
        <tbody>
        \(rowsHTML)
        </tbody>
        </table>
        """
        return document(title: title, body: body, footerNote: footerNote)
    }

    /// Eigenständiges HTML-Dokument der Tabelle.
    static func html(title: String, rows: [TableRow], footerNote: String) -> String {
        let rowsHTML = rows.map { r in
            let diff = r.diff > 0 ? "+\(r.diff)" : "\(r.diff)"
            return """
            <tr><td class="right muted">\(r.position)</td><td>\(escape(r.team.teamName))</td>\
            <td class="right muted">\(r.sp)</td><td class="right muted">\(r.s)</td>\
            <td class="right muted">\(r.u)</td><td class="right muted">\(r.n)</td>\
            <td class="right">\(r.tore):\(r.gegentore)</td>\
            <td class="right muted">\(diff)</td><td class="right"><b>\(r.pkt)</b></td></tr>
            """
        }.joined(separator: "\n")

        let body = """
        <table>
        <thead><tr><th class="right">#</th><th class="left">Mannschaft</th><th class="right">Sp</th>
        <th class="right">S</th><th class="right">U</th><th class="right">N</th>
        <th class="right">Tore</th><th class="right">Diff</th><th class="right">Pkt</th></tr></thead>
        <tbody>
        \(rowsHTML)
        </tbody>
        </table>
        """
        return document(title: title, body: body, footerNote: footerNote)
    }

    private static func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    /// Rahmendokument im Look der App: Systemschrift, weiche Karte, heller und
    /// dunkler Modus.
    private static func document(title: String, body: String, footerNote: String) -> String {
        """
        <!DOCTYPE html>
        <html lang="de"><head><meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>\(escape(title))</title>
        <style>
        :root {
          color-scheme: light dark;
          --bg: #f2f3f6; --card: #ffffff; --text: #14161a; --muted: #6a707a;
          --line: rgba(0,0,0,.08); --accent: #c8102e;
        }
        @media (prefers-color-scheme: dark) {
          :root { --bg: #17181c; --card: #212328; --text: #f2f3f6; --muted: #9aa0aa;
                  --line: rgba(255,255,255,.10); --accent: #ff4f6b; }
        }
        body {
          margin: 0; padding: 40px 20px; background: var(--bg); color: var(--text);
          font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "Helvetica Neue", Arial, sans-serif;
          font-size: 14px; line-height: 1.45;
        }
        main { max-width: 760px; margin: 0 auto; }
        h1 { font-size: 20px; font-weight: 600; margin: 0 0 18px; letter-spacing: -.01em; }
        table {
          width: 100%; border-collapse: collapse; background: var(--card);
          border-radius: 14px; overflow: hidden;
          box-shadow: 0 1px 2px rgba(0,0,0,.06), 0 12px 28px rgba(0,0,0,.07);
        }
        th {
          font-size: 11px; font-weight: 600; text-transform: uppercase;
          letter-spacing: .04em; color: var(--muted); padding: 12px 10px;
          border-bottom: 1px solid var(--line);
        }
        td { padding: 9px 10px; border-bottom: 1px solid var(--line); }
        tbody tr:last-child td { border-bottom: none; }
        .left { text-align: left; } .right { text-align: right; } .center { text-align: center; }
        .muted { color: var(--muted); }
        .score { font-variant-numeric: tabular-nums; }
        .win { font-weight: 600; }
        .empty { color: var(--muted); }
        small { color: var(--accent); font-size: 10px; }
        footer { color: var(--muted); font-size: 11px; margin-top: 16px; }
        </style></head>
        <body><main>
        <h1>\(escape(title))</h1>
        \(body)
        <footer>\(escape(footerNote))</footer>
        </main></body></html>
        """
    }
}
