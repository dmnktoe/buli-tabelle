import SwiftUI
import AppKit

final class WindowBridge {
    static let shared = WindowBridge()
    weak var main: NSWindow?
}

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
            guard window.styleMask.contains(.titled) else { return }
            window.isRestorable = false
            window.isReleasedWhenClosed = false
            window.standardWindowButton(.closeButton)?.isHidden = true
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
            window.standardWindowButton(.zoomButton)?.isHidden = true
            window.tabbingMode = .disallowed
            window.isMovableByWindowBackground = true
            if #available(macOS 26.0, *) {
                window.styleMask.remove(.titled)
                Self.makeKeyable(window)
            } else {
                window.styleMask.insert(.fullSizeContentView)
                window.titlebarAppearsTransparent = true
                window.titleVisibility = .hidden
                Self.hideTitlebar(window)
            }
            window.hasShadow = true
            window.invalidateShadow()
            window.makeKeyAndOrderFront(nil)
        }
    }

    private static func makeKeyable(_ window: NSWindow) {
        guard let cls = object_getClass(window) else { return }
        let yes = imp_implementationWithBlock(
            { (_: NSWindow) -> Bool in true } as @convention(block) (NSWindow) -> Bool
        )
        class_addMethod(cls, NSSelectorFromString("canBecomeKeyWindow"), yes, "B@:")
        class_addMethod(cls, NSSelectorFromString("canBecomeMainWindow"), yes, "B@:")
    }

    private static var titlebarObserverKey: UInt8 = 0

    private static func titlebarContainer(_ window: NSWindow) -> NSView? {
        var v = window.standardWindowButton(.closeButton)?.superview
        while let cur = v {
            if String(describing: type(of: cur)) == "NSTitlebarContainerView" { return cur }
            v = cur.superview
        }
        return window.contentView?.superview?.subviews.first {
            String(describing: type(of: $0)) == "NSTitlebarContainerView"
        }
    }

    private static func hideTitlebar(_ window: NSWindow) {
        let apply = { [weak window] in
            guard let window else { return }
            window.contentView?.additionalSafeAreaInsets = NSEdgeInsets(top: -28, left: 0, bottom: 0, right: 0)
            if let container = Self.titlebarContainer(window) {
                func hideDeep(_ v: NSView) {
                    v.isHidden = true
                    v.subviews.forEach(hideDeep)
                }
                hideDeep(container)
            }
        }
        apply()
        if let old = objc_getAssociatedObject(window, &titlebarObserverKey) as? [NSObjectProtocol] {
            old.forEach(NotificationCenter.default.removeObserver)
        }
        let names: [NSNotification.Name] = [
            NSWindow.didBecomeKeyNotification,
            NSWindow.didUpdateNotification,
            NSWindow.didResizeNotification,
        ]
        let tokens = names.map { name in
            NotificationCenter.default.addObserver(forName: name, object: window, queue: .main) { _ in apply() }
        }
        objc_setAssociatedObject(window, &titlebarObserverKey, tokens, .OBJC_ASSOCIATION_RETAIN)
        for delay in [0.1, 0.3, 0.6, 1.0, 2.0] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: apply)
        }
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
