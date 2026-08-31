import SwiftUI

/// Two chevrons and the current module's name. Hidden when only one
/// module is enabled, because then there is nothing to cycle.
struct ModuleSwitcher: View {
    @EnvironmentObject private var controller: NotchController

    var body: some View {
        HStack(spacing: 0) {
            chevron("chevron.left") { controller.cycle(by: -1) }

            Spacer(minLength: 0)

            HStack(spacing: 5) {
                Image(systemName: controller.module.symbol)
                    .font(.system(size: 9, weight: .semibold))
                Text(controller.module.title.uppercased())
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(0.8)
            }
            .foregroundColor(Palette.secondaryText)

            Spacer(minLength: 0)

            chevron("chevron.right") { controller.cycle(by: 1) }
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
