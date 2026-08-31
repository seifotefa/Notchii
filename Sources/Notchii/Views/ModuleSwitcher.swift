import SwiftUI

/// Two chevrons and the current mode's name. The chevrons disappear when
/// there is nothing to cycle to — in settings, or with one mode enabled.
struct ModuleSwitcher: View {
    @EnvironmentObject private var controller: NotchController
    @EnvironmentObject private var preferences: Preferences

    private var canCycle: Bool {
        !controller.isShowingSettings && preferences.availableModules.count > 1
    }

    var body: some View {
        HStack(spacing: 0) {
            if canCycle {
                chevron("chevron.left") { controller.cycle(by: -1) }
            }

            Spacer(minLength: 0)

            HStack(spacing: 5) {
                Image(systemName: controller.isShowingSettings ? "gearshape" : controller.module.symbol)
                    .font(.system(size: 9, weight: .semibold))
                Text((controller.isShowingSettings ? "Settings" : controller.module.title).uppercased())
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(0.8)
            }
            .foregroundColor(Palette.secondaryText)

            Spacer(minLength: 0)

            if canCycle {
                chevron("chevron.right") { controller.cycle(by: 1) }
            }
        }
        .frame(height: Layout.switcherHeight)
    }

    private func chevron(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Palette.mutedText)
                .frame(width: 22, height: Layout.switcherHeight)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
