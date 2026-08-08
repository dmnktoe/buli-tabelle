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
    @Published var alert: RetroAlertInfo?
    @Published private(set) var cupRounds: [CupRound] = []
    @Published private(set) var goalgetters: [OLGoalGetter] = []
    @Published private(set) var loadingStats = false
    @Published private(set) var isLoading = false

    // MARK: - Live-Zustand

    /// Was gerade läuft. Einmal pro Ticker-Schlag bestimmt, damit die Ansichten
    /// nicht bei jedem Neuzeichnen sämtliche Anstoßzeiten auswerten müssen.
    @Published private(set) var live: LiveOverview = .idle
    /// Uhrzeit, auf die sich Spielminuten und Hervorhebungen beziehen.
    @Published private(set) var liveNow = Date()
    /// Wann zuletzt beim Server nachgefragt wurde.
    @Published private(set) var lastLiveUpdate: Date?
    /// Spiele, in denen gerade ein Tor gefallen ist (Spiel-ID → Zeitpunkt).
    @Published private(set) var flashingMatches: [Int: Date] = [:]

    @Published var liveEnabled: Bool = AppModel.flag("liveUpdates", default: true) {
        didSet {
            guard oldValue != liveEnabled else { return }
            UserDefaults.standard.set(liveEnabled, forKey: "liveUpdates")
            Analytics.signal(.liveToggled, ["state": liveEnabled ? "on" : "off"])
            if liveEnabled {
                refreshLive()
                startLiveTicker()
            } else {
                stopLiveTicker()
                live = .idle
                flashingMatches = [:]
            }
            recompute()
        }
    }

    @Published var liveInTable: Bool = AppModel.flag("liveInTable", default: true) {
        didSet {
            guard oldValue != liveInTable else { return }
            UserDefaults.standard.set(liveInTable, forKey: "liveInTable")
            Analytics.signal(.liveTableToggled, ["state": liveInTable ? "on" : "off"])
            recompute()
        }
    }

    private var matches: [OLMatch] = []
    /// Zählt Ladevorgänge, damit nur der jüngste den Ladezustand beendet.
    private var loadGeneration = 0

    private var liveTask: Task<Void, Never>?
    private var liveGeneration = 0
    private var lastPollAttempt: Date?
    private var lastChangeStamp: String?
    /// Die Spielstände, mit denen die aktuelle Tabelle gerechnet wurde.
    private var appliedLiveScores: [Int: LiveScore] = [:]
    private var didAutoExpandMatchday = false
    private var didReportLive = false

    /// So lange bleibt eine Torzeile hervorgehoben.
    static let flashSeconds: TimeInterval = 60
    /// Taktung des Live-Tickers – engmaschig, solange etwas läuft.
    private static let watchTick: UInt64 = 10
    private static let idleTick: UInt64 = 60

    let currentSeason: Int
    let seasons: [Int]

    init() {
        currentSeason = SeasonCalendar.ongoingSeason()
        season = SeasonCalendar.defaultSeason()
        seasons = SeasonCalendar.selectable()
    }

    /// Einstellung mit eigenem Standardwert – unabhängig davon, ob die
    /// registrierten Voreinstellungen schon greifen.
    private static func flag(_ key: String, default fallback: Bool) -> Bool {
        UserDefaults.standard.object(forKey: key) as? Bool ?? fallback
    }

    // MARK: - Abgeleitete Anzeige-Werte

    var seasonString: String { SeasonCalendar.longString(season) }
    var seasonShort: String { SeasonCalendar.shortString(season) }

    /// Rechnet die gezeigte Tabelle gerade laufende Spiele mit?
    var showsLiveTable: Bool { rows.contains(where: \.isLive) }

    var tableTitle: String {
        if liga.isCup {
            return "\(liga.display) \(seasonString) – \(roundName(spieltag))"
        }
        var title = "\(liga.display) \(seasonString) – \(spieltag). Spieltag"
        switch tableMode {
        case .gesamt: break
        case .heim: title += " (Heimtabelle)"
        case .auswaerts: title += " (Auswärtstabelle)"
        }
        // Ehrlich bleiben: Was hier exportiert, kopiert oder gedruckt wird, ist
        // ein Zwischenstand, keine amtliche Tabelle.
        if showsLiveTable { title += " – Zwischenstand" }
        return title
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
            // Ein überholter Ladevorgang darf die frischeren Daten nicht ersetzen.
            guard generation == loadGeneration else { return }
            matches = ms
            maxSpieltag = ms.map(\.group.groupOrderID).max() ?? (liga.isCup ? 6 : 34)
            // Frisch geladen ist frisch genug: Der Ticker fängt erst danach an
            // zu zählen, statt gleich noch einmal nachzufragen.
            lastChangeStamp = nil
            lastLiveUpdate = Date()
            lastPollAttempt = Date()
            refreshLive()
            // `recompute()` baut die Runden – hier reicht der Sprung ans Ziel.
            let target = min(defaultPeriod(for: ms), maxSpieltag)
            if spieltag == target {
                recompute()
            } else {
                spieltag = target
            }
            startLiveTicker()
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
            live = .idle
            status = "Fehler beim Laden"
            Analytics.signal(.tableLoadFailed, [
                "liga": liga.rawValue,
                "season": String(season),
                "reason": Self.failureReason(error),
            ])
            alert = RetroAlertInfo(
                title: "Fehler",
                message: "Daten konnten nicht geladen werden.\n\n\(error.localizedDescription)"
            )
        }
    }

    /// Auf welchen Spieltag bzw. welche Runde nach dem Laden gesprungen wird.
    ///
    /// In der Liga ist das der Spieltag, auf dem gerade gespielt wird — sonst der
    /// letzte angepfiffene. Im Pokal liegen zwischen den Runden Wochen; dort ist
    /// die erste noch nicht abgeschlossene Runde interessanter als die letzte
    /// gespielte.
    private func defaultPeriod(for ms: [OLMatch], now: Date = Date()) -> Int {
        if liga.isCup {
            let rounds = CupBracket.rounds(from: ms)
            if let running = rounds.first(where: { $0.isDrawn && !$0.isComplete }) {
                return running.order
            }
            return rounds.last(where: \.isDrawn)?.order ?? 1
        }
        let window = liga.liveWindow
        if let live = ms.filter({ $0.isLive(at: now, window: window) })
            .map(\.group.groupOrderID).max() {
            return live
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
        let running = liveScores
        if liga.isCup {
            // K.-o.-System: keine Tabelle, stattdessen die Runden des Wettbewerbs.
            rows = []
            cupRounds = CupBracket.rounds(from: matches)
        } else {
            cupRounds = []
            let table = Standings.compute(from: matches, upTo: spieltag, mode: tableMode, live: running)
            if running.isEmpty {
                rows = table
            } else {
                // Nur fürs Pfeilchen: dieselbe Tabelle noch einmal ohne die
                // laufenden Spiele, damit die Bewegung ablesbar wird.
                let official = Standings.compute(from: matches, upTo: spieltag, mode: tableMode)
                rows = Standings.withMovement(table, against: official)
            }
        }
        appliedLiveScores = running
        matchesOfSpieltag = matches
            .filter { $0.group.groupOrderID == spieltag }
            .sorted { ($0.matchDateTime ?? "") < ($1.matchDateTime ?? "") }
        autoExpandMatchdayIfNeeded()
    }

    // MARK: - Live

    /// Laufende Spielstände, wie sie in die Tabelle einfließen. Leer, sobald
    /// eine der beiden Live-Einstellungen aus ist oder der Pokal läuft (dort
    /// gibt es keine Tabelle).
    private var liveScores: [Int: LiveScore] {
        guard liveEnabled, liveInTable, !liga.isCup else { return [:] }
        var map: [Int: LiveScore] = [:]
        for match in live.running {
            map[match.matchID] = match.runningScore ?? LiveScore(team1: 0, team2: 0)
        }
        return map
    }

    /// Bestimmt neu, was läuft, und stellt die Uhr weiter.
    private func refreshLive(now: Date = Date()) {
        guard liveEnabled else {
            live = .idle
            liveNow = now
            return
        }
        let updated = LiveOverview.make(from: matches, liga: liga, now: now)
        // Solange nichts ansteht, bleibt auch die Uhr stehen: Ein Ticken ohne
        // Spiele würde nur das halbe Fenster neu zeichnen lassen.
        if updated.isWatching || live.isWatching {
            live = updated
            liveNow = now
        }
        if !flashingMatches.isEmpty {
            flashingMatches = flashingMatches.filter {
                now.timeIntervalSince($0.value) < Self.flashSeconds
            }
        }
        if live.isActive, !didReportLive {
            didReportLive = true
            Analytics.signal(.liveDetected, ["liga": liga.rawValue])
        }
    }

    /// Läuft etwas auf dem gezeigten Spieltag, klappt der Spieltag-Bereich einmal
    /// von selbst auf – wer ihn zuklappt, hat wieder das letzte Wort.
    private func autoExpandMatchdayIfNeeded() {
        guard !didAutoExpandMatchday, !liga.isCup, !showSpieltagMenu,
              live.isActive, live.periods.contains(spieltag)
        else { return }
        didAutoExpandMatchday = true
        showSpieltagMenu = true
    }

    func startLiveTicker() {
        guard liveEnabled, liveTask == nil else { return }
        liveGeneration += 1
        let generation = liveGeneration
        liveTask = Task { [weak self] in
            await self?.runLiveTicker(generation: generation)
        }
    }

    func stopLiveTicker() {
        liveGeneration += 1
        liveTask?.cancel()
        liveTask = nil
    }

    /// Ein Schlag alle 10 Sekunden, solange etwas läuft oder gleich anfängt –
    /// sonst einmal pro Minute, nur um nachzusehen, ob es losgeht.
    private func runLiveTicker(generation: Int) async {
        while !Task.isCancelled {
            let seconds = live.isWatching ? Self.watchTick : Self.idleTick
            try? await Task.sleep(nanoseconds: seconds * 1_000_000_000)
            guard !Task.isCancelled, generation == liveGeneration, liveEnabled else { break }
            let wasWatching = live.isWatching
            refreshLive()
            autoExpandMatchdayIfNeeded()
            if liveScores != appliedLiveScores { recompute() }
            // Gerade erst angepfiffen? Dann sofort nachfragen statt abzuwarten.
            if !wasWatching, live.isWatching { lastPollAttempt = nil }
            if live.isWatching, shouldPoll { await pollLive() }
        }
        if generation == liveGeneration { liveTask = nil }
    }

    private var pollInterval: TimeInterval { live.isActive ? 30 : 60 }

    private var shouldPoll: Bool {
        guard let last = lastPollAttempt else { return true }
        return Date().timeIntervalSince(last) >= pollInterval - 1
    }

    /// Fragt die Spieltage nach, auf denen etwas läuft.
    private func pollLive() async {
        let liga = self.liga
        let season = self.season
        let periods = live.periods
        guard !periods.isEmpty else { return }
        lastPollAttempt = Date()

        // Erst der Änderungsstempel: Hat sich nichts getan, sparen wir uns
        // (und OpenLigaDB) die Spieldaten.
        if let stamp = try? await api.lastChangeDate(liga: liga, season: season) {
            guard self.liga == liga, self.season == season else { return }
            if let known = lastChangeStamp, known == stamp {
                lastLiveUpdate = Date()
                return
            }
            lastChangeStamp = stamp
        }

        var fresh: [OLMatch] = []
        for period in periods {
            guard let loaded = try? await api.matches(liga: liga, season: season, period: period)
            else { continue }
            guard self.liga == liga, self.season == season else { return }
            fresh.append(contentsOf: loaded)
        }
        guard !fresh.isEmpty else { return }
        apply(fresh)
    }

    /// Zieht frisch geladene Partien in den Datenbestand nach.
    private func apply(_ fresh: [OLMatch]) {
        let now = Date()
        let before = scoreSnapshot(matches, at: now)

        var index: [Int: Int] = [:]
        for (position, match) in matches.enumerated() { index[match.matchID] = position }
        for match in fresh {
            if let position = index[match.matchID] {
                matches[position] = match
            } else {
                matches.append(match)
            }
        }
        maxSpieltag = max(maxSpieltag, matches.map(\.group.groupOrderID).max() ?? maxSpieltag)

        let after = scoreSnapshot(matches, at: now)
        lastLiveUpdate = now
        refreshLive(now: now)
        recompute()
        announceGoals(before: before, after: after)
    }

    /// Spielstände aller Partien im Anstoßfenster – laufende wie eben
    /// abgepfiffene. Zwei Aufnahmen davor und danach zeigen, wo es geklingelt hat.
    private func scoreSnapshot(_ list: [OLMatch], at now: Date) -> [Int: LiveScore] {
        let window = liga.liveWindow
        var map: [Int: LiveScore] = [:]
        for match in list {
            guard let kickoff = match.kickoffDate,
                  now >= kickoff,
                  now < kickoff.addingTimeInterval(window)
            else { continue }
            if match.matchIsFinished {
                if let final = match.finalScore { map[match.matchID] = final }
            } else {
                map[match.matchID] = match.runningScore ?? LiveScore(team1: 0, team2: 0)
            }
        }
        return map
    }

    private func announceGoals(before: [Int: LiveScore], after: [Int: LiveScore]) {
        let favorite = UserDefaults.standard.integer(forKey: "favoriteTeam")
        for (id, score) in after {
            // Ohne Vorher-Stand ist unklar, ob gerade getroffen wurde – beim
            // ersten Blick auf ein Spiel bleibt es deshalb still.
            guard let previous = before[id], previous != score else { continue }
            flashingMatches[id] = Date()
            if let match = matches.first(where: { $0.matchID == id }) {
                LiveNotifier.goal(match: match, score: score, previous: previous, favorite: favorite)
            }
        }
    }

    // MARK: - Live-Werte für die Ansicht

    /// Laufender Spielstand einer Partie – `nil`, wenn sie nicht (mehr) läuft.
    func liveScore(for match: OLMatch) -> LiveScore? {
        guard liveEnabled else { return nil }
        return match.liveScore(at: liveNow, window: liga.liveWindow)
    }

    /// Geschätzte Spielminute, z. B. „63.“ oder „HZ“.
    func liveMinute(for match: OLMatch) -> String? {
        guard liveEnabled, match.isLive(at: liveNow, window: liga.liveWindow) else { return nil }
        return match.phase(at: liveNow)?.label
    }

    /// Ist in dieser Partie gerade ein Tor gefallen?
    func isFlashing(_ match: OLMatch) -> Bool {
        guard let scored = flashingMatches[match.matchID] else { return false }
        return liveNow.timeIntervalSince(scored) < Self.flashSeconds
    }

    /// Laufende Spiele des gezeigten Spieltags.
    var liveMatchesOfSpieltag: [OLMatch] {
        live.running.filter { $0.group.groupOrderID == spieltag }
    }

    /// Wird gerade woanders gespielt als dort, wo man hinsieht? Dann lohnt sich
    /// ein Sprung – sonst hilft der Zwischenstand in dieser Tabelle nichts.
    var livePeriodElsewhere: Int? {
        guard live.isActive, !live.periods.contains(spieltag) else { return nil }
        return live.periods.last
    }

    /// „Stand 15:47:12“ – wann zuletzt nachgefragt wurde.
    var liveUpdatedText: String {
        guard let stamp = lastLiveUpdate else { return "Stand wird geholt…" }
        return "Stand \(MatchDate.timeWithSeconds(stamp))"
    }

    /// Hinweistext zur geschätzten Spielminute.
    var liveMinuteHint: String {
        "Spielminute aus der Anstoßzeit hochgerechnet – die Nachspielzeit kennt OpenLigaDB nicht."
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
            SettingsSheet(onClose: closer.close).environmentObject(self)
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
        alert = RetroAlertInfo(
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
                alert = RetroAlertInfo(title: "Fehler", message: "Export fehlgeschlagen.\n\(error.localizedDescription)")
            }
        }
    }
}
