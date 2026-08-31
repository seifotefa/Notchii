import SwiftUI

enum Layout {
    /// Wide and short: the sheet reads as the notch stretching sideways,
    /// never as a tall dropdown.
    static let panelWidth: CGFloat = 560
    static let cornerRadius: CGFloat = 26
    static let rowHeight: CGFloat = 28
    static let composerHeight: CGFloat = 38
    static let visibleRows = 4
    static let shelfHeight: CGFloat = 74
    static let musicHeight: CGFloat = 98
    static let switcherHeight: CGFloat = 22
    static let contentPadding: CGFloat = 8
    static let shadowPadding: CGFloat = 16

    static let hoverDelay: TimeInterval = 0.10
    static let closeDelay: TimeInterval = 0.20
    static let animationDuration: TimeInterval = 0.22

    static func listHeight(rowCount: Int) -> CGFloat {
        CGFloat(min(rowCount, visibleRows)) * rowHeight
    }

    static func moduleHeight(_ module: NotchModule, rowCount: Int) -> CGFloat {
        switch module {
        case .tasks: return composerHeight + listHeight(rowCount: rowCount)
        case .files: return shelfHeight
        case .music: return musicHeight
        }
    }

    static func sheetHeight(
        module: NotchModule,
        rowCount: Int,
        notchHeight: CGFloat,
        showsSwitcher: Bool
    ) -> CGFloat {
        notchHeight
            + moduleHeight(module, rowCount: rowCount)
            + (showsSwitcher ? switcherHeight : 0)
            + contentPadding
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
