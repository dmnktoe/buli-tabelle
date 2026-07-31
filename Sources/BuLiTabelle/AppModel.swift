import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct RetroAlertInfo: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

@MainActor
final class AppModel: ObservableObject {
    let panels = PanelWindows()
    private let api = OpenLigaDBClient.shared

    @Published var liga: Liga = .bl1 {
        didSet { if oldValue != liga { Task { await reload() } } }
    }
    @Published var season: Int {
        didSet { if oldValue != season { Task { await reload() } } }
    }
    @Published var spieltag: Int = 1 {
        didSet { if oldValue != spieltag { recompute() } }
    }
    @Published var tableMode: TableMode = .gesamt {
        didSet { if oldValue != tableMode { recompute() } }
    }
    @Published private(set) var maxSpieltag = 34
    @Published private(set) var rows: [TableRow] = []
    @Published private(set) var matchesOfSpieltag: [OLMatch] = []
    @Published var selectedTeamID: Int?
    @Published var status = "Fertig"
    @Published var showSpieltagMenu = false
    @Published var alert: RetroAlertInfo?
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
        let base = "\(liga.display) \(seasonString) – \(spieltag). Spieltag"
        switch tableMode {
        case .gesamt: return base
        case .heim: return base + " (Heimtabelle)"
        case .auswaerts: return base + " (Auswärtstabelle)"
        }
    }

    var canGoPrevSpieltag: Bool { spieltag > 1 }
    var canGoNextSpieltag: Bool { spieltag < max(maxSpieltag, 1) }

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
            maxSpieltag = ms.map(\.group.groupOrderID).max() ?? 34
            let lastFinished = ms.filter(\.matchIsFinished).map(\.group.groupOrderID).max() ?? 1
            let target = min(lastFinished, maxSpieltag)
            if spieltag == target {
                recompute()
            } else {
                spieltag = target
            }
            status = ms.isEmpty ? "Keine Daten für diese Saison verfügbar" : "Fertig"
        } catch is CancellationError {
            return
        } catch let error as URLError where error.code == .cancelled {
            return
        } catch {
            matches = []
            rows = []
            matchesOfSpieltag = []
            status = "Fehler beim Laden"
            alert = RetroAlertInfo(
                title: "Fehler",
                message: "Daten konnten nicht geladen werden.\n\n\(error.localizedDescription)"
            )
        }
    }

    func recompute() {
        rows = Standings.compute(from: matches, upTo: spieltag, mode: tableMode)
        matchesOfSpieltag = matches
            .filter { $0.group.groupOrderID == spieltag }
            .sorted { ($0.matchDateTime ?? "") < ($1.matchDateTime ?? "") }
    }

    // MARK: - Navigation

    func prevSpieltag() {
        if canGoPrevSpieltag { spieltag -= 1 }
    }

    func nextSpieltag() {
        if canGoNextSpieltag { spieltag += 1 }
    }

    func showCurrentTable() {
        let target = SeasonCalendar.defaultSeason()
        if season != target {
            season = target
        } else {
            Task { await reload() }
        }
    }

    func loadFromInternet() {
        Task { await reload() }
    }

    // MARK: - Fenster & Links

    func openInfo() {
        panels.show("info") { closer in
            InfoSheet(onClose: closer.close).environmentObject(self)
        }
    }

    func openSettings() {
        panels.show("settings") { closer in
            SettingsSheet(onClose: closer.close)
        }
    }

    func openStats() {
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
        alert = RetroAlertInfo(
            title: "Update suchen",
            message: "\(AppInfo.name) \(AppInfo.displayVersion)\n\nAuto-Updates sind nur in der veröffentlichten App aktiv."
        )
    }

    func reportBug() {
        let url = URL(string: "mailto:dmnktoe@gmail.com?subject=BuLi%20Tabelle%20Fehlerbericht")!
        NSWorkspace.shared.open(url)
    }

    func openDataSource() {
        NSWorkspace.shared.open(URL(string: "https://www.openligadb.de")!)
    }

    // MARK: - Export & Druck

    func exportHTML() {
        let html = TableExporter.html(
            title: tableTitle,
            rows: rows,
            footerNote: "Erstellt mit \(AppInfo.name) · Daten: OpenLigaDB"
        )
        save(text: html, type: .html, defaultName: exportName(ext: "html"))
    }

    func copyTable() {
        guard !rows.isEmpty else { return }
        let text = TableExporter.plainText(title: tableTitle, rows: rows)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        status = "Tabelle kopiert"
    }

    func printTable() {
        let view = NSHostingView(rootView: PrintableTable(title: tableTitle, rows: rows))
        view.frame = NSRect(origin: .zero, size: view.fittingSize)
        let op = NSPrintOperation(view: view)
        op.printInfo.horizontalPagination = .fit
        op.run()
    }

    private func exportName(ext: String) -> String {
        "Tabelle_\(liga.rawValue)_\(season)_Spieltag\(spieltag).\(ext)"
    }

    private func save(text: String, type: UTType, defaultName: String) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [type]
        panel.nameFieldStringValue = defaultName
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try text.data(using: .utf8)?.write(to: url)
                status = "Exportiert: \(url.lastPathComponent)"
            } catch {
                alert = RetroAlertInfo(title: "Fehler", message: "Export fehlgeschlagen.\n\(error.localizedDescription)")
            }
        }
    }
}
