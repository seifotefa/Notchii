import SwiftUI

/// Settings, right in the notch: one card per mode, with its pieces
/// underneath. Always the last stop in the cycle.
struct SettingsModuleView: View {
    @EnvironmentObject private var preferences: Preferences

    var body: some View {
        HStack(spacing: 8) {
            ForEach(NotchModule.configurable) { module in
                ModuleCard(module: module)
            }
        }
        .frame(height: Layout.contentHeight)
    }
}

private struct ModuleCard: View {
    let module: NotchModule

    @EnvironmentObject private var preferences: Preferences

    private var isOn: Bool { preferences.isEnabled(module) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                preferences.setEnabled(module, !isOn)
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: module.symbol)
                        .font(.system(size: 10))
                    Text(module.title)
                        .font(.system(size: 10, weight: .semibold))
                        .lineLimit(1)
                    Spacer(minLength: 2)
                    Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 10))
                }
                .foregroundColor(isOn ? Palette.primaryText : Palette.mutedText)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                ForEach(module.components) { component in
                    componentRow(component)
                }
            }
            .opacity(isOn ? 1 : 0.35)
            .disabled(!isOn)

            Spacer(minLength: 0)
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Palette.primaryText.opacity(isOn ? 0.07 : 0.03))
        )
        .padding(.vertical, 6)
    }

    private func componentRow(_ component: NotchComponent) -> some View {
        let enabled = preferences.isEnabled(component)
        return Button {
            preferences.setEnabled(component, !enabled)
        } label: {
            HStack(spacing: 5) {
                Image(systemName: enabled ? "checkmark.square.fill" : "square")
                    .font(.system(size: 9))
                    .foregroundColor(enabled ? Palette.accent : Palette.mutedText)
                Text(component.title)
                    .font(.system(size: 9))
                    .foregroundColor(Palette.secondaryText)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
