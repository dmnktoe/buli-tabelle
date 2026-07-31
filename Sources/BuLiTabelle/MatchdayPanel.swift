import SwiftUI

/// Eine Begegnung des Spieltags.
struct MatchRowView: View {
    let match: OLMatch
    var isLast = false

    private var resultText: String {
        if match.matchIsFinished,
           let r = match.finalResult,
           let p1 = r.pointsTeam1, let p2 = r.pointsTeam2 {
            return "\(p1) : \(p2)"
        }
        return "– : –"
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(match.kickoffText)
                .font(.ui(10))
                .foregroundStyle(.secondary)
                .frame(width: 96, alignment: .leading)

            Text(match.team1.displayShort)
                .font(.ui(12))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .trailing)
            TeamIconView(urlString: match.team1.teamIconUrl, fallback: match.team1.displayShort)

            Text(resultText)
                .font(.stat(12, match.matchIsFinished ? .semibold : .regular))
                .foregroundStyle(match.matchIsFinished ? Color.primary : Color.secondary)
                .frame(width: 52)

            TeamIconView(urlString: match.team2.teamIconUrl, fallback: match.team2.displayShort)
            Text(match.team2.displayShort)
                .font(.ui(12))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(Color.primary)
        .padding(.horizontal, 12)
        .frame(height: 28)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(Theme.hairline).frame(height: 1).padding(.horizontal, 12)
            }
        }
    }
}

/// Ausklappbarer Bereich mit allen Paarungen des gewählten Spieltags.
struct MatchdaySection: View {
    @EnvironmentObject var model: AppModel

    private var isOpen: Bool { model.showSpieltagMenu }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(Theme.spring) { model.showSpieltagMenu.toggle() }
                Analytics.signal(.matchdayPanelToggled, ["state": model.showSpieltagMenu ? "open" : "closed"])
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isOpen ? 90 : 0))
                    Text("\(model.spieltag). \(model.liga.periodNoun)")
                        .font(.ui(12, .semibold))
                        .foregroundStyle(Color.primary)
                    Spacer()
                    Text(model.matchesOfSpieltag.isEmpty
                         ? "keine Spiele"
                         : "\(model.matchesOfSpieltag.count) Spiele")
                        .font(.ui(11))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .frame(height: 34)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isOpen {
                Rectangle().fill(Theme.hairline).frame(height: 1)
                if model.matchesOfSpieltag.isEmpty {
                    EmptyStateView(systemImage: "sportscourt", text: "Keine Spiele gefunden.")
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                } else {
                    ForEach(Array(model.matchesOfSpieltag.enumerated()), id: \.element.id) { index, match in
                        MatchRowView(match: match, isLast: index == model.matchesOfSpieltag.count - 1)
                    }
                    Color.clear.frame(height: 4)
                }
            }
        }
        .glass(.card, radius: Theme.Radius.card)
    }
}

/// Schmale Fußzeile mit Ladezustand, Auswahl und Datenquelle.
struct StatusBar: View {
    @EnvironmentObject var model: AppModel

    private var detail: String {
        if let id = model.selectedTeamID,
           let row = model.rows.first(where: { $0.id == id }) {
            return "\(row.team.teamName) · Platz \(row.position) · \(row.pkt) Punkte"
        }
        if model.liga.isCup, let round = model.currentCupRound {
            return "\(round.name) · \(round.progressText)"
        }
        return model.status
    }

    var body: some View {
        HStack(spacing: 8) {
            if model.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .controlSize(.small)
                    .scaleEffect(0.7)
                    .frame(width: 12, height: 12)
            }
            Text(detail)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 8)

            Button {
                model.openDataSource()
            } label: {
                HStack(spacing: 3) {
                    Text("OpenLigaDB")
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 8, weight: .semibold))
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(Theme.accent)
            .help("Datenquelle im Browser öffnen")
        }
        .font(.ui(11))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 18)
        .frame(height: 30)
        .overlay(alignment: .top) {
            Rectangle().fill(Theme.hairline).frame(height: 1)
        }
    }
}
