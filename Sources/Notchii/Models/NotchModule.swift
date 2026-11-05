import Foundation

/// A mode the notch sheet can show.
enum NotchModule: String, CaseIterable, Codable, Identifiable {
    case tasks
    case files
    case music
    case clipboard
    case ai

    var id: String { rawValue }

    /// Every mode can be turned on and off; settings is not a mode, it is
    /// the gear beside the notch.
    static var configurable: [NotchModule] { allCases }

    var title: String {
        switch self {
        case .tasks: return "Tasks"
        case .files: return "Tray"
        case .music: return "Music"
        case .clipboard: return "Clipboard"
        case .ai: return "AI"
        }
    }

    var symbol: String {
        switch self {
        case .tasks: return "checklist"
        case .files: return "tray.full"
        case .music: return "music.note"
        case .clipboard: return "doc.on.clipboard"
        case .ai: return "sparkles"
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
    case aiSessions

    var id: String { rawValue }

    var module: NotchModule {
        switch self {
        case .todos, .focusTimer: return .tasks
        case .airdrop, .shelf: return .files
        case .nowPlaying, .transport: return .music
        case .clipboardHistory: return .clipboard
        case .aiSessions: return .ai
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
        case .aiSessions: return "Chats and tasks"
        }
    }
}
