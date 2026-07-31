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

    static func signal(_ name: String) {
        guard ensureInitialized() else { return }
        TelemetryDeck.signal(name)
    }
}
