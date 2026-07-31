import SwiftUI

enum Col {
    static let platz: CGFloat = 46
    static let icon: CGFloat = 16
    static let sp: CGFloat = 28
    static let sun: CGFloat = 22
    static let tore: CGFloat = 50
    static let diff: CGFloat = 34
    static let pkt: CGFloat = 30
    static let form: CGFloat = 48
}

extension MatchOutcome {
    var color: Color {
        switch self {
        case .win: return Color(hex: 0x3AA53A)
        case .draw: return Color(hex: 0xB8B49E)
        case .loss: return Color(hex: 0xD64431)
        }
    }
}

/// Kleine Ergebnis-Kästchen der letzten (bis zu 5) Spiele – Grün/Grau/Rot.
struct FormDots: View {
    let form: [MatchOutcome]

    var body: some View {
        HStack(spacing: 2) {
            Spacer(minLength: 0)
            ForEach(Array(form.enumerated()), id: \.offset) { _, outcome in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(outcome.color)
                    .frame(width: 7, height: 7)
                    .overlay(
                        RoundedRectangle(cornerRadius: 1.5)
                            .strokeBorder(Color.black.opacity(0.18), lineWidth: 0.5)
                    )
            }
        }
        .frame(width: Col.form, alignment: .trailing)
    }
}

struct TableHeader: View {
    @AppStorage("showForm") private var showForm = true

    private func head(_ t: String, _ w: CGFloat) -> some View {
        Text(t).frame(width: w, alignment: .trailing)
    }

    var body: some View {
        HStack(spacing: 0) {
            Text("PLATZ")
                .padding(.leading, 5)
                .frame(width: Col.platz + 5, alignment: .leading)
            Text("MANNSCHAFT")
                .padding(.leading, Col.icon + 8)
                .frame(maxWidth: .infinity, alignment: .leading)
            head("SP", Col.sp)
            head("S", Col.sun)
            head("U", Col.sun)
            head("N", Col.sun)
            head("TORE", Col.tore)
            head("DIFF", Col.diff)
            head("PKT", Col.pkt)
            if showForm {
                head("FORM", Col.form)
            }
        }
        .padding(.trailing, 5)
        .font(.tahoma(10, bold: true))
        .foregroundStyle(.white)
        .frame(height: 20)
        .background(Color.black)
        .overlay(alignment: .bottom) { XP.bundesligaRed.frame(height: 2) }
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

    private var isSelected: Bool { model.selectedTeamID == row.id }
    private var isFavorite: Bool { favoriteTeam == row.id }

    private var rowBackground: Color {
        if isSelected { return XP.selectionFill }
        if zoneColors, let c = model.liga.zoneColor(position: row.position, teamCount: teamCount) {
            return c
        }
        if isFavorite { return XP.favoriteFill }
        return .white
    }

    private func cell(_ t: String, _ w: CGFloat, bold: Bool = false) -> some View {
        Text(t)
            .font(.tahoma(11, bold: bold))
            .frame(width: w, alignment: .trailing)
    }

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 6) {
                Circle().fill(Color.black).frame(width: 7, height: 7)
                Text("\(row.position)").font(.tahoma(11))
            }
            .padding(.leading, 5)
            .frame(width: Col.platz + 5, alignment: .leading)

            if showLogos {
                TeamIconView(urlString: row.team.teamIconUrl,
                             fallback: row.team.displayShort)
            }
            if isFavorite {
                Text("★")
                    .font(.tahoma(9))
                    .foregroundStyle(XP.selectionBorder)
                    .padding(.leading, 8)
            }
            Text(row.team.teamName)
                .font(.tahoma(11, bold: isFavorite))
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.leading, isFavorite ? 3 : 8)
                .frame(maxWidth: .infinity, alignment: .leading)

            cell("\(row.sp)", Col.sp)
            cell("\(row.s)", Col.sun)
            cell("\(row.u)", Col.sun)
            cell("\(row.n)", Col.sun)
            cell("\(row.tore):\(row.gegentore)", Col.tore)
            cell("\(row.diff)", Col.diff)
            cell("\(row.pkt)", Col.pkt, bold: true)
            if showForm {
                FormDots(form: row.form)
            }
        }
        .padding(.trailing, 5)
        .foregroundStyle(.black)
        .frame(height: 22)
        .background(rowBackground)
        .overlay(alignment: .bottom) {
            Color(hex: 0xE4E2D8).frame(height: 1)
        }
        .overlay(
            isSelected
                ? RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(XP.selectionBorder, lineWidth: 1.5)
                    .padding(1)
                : nil
        )
        .contentShape(Rectangle())
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
                Button("★ Als Lieblingsverein festlegen") {
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
                        XPLoadingIndicator(text: model.status)
                    } else {
                        Text(model.status)
                            .font(.tahoma(11))
                            .foregroundStyle(XP.darkShadow)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 120)
            } else {
                ForEach(model.rows) { row in
                    TableRowView(row: row, teamCount: model.rows.count)
                }
            }
        }
        .background(Color.white)
        .bevel(sunken: true)
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
