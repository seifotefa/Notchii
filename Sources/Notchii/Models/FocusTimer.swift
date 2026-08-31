import AppKit
import Combine

/// A pomodoro-style countdown that lives next to the to-do list.
final class FocusTimer: ObservableObject {
    enum Preset: Int, CaseIterable, Identifiable {
        case focus = 25
        case short = 5
        case long = 15

        var id: Int { rawValue }
        var minutes: Int { rawValue }
        var duration: TimeInterval { TimeInterval(rawValue * 60) }

        var label: String {
            switch self {
            case .focus: return "Focus"
            case .short: return "Break"
            case .long: return "Long"
            }
        }
    }

    @Published private(set) var preset: Preset = .focus
    @Published private(set) var remaining: TimeInterval = Preset.focus.duration
    @Published private(set) var isRunning = false

    private var timer: Timer?

    var isFinished: Bool { remaining <= 0 }

    var clock: String {
        let total = Int(max(0, remaining).rounded(.up))
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    // MARK: - Controls

    func toggle() {
        isRunning ? pause() : start()
    }

    func start() {
        guard !isRunning else { return }
        if isFinished { remaining = preset.duration }
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

    func reset() {
        pause()
        remaining = preset.duration
    }

    func select(_ preset: Preset) {
        self.preset = preset
        reset()
    }

    private func tick() {
        remaining = max(0, remaining - 1)
        guard remaining == 0 else { return }
        pause()
        NSSound(named: "Glass")?.play()
    }
}
