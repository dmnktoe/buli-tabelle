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
    @EnvironmentObject var model: AppModel

    let match: OLMatch

    private var live: LiveScore? { model.liveScore(for: match) }
    private var isFlashing: Bool { model.isFlashing(match) }

    private var resultText: String {
        if let live { return live.text }
        if match.matchIsFinished,
           let r = match.finalResult,
           let p1 = r.pointsTeam1, let p2 = r.pointsTeam2 {
            return "\(p1) : \(p2)"
        }
        return "- : -"
    }

    /// Links steht sonst die Anstoßzeit – während des Spiels das Live-Schild.
    @ViewBuilder
    private var timeColumn: some View {
        if live != nil {
            HStack(spacing: 0) {
                LiveBadge(minute: model.liveMinute(for: match))
                Spacer(minLength: 0)
            }
            .help(model.liveMinuteHint)
        } else {
            Text(match.kickoffText)
                .font(.tahoma(10))
                .foregroundStyle(XP.darkShadow)
        }
    }

    var body: some View {
        HStack(spacing: 5) {
            timeColumn
                .frame(width: 88, alignment: .leading)
            Text(match.team1.displayShort)
                .font(.tahoma(11))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .trailing)
            TeamIconView(urlString: match.team1.teamIconUrl,
                         fallback: match.team1.displayShort)
            Text(resultText)
                .font(.tahoma(11, bold: match.matchIsFinished || live != nil))
                .foregroundStyle(live != nil ? XP.liveRed : .black)
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
        .background(isFlashing ? XP.goalFlash : .clear)
        .overlay(alignment: .bottom) {
            Color(hex: 0xE4E2D8).frame(height: 1)
        }
        .animation(.easeOut(duration: 0.35), value: isFlashing)
    }
}

struct MatchdayPanel: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 5) {
                Text("\(model.spieltag). \(model.liga.periodNoun) – \(model.liga.display)")
                    .font(.tahoma(10, bold: true))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Spacer(minLength: 0)
                if !model.liveMatchesOfSpieltag.isEmpty {
                    LiveBadge(compact: true)
                }
            }
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
            var text = "\(row.team.teamName): Platz \(row.position), \(row.pkt) Punkte"
            if row.movement != 0 {
                text += " · offiziell Platz \(row.position + row.movement)"
            }
            if row.isLive { text += " · spielt gerade" }
            return text
        }
        if model.live.isActive {
            return "\(model.live.headline) · \(model.liveUpdatedText)"
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
