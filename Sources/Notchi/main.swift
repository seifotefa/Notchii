import AppKit

// Notchi runs as an accessory app: no Dock icon, no main menu, just the notch.
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
