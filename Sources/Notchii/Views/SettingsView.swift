import SwiftUI

struct SettingsView: View {
    @ObservedObject var preferences: Preferences

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Modes")
                .font(.system(size: 13, weight: .semibold))

            VStack(alignment: .leading, spacing: 12) {
                ForEach(NotchModule.allCases) { module in
                    moduleSection(module)
                }
            }

            Text("Hover the notch to open. Use the arrows, or ⌘← / ⌘→, to cycle modes.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            HStack {
                Text("Notchii \(Bundle.main.shortVersion)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Spacer()
                Button("Quit") { NSApplication.shared.terminate(nil) }
            }
        }
        .padding(18)
        .frame(width: 340)
    }

    private func moduleSection(_ module: NotchModule) -> some View {
        let isOn = preferences.isEnabled(module)
        return VStack(alignment: .leading, spacing: 5) {
            Toggle(isOn: binding(for: module)) {
                Label(module.title, systemImage: module.symbol)
                    .font(.system(size: 12, weight: .medium))
            }
            .toggleStyle(.switch)
            .controlSize(.small)

            // A mode with more than one piece can be trimmed down.
            if module.components.count > 1 {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(module.components) { component in
                        Toggle(isOn: binding(for: component)) {
                            Text(component.title).font(.system(size: 11))
                        }
                        .toggleStyle(.checkbox)
                        .controlSize(.small)
                        .disabled(!isOn)
                    }
                }
                .padding(.leading, 20)
                .opacity(isOn ? 1 : 0.4)
            }
        }
    }

    private func binding(for module: NotchModule) -> Binding<Bool> {
        Binding(
            get: { preferences.isEnabled(module) },
            set: { preferences.setEnabled(module, $0) }
        )
    }

    private func binding(for component: NotchComponent) -> Binding<Bool> {
        Binding(
            get: { preferences.isEnabled(component) },
            set: { preferences.setEnabled(component, $0) }
        )
    }
}

extension Bundle {
    var shortVersion: String {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"
    }
}
