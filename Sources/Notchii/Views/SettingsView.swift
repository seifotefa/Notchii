import SwiftUI

struct SettingsView: View {
    @ObservedObject var preferences: Preferences

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Modules")
                .font(.system(size: 13, weight: .semibold))

            VStack(alignment: .leading, spacing: 8) {
                ForEach(NotchModule.allCases) { module in
                    Toggle(isOn: binding(for: module)) {
                        Label(module.title, systemImage: module.symbol)
                    }
                    .toggleStyle(.switch)
                    .controlSize(.small)
                }
            }

            Text("Hover the notch to open. Use the arrows, or ⌘← / ⌘→, to cycle modules.")
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
        .frame(width: 320)
    }

    private func binding(for module: NotchModule) -> Binding<Bool> {
        Binding(
            get: { preferences.isEnabled(module) },
            set: { preferences.setEnabled(module, $0) }
        )
    }
}

extension Bundle {
    var shortVersion: String {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"
    }
}
