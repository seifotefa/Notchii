import Foundation

/// A panel that can live inside the notch sheet.
enum NotchModule: String, CaseIterable, Codable, Identifiable {
    case tasks
    case files
    case music

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tasks: return "Tasks"
        case .files: return "Tray"
        case .music: return "Music"
        }
    }

    var symbol: String {
        switch self {
        case .tasks: return "checklist"
        case .files: return "tray.full"
        case .music: return "music.note"
        }
    }
}
