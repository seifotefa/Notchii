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

    @objc private func screensChanged() {
        notch?.repositionForCurrentScreen()
    }

    @objc private func openSettings() {
        settingsWindow.show(preferences: preferences)
    }

    /// A minimal menu bar item, so the app can be configured and quit.
    private func installStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(
            systemSymbolName: "chevron.down.circle",
            accessibilityDescription: "Notchii"
        )
        item.button?.image?.isTemplate = true

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
