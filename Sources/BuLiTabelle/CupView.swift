import SwiftUI

private enum CupCol {
    static let kickoff: CGFloat = 84
    static let score: CGFloat = 52
    static let note: CGFloat = 32
}

/// Kopfzeile der Pokalrunde – analog zum Tabellenkopf, mit rotem Abschluss.
struct CupRoundHeader: View {
    let round: CupRound?
    let fallbackName: String

    var body: some View {
        HStack(spacing: 0) {
            Text((round?.name ?? fallbackName).uppercased())
                .padding(.leading, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(round?.progressText.uppercased() ?? "")
                .padding(.trailing, 6)
        }
        .font(.tahoma(10, bold: true))
        .foregroundStyle(.white)
        .lineLimit(1)
        .frame(height: 20)
        .background(Color.black)
        .overlay(alignment: .bottom) { XP.bundesligaRed.frame(height: 2) }
    }
}

/// Eine Paarung. Der Sieger steht fett, der Ausgeschiedene wird abgeblendet.
struct CupPairingRow: View {
    @AppStorage("favoriteTeam") private var favoriteTeam = 0

    let match: OLMatch
    let index: Int

    private func isWinner(_ side: CupSide) -> Bool { match.cupWinner == side }
    private func isLoser(_ side: CupSide) -> Bool {
        match.cupWinner != nil && match.cupWinner != side
    }

    private var involvesFavorite: Bool {
        favoriteTeam != 0 && (match.team1.teamId == favoriteTeam || match.team2.teamId == favoriteTeam)
    }

    private func teamText(_ team: OLTeam, _ side: CupSide, alignment: Alignment) -> some View {
        Text(team.displayShort)
            .font(.tahoma(11, bold: isWinner(side)))
            .foregroundStyle(.black)
            .opacity(isLoser(side) ? 0.45 : 1)
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity, alignment: alignment)
    }

    var body: some View {
        HStack(spacing: 5) {
            Text(match.kickoffText)
                .font(.tahoma(10))
                .foregroundStyle(XP.darkShadow)
                .lineLimit(1)
                .frame(width: CupCol.kickoff, alignment: .leading)

            teamText(match.team1, .team1, alignment: .trailing)
            TeamIconView(urlString: match.team1.teamIconUrl,
                         fallback: match.team1.displayShort)

            Text(match.cupScoreText)
                .font(.tahoma(11, bold: match.matchIsFinished))
                .foregroundStyle(.black)
                .frame(width: CupCol.score)

            TeamIconView(urlString: match.team2.teamIconUrl,
                         fallback: match.team2.displayShort)
            teamText(match.team2, .team2, alignment: .leading)

            Text(match.cupDecisionNote ?? "")
                .font(.tahoma(9))
                .foregroundStyle(XP.bundesligaRed)
                .frame(width: CupCol.note, alignment: .leading)
        }
        .padding(.horizontal, 6)
        .frame(height: 21)
        .background(involvesFavorite ? XP.favoriteFill : (index % 2 == 0 ? Color.white : Color(hex: 0xF7F6F0)))
        .overlay(alignment: .bottom) {
            Color(hex: 0xE4E2D8).frame(height: 1)
        }
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
                ForEach(Array(round.matches.enumerated()), id: \.element.id) { i, match in
                    CupPairingRow(match: match, index: i)
                }
                if round.isComplete {
                    advancingFooter(round)
                }
            } else {
                Group {
                    if model.isLoading {
                        XPLoadingIndicator(text: model.status)
                    } else {
                        Text(emptyText)
                            .font(.tahoma(11))
                            .foregroundStyle(XP.darkShadow)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 120)
            }
        }
        .background(Color.white)
        .bevel(sunken: true)
    }

    private func advancingFooter(_ round: CupRound) -> some View {
        let names = round.advancingTeams.map(\.displayShort).joined(separator: " · ")
        return Text(names.isEmpty ? "" : "Weiter: \(names)")
            .font(.tahoma(10))
            .foregroundStyle(XP.darkShadow)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(Color(hex: 0xF4F2E8))
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
