import AppKit
import UniformTypeIdentifiers

enum DropSupport {
    /// Pulls file URLs out of a drop's item providers.
    static func loadURLs(
        from providers: [NSItemProvider],
        completion: @escaping ([URL]) -> Void
    ) {
        let group = DispatchGroup()
        let lock = NSLock()
        var urls: [URL] = []

        for provider in providers {
            group.enter()
            provider.loadDataRepresentation(
                forTypeIdentifier: UTType.fileURL.identifier
            ) { data, _ in
                defer { group.leave() }
                guard let data, let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                lock.lock()
                urls.append(url)
                lock.unlock()
            }
        }

        group.notify(queue: .main) { completion(urls) }
    }
}

enum AirDrop {
    static var isAvailable: Bool { service != nil }

    private static var service: NSSharingService? { NSSharingService(named: .sendViaAirDrop) }

    /// The system's own AirDrop icon, so the pad looks like what it is.
    static var icon: NSImage? { service?.image }

    /// Opens the system AirDrop picker for these files.
    static func send(_ urls: [URL]) {
        guard !urls.isEmpty, let service else { return }
        NSApp.activate(ignoringOtherApps: true)
        service.perform(withItems: urls)
    }
}
