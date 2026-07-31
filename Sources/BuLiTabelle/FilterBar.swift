import SwiftUI

/// Auswahlleiste über der Tabelle: Wettbewerb, Saison und Spieltag.
struct FilterBar: View {
    @EnvironmentObject var model: AppModel

    private enum W {
        static let liga: CGFloat = 148
        static let season: CGFloat = 128
        static let spieltag: CGFloat = 132
        /// Rundennamen wie „Viertelfinale“ brauchen etwas mehr Platz.
        static let runde: CGFloat = 146
    }

    var body: some View {
        HStack(spacing: 8) {
            GlassPicker(
                items: Liga.allCases,
                display: { $0.display },
                selection: $model.liga,
                systemImage: "trophy"
            )
            .frame(width: W.liga)

            GlassPicker(
                items: model.seasons,
                display: { "Saison \(SeasonCalendar.shortString($0))" },
                selection: $model.season,
                systemImage: "calendar"
            )
            .frame(width: W.season)

            Spacer(minLength: 4)

            GlassButton("Aktuell", systemImage: "clock.arrow.circlepath") {
                model.showCurrentTable()
            }
            .help(model.liga.isCup ? "Zur laufenden Runde" : "Zur aktuellen Tabelle")

            HStack(spacing: 6) {
                IconButton(systemName: "chevron.left",
                           help: "Vorherige\(model.liga.isCup ? " Runde" : "r Spieltag")") {
                    model.prevSpieltag()
                }
                .disabled(!model.canGoPrevSpieltag)

                GlassPicker(
                    items: Array(1...max(model.maxSpieltag, 1)),
                    display: { model.periodLabel($0) },
                    selection: Binding(
                        get: { model.spieltag },
                        set: { model.jumpToSpieltag($0) }
                    )
                )
                .frame(width: model.liga.isCup ? W.runde : W.spieltag)

                IconButton(systemName: "chevron.right",
                           help: "Nächste\(model.liga.isCup ? " Runde" : "r Spieltag")") {
                    model.nextSpieltag()
                }
                .disabled(!model.canGoNextSpieltag)
            }
        }
    }
}
