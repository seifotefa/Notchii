import SwiftUI

/// Files parked on the notch: drop them in, drag them back out.
struct FileShelfView: View {
    @EnvironmentObject private var shelf: FileShelfStore

    var body: some View {
        Group {
            if shelf.items.isEmpty {
                empty
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(shelf.items) { item in
                            ShelfChip(item: item)
                        }
                    }
                }
            }
        }
        .frame(height: Layout.shelfHeight)
    }

    private var empty: some View {
        RoundedRectangle(cornerRadius: 10)
            .strokeBorder(
                Palette.primaryText.opacity(0.14),
                style: StrokeStyle(lineWidth: 1, dash: [4, 4])
            )
            .overlay(
                Text("Drop files here")
                    .font(.system(size: 11))
                    .foregroundColor(Palette.mutedText)
            )
            .padding(.vertical, 8)
    }
}

private struct ShelfChip: View {
    let item: FileShelfStore.Item

    @EnvironmentObject private var shelf: FileShelfStore
    @State private var isHovering = false

    var body: some View {
        VStack(spacing: 3) {
            Image(nsImage: item.icon)
                .resizable()
                .frame(width: 28, height: 28)
            Text(item.name)
                .font(.system(size: 9))
                .foregroundColor(Palette.secondaryText)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .frame(width: 62, height: 56)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Palette.primaryText.opacity(isHovering ? 0.09 : 0.05))
        )
        .overlay(alignment: .topTrailing) {
            if isHovering {
                Button {
                    shelf.remove(item)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Palette.secondaryText)
                }
                .buttonStyle(.plain)
                .offset(x: 4, y: -4)
            }
        }
        .onHover { isHovering = $0 }
        .onTapGesture(count: 2) { shelf.reveal(item) }
        .onDrag { NSItemProvider(contentsOf: item.url) ?? NSItemProvider() }
        .help(item.url.path)
    }
}
