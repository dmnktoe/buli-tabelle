import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct AlertInfo: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

@MainActor
final class AppModel: ObservableObject {
    let panels = PanelWindows()
    private let api = OpenLigaDBClient.shared

    @Published var liga: Liga = .bl1 {
        didSet {
            guard oldValue != liga else { return }
            Analytics.signal(.leagueChanged, ["liga": liga.rawValue])
            Task { await reload() }
        }
    }
    @Published var season: Int {
        didSet {
            guard oldValue != season else { return }
            Analytics.signal(.seasonChanged, ["season": String(season)])
            Task { await reload() }
        }
    }
    @Published var spieltag: Int = 1 {
        didSet { if oldValue != spieltag { recompute() } }
    }
    @Published var tableMode: TableMode = .gesamt {
        didSet {
            guard oldValue != tableMode else { return }
            Analytics.signal(.tableModeChanged, ["mode": tableMode.rawValue])
            recompute()
        }
    }
    @Published private(set) var maxSpieltag = 34
    @Published private(set) var rows: [TableRow] = []
    @Published private(set) var matchesOfSpieltag: [OLMatch] = []
    @Published var selectedTeamID: Int?
    @Published var status = "Fertig"
    @Published var showSpieltagMenu = false
    @Published var alert: AlertInfo?
    @Published private(set) var cupRounds: [CupRound] = []
    @Published private(set) var goalgetters: [OLGoalGetter] = []
    @Published private(set) var loadingStats = false
    @Published private(set) var isLoading = false

    private var matches: [OLMatch] = []
    /// Zählt Ladevorgänge, damit nur der jüngste den Ladezustand beendet.
    private var loadGeneration = 0

    let currentSeason: Int
    let seasons: [Int]

    init() {
        currentSeason = SeasonCalendar.ongoingSeason()
        season = SeasonCalendar.defaultSeason()
        seasons = SeasonCalendar.selectable()
    }

    // MARK: - Abgeleitete Anzeige-Werte

    var seasonString: String { SeasonCalendar.longString(season) }
    var seasonShort: String { SeasonCalendar.shortString(season) }

    var tableTitle: String {
        if liga.isCup {
            return "\(liga.display) \(seasonString) – \(roundName(spieltag))"
        }
        let base = "\(liga.display) \(seasonString) – \(spieltag). Spieltag"
        switch tableMode {
        case .gesamt: return base
        case .heim: return base + " (Heimtabelle)"
        case .auswaerts: return base + " (Auswärtstabelle)"
        }
    }

    var canGoPrevSpieltag: Bool { spieltag > 1 }
    var canGoNextSpieltag: Bool { spieltag < max(maxSpieltag, 1) }

    // MARK: - Pokal

    /// Die gerade gewählte Pokalrunde – `nil` außerhalb des Pokalmodus.
    var currentCupRound: CupRound? {
        cupRounds.first { $0.order == spieltag }
    }

    /// Anzeigename einer Runde. Greift auf die geladenen Daten zurück und fällt
    /// auf „N. Runde“ zurück, solange nichts geladen ist.
    func roundName(_ order: Int) -> String {
        cupRounds.first { $0.order == order }?.name ?? "\(order). Runde"
    }

    /// Beschriftung fürs Auswahlfeld – im Pokal Rundennamen, sonst Spieltage.
    func periodLabel(_ order: Int) -> String {
        liga.isCup ? CupBracket.shortName(roundName(order)) : "\(order). Spieltag"
    }

    // MARK: - Laden & Berechnen

    func initialLoad() async {
        await reload()
    }

