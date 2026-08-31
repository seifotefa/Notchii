import Combine
import Foundation

/// User-facing settings. Small enough for UserDefaults.
final class Preferences: ObservableObject {
    private enum Key {
        static let enabled = "enabledModules"
        static let lastModule = "lastModule"
    }

    @Published var enabledModules: Set<NotchModule> {
        didSet {
            // Never leave the sheet with nothing to show.
            if enabledModules.isEmpty { enabledModules = [.tasks] }
            defaults.set(enabledModules.map(\.rawValue), forKey: Key.enabled)
        }
    }

    @Published var lastModule: NotchModule {
        didSet { defaults.set(lastModule.rawValue, forKey: Key.lastModule) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if let raw = defaults.array(forKey: Key.enabled) as? [String] {
            let modules = Set(raw.compactMap(NotchModule.init(rawValue:)))
            enabledModules = modules.isEmpty ? [.tasks] : modules
        } else {
            enabledModules = Set(NotchModule.allCases)
        }

        lastModule = NotchModule(rawValue: defaults.string(forKey: Key.lastModule) ?? "") ?? .tasks
    }

    /// Enabled modules in a stable order, for cycling.
    var orderedModules: [NotchModule] {
        NotchModule.allCases.filter(enabledModules.contains)
    }

    func isEnabled(_ module: NotchModule) -> Bool {
        enabledModules.contains(module)
    }

    func setEnabled(_ module: NotchModule, _ isOn: Bool) {
        if isOn {
            enabledModules.insert(module)
        } else {
            enabledModules.remove(module)
        }
    }
}
