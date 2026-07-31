import SwiftUI

/// Schwebendes Glaspanel mit Titelzeile und Schließknopf.
///
/// Trägt die eigenen Fenster für Info, Einstellungen und Statistiken – die
/// Fenster selbst sind randlos, die Form entsteht hier.
struct GlassPanel<Content: View>: View {
    let title: String
    var systemImage: String = "sparkles"
    let onClose: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                Text(title)
                    .font(.ui(13, .semibold))
                    .foregroundStyle(Color.primary)
                Spacer(minLength: 12)
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(GlassButtonStyle(radius: 8, insets: EdgeInsets()))
                .keyboardShortcut(.cancelAction)
                .help("Schließen")
            }
            .padding(.horizontal, 14)
            .frame(height: 44)

            Rectangle().fill(Theme.hairline).frame(height: 1)

            content
                .padding(18)
        }
        .background {
            if Theme.capturing {
                Color.adaptive(light: 0xFAFAFC, dark: 0x232529)
            } else {
                VisualEffect(material: .popover, blending: .behindWindow)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.panel, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Radius.panel, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.45), .white.opacity(0.06)],
                        startPoint: .top, endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        }
    }
}

/// Hinweis- und Fehlerdialog.
struct AlertPanel: View {
    let info: AlertInfo
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 26))
                .foregroundStyle(Theme.accent)
            Text(info.title)
                .font(.display(15, .semibold))
                .foregroundStyle(Color.primary)
            Text(info.message)
                .font(.ui(12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            GlassButton("OK", prominent: true, action: onClose)
                .keyboardShortcut(.defaultAction)
                .padding(.top, 2)
        }
        .padding(24)
        .frame(width: 320)
    }
}

struct InfoSheet: View {
    @EnvironmentObject var model: AppModel
    let onClose: () -> Void

    var body: some View {
        GlassPanel(title: "Über \(AppInfo.name)", systemImage: "info.circle", onClose: onClose) {
            VStack(spacing: 12) {
                LeagueBadge(liga: model.liga)
                    .scaleEffect(1.6)
                    .frame(height: 54)

                VStack(spacing: 2) {
                    Text(AppInfo.name)
                        .font(.display(17, .semibold))
                        .foregroundStyle(Color.primary)
                    Text("Version \(AppInfo.displayVersion)")
                        .font(.ui(11))
                        .foregroundStyle(.secondary)
                }

                Text("""
                Bundesliga-Tabellen und DFB-Pokal für macOS.
                Live-Daten, jeder Spieltag und jede Pokalrunde seit 2004/05.
                """)
                .font(.ui(12))
                .foregroundStyle(Color.primary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

                Text("Daten: OpenLigaDB · © 2026 dmnktoe · Swift & SwiftUI")
                    .font(.ui(10))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                GlassButton("Fertig", prominent: true, action: onClose)
                    .keyboardShortcut(.defaultAction)
            }
            .frame(width: 300)
        }
    }
}

struct StatsSheet: View {
    @EnvironmentObject var model: AppModel
    let onClose: () -> Void

    private func rankColor(_ index: Int) -> Color {
        switch index {
        case 0: return Theme.favorite
        case 1, 2: return Theme.accent
        default: return .secondary
        }
    }

    var body: some View {
        GlassPanel(title: "Torjägerliste", systemImage: "chart.bar.xaxis", onClose: onClose) {
            VStack(spacing: 12) {
                Text("\(model.liga.display) · Saison \(model.seasonShort)")
                    .font(.ui(11))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 0) {
                    if model.loadingStats {
                        LoadingIndicator(text: "Lade Torjägerliste …")
                            .frame(maxWidth: .infinity)
                            .frame(height: 120)
                    } else if model.goalgetters.isEmpty {
                        EmptyStateView(systemImage: "soccerball", text: "Keine Daten verfügbar.")
                            .frame(maxWidth: .infinity)
                            .frame(height: 120)
                    } else {
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(Array(model.goalgetters.prefix(20).enumerated()), id: \.element.id) { index, getter in
                                    HStack(spacing: 10) {
                                        Text("\(index + 1)")
                                            .font(.stat(11, .semibold))
                                            .foregroundStyle(rankColor(index))
                                            .frame(width: 20, alignment: .trailing)
                                        Text(getter.goalGetterName ?? "?")
                                            .font(.ui(12))
                                            .foregroundStyle(Color.primary)
                                            .lineLimit(1)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        Text("\(getter.goalCount ?? 0)")
                                            .font(.stat(12, .semibold))
                                            .foregroundStyle(Color.primary)
                                            .frame(width: 28, alignment: .trailing)
                                    }
                                    .padding(.horizontal, 12)
                                    .frame(height: 28)
                                    .overlay(alignment: .bottom) {
                                        if index < min(model.goalgetters.count, 20) - 1 {
                                            Rectangle().fill(Theme.hairline)
                                                .frame(height: 1)
                                                .padding(.horizontal, 12)
                                        }
                                    }
                                }
                            }
                        }
                        .frame(height: 260)
                    }
                }
                .padding(.vertical, 4)
                .glass(.card, radius: Theme.Radius.card)

                GlassButton("Fertig", prominent: true, action: onClose)
                    .keyboardShortcut(.defaultAction)
            }
            .frame(width: 320)
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

    private func section(_ title: String) -> some View {
        Text(title)
            .font(.ui(10, .semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    var body: some View {
        GlassPanel(title: "Einstellungen", systemImage: "gearshape", onClose: onClose) {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    section("Darstellung")
                    Toggle("Auf- und Abstiegszonen einfärben", isOn: $zoneColors)
                    Toggle("Vereinswappen anzeigen", isOn: $showLogos)
                    Toggle("Formkurve der letzten fünf Spiele", isOn: $showForm)
                }

                VStack(alignment: .leading, spacing: 8) {
                    section("Menüleiste")
                    Toggle("Symbol in der Menüleiste anzeigen", isOn: $showMenuBarItem)
                    Toggle("Beim Schließen in der Menüleiste weiterlaufen", isOn: $keepInMenuBar)
                        .disabled(!showMenuBarItem)
                        .opacity(showMenuBarItem ? 1 : 0.45)
                }

                VStack(alignment: .leading, spacing: 8) {
                    section("Datenschutz")
                    Toggle("Anonyme Nutzungsstatistik senden", isOn: $sendAnalytics)
                    Text("Zählt nur anonym die Zahl der Nutzer – keine personenbezogenen Daten, kein Tracking. Änderung wirkt beim nächsten Start.")
                        .font(.ui(10))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                GlassButton("Fertig", prominent: true, action: onClose)
                    .keyboardShortcut(.defaultAction)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .toggleStyle(.switch)
            .controlSize(.small)
            .font(.ui(12))
            .frame(width: 300)
            .onChange(of: zoneColors) { track("zoneColors", $0) }
            .onChange(of: showLogos) { track("showLogos", $0) }
            .onChange(of: showForm) { track("showForm", $0) }
            .onChange(of: showMenuBarItem) { track("showMenuBarItem", $0) }
            .onChange(of: keepInMenuBar) { track("keepInMenuBar", $0) }
            .onChange(of: sendAnalytics) { track("sendAnalytics", $0) }
        }
    }
}
