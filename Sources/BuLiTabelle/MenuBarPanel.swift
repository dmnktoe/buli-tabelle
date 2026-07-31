import SwiftUI
import AppKit

struct MenuBarPanel: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.openWindow) private var openWindow
    @AppStorage("favoriteTeam") private var favoriteTeam = 0

    private enum MCol {
        static let pos: CGFloat = 24
        static let sp: CGFloat = 26
        static let diff: CGFloat = 34
        static let pkt: CGFloat = 30
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            if model.liga.isCup {
                cupSection
            } else {
                tableSection
            }
            footer
        }
        .frame(width: 300)
        .background(XP.face)
        .task {
            Analytics.signal(.menuBarOpened)
            if model.rows.isEmpty && model.cupRounds.isEmpty { await model.reload() }
        }
    }

    /// Kompakte Pokalansicht: die Paarungen der laufenden Runde.
    @ViewBuilder
    private var cupSection: some View {
        let round = model.currentCupRound
        Text((round?.name ?? model.roundName(model.spieltag)).uppercased())
            .font(.tahoma(9, bold: true))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 5)
            .frame(height: 16)
            .background(Color.black)
            .overlay(alignment: .bottom) { XP.bundesligaRed.frame(height: 2) }

        if let round, round.isDrawn {
            ForEach(round.matches) { match in
                compactPairing(match)
            }
        } else {
            Text(model.isLoading ? model.status : "Auslosung steht noch aus.")
                .font(.tahoma(11))
                .foregroundStyle(XP.darkShadow)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(Color.white)
        }
    }

    private func compactPairing(_ match: OLMatch) -> some View {
        HStack(spacing: 0) {
            Text(match.team1.displayShort)
                .font(.tahoma(10, bold: match.cupWinner == .team1))
                .opacity(match.cupWinner == .team2 ? 0.45 : 1)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text(match.cupScoreText)
                .font(.tahoma(10, bold: match.matchIsFinished))
                .frame(width: 54)
            Text(match.team2.displayShort)
                .font(.tahoma(10, bold: match.cupWinner == .team2))
                .opacity(match.cupWinner == .team1 ? 0.45 : 1)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 5)
        .foregroundStyle(.black)
        .frame(height: 18)
        .background(Color.white)
        .overlay(alignment: .bottom) {
            Color(hex: 0xE4E2D8).frame(height: 1)
        }
    }

    @ViewBuilder
    private var tableSection: some View {
        tableHead
        if model.rows.isEmpty {
            Group {
                if model.isLoading {
                    XPLoadingIndicator(text: model.status, barWidth: 140)
                } else {
                    Text(model.status)
                        .font(.tahoma(11))
                        .foregroundStyle(XP.darkShadow)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(Color.white)
        } else {
            ForEach(model.rows) { row in
                compactRow(row)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 5) {
            MiniBallIcon()
            Text("\(AppInfo.name) – \(model.liga.display)")
                .font(.tahoma(11, bold: true))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.55), radius: 0, x: 1, y: 1)
                .lineLimit(1)
            Spacer()
            Text(model.liga.isCup ? CupBracket.shortName(model.roundName(model.spieltag))
                                  : "\(model.spieltag). Spieltag")
                .font(.tahoma(10))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 6)
        .frame(height: 24)
        .titleBarBackground()
    }

    private var tableHead: some View {
        HStack(spacing: 0) {
            Text("PL").frame(width: MCol.pos, alignment: .leading).padding(.leading, 5)
            Text("MANNSCHAFT")
                .padding(.leading, Col.icon + 6)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("SP").frame(width: MCol.sp, alignment: .trailing)
            Text("DIFF").frame(width: MCol.diff, alignment: .trailing)
            Text("PKT").frame(width: MCol.pkt, alignment: .trailing)
        }
        .padding(.trailing, 5)
        .font(.tahoma(9, bold: true))
        .foregroundStyle(.white)
        .frame(height: 16)
        .background(Color.black)
        .overlay(alignment: .bottom) { XP.bundesligaRed.frame(height: 2) }
    }

    private func compactRow(_ row: TableRow) -> some View {
        let isFavorite = favoriteTeam == row.id
        return HStack(spacing: 0) {
            Text("\(row.position)")
                .frame(width: MCol.pos, alignment: .leading)
                .padding(.leading, 5)
            TeamIconView(urlString: row.team.teamIconUrl,
                         fallback: row.team.displayShort)
            if isFavorite {
                Text("★")
                    .font(.tahoma(8))
                    .foregroundStyle(XP.selectionBorder)
                    .padding(.leading, 6)
            }
            Text(row.team.displayShort)
                .font(.tahoma(10, bold: isFavorite))
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.leading, isFavorite ? 2 : 6)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("\(row.sp)").frame(width: MCol.sp, alignment: .trailing)
            Text("\(row.diff)").frame(width: MCol.diff, alignment: .trailing)
            Text("\(row.pkt)")
                .font(.tahoma(10, bold: true))
                .frame(width: MCol.pkt, alignment: .trailing)
        }
        .padding(.trailing, 5)
        .font(.tahoma(10))
        .foregroundStyle(.black)
        .frame(height: 18)
        .background(
            model.liga.zoneColor(position: row.position, teamCount: model.rows.count)
                ?? (isFavorite ? XP.favoriteFill : .white)
        )
        .overlay(alignment: .bottom) {
            Color(hex: 0xE4E2D8).frame(height: 1)
        }
    }

    private var footer: some View {
        HStack(spacing: 4) {
            XPButton("Fenster öffnen", emphasized: true) { openMainWindow() }
            XPButton("Aktualisieren") { model.loadFromInternet() }
            XPButton("Beenden") { NSApp.terminate(nil) }
        }
        .padding(4)
    }

    private func openMainWindow() {
        Analytics.signal(.menuBarWindowOpened)
        NSApp.setActivationPolicy(.regular)
        openWindow(id: "main")
        NSApp.activate(ignoringOtherApps: true)
    }
}
