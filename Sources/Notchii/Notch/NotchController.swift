import AppKit
import Combine
import SwiftUI

/// Owns the notch panel, the closed <-> open transition, and which module
/// the sheet is showing.
///
/// Hover is detected from the global cursor position rather than from a
/// tracking area: the panel sits above the menu bar, so it never has to
/// receive an event to notice the pointer.
final class NotchController: ObservableObject {
    @Published private(set) var isOpen = false
    @Published private(set) var module: NotchModule = .tasks
    @Published private(set) var isShowingSettings = false

    /// Set while the user is typing or dragging, so the sheet does not
    /// close under them.
    @Published var isPinned = false

    private let store: TodoStore
    private let shelf: FileShelfStore
    private let music: MusicController
    private let clipboard: ClipboardStore
    private let focusTimer: FocusTimer
    private let preferences: Preferences

    private var geometry: NotchGeometry?
    private var panel: NotchPanel?

    private var openWork: DispatchWorkItem?
    private var closeWork: DispatchWorkItem?
    private var pendingOpen = false
    private var pendingClose = false
    private var isDraggingFiles = false

    private var cancellables = Set<AnyCancellable>()
    private var monitors: [Any] = []

    private let debug = ProcessInfo.processInfo.environment["NOTCHII_DEBUG"] != nil

    init(
        store: TodoStore,
        shelf: FileShelfStore,
        music: MusicController,
        clipboard: ClipboardStore,
        focusTimer: FocusTimer,
        preferences: Preferences
    ) {
        self.store = store
        self.shelf = shelf
        self.music = music
        self.clipboard = clipboard
        self.focusTimer = focusTimer
        self.preferences = preferences
        self.module = preferences.lastModule
    }

    private func log(_ message: @autoclosure () -> String) {
        guard debug else { return }
        FileHandle.standardError.write(Data((message() + "\n").utf8))
    }

    // MARK: - Lifecycle

    func start() {
        guard let screen = NotchGeometry.preferredScreen() else { return }
        let geometry = NotchGeometry(screen: screen)
        self.geometry = geometry

        let panel = NotchPanel(contentRect: geometry.notchRect)
        // Stays interactive while closed so a dragged file can land on the notch.
        panel.ignoresMouseEvents = false

        let root = NotchRootView(geometry: geometry)
            .environmentObject(store)
            .environmentObject(shelf)
            .environmentObject(music)
            .environmentObject(clipboard)
            .environmentObject(focusTimer)
            .environmentObject(preferences)
            .environmentObject(self)
        panel.contentView = NSHostingView(rootView: root)
        panel.orderFront(nil)
        self.panel = panel

        // Background work follows the settings: music polling costs nothing
        // while neither player is running, and the clipboard is not watched
        // at all unless you asked for the history.
        Publishers.CombineLatest(
            preferences.$enabledModules,
            preferences.$enabledComponents
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] _, _ in
            guard let self else { return }
            let available = preferences.availableModules

            if available.contains(.music) {
                self.music.startPolling()
            } else {
                self.music.stopPolling()
            }

            if available.contains(.clipboard) {
                self.clipboard.start()
            } else {
                self.clipboard.stop()
            }

            if !available.contains(self.module), let first = available.first {
                self.select(first)
            }
        }
        .store(in: &cancellables)

