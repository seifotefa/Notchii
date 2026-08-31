# Notchii

A hover-the-notch dropdown for macOS. Move your pointer to the notch and a wide,
short sheet slides down out of it — tasks, a file tray, and music controls,
without leaving whatever you're working in.

No Dock icon, no window, no Electron. One small AppKit + SwiftUI binary.

## Modules

Five modes, each made of pieces you can switch off individually.

| | |
|---|---|
| **Tasks** | To-do list and timer, side by side. Type and press Return to add a task; click the circle to scratch off. For the timer, type a time — `5`, `5:30`, `0:45` — and press Return to start it. It chimes when it lands. |
| **Tray** | Drag files onto the notch to park them, drag them back out anywhere. Double-click reveals in Finder. Drop onto the AirDrop pad on the left to send, or click it to AirDrop the whole tray. |
| **Music** | Artwork, playhead, and shuffle / prev / play-pause / next for Spotify and Apple Music. |
| **Clipboard** | The last 20 things you copied. Click one to put it back. Items marked private by password managers are never recorded. |


Settings is the gear beside the notch, not a mode: one line per mode with a
check mark to turn it on or off, and a gear that opens that mode's own pieces.
Notchii's own two-eyed mark sits on the other side of the notch.

The sheet is context aware: dragging a file opens the tray, music playing opens
music, otherwise it opens whatever you used last. Cycle with the ‹ › arrows or
⌘← / ⌘→.

The sheet is always the same size no matter which mode is showing, so the
arrows stay under your pointer as you cycle.

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

## Releasing

```bash
make release VERSION=0.1.0
```

Builds a universal (Apple silicon + Intel) binary, wraps it in `Notchii.app`,
and produces a DMG in `dist/`. It also writes `dist/Notchii.dmg` under a fixed
name so a download link never has to change, plus `latest.json` with the
version, date and SHA-256.

Signing and notarization switch on when the credentials are present:

```bash
export DEVELOPER_ID="Developer ID Application: Your Name (TEAMID)"
export NOTARY_PROFILE="notchii"     # see xcrun notarytool store-credentials
make release VERSION=0.1.0
```

Without them you still get a working DMG — it is simply unsigned, and macOS
will block it on other people's machines (see below).

### Publishing

Attach the DMG to a GitHub release. That gives a permanent link that always
points at the newest build, which is what a download button should use:

```
https://github.com/OWNER/Notchii/releases/latest/download/Notchii.dmg
```

`latest.json` is there if the page wants to show the version number, release
date or checksum without hardcoding them.

### First launch, before notarization

Until the app is notarized, macOS blocks it on first launch with "Apple could
not verify Notchii is free of malware" — and on macOS 15 and later there is no
right-click → Open shortcut any more. The steps are:

1. Open **System Settings → Privacy & Security**
2. Scroll to **Security**, find the line about Notchii being blocked
3. Click **Open Anyway** and authenticate
4. Launch Notchii again and confirm

Notchii has no Dock icon and no window, so the only sign it is running is the
chevron in the menu bar.

Any download page should carry these steps too, not just this README.

## Using it

- **Hover the notch** — the sheet drops down.
- **Move away, click elsewhere, or press Escape** — it closes. It stays open
  while you are typing or dragging a file onto it.

State lives in `~/Library/Application Support/Notchii/`
(`todos.json`, `shelf.json`, `clipboard.json`); settings live in `UserDefaults`.

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
├── Models/               # stores and state, one file each
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

Adding a mode means: a case in `NotchModule`, its pieces in `NotchComponent`,
and a SwiftUI view sized to `Layout.contentHeight`. The switcher, the settings
card, and the enable/disable plumbing pick it up automatically.

## License

MIT
