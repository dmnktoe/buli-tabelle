import SwiftUI

struct TableModeBar: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        GlassSegmented(
            items: TableMode.allCases,
            display: { $0.display },
            selection: $model.tableMode
        )
    }
}

struct ContentView: View {
    @EnvironmentObject var model: AppModel
    @AppStorage("zoneColors") private var zoneColors = true

    var body: some View {
        VStack(spacing: 0) {
            // Streifen für die Fenster-Ampel. Der Inhalt reicht bis unter die
            // Titelleiste, damit das Glas durchgehend ist – die Höhe wird hier
            // bewusst selbst reserviert statt über die Safe Area.
            Color.clear.frame(height: 28)

            HeaderBar()

            VStack(spacing: 10) {
                FilterBar()

                if model.liga.isCup {
                    // K.-o.-Runde statt Tabelle: Heim-/Auswärtstabelle gibt es
                    // hier nicht, und die Paarungen stehen bereits im Panel –
                    // der Spieltag-Bereich darunter wäre nur eine Dopplung.
                    CupPanel()
                } else {
                    HStack(spacing: 0) {
                        TableModeBar().frame(width: 260)
                        Spacer(minLength: 0)
                    }
                    TablePanel()
                    if zoneColors && !model.rows.isEmpty {
                        ZoneLegend(liga: model.liga, teamCount: model.rows.count)
                    }
                    MatchdaySection()
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 12)

            StatusBar()
        }
        .frame(width: 720)
        .background(WindowBackdrop().ignoresSafeArea())
        .animation(Theme.spring, value: model.liga)
        .animation(Theme.spring, value: model.showSpieltagMenu)
        .sheet(item: $model.alert) { info in
            AlertPanel(info: info) { model.alert = nil }
        }
    }
}
