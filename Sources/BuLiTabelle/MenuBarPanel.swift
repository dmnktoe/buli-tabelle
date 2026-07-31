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
            footer
        }
        .frame(width: 300)
        .background(XP.face)
        .task {
            if model.rows.isEmpty { await model.reload() }
        }
    }

    private var header: some View {
        HStack(spacing: 5) {
            MiniFlagIcon()
            Text("\(AppInfo.name) – \(model.liga.display)")
                .font(.tahoma(11, bold: true))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.55), radius: 0, x: 1, y: 1)
                .lineLimit(1)
            Spacer()
            Text("\(model.spieltag). Spieltag")
                .font(.tahoma(10))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 6)
        .frame(height: 24)
        .background(XP.titleGradient)
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
        NSApp.setActivationPolicy(.regular)
        openWindow(id: "main")
        NSApp.activate(ignoringOtherApps: true)
    }
}
