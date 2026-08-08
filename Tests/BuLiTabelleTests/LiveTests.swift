import XCTest
@testable import BuLiTabelle

final class LiveTests: XCTestCase {

    private let kickoff = Date(timeIntervalSinceReferenceDate: 800_000_000)

    private func team(_ id: Int, _ name: String) -> OLTeam {
        OLTeam(teamId: id, teamName: name, shortName: nil, teamIconUrl: nil)
    }

    /// Baut ein Spiel mit einer Anstoßzeit in UTC – so liefert die API sie.
    private func match(
        id: Int = 1,
        day: Int = 1,
        _ t1: OLTeam,
        _ t2: OLTeam,
        finished: Bool = false,
        result: (Int, Int)? = nil,
        goals: [OLGoal] = [],
        kickoffOffset: TimeInterval = 0
    ) -> OLMatch {
        var results: [OLResult] = []
        if let result {
            results = [
                OLResult(
                    resultTypeID: 2, resultName: "Endergebnis",
                    pointsTeam1: result.0, pointsTeam2: result.1
                )
            ]
        }
        let stamp = ISO8601DateFormatter().string(from: kickoff.addingTimeInterval(kickoffOffset))
        return OLMatch(
            matchID: id,
            matchDateTime: nil,
            group: OLGroup(groupOrderID: day, groupName: "\(day). Spieltag"),
            team1: t1, team2: t2,
            matchResults: results,
            matchIsFinished: finished,
            matchDateTimeUTC: stamp,
            goals: goals
        )
    }

    private func goal(_ id: Int, _ minute: Int, _ a: Int, _ b: Int, scorer: String? = nil) -> OLGoal {
        OLGoal(
            goalID: id, scoreTeam1: a, scoreTeam2: b, matchMinute: minute,
            goalGetterName: scorer, isPenalty: false, isOwnGoal: false
        )
    }

    // MARK: - Anstoßzeit

    func testKickoffPrefersUTC() {
        let expected = ISO8601DateFormatter().date(from: "2026-08-08T11:30:00Z")
        XCTAssertNotNil(expected)
        XCTAssertEqual(
            MatchDate.kickoff(utc: "2026-08-08T11:30:00Z", local: "2026-08-08T13:30:00"),
            expected
        )
    }

    func testKickoffFallsBackToLocalString() {
        XCTAssertNotNil(MatchDate.kickoff(utc: nil, local: "2026-08-08T13:30:00"))
        XCTAssertNil(MatchDate.kickoff(utc: nil, local: nil))
        XCTAssertNil(MatchDate.kickoff(utc: "Unfug", local: nil))
    }

    // MARK: - Spieluhr

    func testPhaseFollowsTheClock() {
        func phase(_ minutes: Double) -> LivePhase? {
            LiveClock.phase(kickoff: kickoff, now: kickoff.addingTimeInterval(minutes * 60))
        }
        XCTAssertNil(phase(-1), "Vor dem Anpfiff läuft nichts")
        XCTAssertEqual(phase(0), LivePhase.firstHalf(1))
        XCTAssertEqual(phase(22.5), LivePhase.firstHalf(23))
        XCTAssertEqual(phase(44), LivePhase.firstHalf(45))
        XCTAssertEqual(phase(50), LivePhase.halftime)
        XCTAssertEqual(phase(60), LivePhase.secondHalf(46))
        XCTAssertEqual(phase(104), LivePhase.secondHalf(90))
        XCTAssertEqual(phase(120), LivePhase.beyondRegulation)
    }

    func testPhaseLabels() {
        XCTAssertEqual(LivePhase.firstHalf(23).label, "23.")
        XCTAssertEqual(LivePhase.halftime.label, "HZ")
        XCTAssertEqual(LivePhase.beyondRegulation.label, "90.+")
    }

    // MARK: - Laufende Spiele erkennen

    func testLiveOnlyWithinTheWindow() {
        let m = match(team(1, "A"), team(2, "B"))
        XCTAssertFalse(m.isLive(at: kickoff.addingTimeInterval(-60)), "Vor dem Anpfiff")
        XCTAssertTrue(m.isLive(at: kickoff))
        XCTAssertTrue(m.isLive(at: kickoff.addingTimeInterval(60 * 60)))
        XCTAssertFalse(
            m.isLive(at: kickoff.addingTimeInterval(200 * 60)),
            "Nach dem Zeitfenster gilt ein Spiel nicht mehr als laufend, auch wenn die API es nie abpfeift"
        )
    }

