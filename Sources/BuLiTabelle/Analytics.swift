import Foundation
import TelemetryDeck

enum Analytics {
    private static let appID = "1E0AC7BC-74CF-4962-B6D2-77C6EC6D4901"
    private static let placeholderAppID = "YOUR-TELEMETRYDECK-APP-ID"

    private static var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: "sendAnalytics")
            && appID != placeholderAppID
            && Bundle.main.bundleURL.pathExtension == "app"
            && ProcessInfo.processInfo.environment["BULI_SCREENSHOT"] == nil
    }

    private static var initialized = false

    @discardableResult
    private static func ensureInitialized() -> Bool {
        guard isEnabled else { return false }
        if !initialized {
            TelemetryDeck.initialize(config: .init(appID: appID))
            initialized = true
        }
        return true
    }

    static func start() {
        ensureInitialized()
    }

    /// Sendet ein Ereignis, sofern die Nutzungsstatistik aktiviert ist.
    ///
    /// Der Guard greift bei jedem Aufruf neu: Wer den Schalter in den Einstellungen
    /// umlegt, verschickt ab sofort keine Ereignisse mehr.
    static func signal(_ event: Event, _ parameters: [String: String] = [:]) {
        guard ensureInitialized() else { return }
        TelemetryDeck.signal(event.rawValue, parameters: parameters)
    }
}

extension Analytics {
    /// Ereignisnamen in TelemetryDeck-Konvention `Bereich.aktion`.
    ///
    /// Bewusst nur anonyme Interaktionen – keine Tabelleninhalte, keine Kennungen.
    enum Event: String {
        case appLaunched = "App.launched"

        case tableLoaded = "Table.loaded"
        case tableLoadFailed = "Table.loadFailed"
        case tableReloadRequested = "Table.reloadRequested"
        case tableCurrentRequested = "Table.currentRequested"
        case tableCopied = "Table.copied"
        case tableExported = "Table.exported"
        case tablePrinted = "Table.printed"

        case leagueChanged = "League.changed"
        case seasonChanged = "Season.changed"
        case tableModeChanged = "TableMode.changed"
        case matchdayChanged = "Matchday.changed"
        case matchdayPanelToggled = "MatchdayPanel.toggled"

        /// Einmal je Sitzung, sobald zum ersten Mal ein Spiel läuft.
        case liveDetected = "Live.detected"
        case liveToggled = "Live.toggled"
        case liveTableToggled = "Live.tableToggled"

        case teamSelected = "Team.selected"
        case favoriteSet = "Team.favoriteSet"
        case favoriteCleared = "Team.favoriteCleared"

        case statsOpened = "Stats.opened"
        case infoOpened = "Info.opened"
        case settingsOpened = "Settings.opened"
        case settingChanged = "Setting.changed"

        case updateCheckRequested = "Update.checkRequested"
        case bugReported = "Bug.reported"
        case dataSourceOpened = "DataSource.opened"

        case menuBarOpened = "MenuBar.opened"
        case menuBarWindowOpened = "MenuBar.windowOpened"
    }
}
