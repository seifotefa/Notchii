import SwiftUI

/// Notchii itself: a soft dark blob with two mint eyes.
///
/// Uses the bundled artwork when it is there, and falls back to a drawn
/// version so the mark still shows when running the bare binary.
struct Mascot: View {
    var size: CGFloat = 22

    var body: some View {
        Group {
            if let artwork = NSImage(named: "mascot") {
                Image(nsImage: artwork)
                    .resizable()
                    .interpolation(.high)
            } else {
                drawn
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.3, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
                .strokeBorder(Palette.primaryText.opacity(0.12), lineWidth: 0.5)
        )
        .accessibilityLabel("Notchii")
    }

    private var drawn: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.42, style: .continuous)
                .fill(Palette.primaryText.opacity(0.07))

            HStack(spacing: size * 0.16) {
                eye
                eye
            }
        }
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