    func reload() async {
        loadGeneration += 1
        let generation = loadGeneration
        isLoading = true
        defer { if generation == loadGeneration { isLoading = false } }
        status = "Lade Daten aus dem Internet…"
        do {
            let ms = try await api.matches(liga: liga, season: season)
            matches = ms
            maxSpieltag = ms.map(\.group.groupOrderID).max() ?? (liga.isCup ? 6 : 34)
            // `recompute()` baut die Runden – hier reicht der Sprung ans Ziel.
            let target = min(defaultPeriod(for: ms), maxSpieltag)
            if spieltag == target {
                recompute()
            } else {
                spieltag = target
            }
            status = ms.isEmpty ? "Keine Daten für diese Saison verfügbar" : "Fertig"
            Analytics.signal(.tableLoaded, [
                "liga": liga.rawValue,
                "season": String(season),
                "mode": tableMode.rawValue,
                "empty": ms.isEmpty ? "yes" : "no",
            ])
        } catch is CancellationError {
            return
        } catch let error as URLError where error.code == .cancelled {
            return
        } catch {
            matches = []
            rows = []
            cupRounds = []
            matchesOfSpieltag = []
            status = "Fehler beim Laden"
            Analytics.signal(.tableLoadFailed, [
                "liga": liga.rawValue,
                "season": String(season),
                "reason": Self.failureReason(error),
            ])
            alert = AlertInfo(
                title: "Fehler",
                message: "Daten konnten nicht geladen werden.\n\n\(error.localizedDescription)"
            )
        }
    }

    /// Auf welchen Spieltag bzw. welche Runde nach dem Laden gesprungen wird.
    ///
    /// In der Liga ist das der letzte angepfiffene Spieltag. Im Pokal liegen
    /// zwischen den Runden Wochen — dort ist die erste noch nicht abgeschlossene
    /// Runde interessanter als die letzte gespielte.
    private func defaultPeriod(for ms: [OLMatch]) -> Int {
        if liga.isCup {
            let rounds = CupBracket.rounds(from: ms)
            if let running = rounds.first(where: { $0.isDrawn && !$0.isComplete }) {
                return running.order
            }
            return rounds.last(where: \.isDrawn)?.order ?? 1
        }
        return ms.filter(\.matchIsFinished).map(\.group.groupOrderID).max() ?? 1
    }

