import SwiftUI
import UniformTypeIdentifiers

/// Closed: an invisible hover target shaped like the notch.
/// Open: a wide black sheet that reads as the notch stretching outwards.
struct NotchRootView: View {
    let geometry: NotchGeometry

    @EnvironmentObject private var controller: NotchController
    @EnvironmentObject private var preferences: Preferences
    @EnvironmentObject private var shelf: FileShelfStore

    var body: some View {
        Group {
            if controller.isOpen {
                sheet
            } else {
                closed
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onDrop(
            of: [UTType.fileURL],
            delegate: ShelfDropDelegate(controller: controller, shelf: shelf)
        )
    }

    private var closed: some View {
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

    private var sheet: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: geometry.size.height) // sits behind the notch itself

            VStack(spacing: 0) {
                module
                if preferences.orderedModules.count > 1 {
                    ModuleSwitcher()
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, Layout.contentPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Palette.surface)
        .clipShape(BottomRoundedRectangle(radius: Layout.cornerRadius))
        .overlay(
            BottomRoundedRectangle(radius: Layout.cornerRadius)
                .stroke(Palette.hairline, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.5), radius: 10, y: 4)
        .padding(.bottom, Layout.shadowPadding)
    }

    @ViewBuilder
    private var module: some View {
        switch controller.module {
        case .tasks: TodoListView()
        case .files: FileShelfView()
        case .music: MusicView()
        }
    }
}

/// Dragging a file at the notch opens the tray and drops into it.
private struct ShelfDropDelegate: DropDelegate {
    let controller: NotchController
    let shelf: FileShelfStore

    func validateDrop(info: DropInfo) -> Bool {
        controller.isFileTrayAvailable && info.hasItemsConforming(to: [UTType.fileURL])
    }

    func dropEntered(info: DropInfo) {
        controller.beginFileDrag()
    }

    func dropExited(info: DropInfo) {
        controller.endFileDrag()
    }

    func performDrop(info: DropInfo) -> Bool {
        let providers = info.itemProviders(for: [UTType.fileURL])
        let group = DispatchGroup()
        var urls: [URL] = []
        let lock = NSLock()

        for provider in providers {
            group.enter()
            provider.loadDataRepresentation(
                forTypeIdentifier: UTType.fileURL.identifier
            ) { data, _ in
                defer { group.leave() }
                guard let data, let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                lock.lock()
                urls.append(url)
                lock.unlock()
            }
        }

        group.notify(queue: .main) {
            shelf.add(urls)
            controller.endFileDrag()
        }
        return true
    }
}
