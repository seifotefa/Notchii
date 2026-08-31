import SwiftUI

enum Layout {
    static let panelWidth: CGFloat = 340
    static let cornerRadius: CGFloat = 22
    static let rowHeight: CGFloat = 32
    static let headerHeight: CGFloat = 34
    static let composerHeight: CGFloat = 38
    static let footerHeight: CGFloat = 26
    static let maxListHeight: CGFloat = 240

    static let hoverDelay: TimeInterval = 0.12
    static let closeDelay: TimeInterval = 0.22
    static let animationDuration: TimeInterval = 0.2

    static func listHeight(rowCount: Int) -> CGFloat {
        min(maxListHeight, CGFloat(max(rowCount, 1)) * rowHeight)
    }

    static func expandedHeight(rowCount: Int, notchHeight: CGFloat) -> CGFloat {
        notchHeight + headerHeight + composerHeight + listHeight(rowCount: rowCount)
            + footerHeight + 16
    }
}

enum Palette {
    static let surface = Color.black
    static let primaryText = Color.white
    static let secondaryText = Color.white.opacity(0.55)
    static let mutedText = Color.white.opacity(0.35)
    static let hairline = Color.white.opacity(0.10)
    static let accent = Color(red: 0.40, green: 0.78, blue: 0.62)
}

/// The dropdown is flush with the top screen edge, so only the bottom corners round.
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
