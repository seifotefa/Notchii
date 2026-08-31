import AppKit
import Combine

/// Now playing for Spotify and Apple Music, over AppleScript.
///
/// Polling only runs while one of the two apps is actually running, so an
/// idle Mac does no work at all.
final class MusicController: ObservableObject {
    enum Source: String, CaseIterable {
        case spotify = "Spotify"
        case appleMusic = "Music"

        var bundleID: String {
            switch self {
            case .spotify: return "com.spotify.client"
            case .appleMusic: return "com.apple.Music"
            }
        }

        var isRunning: Bool {
            !NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).isEmpty
        }
    }

    struct Track: Equatable {
        var source: Source
        var title: String
        var artist: String
        var isPlaying: Bool
        var artworkURL: URL?
    }

    @Published private(set) var track: Track?

    var isPlaying: Bool { track?.isPlaying == true }

    private var timer: Timer?
    private let queue = DispatchQueue(label: "com.notchii.music", qos: .utility)

    // MARK: - Polling

    func startPolling(interval: TimeInterval = 2) {
        guard timer == nil else { return }
        refresh()
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            self?.refresh()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stopPolling() {
        timer?.invalidate()
        timer = nil
    }

    func refresh() {
        let sources = Source.allCases.filter(\.isRunning)
        guard !sources.isEmpty else {
            if track != nil { track = nil }
            return
        }

        queue.async { [weak self] in
            guard let self else { return }
            let found = sources.compactMap(self.readTrack(from:))
            // Whatever is actually playing wins; otherwise show the paused one.
            let best = found.first(where: \.isPlaying) ?? found.first
            DispatchQueue.main.async {
                if self.track != best { self.track = best }
            }
        }
    }

    // MARK: - Transport

    func playPause() { send("playpause") }
    func next() { send("next track") }
    func previous() {
        // Spotify's previous jumps to the track start first; go back twice.
        send(track?.source == .spotify ? "previous track\nprevious track" : "previous track")
    }

    private func send(_ command: String) {
        guard let source = track?.source else { return }
        queue.async { [weak self] in
            _ = self?.run(
                """
                if application "\(source.rawValue)" is running then
                    tell application "\(source.rawValue)"
                        \(command)
                    end tell
                end if
                """
            )
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { self?.refresh() }
        }
    }

    // MARK: - AppleScript

    private func readTrack(from source: Source) -> Track? {
        let artwork = source == .spotify ? "set art to artwork url of current track" : "set art to \"\""
        let script = """
        if application "\(source.rawValue)" is running then
            tell application "\(source.rawValue)"
                if player state is stopped then return ""
                set st to player state as text
                set t to name of current track
                set a to artist of current track
                \(artwork)
                return st & tab & t & tab & a & tab & art
            end tell
        end if
        """

        guard let raw = run(script), !raw.isEmpty else { return nil }
        let parts = raw.components(separatedBy: "\t")
        guard parts.count >= 3, !parts[1].isEmpty else { return nil }

        return Track(
            source: source,
            title: parts[1],
            artist: parts[2],
            isPlaying: parts[0] == "playing",
            artworkURL: parts.count > 3 ? URL(string: parts[3]) : nil
        )
    }

    private func run(_ source: String) -> String? {
        var error: NSDictionary?
        let value = NSAppleScript(source: source)?.executeAndReturnError(&error)
        if error != nil { return nil }
        return value?.stringValue
    }
}
