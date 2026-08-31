import AppKit
import Combine

/// A countdown you set by typing. No presets, no modes — type minutes and
/// seconds, press Return, and it runs.
final class FocusTimer: ObservableObject {
    @Published private(set) var duration: TimeInterval = 25 * 60
    @Published private(set) var remaining: TimeInterval = 25 * 60
    @Published private(set) var isRunning = false

    private var timer: Timer?

    var isFinished: Bool { remaining <= 0 }

    /// mm:ss of whatever is left.
    var clock: String { Self.format(remaining) }

    static func format(_ seconds: TimeInterval) -> String {
        let total = Int(max(0, seconds).rounded(.up))
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    /// Accepts "5", "5:30", "0:45". A bare number means minutes.
    static func parse(_ text: String) -> TimeInterval? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        let parts = trimmed.split(separator: ":", omittingEmptySubsequences: false)
        let seconds: TimeInterval

        switch parts.count {
        case 1:
            guard let minutes = Int(parts[0]) else { return nil }
            seconds = TimeInterval(minutes * 60)
        case 2:
            guard
                let minutes = Int(parts[0].isEmpty ? "0" : String(parts[0])),
                let secs = Int(parts[1].isEmpty ? "0" : String(parts[1])),
                secs < 60
            else { return nil }
            seconds = TimeInterval(minutes * 60 + secs)
        default:
            return nil
        }

        guard seconds > 0, seconds <= 99 * 3600 else { return nil }
        return seconds
    }

    // MARK: - Controls

    /// Type a time and press Return: sets the duration and starts it.
    @discardableResult
    func startTyped(_ text: String) -> Bool {
        guard let seconds = Self.parse(text) else { return false }
        duration = seconds
        remaining = seconds
        start()
        return true
    }

    func toggle() { isRunning ? pause() : start() }

    func start() {
        guard !isRunning else { return }
        if isFinished { remaining = duration }
        isRunning = true

        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    /// Back to the time you last typed.
    func reset() {
        pause()
        remaining = duration
    }

    private func tick() {
        remaining = max(0, remaining - 1)
        guard remaining == 0 else { return }
        pause()
        NSSound(named: "Glass")?.play()
    }
}
