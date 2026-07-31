import SwiftUI
import AppKit

final class WindowBridge {
    static let shared = WindowBridge()
    weak var main: NSWindow?
}

/// Richtet das Hauptfenster ein: native Chrome, transparente Titelleiste,
/// Inhalt bis unter die Ampel.
///
/// Die App bringt keine eigenen Fensterknöpfe mehr mit – Schließen, Minimieren
/// und Zoomen übernimmt wieder macOS selbst.
struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        configure(view)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    private func configure(_ view: NSView, attempt: Int = 0) {
        DispatchQueue.main.asyncAfter(deadline: .now() + (attempt == 0 ? 0 : 0.05)) {
            guard let window = view.window else {
                if attempt < 20 { configure(view, attempt: attempt + 1) }
                return
            }
            WindowBridge.shared.main = window
            window.isRestorable = false
            window.isReleasedWhenClosed = false
            window.tabbingMode = .disallowed
            window.isMovableByWindowBackground = true
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.titlebarSeparatorStyle = .none
            window.styleMask.insert(.fullSizeContentView)
            window.hasShadow = true
            window.invalidateShadow()
            Self.observeClose(window)
            window.makeKeyAndOrderFront(nil)
        }
    }

    private static var closeObserverKey: UInt8 = 0

    /// Wer das Fenster über die Ampel schließt, während das Menüleisten-Symbol
    /// aktiv ist, soll die App dort weiterlaufen sehen – ohne Dock-Icon.
    private static func observeClose(_ window: NSWindow) {
        guard objc_getAssociatedObject(window, &closeObserverKey) == nil else { return }
        let token = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification, object: window, queue: .main
        ) { _ in
            let defaults = UserDefaults.standard
            if defaults.bool(forKey: "showMenuBarItem") && defaults.bool(forKey: "keepInMenuBar") {
                NSApp.setActivationPolicy(.accessory)
            }
        }
        objc_setAssociatedObject(window, &closeObserverKey, token, .OBJC_ASSOCIATION_RETAIN)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.register(defaults: [
            "zoneColors": true,
            "showLogos": true,
            "showForm": true,
            "showMenuBarItem": true,
            "keepInMenuBar": true,
            "sendAnalytics": true,
        ])
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        Analytics.start()
        Analytics.signal(.appLaunched, [
            "version": AppInfo.version,
            "menuBarItem": UserDefaults.standard.bool(forKey: "showMenuBarItem") ? "on" : "off",
        ])
        ScreenshotComposer.scheduleIfRequested()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        !(UserDefaults.standard.bool(forKey: "showMenuBarItem")
            && UserDefaults.standard.bool(forKey: "keepInMenuBar"))
    }
}

@main
struct BuLiTabelleApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var model = AppModel()
    @StateObject private var updater = UpdaterManager()
    @AppStorage("showMenuBarItem") private var showMenuBarItem = true

    var body: some Scene {
        Window(AppInfo.name, id: "main") {
            ContentView()
                .environmentObject(model)
                .environmentObject(updater)
                .background(WindowConfigurator())
                .task { await model.initialLoad() }
                .ignoresSafeArea()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Nach Updates suchen …") {
                    if updater.isActive {
                        updater.checkForUpdates()
                    } else {
                        model.checkForUpdate()
                    }
                }
            }
            CommandGroup(after: .pasteboard) {
                Button(model.liga.isCup ? "Runde kopieren" : "Tabelle kopieren") { model.copyTable() }
                    .keyboardShortcut("c", modifiers: [.command, .shift])
                    .disabled(!model.hasExportableContent)
            }
            CommandMenu("Spieltag") {
                Button("Vorherige\(model.liga.isCup ? " Runde" : "r Spieltag")") { model.prevSpieltag() }
                    .keyboardShortcut(.leftArrow, modifiers: .command)
                    .disabled(!model.canGoPrevSpieltag)
                Button("Nächste\(model.liga.isCup ? " Runde" : "r Spieltag")") { model.nextSpieltag() }
                    .keyboardShortcut(.rightArrow, modifiers: .command)
                    .disabled(!model.canGoNextSpieltag)
                Divider()
                Button(model.liga.isCup ? "Aktuelle Runde" : "Aktuelle Tabelle") { model.showCurrentTable() }
                    .keyboardShortcut("r", modifiers: .command)
            }
        }

        MenuBarExtra(isInserted: $showMenuBarItem) {
            MenuBarPanel()
                .environmentObject(model)
                .environmentObject(updater)
        } label: {
            Image(nsImage: .soccerBall)
        }
        .menuBarExtraStyle(.window)
    }
}
