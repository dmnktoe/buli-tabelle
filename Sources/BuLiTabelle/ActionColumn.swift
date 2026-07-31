import SwiftUI

private struct GroupCaption: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.tahoma(9, bold: true))
            .foregroundStyle(XP.bundesligaRed)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
            .padding(.bottom, 1)
            .overlay(alignment: .bottom) {
                XP.shadow.frame(height: 1)
            }
    }
}

struct ActionColumn: View {
    @EnvironmentObject var model: AppModel
    @EnvironmentObject var updater: UpdaterManager

    private func checkForUpdates() {
        if updater.isActive {
            updater.checkForUpdates()
        } else {
            model.checkForUpdate()
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            LeaguePlate(liga: model.liga, season: "Saison \(model.seasonShort)")

            GroupCaption(text: "ANSEHEN")
            XPButton("Aktuelle Tabelle", emphasized: true) { model.showCurrentTable() }
            XPButton("Statistiken…") { model.openStats() }

            GroupCaption(text: "DATEN")
            XPButton("Neu laden") { model.loadFromInternet() }
            XPButton("Kopieren") { model.copyTable() }
            XPButton("HTML-Export…") { model.exportHTML() }
            XPButton("Drucken…") { model.printTable() }

            GroupCaption(text: "PROGRAMM")
            XPButton("Einstellungen…") { model.openSettings() }
            XPButton("Update suchen…") { checkForUpdates() }
            XPButton("Info") { model.openInfo() }
            XPButton("Fehler melden…") { model.reportBug() }

            Spacer(minLength: 0)
        }
        .frame(width: 124)
    }
}
