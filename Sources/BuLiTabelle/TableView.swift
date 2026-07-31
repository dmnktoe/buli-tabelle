import SwiftUI

enum Col {
    static let zone: CGFloat = 3
    static let platz: CGFloat = 26
    static let icon: CGFloat = 20
    static let sp: CGFloat = 30
    static let sun: CGFloat = 24
    static let tore: CGFloat = 52
    static let diff: CGFloat = 38
    static let pkt: CGFloat = 34
    static let form: CGFloat = 56
}

extension MatchOutcome {
    var color: Color {
        switch self {
        case .win: return Theme.win
        case .draw: return Theme.draw
        case .loss: return Theme.loss
        }
    }

    var label: String {
        switch self {
        case .win: return "Sieg"
        case .draw: return "Unentschieden"
        case .loss: return "Niederlage"
        }
    }
}

/// Formkurve der letzten (bis zu fünf) Spiele als kleine Pillen.
struct FormDots: View {
    let form: [MatchOutcome]

    var body: some View {
        HStack(spacing: 3) {
            Spacer(minLength: 0)
            ForEach(Array(form.enumerated()), id: \.offset) { _, outcome in
                Capsule(style: .continuous)
                    .fill(outcome.color)
                    .frame(width: 6, height: 6)
                    .help(outcome.label)
            }
        }
        .frame(width: Col.form, alignment: .trailing)
    }
}

struct TableHeader: View {
    @AppStorage("showForm") private var showForm = true

    private func head(_ title: String, _ width: CGFloat) -> some View {
        Text(title).frame(width: width, alignment: .trailing)
    }

    var body: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: Col.zone)
            Text("#")
                .padding(.leading, 8)
                .frame(width: Col.platz + 8, alignment: .leading)
            Text("Mannschaft")
                .padding(.leading, Col.icon + 10)
                .frame(maxWidth: .infinity, alignment: .leading)
            head("Sp", Col.sp)
            head("S", Col.sun)
            head("U", Col.sun)
            head("N", Col.sun)
            head("Tore", Col.tore)
            head("Diff", Col.diff)
            head("Pkt", Col.pkt)
            if showForm {
                head("Form", Col.form)
            }
        }
        .font(.ui(10, .semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .frame(height: 28)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.hairline).frame(height: 1)
        }
    }
}

struct TableRowView: View {
    @EnvironmentObject var model: AppModel
    @AppStorage("zoneColors") private var zoneColors = true
    @AppStorage("showLogos") private var showLogos = true
    @AppStorage("showForm") private var showForm = true
    @AppStorage("favoriteTeam") private var favoriteTeam = 0

    let row: TableRow
    let teamCount: Int
    var isLast = false

    @State private var hovering = false

    private var isSelected: Bool { model.selectedTeamID == row.id }
    private var isFavorite: Bool { favoriteTeam == row.id }
    private var zone: LeagueZone? { model.liga.zone(position: row.position, teamCount: teamCount) }

    private func cell(_ text: String, _ width: CGFloat,
                      weight: Font.Weight = .regular,
                      muted: Bool = false) -> some View {
        Text(text)
            .font(.stat(12, weight))
            .foregroundStyle(muted ? Color.secondary : Color.primary)
            .frame(width: width, alignment: .trailing)
    }

    /// Farbiger Balken der Auf-/Abstiegszone am linken Zeilenrand.
    @ViewBuilder
    private var zoneBar: some View {
        if zoneColors, let zone {
            Capsule(style: .continuous)
                .fill(zone.color)
                .frame(width: Col.zone, height: 20)
                .help(zone.label)
        } else {
            Color.clear.frame(width: Col.zone)
        }
    }

