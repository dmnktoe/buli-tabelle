import SwiftUI

struct UpTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

struct SpieltagMenuBar: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        Button {
            model.showSpieltagMenu.toggle()
            Analytics.signal(.matchdayPanelToggled, ["state": model.showSpieltagMenu ? "open" : "closed"])
        } label: {
            HStack {
                Text("\(model.liga.periodNoun)-Menü >>")
                    .font(.tahoma(11, bold: true))
                    .foregroundStyle(.black)
                Spacer()
                UpTriangle()
                    .fill(Color(hex: 0x00A000))
                    .frame(width: 36, height: 13)
                    .rotationEffect(model.showSpieltagMenu ? .degrees(180) : .zero)
                    .padding(.trailing, 4)
            }
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .frame(height: 24)
            .background(XP.face)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .bevel()
    }
}

struct MatchRowView: View {
    let match: OLMatch

    private var resultText: String {
        if match.matchIsFinished,
           let r = match.finalResult,
           let p1 = r.pointsTeam1, let p2 = r.pointsTeam2 {
            return "\(p1) : \(p2)"
        }
        return "- : -"
    }

    var body: some View {
        HStack(spacing: 5) {
            Text(match.kickoffText)
                .font(.tahoma(10))
                .foregroundStyle(XP.darkShadow)
                .frame(width: 88, alignment: .leading)
            Text(match.team1.displayShort)
                .font(.tahoma(11))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .trailing)
            TeamIconView(urlString: match.team1.teamIconUrl,
                         fallback: match.team1.displayShort)
            Text(resultText)
                .font(.tahoma(11, bold: match.matchIsFinished))
                .frame(width: 42)
            TeamIconView(urlString: match.team2.teamIconUrl,
                         fallback: match.team2.displayShort)
            Text(match.team2.displayShort)
                .font(.tahoma(11))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(.black)
        .padding(.horizontal, 6)
        .frame(height: 21)
        .overlay(alignment: .bottom) {
            Color(hex: 0xE4E2D8).frame(height: 1)
        }
    }
}

struct MatchdayPanel: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            Text("\(model.spieltag). \(model.liga.periodNoun) – \(model.liga.display)")
                .font(.tahoma(10, bold: true))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 6)
                .frame(height: 17)
                .background(Color.black)
            if model.matchesOfSpieltag.isEmpty {
                Text("Keine Spiele gefunden.")
                    .font(.tahoma(11))
                    .foregroundStyle(XP.darkShadow)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
            } else {
                ForEach(model.matchesOfSpieltag) { m in
                    MatchRowView(match: m)
                }
            }
        }
        .background(Color.white)
        .bevel(sunken: true)
        .padding(.horizontal, 6)
        .padding(.bottom, 5)
    }
}

struct StatusBar: View {
    @EnvironmentObject var model: AppModel

    private var rightText: String {
        if let id = model.selectedTeamID,
           let row = model.rows.first(where: { $0.id == id }) {
            return "\(row.team.teamName): Platz \(row.position), \(row.pkt) Punkte"
        }
        if model.liga.isCup, let round = model.currentCupRound {
            return "\(model.liga.display) \(model.seasonString) · \(round.name): \(round.progressText)"
        }
        return "Daten: OpenLigaDB · \(model.liga.display) \(model.seasonString)"
    }

    var body: some View {
        HStack(spacing: 3) {
            Text(model.status)
                .font(.tahoma(11))
                .foregroundStyle(.black)
                .lineLimit(1)
                .padding(.horizontal, 5)
                .frame(width: 170, height: 19, alignment: .leading)
                .bevel(sunken: true)
            Text(rightText)
                .font(.tahoma(11))
                .foregroundStyle(.black)
                .lineLimit(1)
                .padding(.horizontal, 5)
                .frame(maxWidth: .infinity)
                .frame(height: 19, alignment: .leading)
                .bevel(sunken: true)
        }
        .padding(3)
        .background(XP.face)
    }
}