    /// Grobe Fehlerkategorie fürs Ereignis – bewusst ohne `localizedDescription`,
    /// damit weder URLs noch Systemsprache in der Statistik landen.
    private static func failureReason(_ error: Error) -> String {
        guard let urlError = error as? URLError else { return "decoding" }
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost: return "offline"
        case .timedOut: return "timeout"
        case .badServerResponse, .cannotParseResponse: return "badResponse"
        case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed: return "unreachable"
        default: return "other"
        }
    }

    func recompute() {
        if liga.isCup {
            // K.-o.-System: keine Tabelle, stattdessen die Runden des Wettbewerbs.
            rows = []
            cupRounds = CupBracket.rounds(from: matches)
        } else {
            cupRounds = []
            rows = Standings.compute(from: matches, upTo: spieltag, mode: tableMode)
        }
        matchesOfSpieltag = matches
            .filter { $0.group.groupOrderID == spieltag }
            .sorted { ($0.matchDateTime ?? "") < ($1.matchDateTime ?? "") }
    }

    // MARK: - Navigation

    func prevSpieltag() {
        guard canGoPrevSpieltag else { return }
        spieltag -= 1
        Analytics.signal(.matchdayChanged, ["source": "prev"])
    }

    func nextSpieltag() {
        guard canGoNextSpieltag else { return }
        spieltag += 1
        Analytics.signal(.matchdayChanged, ["source": "next"])
    }

    /// Springt zum Spieltag `value` – getrennt von `spieltag`, damit nur bewusste
    /// Sprünge gezählt werden und nicht das Nachziehen beim Laden.
    func jumpToSpieltag(_ value: Int) {
        guard value != spieltag else { return }
        spieltag = value
        Analytics.signal(.matchdayChanged, ["source": "dropdown"])
    }

    func showCurrentTable() {
        Analytics.signal(.tableCurrentRequested)
        let target = SeasonCalendar.defaultSeason()
        if season != target {
            season = target
        } else {
            Task { await reload() }
        }
    }

    func loadFromInternet() {
        Analytics.signal(.tableReloadRequested)
        Task { await reload() }
    }

    // MARK: - Fenster & Links

    func openInfo() {
        Analytics.signal(.infoOpened)
        panels.show("info") { closer in
            InfoSheet(onClose: closer.close).environmentObject(self)
        }
    }

    func openSettings() {
        Analytics.signal(.settingsOpened)
        panels.show("settings") { closer in
            SettingsSheet(onClose: closer.close)
        }
    }

    func openStats() {
        Analytics.signal(.statsOpened)
        panels.show("stats") { closer in
            StatsSheet(onClose: closer.close).environmentObject(self)
        }
        loadingStats = true
        Task {
            defer { loadingStats = false }
            let getters = (try? await api.goalGetters(liga: liga, season: season)) ?? []
            goalgetters = getters.sorted { ($0.goalCount ?? 0) > ($1.goalCount ?? 0) }
        }
    }

    func checkForUpdate() {
        Analytics.signal(.updateCheckRequested, ["mode": "unavailable"])
        alert = AlertInfo(
            title: "Update suchen",
            message: "\(AppInfo.name) \(AppInfo.displayVersion)\n\nAuto-Updates sind nur in der veröffentlichten App aktiv."
        )
    }

    func reportBug() {
        Analytics.signal(.bugReported)
        let url = URL(string: "mailto:dmnktoe@gmail.com?subject=BuLi%20Tabelle%20Fehlerbericht")!
        NSWorkspace.shared.open(url)
    }

    func openDataSource() {
        Analytics.signal(.dataSourceOpened)
        NSWorkspace.shared.open(URL(string: "https://www.openligadb.de")!)
    }

    // MARK: - Export & Druck

    /// Im Pokal gibt es nichts zu exportieren, solange die Runde nicht ausgelost ist.
    var hasExportableContent: Bool {
        liga.isCup ? (currentCupRound?.isDrawn ?? false) : !rows.isEmpty
    }

    private let exportFooter = "Erstellt mit \(AppInfo.name) · Daten: OpenLigaDB"

    func exportHTML() {
        let html: String
        if liga.isCup, let round = currentCupRound {
            html = TableExporter.html(title: tableTitle, round: round, footerNote: exportFooter)
        } else {
            html = TableExporter.html(title: tableTitle, rows: rows, footerNote: exportFooter)
        }
        save(text: html, type: .html, defaultName: exportName(ext: "html"))
    }

    func copyTable() {
        guard hasExportableContent else { return }
        let text: String
        if liga.isCup, let round = currentCupRound {
            text = TableExporter.plainText(title: tableTitle, round: round)
        } else {
            text = TableExporter.plainText(title: tableTitle, rows: rows)
        }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        status = liga.isCup ? "Runde kopiert" : "Tabelle kopiert"
        Analytics.signal(.tableCopied, ["kind": liga.isCup ? "cupRound" : "table"])
    }

    func printTable() {
        Analytics.signal(.tablePrinted, ["kind": liga.isCup ? "cupRound" : "table"])
        let root: NSHostingView<AnyView>
        if liga.isCup, let round = currentCupRound {
            root = NSHostingView(rootView: AnyView(PrintableCupRound(title: tableTitle, round: round)))
        } else {
            root = NSHostingView(rootView: AnyView(PrintableTable(title: tableTitle, rows: rows)))
        }
        root.frame = NSRect(origin: .zero, size: root.fittingSize)
        let op = NSPrintOperation(view: root)
        op.printInfo.horizontalPagination = .fit
        op.run()
    }

    private func exportName(ext: String) -> String {
        let period = liga.isCup ? "Runde\(spieltag)" : "Spieltag\(spieltag)"
        let kind = liga.isCup ? "Pokal" : "Tabelle"
        return "\(kind)_\(liga.rawValue)_\(season)_\(period).\(ext)"
    }

    private func save(text: String, type: UTType, defaultName: String) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [type]
        panel.nameFieldStringValue = defaultName
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try text.data(using: .utf8)?.write(to: url)
                status = "Exportiert: \(url.lastPathComponent)"
                Analytics.signal(.tableExported, ["format": type.preferredFilenameExtension ?? "unknown"])
            } catch {
                alert = AlertInfo(title: "Fehler", message: "Export fehlgeschlagen.\n\(error.localizedDescription)")
            }
        }
    }
}
