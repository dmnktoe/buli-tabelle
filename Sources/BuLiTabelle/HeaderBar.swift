import SwiftUI
import AppKit

/// Kopfzeile des Fensters: Wettbewerb, Saison und alle Aktionen.
///
/// Die frühere Knopfspalte am linken Rand ist hier aufgegangen – häufiges liegt
/// als Symbol offen, Selteneres in zwei Menüs.
struct HeaderBar: View {
    @EnvironmentObject var model: AppModel
    @EnvironmentObject var updater: UpdaterManager

    private var subtitle: String {
        let period = model.liga.isCup
            ? CupBracket.shortName(model.roundName(model.spieltag))
            : "\(model.spieltag). Spieltag"
        return "Saison \(model.seasonShort) · \(period)"
    }

    private func checkForUpdates() {
        if updater.isActive {
            updater.checkForUpdates()
        } else {
            model.checkForUpdate()
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            LeagueBadge(liga: model.liga)

            VStack(alignment: .leading, spacing: 1) {
                Text(model.liga.display)
                    .font(.display(16, .semibold))
                    .foregroundStyle(Color.primary)
                Text(subtitle)
                    .font(.ui(11))
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)

            Spacer(minLength: 8)

            HStack(spacing: 6) {
                IconButton(systemName: "arrow.clockwise", help: "Neu laden") {
                    model.loadFromInternet()
                }
                IconButton(systemName: "chart.bar.xaxis", help: "Torjägerliste") {
                    model.openStats()
                }
                IconMenu(systemName: "square.and.arrow.up", help: "Teilen und exportieren") {
                    Button(model.liga.isCup ? "Runde kopieren" : "Tabelle kopieren") {
                        model.copyTable()
                    }
                    .disabled(!model.hasExportableContent)
                    Button("Als HTML sichern …") { model.exportHTML() }
                        .disabled(!model.hasExportableContent)
                    Button("Drucken …") { model.printTable() }
                        .disabled(!model.hasExportableContent)
                }
                IconMenu(systemName: "ellipsis", help: "Weitere Optionen") {
                    Button("Einstellungen …") { model.openSettings() }
                    Button("Nach Updates suchen …") { checkForUpdates() }
                    Divider()
                    Button("Daten von OpenLigaDB") { model.openDataSource() }
                    Button("Fehler melden …") { model.reportBug() }
                    Divider()
                    Button("Über \(AppInfo.name)") { model.openInfo() }
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
    }
}

/// Rundes Markenzeichen links im Kopf – Ball auf getöntem Glas.
struct LeagueBadge: View {
    let liga: Liga

    var body: some View {
        ZStack {
            Circle()
                .fill(Theme.accentGradient)
                .shadow(color: Theme.accent.opacity(0.35), radius: 6, y: 2)
            Circle()
                .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
            Image(nsImage: .soccerBall)
                .renderingMode(.template)
                .resizable()
                .interpolation(.high)
                .frame(width: 17, height: 17)
                .foregroundStyle(Color.white)
        }
        .frame(width: 30, height: 30)
        .accessibilityLabel(liga.display)
    }
}