    func testFinishedMatchIsNeverLive() {
        let m = match(team(1, "A"), team(2, "B"), finished: true, result: (2, 1))
        XCTAssertFalse(m.isLive(at: kickoff.addingTimeInterval(30 * 60)))
        XCTAssertNil(m.liveScore(at: kickoff.addingTimeInterval(30 * 60)))
        XCTAssertEqual(m.finalScore, LiveScore(team1: 2, team2: 1))
    }

    func testImminentKickoff() {
        let m = match(team(1, "A"), team(2, "B"))
        XCTAssertTrue(m.isImminent(at: kickoff.addingTimeInterval(-10 * 60)))
        XCTAssertFalse(m.isImminent(at: kickoff.addingTimeInterval(-30 * 60)))
        XCTAssertFalse(m.isImminent(at: kickoff), "Angepfiffen ist nicht mehr „gleich“")
    }

    // MARK: - Laufender Spielstand

    func testRunningScoreComesFromTheLatestGoal() {
        let m = match(
            team(1, "A"), team(2, "B"),
            goals: [goal(2, 63, 1, 1), goal(1, 12, 1, 0), goal(3, 77, 2, 1)]
        )
        XCTAssertEqual(m.runningScore, LiveScore(team1: 2, team2: 1))
        XCTAssertEqual(m.latestGoal?.goalID, 3)
    }

    func testRunningScoreIsZeroZeroAfterKickoff() {
        let m = match(team(1, "A"), team(2, "B"))
        XCTAssertEqual(m.liveScore(at: kickoff.addingTimeInterval(300)), LiveScore(team1: 0, team2: 0))
    }

    func testRunningScoreFallsBackToReportedResult() {
        let m = OLMatch(
            matchID: 5,
            matchDateTime: "2025-08-01T15:30:00",
            group: OLGroup(groupOrderID: 1, groupName: nil),
            team1: team(1, "A"), team2: team(2, "B"),
            matchResults: [OLResult(resultTypeID: 1, resultName: "Halbzeit", pointsTeam1: 0, pointsTeam2: 2)],
            matchIsFinished: false
        )
        XCTAssertEqual(m.runningScore, LiveScore(team1: 0, team2: 2))
    }

    // MARK: - Übersicht

    func testOverviewSortsAndCounts() {
        let running = match(id: 1, team(1, "A"), team(2, "B"))
        let later = match(id: 2, team(3, "C"), team(4, "D"), kickoffOffset: 10 * 60)
        let done = match(id: 3, team(5, "E"), team(6, "F"), finished: true, result: (1, 1))
        let overview = LiveOverview.make(
            from: [later, running, done],
            liga: .bl2,
            now: kickoff.addingTimeInterval(60)
        )
        XCTAssertEqual(overview.running.map(\.matchID), [1])
        XCTAssertEqual(overview.imminent.map(\.matchID), [2])
        XCTAssertTrue(overview.isActive)
        XCTAssertTrue(overview.isWatching)
        XCTAssertEqual(overview.periods, [1])
    }

    func testOverviewIdleWithoutMatches() {
        let overview = LiveOverview.make(from: [], liga: .bl2, now: kickoff)
        XCTAssertFalse(overview.isActive)
        XCTAssertFalse(overview.isWatching)
        XCTAssertEqual(overview.headline, "Keine laufenden Spiele")
    }

    // MARK: - Live-Tabelle

    func testLiveResultCountsLikeAFinishedMatch() {
        let a = team(1, "Alpha"), b = team(2, "Beta")
        let running = match(id: 1, a, b, goals: [goal(1, 20, 1, 0)])
        let table = Standings.compute(
            from: [running],
            upTo: 1,
            live: [1: LiveScore(team1: 1, team2: 0)]
        )
        let byId = Dictionary(uniqueKeysWithValues: table.map { ($0.team.teamId, $0) })
        XCTAssertEqual(byId[1]?.pkt, 3)
        XCTAssertEqual(byId[1]?.sp, 1)
        XCTAssertEqual(byId[1]?.form, [.win])
        XCTAssertTrue(byId[1]?.isLive == true)
        XCTAssertTrue(byId[2]?.isLive == true)
    }

