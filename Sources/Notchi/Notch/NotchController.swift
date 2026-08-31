import AppKit
import Combine
import SwiftUI

/// Owns the notch panel and the collapsed <-> expanded transition.
final class NotchController: ObservableObject {
    @Published private(set) var isExpanded = false

    /// Set while the user is typing, so the panel does not close under them.
    @Published var isPinned = false

    private let store: TodoStore
    private var geometry: NotchGeometry?
    private var panel: NotchPanel?
    private var hoverView: HoverView?

    private var expandWork: DispatchWorkItem?
    private var collapseWork: DispatchWorkItem?
    private var cancellables = Set<AnyCancellable>()
    private var escapeMonitor: Any?
    private var outsideClickMonitor: Any?

    init(store: TodoStore) {
        self.store = store
    }

    // MARK: - Lifecycle

    func start() {
        guard let screen = NotchGeometry.preferredScreen() else { return }
        let geometry = NotchGeometry(screen: screen)
        self.geometry = geometry

        let panel = NotchPanel(contentRect: geometry.collapsedFrame)
        let hoverView = HoverView(frame: .init(origin: .zero, size: geometry.collapsedFrame.size))
        hoverView.autoresizingMask = [.width, .height]
        hoverView.onEnter = { [weak self] in self?.scheduleExpand() }
        hoverView.onExit = { [weak self] in self?.scheduleCollapse() }

        let root = NotchRootView(geometry: geometry)
            .environmentObject(store)
            .environmentObject(self)
        let hosting = NSHostingView(rootView: root)
        hosting.frame = hoverView.bounds
        hosting.autoresizingMask = [.width, .height]
        hoverView.addSubview(hosting)

        panel.contentView = hoverView
        panel.orderFront(nil)

        self.panel = panel
        self.hoverView = hoverView

        // Keep the dropdown sized to its content while it is open.
        store.$todos
            .receive(on: RunLoop.main)
            .sink { [weak self] todos in
                guard let self, self.isExpanded else { return }
                self.applyExpandedFrame(rowCount: todos.count, animated: true)
            }
            .store(in: &cancellables)

        installMonitors()
    }

    func repositionForCurrentScreen() {
        guard let screen = NotchGeometry.preferredScreen() else { return }
        geometry = NotchGeometry(screen: screen)
        if isExpanded {
            applyExpandedFrame(rowCount: store.todos.count, animated: false)
        } else {
            collapseNow(animated: false)
        }
    }

    // MARK: - Expand / collapse

    private func scheduleExpand() {
        collapseWork?.cancel()
        guard !isExpanded else { return }
        let work = DispatchWorkItem { [weak self] in self?.expandNow() }
        expandWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Layout.hoverDelay, execute: work)
    }

    private func scheduleCollapse() {
        expandWork?.cancel()
        guard isExpanded, !isPinned else { return }
        let work = DispatchWorkItem { [weak self] in
            guard let self, !self.isPinned else { return }
            self.collapseNow(animated: true)
        }
        collapseWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Layout.closeDelay, execute: work)
    }

    private func expandNow() {
        guard !isExpanded, panel != nil else { return }
        isExpanded = true
        applyExpandedFrame(rowCount: store.todos.count, animated: true)
        panel?.makeKeyAndOrderFront(nil)
    }

    func collapseNow(animated: Bool) {
        guard let panel, let geometry else { return }
        isPinned = false
        isExpanded = false

        let finish = {
            // Ordering out hands key focus back to the frontmost app.
            panel.orderOut(nil)
            panel.setFrame(geometry.collapsedFrame, display: false)
            panel.orderFront(nil)
        }

        guard animated else { return finish() }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = Layout.animationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().setFrame(geometry.expandedFrame(height: geometry.size.height), display: true)
        } completionHandler: {
            finish()
        }
    }

    private func applyExpandedFrame(rowCount: Int, animated: Bool) {
        guard let panel, let geometry else { return }
        let height = Layout.expandedHeight(rowCount: rowCount, notchHeight: geometry.size.height)
        let frame = geometry.expandedFrame(height: height)

        guard animated else { return panel.setFrame(frame, display: true) }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = Layout.animationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().setFrame(frame, display: true)
        }
    }

    // MARK: - Global monitors

    private func installMonitors() {
        escapeMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.isExpanded, event.keyCode == 53 else { return event }
            self.collapseNow(animated: true)
            return nil
        }

        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            guard let self, self.isExpanded else { return }
            self.collapseNow(animated: true)
        }
    }

    deinit {
        if let escapeMonitor { NSEvent.removeMonitor(escapeMonitor) }
        if let outsideClickMonitor { NSEvent.removeMonitor(outsideClickMonitor) }
    }
}
