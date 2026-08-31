import AppKit
import SwiftUI

/// A plain settings window; the app has no other windows.
final class SettingsWindow {
    private var window: NSWindow?

    func show(preferences: Preferences) {
        if window == nil {
            let window = NSWindow(
                contentRect: .init(x: 0, y: 0, width: 320, height: 260),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "Notchii Settings"
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: SettingsView(preferences: preferences))
            window.center()
            self.window = window
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
