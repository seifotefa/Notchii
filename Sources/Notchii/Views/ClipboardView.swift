import SwiftUI

/// Recent clipboard text. Click a row to put it back on the clipboard.
struct ClipboardView: View {
    @EnvironmentObject private var clipboard: ClipboardStore

    var body: some View {
        Group {
            if clipboard.entries.isEmpty {
                Text("Nothing copied yet")
                    .font(.system(size: 11))
                    .foregroundColor(Palette.mutedText)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(clipboard.entries) { entry in
                            ClipboardRow(entry: entry)
                        }
                    }
                }
            }
        }
        .frame(height: Layout.contentHeight)
    }
}

private struct ClipboardRow: View {
    let entry: ClipboardStore.Entry

    @EnvironmentObject private var clipboard: ClipboardStore
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 8) {
            Text(entry.preview)
                .font(.system(size: 11))
                .foregroundColor(isHovering ? Palette.primaryText : Palette.secondaryText)
                .lineLimit(1)

            Spacer(minLength: 8)

            Image(systemName: "doc.on.doc")
                .font(.system(size: 9))
                .foregroundColor(Palette.mutedText)
                .opacity(isHovering ? 1 : 0)
        }
        .frame(height: Layout.clipRowHeight)
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .onTapGesture { clipboard.copy(entry) }
    }
}
