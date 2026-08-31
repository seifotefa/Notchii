import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var notch: NotchController?
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        notch = NotchController(store: TodoStore())
        notch?.start()
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

    /// A minimal menu bar item, so the app can be quit and discovered.
    private func installStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(
            systemSymbolName: "checklist",
            accessibilityDescription: "Notchi"
        )
        item.button?.image?.isTemplate = true

        let menu = NSMenu()
        menu.addItem(
            withTitle: "Hover the notch to open Notchi",
            action: nil,
            keyEquivalent: ""
        ).isEnabled = false
        menu.addItem(.separator())
        menu.addItem(
            withTitle: "Quit Notchi",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        item.menu = menu
        statusItem = item
    }
}