        installMonitors()
        log("started notch=\(geometry.notchRect) real=\(geometry.isRealNotch)")
    }

    func repositionForCurrentScreen() {
        guard let screen = NotchGeometry.preferredScreen() else { return }
        geometry = NotchGeometry(screen: screen)
        if isOpen {
            applyOpenFrame(animated: false)
        } else {
            close(animated: false)
        }
    }

    // MARK: - Modules

    var isFileTrayAvailable: Bool { preferences.availableModules.contains(.files) }

    func select(_ module: NotchModule) {
        guard preferences.availableModules.contains(module) else { return }
        self.module = module
        preferences.lastModule = module
    }

    func toggleSettings() {
        isShowingSettings.toggle()
    }

    func cycle(by offset: Int) {
        let modules = preferences.availableModules
        guard !isShowingSettings, modules.count > 1 else { return }
        let current = modules.firstIndex(of: module) ?? 0
        let next = (current + offset + modules.count) % modules.count
        select(modules[next])
    }

    /// What the sheet should show right now, given what is going on.
    private func contextualModule() -> NotchModule {
        let modules = preferences.availableModules
        if isDraggingFiles, modules.contains(.files) { return .files }
        if music.isPlaying, modules.contains(.music) { return .music }
        if modules.contains(preferences.lastModule) { return preferences.lastModule }
        return modules.first ?? .tasks
    }

    // MARK: - File drags

    func beginFileDrag() {
        guard isFileTrayAvailable else { return }
        isDraggingFiles = true
        isPinned = true
        select(.files)
        if !isOpen { open() }
    }

    func endFileDrag() {
        isDraggingFiles = false
        isPinned = false
    }

    // MARK: - Hover

    private func cursorMoved() {
        guard let geometry, let panel else { return }
        let point = NSEvent.mouseLocation

        if isOpen {
            if panel.frame.insetBy(dx: -6, dy: -6).contains(point) || isPinned {
                cancelClose()
            } else {
                scheduleClose()
            }
        } else if geometry.notchRect.contains(point) {
            scheduleOpen()
        } else {
            cancelOpen()
        }
    }

    private func cancelOpen() {
        openWork?.cancel()
        openWork = nil
        pendingOpen = false
    }

    private func cancelClose() {
        closeWork?.cancel()
        closeWork = nil
        pendingClose = false
    }

    private func scheduleOpen() {
        guard !isOpen, !pendingOpen else { return }
        cancelClose()
        pendingOpen = true
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.pendingOpen = false
            self.open()
        }
        openWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Layout.hoverDelay, execute: work)
    }

    private func scheduleClose() {
        cancelOpen()
        guard isOpen, !pendingClose else { return }
        pendingClose = true
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.pendingClose = false
            guard !self.isPinned else { return }
            self.close(animated: true)
        }
        closeWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Layout.closeDelay, execute: work)
    }

    // MARK: - Open / close

    private func open() {
        guard !isOpen, let panel else { return }
        isShowingSettings = false // always open on content, not on settings
        select(contextualModule())
        isOpen = true
        log("open module=\(module.rawValue)")
        applyOpenFrame(animated: true)
        panel.makeKeyAndOrderFront(nil)
    }

    func close(animated: Bool) {
        guard let panel, let geometry else { return }
        cancelOpen()
        cancelClose()
        isPinned = false
        isDraggingFiles = false
        isOpen = false

        let finish = {
            // Ordering out hands key focus back to the frontmost app.
            panel.orderOut(nil)
            panel.setFrame(geometry.notchRect, display: false)
            panel.orderFront(nil)
        }

        guard animated else { return finish() }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = Layout.animationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().setFrame(
                geometry.windowFrame(height: geometry.size.height),
                display: true
            )
        } completionHandler: {
            finish()
        }
    }

    private func applyOpenFrame(animated: Bool) {
        guard let panel, let geometry else { return }
        let frame = geometry.windowFrame(
            height: Layout.sheetHeight(notchHeight: geometry.size.height)
        )

        guard animated else { return panel.setFrame(frame, display: true) }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = Layout.animationDuration
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.2, 0.9, 0.25, 1.0)
            panel.animator().setFrame(frame, display: true)
        }
    }

    // MARK: - Monitors

    private func installMonitors() {
        let moved: (NSEvent) -> Void = { [weak self] _ in self?.cursorMoved() }

        if let m = NSEvent.addGlobalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDragged],
            handler: moved
        ) { monitors.append(m) }

        if let m = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved], handler: { event in
            moved(event)
            return event
        }) { monitors.append(m) }

        // Escape closes; arrow keys cycle modules.
        if let m = NSEvent.addLocalMonitorForEvents(matching: .keyDown, handler: { [weak self] event in
            guard let self, self.isOpen else { return event }
            switch event.keyCode {
            case 53: // escape
                self.close(animated: true)
                return nil
            case 123 where event.modifierFlags.contains(.command): // cmd + left
                self.cycle(by: -1)
                return nil
            case 124 where event.modifierFlags.contains(.command): // cmd + right
                self.cycle(by: 1)
                return nil
            default:
                return event
            }
        }) { monitors.append(m) }

        // A click anywhere else closes.
        if let m = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown],
            handler: { [weak self] _ in
                guard let self, self.isOpen else { return }
                self.close(animated: true)
            }
        ) { monitors.append(m) }
    }

    deinit {
        monitors.forEach(NSEvent.removeMonitor)
    }
}
