import SwiftUI

private enum CupCol {
    static let kickoff: CGFloat = 96
    static let score: CGFloat = 56
    static let note: CGFloat = 34
}

/// Kopfzeile der Pokalrunde – Name links, Fortschritt rechts.
struct CupRoundHeader: View {
    let round: CupRound?
    let fallbackName: String

    var body: some View {
        HStack(spacing: 0) {
            Text(round?.name ?? fallbackName)
                .font(.ui(12, .semibold))
                .foregroundStyle(Color.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(round?.progressText ?? "")
                .font(.ui(11))
                .foregroundStyle(.secondary)
        }
        .lineLimit(1)
        .padding(.horizontal, 12)
        .frame(height: 30)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.hairline).frame(height: 1)
        }
    }
}

/// Eine Paarung. Der Sieger steht fett, der Ausgeschiedene wird abgeblendet.
struct CupPairingRow: View {
    @AppStorage("favoriteTeam") private var favoriteTeam = 0

    let match: OLMatch
    var isLast = false

    @State private var hovering = false

    private func isWinner(_ side: CupSide) -> Bool { match.cupWinner == side }
    private func isLoser(_ side: CupSide) -> Bool {
        match.cupWinner != nil && match.cupWinner != side
    }

    private var involvesFavorite: Bool {
        favoriteTeam != 0 && (match.team1.teamId == favoriteTeam || match.team2.teamId == favoriteTeam)
    }

    private func teamText(_ team: OLTeam, _ side: CupSide, alignment: Alignment) -> some View {
        Text(team.displayShort)
            .font(.ui(12, isWinner(side) ? .semibold : .regular))
            .foregroundStyle(Color.primary)
            .opacity(isLoser(side) ? 0.45 : 1)
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity, alignment: alignment)
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(match.kickoffText)
                .font(.ui(10))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(width: CupCol.kickoff, alignment: .leading)

            teamText(match.team1, .team1, alignment: .trailing)
            TeamIconView(urlString: match.team1.teamIconUrl, fallback: match.team1.displayShort)

            Text(match.cupScoreText)
                .font(.stat(12, match.matchIsFinished ? .semibold : .regular))
                .foregroundStyle(match.matchIsFinished ? Color.primary : Color.secondary)
                .frame(width: CupCol.score)

            TeamIconView(urlString: match.team2.teamIconUrl, fallback: match.team2.displayShort)
            teamText(match.team2, .team2, alignment: .leading)

            Text(match.cupDecisionNote ?? "")
                .font(.ui(9, .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: CupCol.note, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .frame(height: 30)
        .background {
            let shape = RoundedRectangle(cornerRadius: Theme.Radius.row, style: .continuous)
            if hovering {
                shape.fill(Theme.hover).padding(.horizontal, 6)
            } else if involvesFavorite {
                shape.fill(Theme.favorite.opacity(0.14)).padding(.horizontal, 6)
            }
        }
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle()
                    .fill(Theme.hairline)
                    .frame(height: 1)
                    .padding(.horizontal, 12)
                    .opacity(hovering ? 0 : 1)
            }
        }
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .animation(Theme.quick, value: hovering)
    }
}

struct CupPanel: View {
    @EnvironmentObject var model: AppModel

    private var round: CupRound? { model.currentCupRound }

    /// Text für den leeren Zustand. Zwischen den Runden wird ausgelost – das ist
    /// kein Fehler, sondern der Normalfall, und wird entsprechend benannt.
    private var emptyText: String {
        if model.isLoading { return model.status }
        if model.cupRounds.isEmpty { return model.status }
        return "Die Auslosung für diese Runde steht noch aus."
    }

    var body: some View {
        VStack(spacing: 0) {
            CupRoundHeader(round: round, fallbackName: model.roundName(model.spieltag))

            if let round, round.isDrawn {
                ForEach(Array(round.matches.enumerated()), id: \.element.id) { index, match in
                    CupPairingRow(match: match, isLast: index == round.matches.count - 1)
                }
                if round.isComplete {
                    advancingFooter(round)
                }
            } else {
                Group {
                    if model.isLoading {
                        LoadingIndicator(text: model.status)
                    } else {
                        EmptyStateView(systemImage: "trophy", text: emptyText)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 140)
            }
        }
        .padding(.vertical, 4)
        .glass(.card, radius: Theme.Radius.card)
    }

    private func advancingFooter(_ round: CupRound) -> some View {
        let names = round.advancingTeams.map(\.displayShort).joined(separator: " · ")
        return Group {
            if !names.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "arrow.forward.circle")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.accent)
                    Text(names)
                        .font(.ui(10))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 2)
            }
        }
    }
}

/// Druckansicht einer Pokalrunde.
struct PrintableCupRound: View {
    let title: String
    let round: CupRound

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 14, weight: .bold))
            if round.isDrawn {
                ForEach(round.matches) { m in
                    HStack(spacing: 8) {
                        Text(m.kickoffText)
                            .frame(width: 110, alignment: .leading)
                        Text(m.team1.teamName)
                            .bold(m.cupWinner == .team1)
                            .frame(width: 170, alignment: .trailing)
                        Text(m.cupScoreText)
                            .frame(width: 54, alignment: .center)
                        Text(m.team2.teamName)
                            .bold(m.cupWinner == .team2)
                            .frame(width: 170, alignment: .leading)
                        Text(m.cupDecisionNote ?? "")
                            .frame(width: 40, alignment: .leading)
                    }
                    .font(.system(size: 11))
                }
            } else {
                Text("Die Auslosung steht noch aus.").font(.system(size: 11))
            }
            Text("Erstellt mit \(AppInfo.name) · Daten: OpenLigaDB")
                .font(.system(size: 9))
                .foregroundStyle(.gray)
                .padding(.top, 6)
        }
        .padding(24)
    }
}
