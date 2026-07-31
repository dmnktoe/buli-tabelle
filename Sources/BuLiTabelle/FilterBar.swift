import SwiftUI

struct FilterBar: View {
    @EnvironmentObject var model: AppModel

    private enum W {
        static let liga: CGFloat = 150
        static let season: CGFloat = 118
        static let spieltag: CGFloat = 118
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
                display: { "\($0). Spieltag" },
                selection: $model.spieltag
            )
            .frame(width: W.spieltag)

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