    func testWithoutLiveScoresTheTableStaysOfficial() {
        let a = team(1, "Alpha"), b = team(2, "Beta")
        let running = match(id: 1, a, b, goals: [goal(1, 20, 1, 0)])
        let table = Standings.compute(from: [running], upTo: 1)
        XCTAssertEqual(table.first?.sp, 0, "Ohne Live-Liste zählt ein laufendes Spiel nicht")
        XCTAssertFalse(table.contains { $0.isLive })
    }

    func testFinishedResultBeatsAStaleLiveScore() {
        let a = team(1, "Alpha"), b = team(2, "Beta")
        let done = match(id: 1, a, b, finished: true, result: (3, 0))
        let table = Standings.compute(
            from: [done],
            upTo: 1,
            live: [1: LiveScore(team1: 1, team2: 0)]
        )
        let byId = Dictionary(uniqueKeysWithValues: table.map { ($0.team.teamId, $0) })
        XCTAssertEqual(byId[1]?.tore, 3)
        XCTAssertFalse(byId[1]?.isLive == true)
    }

    func testMovementAgainstTheOfficialTable() {
        let a = team(1, "Alpha"), b = team(2, "Beta"), c = team(3, "Gamma")
        let played = [
            match(id: 1, day: 1, a, b, finished: true, result: (0, 1)),
            match(id: 2, day: 1, c, a, finished: true, result: (0, 0)),
        ]
        // Beta führt, Alpha hat einen Punkt. Jetzt liegt Alpha live 3:0 vorn.
        let running = match(id: 3, day: 2, a, c)
        let all = played + [running]
        let official = Standings.compute(from: all, upTo: 2)
        let live = Standings.compute(from: all, upTo: 2, live: [3: LiveScore(team1: 3, team2: 0)])
        let table = Standings.withMovement(live, against: official)

        // Offiziell: Beta 1., Gamma 2., Alpha 3. – live zieht Alpha ganz nach oben.
        XCTAssertEqual(official.map(\.id), [2, 3, 1])
        XCTAssertEqual(table.map(\.id), [1, 2, 3])

        let alpha = table.first { $0.id == 1 }
        XCTAssertEqual(alpha?.position, 1, "Mit dem laufenden Sieg steht Alpha oben")
        XCTAssertEqual(alpha?.movement, 2, "Zwei Plätze gutgemacht")
        XCTAssertEqual(table.first { $0.id == 2 }?.movement, -1)
        XCTAssertEqual(table.first { $0.id == 3 }?.movement, -1)
    }

    func testMovementIsZeroWhenNothingChanges() {
        let a = team(1, "Alpha"), b = team(2, "Beta")
        let played = [match(id: 1, day: 1, a, b, finished: true, result: (2, 0))]
        let table = Standings.compute(from: played, upTo: 1)
        XCTAssertTrue(Standings.withMovement(table, against: table).allSatisfy { $0.movement == 0 })
    }

    // MARK: - Dekodieren

    func testDecodesGoalsAndUTCKickoff() throws {
        let json = #"""
        {
          "matchID": 12, "matchDateTime": "2026-08-08T13:30:00",
          "matchDateTimeUTC": "2026-08-08T11:30:00Z",
          "group": { "groupOrderID": 1 },
          "team1": { "teamId": 1, "teamName": "A" }, "team2": { "teamId": 2, "teamName": "B" },
          "matchResults": [], "matchIsFinished": false,
          "goals": [
            { "goalID": 1, "scoreTeam1": 1, "scoreTeam2": 0, "matchMinute": 12,
              "goalGetterName": "Meier", "isPenalty": false, "isOwnGoal": false }
          ]
        }
        """#
        let m = try JSONDecoder.openLigaDB.decode(OLMatch.self, from: Data(json.utf8))
        XCTAssertEqual(m.goals?.count, 1)
        XCTAssertEqual(m.runningScore, LiveScore(team1: 1, team2: 0))
        XCTAssertEqual(m.latestGoal?.goalGetterName, "Meier")
        XCTAssertNotNil(m.kickoffDate)
    }

    func testDecodesWithoutGoals() throws {
        let json = #"""
        {
          "MatchID": 12, "Group": { "GroupOrderID": 1 },
          "Team1": { "TeamId": 1, "TeamName": "A" }, "Team2": { "TeamId": 2, "TeamName": "B" },
          "MatchResults": [], "MatchIsFinished": false
        }
        """#
        let m = try JSONDecoder.openLigaDB.decode(OLMatch.self, from: Data(json.utf8))
        XCTAssertNil(m.goals)
        XCTAssertNil(m.kickoffDate)
        XCTAssertNil(m.runningScore)
    }
}
