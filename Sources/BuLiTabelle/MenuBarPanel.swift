import SwiftUI
import AppKit

/// Kompaktansicht hinter dem Menüleisten-Symbol.
struct MenuBarPanel: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.openWindow) private var openWindow
    @AppStorage("favoriteTeam") private var favoriteTeam = 0

    private enum MCol {
        static let pos: CGFloat = 20
        static let sp: CGFloat = 26
        static let diff: CGFloat = 34
        static let pkt: CGFloat = 28
    }

    var body: some View {
        VStack(spacing: 10) {
            header
            VStack(spacing: 0) {
                if model.liga.isCup {
                    cupSection
                } else {
                    tableSection
                }
            }
            .padding(.vertical, 4)
            .glass(.card, radius: Theme.Radius.card)
            footer
        }
        .padding(12)
        .frame(width: 320)
        .task {
            Analytics.signal(.menuBarOpened)
            if model.rows.isEmpty && model.cupRounds.isEmpty { await model.reload() }
        }
    }

    private var header: some View {
        HStack(spacing: 9) {
            LeagueBadge(liga: model.liga)
                .scaleEffect(0.85)
                .frame(width: 26, height: 26)
            VStack(alignment: .leading, spacing: 0) {
                Text(model.liga.display)
                    .font(.ui(12, .semibold))
                    .foregroundStyle(Color.primary)
                Text("Saison \(model.seasonShort)")
                    .font(.ui(10))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 4)
            Text(model.liga.isCup
                 ? CupBracket.shortName(model.roundName(model.spieltag))
                 : "\(model.spieltag). Spieltag")
                .font(.ui(10, .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    // MARK: - Tabelle

    @ViewBuilder
    private var tableSection: some View {
        tableHead
        if model.rows.isEmpty {
            Group {
                if model.isLoading {
                    LoadingIndicator(text: model.status)
                } else {
                    EmptyStateView(systemImage: "tablecells", text: model.status)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
        } else {
            ForEach(Array(model.rows.enumerated()), id: \.element.id) { index, row in
                compactRow(row, isLast: index == model.rows.count - 1)
            }
        }
    }

    private var tableHead: some View {
        HStack(spacing: 0) {
            Text("#").frame(width: MCol.pos, alignment: .leading)
            Text("Mannschaft")
                .padding(.leading, Col.icon + 8)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Sp").frame(width: MCol.sp, alignment: .trailing)
            Text("Diff").frame(width: MCol.diff, alignment: .trailing)
            Text("Pkt").frame(width: MCol.pkt, alignment: .trailing)
        }
        .font(.ui(9, .semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .frame(height: 22)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.hairline).frame(height: 1)
        }
    }

    private func compactRow(_ row: TableRow, isLast: Bool) -> some View {
        let isFavorite = favoriteTeam == row.id
        let zone = model.liga.zone(position: row.position, teamCount: model.rows.count)
        return HStack(spacing: 0) {
            Text("\(row.position)")
                .font(.stat(10))
                .foregroundStyle(.secondary)
                .frame(width: MCol.pos, alignment: .leading)
            TeamIconView(urlString: row.team.teamIconUrl, fallback: row.team.displayShort)
            HStack(spacing: 3) {
                Text(row.team.displayShort)
                    .font(.ui(11, isFavorite ? .semibold : .regular))
                    .lineLimit(1)
                    .truncationMode(.tail)
                if isFavorite {
                    Image(systemName: "star.fill")
                        .font(.system(size: 7))
                        .foregroundStyle(Theme.favorite)
                }
            }
            .padding(.leading, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            Text("\(row.sp)")
                .font(.stat(10))
                .foregroundStyle(.secondary)
                .frame(width: MCol.sp, alignment: .trailing)
            Text(row.diff > 0 ? "+\(row.diff)" : "\(row.diff)")
                .font(.stat(10))
                .foregroundStyle(.secondary)
                .frame(width: MCol.diff, alignment: .trailing)
            Text("\(row.pkt)")
                .font(.stat(11, .semibold))
                .frame(width: MCol.pkt, alignment: .trailing)
        }
        .foregroundStyle(Color.primary)
        .padding(.horizontal, 10)
        .frame(height: 22)
        .background(alignment: .leading) {
            if let zone {
                Capsule(style: .continuous)
                    .fill(zone.color)
                    .frame(width: 2, height: 14)
                    .padding(.leading, 4)
            }
        }
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(Theme.hairline).frame(height: 1).padding(.horizontal, 10)
            }
        }
    }

    // MARK: - Pokal

    /// Kompakte Pokalansicht: die Paarungen der laufenden Runde.
    @ViewBuilder
    private var cupSection: some View {
        let round = model.currentCupRound
        Text(round?.name ?? model.roundName(model.spieltag))
            .font(.ui(10, .semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .frame(height: 22)
            .overlay(alignment: .bottom) {
                Rectangle().fill(Theme.hairline).frame(height: 1)
            }

        if let round, round.isDrawn {
            ForEach(Array(round.matches.enumerated()), id: \.element.id) { index, match in
                compactPairing(match, isLast: index == round.matches.count - 1)
            }
        } else {
            EmptyStateView(
                systemImage: "trophy",
                text: model.isLoading ? model.status : "Auslosung steht noch aus."
            )
            .frame(maxWidth: .infinity)
            .frame(height: 72)
        }
    }

    private func compactPairing(_ match: OLMatch, isLast: Bool) -> some View {
        HStack(spacing: 0) {
            Text(match.team1.displayShort)
                .font(.ui(10, match.cupWinner == .team1 ? .semibold : .regular))
                .opacity(match.cupWinner == .team2 ? 0.45 : 1)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text(match.cupScoreText)
                .font(.stat(10, match.matchIsFinished ? .semibold : .regular))
                .frame(width: 56)
            Text(match.team2.displayShort)
                .font(.ui(10, match.cupWinner == .team2 ? .semibold : .regular))
                .opacity(match.cupWinner == .team1 ? 0.45 : 1)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(Color.primary)
        .padding(.horizontal, 10)
        .frame(height: 22)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(Theme.hairline).frame(height: 1).padding(.horizontal, 10)
            }
        }
    }

    // MARK: - Fußzeile

    private var footer: some View {
        HStack(spacing: 6) {
            GlassButton("Fenster öffnen", systemImage: "macwindow", prominent: true) {
                openMainWindow()
            }
            IconButton(systemName: "arrow.clockwise", help: "Aktualisieren") {
                model.loadFromInternet()
            }
            Spacer(minLength: 0)
            IconButton(systemName: "power", help: "\(AppInfo.name) beenden") {
                NSApp.terminate(nil)
            }
        }
    }

    private func openMainWindow() {
        Analytics.signal(.menuBarWindowOpened)
        NSApp.setActivationPolicy(.regular)
        openWindow(id: "main")
        NSApp.activate(ignoringOtherApps: true)
    }
}
