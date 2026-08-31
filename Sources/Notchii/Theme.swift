import SwiftUI

enum Layout {
    /// The sheet is one fixed size, always. Modules lay out inside it, so
    /// the switcher arrows never move out from under the pointer.
    static let panelWidth: CGFloat = 560
    static let contentHeight: CGFloat = 120
    static let switcherHeight: CGFloat = 22
    static let contentPadding: CGFloat = 8
    static let cornerRadius: CGFloat = 26
    static let shadowPadding: CGFloat = 16

    static let rowHeight: CGFloat = 28
    static let composerHeight: CGFloat = 38
    static let clipRowHeight: CGFloat = 26
    static let timerColumnWidth: CGFloat = 150

    static let hoverDelay: TimeInterval = 0.10
    static let closeDelay: TimeInterval = 0.20
    static let animationDuration: TimeInterval = 0.22

    static func sheetHeight(notchHeight: CGFloat) -> CGFloat {
        notchHeight + contentHeight + switcherHeight + contentPadding
    }
}

enum Palette {
    static let surface = Color.black
    static let primaryText = Color.white
    static let secondaryText = Color.white.opacity(0.45)
    static let mutedText = Color.white.opacity(0.30)
    static let hairline = Color.white.opacity(0.10)
    static let accent = Color(red: 0.42, green: 0.85, blue: 0.66)
}

/// The sheet is flush with the top screen edge, so only the bottom corners round.
struct BottomRoundedRectangle: Shape {
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let r = min(radius, min(rect.width, rect.height) / 2)
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - r, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - r),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )
        path.closeSubpath()
        return path
    }
}

/// A thin vertical rule between two columns.
struct ColumnDivider: View {
    var body: some View {
        Rectangle()
            .fill(Palette.hairline)
            .frame(width: 1)
            .padding(.vertical, 6)
    }
}
