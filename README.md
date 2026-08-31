# Notchi

A hover-the-notch dropdown for macOS. Move your pointer to the notch and a small
panel slides down out of it. First thing it does: a to-do list you can add to and
scratch off without leaving whatever you're working in.

No Dock icon, no window, no Electron. One small AppKit + SwiftUI binary.

## Requirements

- macOS 13 or later
- Swift 5.9 toolchain (ships with Xcode 15+)

Works on notched MacBooks and on every other Mac — on displays without a notch,
Notchi uses a virtual notch of the same size at the top centre of the screen,
marked by a faint hairline.

## Run it

```bash
make run
```

## Install it

```bash
make install     # builds Notchi.app and copies it to /Applications
```

Quit from the menu bar item.

## Using it

- **Hover the notch** — the panel drops down.
- **Type and press Return** — adds a task.
- **Click the circle** — scratches it off.
- **Hover a row, click ×** — deletes it.
- **Move away, or press Escape** — the panel closes. It stays open while the
  text field has focus.

Tasks are stored as JSON at
`~/Library/Application Support/Notchi/todos.json`.

## Layout

```
Sources/Notchi
├── main.swift            # accessory-app entry point
├── AppDelegate.swift     # wiring + menu bar item
├── Theme.swift           # layout constants, palette, panel shape
├── Models/               # Todo, TodoStore (JSON persistence)
├── Notch/                # geometry, panel, hover controller
└── Views/                # SwiftUI content
```

`NotchController` owns the collapsed/expanded transition; the panel is a
borderless non-activating `NSPanel` above the menu bar, resized between the
notch rect and the dropdown rect. Because it is non-activating, typing in the
panel does not deactivate the app you were using.

## Roadmap

The dropdown is deliberately a container — the to-do list is the first module.
Next candidates: now-playing controls, a file shelf, quick timers.

## License

MIT
