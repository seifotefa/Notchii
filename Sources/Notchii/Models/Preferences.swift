import Combine
import Foundation

/// Which modes are on, and which pieces of each mode are on.
final class Preferences: ObservableObject {
    private enum Key {
        static let modules = "enabledModules"
        static let components = "enabledComponents"
        static let lastModule = "lastModule"
    }

    @Published var enabledModules: Set<NotchModule> {
        didSet { normalize(); defaults.set(enabledModules.map(\.rawValue), forKey: Key.modules) }
    }

    @Published var enabledComponents: Set<NotchComponent> {
        didSet { normalize(); defaults.set(enabledComponents.map(\.rawValue), forKey: Key.components) }
    }

    @Published var lastModule: NotchModule {
        didSet { defaults.set(lastModule.rawValue, forKey: Key.lastModule) }
    }

    private let defaults: UserDefaults
    private var isNormalizing = false

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if let raw = defaults.array(forKey: Key.modules) as? [String] {
            enabledModules = Set(raw.compactMap(NotchModule.init(rawValue:)))
        } else {
            enabledModules = Set(NotchModule.configurable)
        }

        if let raw = defaults.array(forKey: Key.components) as? [String] {
            enabledComponents = Set(raw.compactMap(NotchComponent.init(rawValue:)))
        } else {
            enabledComponents = Set(NotchComponent.allCases)
        }

        lastModule = NotchModule(rawValue: defaults.string(forKey: Key.lastModule) ?? "") ?? .tasks
        normalize()
    }

    // MARK: - Queries

    /// A mode is only shown if it is on and still has something in it.
    var configuredModules: [NotchModule] {
        NotchModule.configurable.filter { module in
            enabledModules.contains(module) && !components(of: module).isEmpty
        }
    }

    /// Settings is always the last stop in the cycle.
    var availableModules: [NotchModule] { configuredModules + [.settings] }

    func isEnabled(_ module: NotchModule) -> Bool { enabledModules.contains(module) }
    func isEnabled(_ component: NotchComponent) -> Bool { enabledComponents.contains(component) }

    /// The enabled components of a module, in declaration order.
    func components(of module: NotchModule) -> [NotchComponent] {
        module.components.filter(enabledComponents.contains)
    }

    // MARK: - Mutations

    func setEnabled(_ module: NotchModule, _ isOn: Bool) {
        if isOn {
            enabledModules.insert(module)
            // Turning a mode back on with nothing inside it would be a dead end.
            if components(of: module).isEmpty {
                enabledComponents.formUnion(module.components)
            }
        } else {
            enabledModules.remove(module)
        }
    }

    func setEnabled(_ component: NotchComponent, _ isOn: Bool) {
        if isOn {
            enabledComponents.insert(component)
        } else {
            enabledComponents.remove(component)
        }
    }

    /// Never leave the sheet with nothing at all to show.
    private func normalize() {
        guard !isNormalizing else { return }
        isNormalizing = true
        defer { isNormalizing = false }

        if configuredModules.isEmpty {
            enabledModules.insert(.tasks)
            enabledComponents.insert(.todos)
        }
        if !configuredModules.contains(lastModule) {
            lastModule = configuredModules.first ?? .tasks
        }
    }
}
