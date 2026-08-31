# Notchii

A hover-the-notch dropdown for macOS. Move your pointer to the notch and a wide,
short sheet slides down out of it — tasks, a file tray, and music controls,
without leaving whatever you're working in.

No Dock icon, no window, no Electron. One small AppKit + SwiftUI binary.

## Modules

| | |
|---|---|
| **Tasks** | Type and press Return to add. Click the circle to scratch off, hover a row and click × to delete. |
| **Tray** | Drag files onto the notch to park them, drag them back out anywhere. Double-click reveals in Finder. |
| **Music** | Now playing plus prev / play-pause / next for Spotify and Apple Music. |

The sheet is context aware: dragging a file opens the tray, music playing opens
music, otherwise it opens whatever you used last. Cycle with the ‹ › arrows or
⌘← / ⌘→, and turn modules on or off in Settings (menu bar item → Settings…).

## Requirements

- macOS 13 or later
- Swift 5.9 toolchain (ships with Xcode 15+)

Works on notched MacBooks and on every other Mac — on displays without a notch,
Notchii uses a virtual notch of the same size at the top centre of the screen,
marked by a faint hairline.

## Run it

```bash
make run
```

## Install it

```bash
make install     # builds Notchii.app and copies it to /Applications
```

Quit from the menu bar item.

## Using it

- **Hover the notch** — the sheet drops down.
- **Move away, click elsewhere, or press Escape** — it closes. It stays open
  while you are typing or dragging a file onto it.

State lives in `~/Library/Application Support/Notchii/`
(`todos.json`, `shelf.json`); settings live in `UserDefaults`.

## Permissions

Music control uses Apple Events, so the first time the music module talks to
Spotify or Apple Music macOS asks to allow it. That prompt requires the signed
`.app` bundle — `make run` runs an unbundled binary and music will stay empty.
Nothing else needs a permission grant; hover detection uses mouse-position
monitoring, which does not require Accessibility access.

## Layout

```
Sources/Notchii
├── main.swift            # accessory-app entry point
├── AppDelegate.swift     # wiring + menu bar item
├── Theme.swift           # layout constants, palette, panel shape
├── Models/               # Todo, TodoStore, FileShelfStore, MusicController, Preferences
├── Notch/                # geometry, panel, hover controller, settings window
└── Views/                # SwiftUI content, one file per module
```

`NotchController` owns the collapsed/expanded transition; the panel is a
borderless non-activating `NSPanel` above the menu bar, resized between the
notch rect and the dropdown rect. Because it is non-activating, typing in the
panel does not deactivate the app you were using.

## Roadmap

The sheet is deliberately a container. Next candidates: quick timers, a
clipboard history, launch at login, and a per-module keyboard shortcut.

Adding a module means: a case in `NotchModule`, a height in `Layout`, and a
SwiftUI view. Everything else — the switcher, the settings toggle, the sizing —
picks it up automatically.

## License

MIT
