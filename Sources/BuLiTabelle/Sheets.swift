import SwiftUI

struct RetroPanel<Content: View>: View {
    let title: String
    let onClose: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 5) {
                MiniBallIcon()
                Text(title)
                    .font(.tahoma(11, bold: true))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.55), radius: 0, x: 1, y: 1)
                Spacer()
                TitleButton(kind: .close, action: onClose)
            }
            .padding(.horizontal, 6)
            .frame(height: 26)
            .titleBarBackground()
            content
                .padding(12)
        }
        .background(XP.face)
        .bevel()
    }
}

struct RetroAlertView: View {
    let info: RetroAlertInfo
    let onClose: () -> Void

    var body: some View {
        RetroPanel(title: info.title, onClose: onClose) {
            VStack(spacing: 12) {
                Text(info.message)
                    .font(.tahoma(11))
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                XPButton("OK", action: onClose)
                    .frame(width: 80)
            }
            .frame(width: 260)
        }
    }
}

struct InfoSheet: View {
    @EnvironmentObject var model: AppModel
    let onClose: () -> Void

    var body: some View {
        RetroPanel(title: "Info", onClose: onClose) {
            VStack(spacing: 10) {
                LeaguePlate(liga: model.liga, season: "Saison \(model.seasonShort)")
                    .frame(width: 130)
                Text("\(AppInfo.name) \(AppInfo.displayVersion)")
                    .font(.tahoma(12, bold: true))
                    .foregroundStyle(.black)
                Text("""
                Bundesliga-Tabellen und DFB-Pokal für macOS.
                Live-Daten, jeder Spieltag und jede Pokalrunde seit 2004/05.

                Daten: OpenLigaDB (www.openligadb.de)
                © 2026 dmnktoe · Swift & SwiftUI
                """)
                .font(.tahoma(11))
                .foregroundStyle(.black)
                .multilineTextAlignment(.center)
                XPButton("OK") { onClose() }
                    .frame(width: 80)
            }
            .frame(width: 280)
        }
    }
}

struct StatsSheet: View {
    @EnvironmentObject var model: AppModel
    let onClose: () -> Void

    var body: some View {
        RetroPanel(title: "Statistiken – Torjäger", onClose: onClose) {
            VStack(spacing: 8) {
                VStack(spacing: 0) {
                    HStack {
                        Text("SPIELER").frame(maxWidth: .infinity, alignment: .leading)
                        Text("TORE").frame(width: 40, alignment: .trailing)
                    }
                    .font(.tahoma(10, bold: true))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .frame(height: 18)
                    .background(Color.black)

                    if model.loadingStats {
                        Text("Lade Torjägerliste…")
                            .font(.tahoma(11))
                            .foregroundStyle(XP.darkShadow)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                    } else if model.goalgetters.isEmpty {
                        Text("Keine Daten verfügbar.")
                            .font(.tahoma(11))
                            .foregroundStyle(XP.darkShadow)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                    } else {
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(Array(model.goalgetters.prefix(20).enumerated()), id: \.element.id) { i, g in
                                    HStack {
                                        Text("\(i + 1). \(g.goalGetterName ?? "?")")
                                            .lineLimit(1)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        Text("\(g.goalCount ?? 0)")
                                            .frame(width: 40, alignment: .trailing)
                                    }
                                    .font(.tahoma(11))
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 6)
                                    .frame(height: 19)
                                    .background(i % 2 == 0 ? Color.white : Color(hex: 0xF4F2E8))
                                }
                            }
                        }
                        .frame(height: 240)
                    }
                }
                .background(Color.white)
                .bevel(sunken: true)

                XPButton("Schließen") { onClose() }
                    .frame(width: 90)
            }
            .frame(width: 300)
        }
    }
}

struct SettingsSheet: View {
    let onClose: () -> Void
    @AppStorage("zoneColors") private var zoneColors = true
    @AppStorage("showLogos") private var showLogos = true
    @AppStorage("showForm") private var showForm = true
    @AppStorage("showMenuBarItem") private var showMenuBarItem = true
    @AppStorage("keepInMenuBar") private var keepInMenuBar = true
    @AppStorage("sendAnalytics") private var sendAnalytics = true

    /// Beim Abschalten der Statistik greift der Guard in `Analytics` bereits –
    /// das Ausschalten selbst wird also bewusst nicht mehr gemeldet.
    private func track(_ key: String, _ value: Bool) {
        Analytics.signal(.settingChanged, ["key": key, "value": value ? "on" : "off"])
    }

    var body: some View {
        RetroPanel(title: "Einstellungen", onClose: onClose) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Darstellung")
                    .font(.tahoma(11, bold: true))
                    .foregroundStyle(.black)
                Toggle("Auf-/Abstiegszonen einfärben", isOn: $zoneColors)
                    .toggleStyle(XPCheckboxStyle())
                Toggle("Vereinswappen anzeigen", isOn: $showLogos)
                    .toggleStyle(XPCheckboxStyle())
                Toggle("Formkurve (letzte 5) anzeigen", isOn: $showForm)
                    .toggleStyle(XPCheckboxStyle())

                Text("Menüleiste")
                    .font(.tahoma(11, bold: true))
                    .foregroundStyle(.black)
                    .padding(.top, 4)
                Toggle("Symbol in der Menüleiste anzeigen", isOn: $showMenuBarItem)
                    .toggleStyle(XPCheckboxStyle())
                Toggle("Beim Schließen in der Menüleiste weiterlaufen", isOn: $keepInMenuBar)
                    .toggleStyle(XPCheckboxStyle())
                    .disabled(!showMenuBarItem)
                    .opacity(showMenuBarItem ? 1 : 0.45)

                Text("Datenschutz")
                    .font(.tahoma(11, bold: true))
                    .foregroundStyle(.black)
                    .padding(.top, 4)
                Toggle("Anonyme Nutzungsstatistik senden", isOn: $sendAnalytics)
                    .toggleStyle(XPCheckboxStyle())
                Text("Zählt nur anonym die Zahl der Nutzer – keine personenbezogenen Daten, kein Tracking. Änderung wirkt beim nächsten Start.")
                    .font(.tahoma(10))
                    .foregroundStyle(XP.darkShadow)
                    .fixedSize(horizontal: false, vertical: true)

                XPButton("OK") { onClose() }
                    .frame(width: 80)
                    .frame(maxWidth: .infinity)
            }
            .frame(width: 250)
            .onChange(of: zoneColors) { track("zoneColors", $0) }
            .onChange(of: showLogos) { track("showLogos", $0) }
            .onChange(of: showForm) { track("showForm", $0) }
            .onChange(of: showMenuBarItem) { track("showMenuBarItem", $0) }
            .onChange(of: keepInMenuBar) { track("keepInMenuBar", $0) }
            .onChange(of: sendAnalytics) { track("sendAnalytics", $0) }
        }
    }
}
