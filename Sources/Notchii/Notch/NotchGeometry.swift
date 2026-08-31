import AppKit

/// Describes the hover target at the top of a screen.
/// On notched MacBooks this is the real notch; on every other Mac
/// Notchii falls back to a virtual notch of the same shape.
struct NotchGeometry {
    let screen: NSScreen
    let size: CGSize
    let isRealNotch: Bool

    static let fallbackSize = CGSize(width: 190, height: 24)

    /// Prefers the built-in display that actually has a notch.
    static func preferredScreen() -> NSScreen? {
        NSScreen.screens.first { $0.safeAreaInsets.top > 0 } ?? NSScreen.main
    }

    init(screen: NSScreen) {
        self.screen = screen

        let left = screen.auxiliaryTopLeftArea?.width ?? 0
        let right = screen.auxiliaryTopRightArea?.width ?? 0
        let inset = screen.safeAreaInsets.top

        if inset > 0, left > 0, right > 0 {
            let width = screen.frame.width - left - right
            size = CGSize(width: max(width, 100), height: inset)
            isRealNotch = true
        } else {
            size = Self.fallbackSize
            isRealNotch = false
        }
    }

    /// The hover target, in global screen coordinates.
    var notchRect: CGRect {
        CGRect(
            x: screen.frame.midX - size.width / 2,
            y: screen.frame.maxY - size.height,
            width: size.width,
            height: size.height
        )
    }

    var width: CGFloat {
        max(Layout.panelWidth, size.width + 200)
    }

    /// The open sheet: same centre line, hanging down from the screen edge.
    /// `height` is the sheet itself; extra room is added underneath for the shadow.
    func windowFrame(height: CGFloat) -> CGRect {
        let total = height + Layout.shadowPadding
        return CGRect(
            x: screen.frame.midX - width / 2,
            y: screen.frame.maxY - total,
            width: width,
            height: total
        )
    }
}