    @ViewBuilder
    private var rowBackground: some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.row, style: .continuous)
        if isSelected {
            shape.fill(Theme.accent.opacity(0.16))
                .overlay(shape.strokeBorder(Theme.accent.opacity(0.55), lineWidth: 1))
        } else if hovering {
            shape.fill(Theme.hover)
        } else if isFavorite {
            shape.fill(Theme.favorite.opacity(0.14))
        } else if zoneColors, let zone {
            shape.fill(zone.color.opacity(0.07))
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            zoneBar
            Text("\(row.position)")
                .font(.stat(12, .medium))
                .foregroundStyle(.secondary)
                .padding(.leading, 8)
                .frame(width: Col.platz + 8, alignment: .leading)

            if showLogos {
                TeamIconView(urlString: row.team.teamIconUrl, fallback: row.team.displayShort)
            } else {
                Color.clear.frame(width: Col.icon)
            }

            HStack(spacing: 4) {
                Text(row.team.teamName)
                    .font(.ui(13, isFavorite ? .semibold : .regular))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                if isFavorite {
                    Image(systemName: "star.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(Theme.favorite)
                }
            }
            .padding(.leading, 10)
            .frame(maxWidth: .infinity, alignment: .leading)

            cell("\(row.sp)", Col.sp, muted: true)
            cell("\(row.s)", Col.sun, muted: true)
            cell("\(row.u)", Col.sun, muted: true)
            cell("\(row.n)", Col.sun, muted: true)
            cell("\(row.tore):\(row.gegentore)", Col.tore)
            cell(row.diff > 0 ? "+\(row.diff)" : "\(row.diff)", Col.diff, muted: true)
            cell("\(row.pkt)", Col.pkt, weight: .bold)
            if showForm {
                FormDots(form: row.form)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 32)
        .background { rowBackground.padding(.horizontal, 6) }
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle()
                    .fill(Theme.hairline)
                    .frame(height: 1)
                    .padding(.horizontal, 12)
                    .opacity(hovering || isSelected ? 0 : 1)
            }
        }
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .animation(Theme.quick, value: hovering)
        .animation(Theme.spring, value: isSelected)
        .onTapGesture {
            model.selectedTeamID = isSelected ? nil : row.id
            if !isSelected { Analytics.signal(.teamSelected) }
        }
        .contextMenu {
            if isFavorite {
                Button("Lieblingsverein entfernen") {
                    favoriteTeam = 0
                    Analytics.signal(.favoriteCleared)
                }
            } else {
                Button("Als Lieblingsverein festlegen") {
                    favoriteTeam = row.id
                    Analytics.signal(.favoriteSet)
                }
            }
        }
    }
}

struct TablePanel: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            TableHeader()
            if model.rows.isEmpty {
                Group {
                    if model.isLoading {
                        LoadingIndicator(text: model.status)
                    } else {
                        EmptyStateView(systemImage: "tablecells", text: model.status)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 140)
            } else {
                ForEach(Array(model.rows.enumerated()), id: \.element.id) { index, row in
                    TableRowView(
                        row: row,
                        teamCount: model.rows.count,
                        isLast: index == model.rows.count - 1
                    )
                }
            }
        }
        .padding(.vertical, 4)
        .glass(.card, radius: Theme.Radius.card)
    }
}

/// Legende der Auf- und Abstiegszonen unter der Tabelle.
struct ZoneLegend: View {
    let liga: Liga
    let teamCount: Int

    var body: some View {
        let zones = liga.zones(teamCount: teamCount)
        if !zones.isEmpty {
            HStack(spacing: 12) {
                ForEach(zones, id: \.self) { zone in
                    HStack(spacing: 5) {
                        Capsule(style: .continuous)
                            .fill(zone.color)
                            .frame(width: 3, height: 10)
                        Text(zone.label)
                            .font(.ui(10))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 4)
        }
    }
}

struct PrintableTable: View {
    let title: String
    let rows: [TableRow]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 14, weight: .bold))
            ForEach(rows) { r in
                HStack(spacing: 8) {
                    Text("\(r.position).").frame(width: 24, alignment: .trailing)
                    Text(r.team.teamName).frame(width: 200, alignment: .leading)
                    Text("\(r.sp)").frame(width: 28, alignment: .trailing)
                    Text("\(r.s)/\(r.u)/\(r.n)").frame(width: 60, alignment: .trailing)
                    Text("\(r.tore):\(r.gegentore)").frame(width: 50, alignment: .trailing)
                    Text("\(r.pkt)").bold().frame(width: 30, alignment: .trailing)
                }
                .font(.system(size: 11))
            }
            Text("Erstellt mit \(AppInfo.name) · Daten: OpenLigaDB")
                .font(.system(size: 9))
                .foregroundStyle(.gray)
                .padding(.top, 6)
        }
        .padding(24)
        .frame(width: 480, alignment: .leading)
        .background(Color.white)
    }
}
