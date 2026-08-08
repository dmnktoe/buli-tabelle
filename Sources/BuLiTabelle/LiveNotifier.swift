import Foundation
import UserNotifications

/// Mitteilungen zu Toren des Lieblingsvereins.
///
/// Bewusst zurückhaltend: standardmäßig aus, nur für den Lieblingsverein und nur
/// aus der installierten App heraus — ohne Bundle (etwa bei `swift run`) gibt es
/// kein Mitteilungssystem, das uns kennt.
enum LiveNotifier {
    static let defaultsKey = "notifyFavoriteGoals"

    private static var isBundled: Bool {
        Bundle.main.bundleURL.pathExtension == "app"
            && Bundle.main.bundleIdentifier != nil
            && ProcessInfo.processInfo.environment["BULI_SCREENSHOT"] == nil
    }

    static var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: defaultsKey) && isBundled
    }

    /// Fragt die Erlaubnis ab – erst, wenn der Schalter umgelegt wird.
    static func requestAuthorization() {
        guard isBundled else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    /// Meldet ein Tor, sofern der Lieblingsverein beteiligt ist.
    static func goal(match: OLMatch, score: LiveScore, previous: LiveScore, favorite: Int) {
        guard isEnabled, favorite != 0 else { return }
        let isHome = match.team1.teamId == favorite
        let isAway = match.team2.teamId == favorite
        guard isHome || isAway else { return }

        let scoredHome = score.team1 > previous.team1
        let scoredAway = score.team2 > previous.team2
        guard scoredHome || scoredAway else { return }
        let forFavorite = (isHome && scoredHome) || (isAway && scoredAway)

        let content = UNMutableNotificationContent()
        content.title = forFavorite ? "TOR!" : "Gegentor"
        content.subtitle = "\(match.team1.displayShort) \(score.text) \(match.team2.displayShort)"
        content.body = detail(of: match)
        content.sound = forFavorite ? .default : nil

        UNUserNotificationCenter.current().add(
            UNNotificationRequest(
                identifier: "goal-\(match.matchID)-\(score.team1)-\(score.team2)",
                content: content,
                trigger: nil
            )
        )
    }

    /// „Torschütze: Max Mustermann (63.)“ – so weit die Daten das hergeben.
    private static func detail(of match: OLMatch) -> String {
        guard let goal = match.latestGoal else { return "" }
        let name = goal.goalGetterName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let minute = goal.matchMinute.map { "\($0)." }
        var extras: [String] = []
        if goal.isPenalty == true { extras.append("Elfmeter") }
        if goal.isOwnGoal == true { extras.append("Eigentor") }
        let suffix = [minute, extras.isEmpty ? nil : extras.joined(separator: ", ")]
            .compactMap { $0 }
            .joined(separator: " · ")
        if name.isEmpty { return suffix }
        return suffix.isEmpty ? name : "\(name) (\(suffix))"
    }
}
