import SwiftUI
import UniformTypeIdentifiers

/// Files parked on the notch: drop them in, drag them back out,
/// or throw them at AirDrop on the left.
struct FileShelfView: View {
    @EnvironmentObject private var shelf: FileShelfStore

    var body: some View {
        HStack(spacing: 12) {
            AirDropZone()

            Rectangle()
                .fill(Palette.hairline)
                .frame(width: 1, height: 40)

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
            .padding(.vertical, 9)
    }
}

/// Drop files here to send them straight out; click to send everything
/// currently on the shelf.
private struct AirDropZone: View {
    @EnvironmentObject private var shelf: FileShelfStore
    @State private var isTargeted = false
    @State private var isHovering = false

    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: "dot.radiowaves.up.forward")
                .font(.system(size: 15, weight: .medium))
            Text("AirDrop")
                .font(.system(size: 9, weight: .medium))
        }
        .foregroundColor(isTargeted ? Palette.accent : Palette.secondaryText)
        .frame(width: 62, height: 56)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Palette.primaryText.opacity(isTargeted || isHovering ? 0.10 : 0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isTargeted ? Palette.accent.opacity(0.6) : .clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .onTapGesture { AirDrop.send(shelf.items.map(\.url)) }
        .onDrop(of: [UTType.fileURL], isTargeted: $isTargeted) { providers in
            DropSupport.loadURLs(from: providers) { urls in AirDrop.send(urls) }
            return true
        }
        .animation(.easeOut(duration: 0.12), value: isTargeted)
        .help("Drop files to AirDrop them, or click to send the whole tray")
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
