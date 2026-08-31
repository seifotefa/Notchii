import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let preferences = Preferences()
    private let todos = TodoStore()
    private let shelf = FileShelfStore()
    private let music = MusicController()
    private let clipboard = ClipboardStore()
    private let focusTimer = FocusTimer()
    private let settingsWindow = SettingsWindow()

    private var notch: NotchController?
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        terminateOtherInstances()

        let notch = NotchController(
            store: todos,
            shelf: shelf,
            music: music,
            clipboard: clipboard,
            focusTimer: focusTimer,
            preferences: preferences
        )
        notch.start()
        self.notch = notch

        installStatusItem()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    /// Two copies would put two panels on the notch. Relaunching replaces.
    private func terminateOtherInstances() {
        guard let id = Bundle.main.bundleIdentifier else { return }
        let mine = ProcessInfo.processInfo.processIdentifier
        for app in NSRunningApplication.runningApplications(withBundleIdentifier: id)
        where app.processIdentifier != mine {
            app.terminate()
        }
    }

    @objc private func screensChanged() {
        notch?.repositionForCurrentScreen()
    }

    @objc private func openSettings() {
        settingsWindow.show(preferences: preferences)
    }

    /// A minimal menu bar item, so the app can be configured and quit.
    private func installStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        // The bundled mask renders as a proper menu bar template; the symbol
        // is the fallback when running the bare binary.
        if let mark = NSImage(named: "menubar") {
            mark.size = NSSize(width: 18, height: 18)
            mark.isTemplate = true
            item.button?.image = mark
        } else {
            item.button?.image = NSImage(
                systemSymbolName: "chevron.down.circle",
                accessibilityDescription: "Notchii"
            )
            item.button?.image?.isTemplate = true
        }

        let menu = NSMenu()
        menu.addItem(withTitle: "Hover the notch to open", action: nil, keyEquivalent: "")
            .isEnabled = false
        menu.addItem(.separator())
        menu.addItem(
            withTitle: "Settings…",
            action: #selector(openSettings),
            keyEquivalent: ","
        ).target = self
        menu.addItem(
            withTitle: "Quit Notchii",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        item.menu = menu
        statusItem = item
    }
}
