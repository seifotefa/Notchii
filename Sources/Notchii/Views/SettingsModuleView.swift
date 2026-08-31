import SwiftUI

/// Settings, right in the notch. One line per mode: a check mark turns it
/// on or off, the gear opens that mode's own settings.
struct SettingsModuleView: View {
    @EnvironmentObject private var preferences: Preferences
    @State private var focused: NotchModule?

    var body: some View {
        Group {
            if let focused {
                ModuleDetail(module: focused) { self.focused = nil }
            } else {
                modeList
            }
        }
        .frame(height: Layout.contentHeight)
        .onAppear { focused = nil } // always open at the top level
    }

    private var modeList: some View {
        VStack(spacing: 0) {
            ForEach(NotchModule.configurable) { module in
                ModeRow(module: module) { focused = module }
            }
        }
    }
}

private struct ModeRow: View {
    let module: NotchModule
    let openDetail: () -> Void

    @EnvironmentObject private var preferences: Preferences
    @State private var isHovering = false

    private var isOn: Bool { preferences.isEnabled(module) }

    var body: some View {
        HStack(spacing: 10) {
            Button {
                preferences.setEnabled(module, !isOn)
            } label: {
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 13))
                    .foregroundColor(isOn ? Palette.accent : Palette.mutedText)
            }
            .buttonStyle(.plain)

            Image(systemName: module.symbol)
                .font(.system(size: 11))
                .foregroundColor(isOn ? Palette.secondaryText : Palette.mutedText)
                .frame(width: 16)

            Text(module.title)
                .font(.system(size: 12))
                .foregroundColor(isOn ? Palette.primaryText : Palette.mutedText)

            Spacer(minLength: 8)

            if module.components.count > 1 {
                Button(action: openDetail) {
                    HStack(spacing: 4) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 10))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 8, weight: .semibold))
                    }
                    .foregroundColor(Palette.mutedText)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!isOn)
                .opacity(isOn ? 1 : 0.3)
            }
        }
        .padding(.horizontal, 8)
        .frame(height: Layout.contentHeight / CGFloat(NotchModule.configurable.count))
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Palette.primaryText.opacity(isHovering ? 0.05 : 0))
        )
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
    }
}

/// One mode's own settings.
private struct ModuleDetail: View {
    let module: NotchModule
    let back: () -> Void

    @EnvironmentObject private var preferences: Preferences

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: back) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 10, weight: .semibold))
                    Image(systemName: module.symbol)
                        .font(.system(size: 10))
                    Text(module.title)
                        .font(.system(size: 11, weight: .semibold))
                    Spacer(minLength: 0)
                }
                .foregroundColor(Palette.secondaryText)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(height: 24)

            ForEach(module.components) { component in
                componentRow(component)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
    }

    private func componentRow(_ component: NotchComponent) -> some View {
        let isOn = preferences.isEnabled(component)
        return Button {
            preferences.setEnabled(component, !isOn)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 12))
                    .foregroundColor(isOn ? Palette.accent : Palette.mutedText)
                Text(component.title)
                    .font(.system(size: 12))
                    .foregroundColor(isOn ? Palette.primaryText : Palette.mutedText)
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(height: 26)
    }
}
