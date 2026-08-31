import AppKit
import Combine

/// Files parked on the notch. Only paths are stored; the file itself stays put.
final class FileShelfStore: ObservableObject {
    struct Item: Identifiable, Equatable {
        let id = UUID()
        let url: URL

        var name: String { url.lastPathComponent }
        var icon: NSImage { NSWorkspace.shared.icon(forFile: url.path) }
    }

    @Published private(set) var items: [Item] = []

    private let fileURL: URL

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? Storage.url(for: "shelf.json")
        items = load()
    }

    func add(_ urls: [URL]) {
        let known = Set(items.map(\.url))
        let fresh = urls
            .filter { !known.contains($0) && FileManager.default.fileExists(atPath: $0.path) }
            .map(Item.init(url:))
        guard !fresh.isEmpty else { return }
        items.insert(contentsOf: fresh, at: 0)
        save()
    }

    func remove(_ item: Item) {
        items.removeAll { $0.id == item.id }
        save()
    }

    func removeAll() {
        items.removeAll()
        save()
    }

    func reveal(_ item: Item) {
        NSWorkspace.shared.activateFileViewerSelecting([item.url])
    }

    // MARK: - Persistence

    private func load() -> [Item] {
        guard
            let data = try? Data(contentsOf: fileURL),
            let paths = try? JSONDecoder().decode([String].self, from: data)
        else { return [] }
        // Drop anything that moved or was deleted since last launch.
        return paths
            .filter { FileManager.default.fileExists(atPath: $0) }
            .map { Item(url: URL(fileURLWithPath: $0)) }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items.map(\.url.path)) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}

/// Shared Application Support location.
enum Storage {
    static func url(for name: String) -> URL {
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first ?? FileManager.default.temporaryDirectory
        let folder = base.appendingPathComponent("Notchii", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent(name)
    }
}
