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
            topBar // flanks the notch: mascot on one side, settings on the other

            VStack(spacing: 0) {
                if controller.isShowingSettings {
                    SettingsModuleView()
                } else {
                    module
                }
                ModuleSwitcher()
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

    /// The notch is only ~180pt wide inside a 560pt sheet, so there is room
    /// either side of it for the mark and the gear.
    private var topBar: some View {
        HStack(spacing: 0) {
            Mascot(size: 18)
            Spacer(minLength: 0)
            Button(action: controller.toggleSettings) {
                Image(systemName: controller.isShowingSettings ? "xmark" : "gearshape")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(
                        controller.isShowingSettings ? Palette.primaryText : Palette.mutedText
                    )
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(controller.isShowingSettings ? "Close settings" : "Settings")
        }
        .padding(.horizontal, 14)
        .frame(height: geometry.size.height)
    }

    @ViewBuilder
    private var module: some View {
        switch controller.module {
        case .tasks: TasksView()
        case .files: FileShelfView()
        case .music: MusicView()
        case .clipboard: ClipboardView()
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
        DropSupport.loadURLs(from: info.itemProviders(for: [UTType.fileURL])) { urls in
            shelf.add(urls)
            controller.endFileDrag()
        }
        return true
    }
}
