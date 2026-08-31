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
        var isShuffling: Bool
        var artworkURL: URL?
        var duration: TimeInterval
        var position: TimeInterval
        var sampledAt: Date

        /// Where the playhead is right now, without asking the player again.
        var livePosition: TimeInterval {
            guard isPlaying else { return position }
            return min(duration, position + Date().timeIntervalSince(sampledAt))
        }
    }

    @Published private(set) var track: Track?
    /// Kept separate from `track` so a metadata refresh never re-fetches the image.
    @Published private(set) var artwork: NSImage?

    var isPlaying: Bool { track?.isPlaying == true }

    private var timer: Timer?
    private var artworkURL: URL?
    private let queue = DispatchQueue(label: "com.notchii.music", qos: .utility)
    private let debug = ProcessInfo.processInfo.environment["NOTCHII_DEBUG"] != nil

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
            if track != nil {
                track = nil
                artwork = nil
                artworkURL = nil
            }
            return
        }

        queue.async { [weak self] in
            guard let self else { return }
            let found = sources.compactMap(self.readTrack(from:))
            // Whatever is actually playing wins; otherwise show the paused one.
            let best = found.first(where: \.isPlaying) ?? found.first
            DispatchQueue.main.async {
                self.track = best
                self.loadArtwork(best?.artworkURL)
            }
        }
    }

    // MARK: - Transport

    func playPause() { send("playpause") }
    func next() { send("next track") }

    func previous() {
        // Spotify's previous restarts the track first, so go back twice.
        send(track?.source == .spotify ? "previous track\n\t\tprevious track" : "previous track")
    }

    func toggleShuffle() {
        guard let source = track?.source else { return }
        switch source {
        case .spotify: send("set shuffling to not shuffling")
        case .appleMusic: send("set shuffle enabled to not shuffle enabled")
        }
    }

    private func send(_ command: String) {
        guard let source = track?.source else { return }
        queue.async { [weak self] in
            _ = self?.run(
                """
                if application "\(source.rawValue)" is running then
                \ttell application "\(source.rawValue)"
                \t\t\(command)
                \tend tell
                end if
                """
            )
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { self?.refresh() }
        }
    }

    // MARK: - AppleScript

    private func readTrack(from source: Source) -> Track? {
        // Every value goes into one expression: `set x to ...` statements
        // inside a tell block collide with the players' own terminology.
        let artwork = source == .spotify ? "(artwork url of current track)" : "\"\""
        let shuffle = source == .spotify ? "(shuffling)" : "(shuffle enabled)"
        let script = """
        if application "\(source.rawValue)" is running then
        \ttell application "\(source.rawValue)"
        \t\tif player state is stopped then return ""
        \t\treturn (player state as text) & tab & (name of current track) & tab \
        & (artist of current track) & tab & \(artwork) & tab \
        & ((player position) as text) & tab & ((duration of current track) as text) \
        & tab & (\(shuffle) as text)
        \tend tell
        end if
        """

        guard let raw = run(script), !raw.isEmpty else { return nil }
        let parts = raw.components(separatedBy: "\t")
        guard parts.count >= 7, !parts[1].isEmpty else { return nil }

        // Spotify reports track length in milliseconds, Music in seconds.
        let rawDuration = number(parts[5])
        let duration = source == .spotify ? rawDuration / 1000 : rawDuration

        return Track(
            source: source,
            title: parts[1],
            artist: parts[2],
            isPlaying: parts[0] == "playing",
            isShuffling: parts[6] == "true",
            artworkURL: URL(string: parts[3]),
            duration: duration,
            position: number(parts[4]),
            sampledAt: Date()
        )
    }

    /// AppleScript formats reals with the user's decimal separator.
    private func number(_ text: String) -> TimeInterval {
        TimeInterval(text.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    private func run(_ source: String) -> String? {
        var error: NSDictionary?
        let value = NSAppleScript(source: source)?.executeAndReturnError(&error)
        if let error, debug {
            FileHandle.standardError.write(Data("applescript error: \(error)\n".utf8))
            return nil
        }
        return error == nil ? value?.stringValue : nil
    }

    // MARK: - Artwork

    private func loadArtwork(_ url: URL?) {
        guard url != artworkURL else { return }
        artworkURL = url
        artwork = nil
        guard let url else { return }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, let image = NSImage(data: data) else { return }
            DispatchQueue.main.async {
                guard self?.artworkURL == url else { return } // track moved on
                self?.artwork = image
            }
        }.resume()
    }
}
