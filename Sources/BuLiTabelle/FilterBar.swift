import SwiftUI

struct FilterBar: View {
    @EnvironmentObject var model: AppModel

    private enum W {
        static let liga: CGFloat = 150
        static let season: CGFloat = 118
        static let spieltag: CGFloat = 118
        /// Rundennamen wie „Viertelfinale“ brauchen etwas mehr Platz.
        static let runde: CGFloat = 130
    }

    var body: some View {
        HStack(spacing: 5) {
            RetroDropdown(
                items: Liga.allCases,
                display: { $0.display },
                selection: $model.liga
            )
            .frame(width: W.liga)

            RetroDropdown(
                items: model.seasons,
                display: { "Saison \(SeasonCalendar.shortString($0))" },
                selection: $model.season
            )
            .frame(width: W.season)

            XPButton("‹", fill: false) { model.prevSpieltag() }
                .disabled(!model.canGoPrevSpieltag)
                .opacity(model.canGoPrevSpieltag ? 1 : 0.4)

            RetroDropdown(
                items: Array(1...max(model.maxSpieltag, 1)),
                display: { model.periodLabel($0) },
                selection: Binding(
                    get: { model.spieltag },
                    set: { model.jumpToSpieltag($0) }
                )
            )
            .frame(width: model.liga.isCup ? W.runde : W.spieltag)

            XPButton("›", fill: false) { model.nextSpieltag() }
                .disabled(!model.canGoNextSpieltag)
                .opacity(model.canGoNextSpieltag ? 1 : 0.4)

            Spacer(minLength: 0)
        }
        .padding(5)
        .background(XP.face)
        .bevel()
    }
}
