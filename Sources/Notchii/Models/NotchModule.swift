import Foundation

/// A mode the notch sheet can show.
enum NotchModule: String, CaseIterable, Codable, Identifiable {
    case tasks
    case files
    case music
    case clipboard
    /// Always available, and never switched off from inside itself.
    case settings

    var id: String { rawValue }

    /// The modes that can be turned on and off.
    static var configurable: [NotchModule] { allCases.filter { $0 != .settings } }

    var title: String {
        switch self {
        case .tasks: return "Tasks"
        case .files: return "Tray"
        case .music: return "Music"
        case .clipboard: return "Clipboard"
        case .settings: return "Settings"
        }
    }

    var symbol: String {
        switch self {
        case .tasks: return "checklist"
        case .files: return "tray.full"
        case .music: return "music.note"
        case .clipboard: return "doc.on.clipboard"
        case .settings: return "gearshape"
        }
    }

    var components: [NotchComponent] {
        NotchComponent.allCases.filter { $0.module == self }
    }
}

/// A single piece inside a mode. Every one of these can be switched off
/// on its own, so a mode is only ever what you asked it to be.
enum NotchComponent: String, CaseIterable, Codable, Identifiable {
    case todos
    case focusTimer

    case airdrop
    case shelf

    case nowPlaying
    case transport

    case clipboardHistory

    var id: String { rawValue }

    var module: NotchModule {
        switch self {
        case .todos, .focusTimer: return .tasks
        case .airdrop, .shelf: return .files
        case .nowPlaying, .transport: return .music
        case .clipboardHistory: return .clipboard
        }
    }

    var title: String {
        switch self {
        case .todos: return "To-do list"
        case .focusTimer: return "Focus timer"
        case .airdrop: return "AirDrop"
        case .shelf: return "File shelf"
        case .nowPlaying: return "Now playing"
        case .transport: return "Playback controls"
        case .clipboardHistory: return "History"
        }
    }
}
