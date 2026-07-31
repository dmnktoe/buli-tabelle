import SwiftUI
import Sparkle

@MainActor
final class UpdaterManager: ObservableObject {
    private let controller: SPUStandardUpdaterController?
    @Published var canCheckForUpdates = false

    var isActive: Bool { controller != nil }

    init() {
        let isBundle = Bundle.main.bundleURL.pathExtension == "app"
        let hasFeed = Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") != nil
        if isBundle && hasFeed {
            let c = SPUStandardUpdaterController(
                startingUpdater: true,
                updaterDelegate: nil,
                userDriverDelegate: nil
            )
            controller = c
            c.updater.publisher(for: \.canCheckForUpdates)
                .assign(to: &$canCheckForUpdates)
        } else {
            controller = nil
        }
    }

    func checkForUpdates() {
        controller?.checkForUpdates(nil)
    }
}
