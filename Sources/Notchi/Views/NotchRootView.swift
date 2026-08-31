import SwiftUI

/// Collapsed: an invisible hover target shaped like the notch.
/// Expanded: a black sheet that reads as the notch stretching downwards.
struct NotchRootView: View {
    let geometry: NotchGeometry

    @EnvironmentObject private var controller: NotchController
    @EnvironmentObject private var store: TodoStore

    var body: some View {
        Group {
            if controller.isExpanded {
                expanded
            } else {
                collapsed
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var collapsed: some View {
        // Nothing to draw over a real notch; a hairline hints at the
        // hover target on displays that do not have one.
        VStack {
            Spacer()
            if !geometry.isRealNotch {
                Capsule()
                    .fill(Palette.primaryText.opacity(0.22))
                    .frame(width: 34, height: 3)
                    .padding(.bottom, 3)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
    }

    private var expanded: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: geometry.size.height) // sits behind the notch itself
            TodoListView()
                .padding(.horizontal, 14)
                .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Palette.surface)
        .clipShape(BottomRoundedRectangle(radius: Layout.cornerRadius))
        .overlay(
            BottomRoundedRectangle(radius: Layout.cornerRadius)
                .stroke(Palette.hairline, lineWidth: 1)
        )
        .transition(.opacity)
    }
}
