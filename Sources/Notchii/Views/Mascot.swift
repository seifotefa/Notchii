import SwiftUI

/// Notchii itself: a soft dark blob with two mint eyes. Drawn rather than
/// shipped as an asset so it stays crisp at any size.
struct Mascot: View {
    var size: CGFloat = 18

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.42, style: .continuous)
                .fill(Palette.primaryText.opacity(0.07))

            HStack(spacing: size * 0.16) {
                eye
                eye
            }
        }
        .frame(width: size, height: size * 0.96)
        .accessibilityLabel("Notchii")
    }

    private var eye: some View {
        Capsule()
            .fill(Palette.accent)
            .frame(width: size * 0.22, height: size * 0.34)
            .overlay(alignment: .top) {
                Circle()
                    .fill(Palette.primaryText)
                    .frame(width: size * 0.08, height: size * 0.08)
                    .padding(.top, size * 0.06)
            }
    }
}
