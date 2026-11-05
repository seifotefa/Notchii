import AppKit
import SwiftUI

struct AIView: View {
    @EnvironmentObject private var store: AISessionStore
    @EnvironmentObject private var controller: NotchController
    @State private var hoveredID: String?
    @State private var trashTargeted = false
    @State private var pinTargeted = false
    @State private var draggingID: String?
    @State private var draggingOffset: CGSize = .zero
    @State private var suppressedClickID: String?
    @State private var trashFrame: CGRect = .zero
    @State private var pinFrame: CGRect = .zero
    private let ticker = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 12) {
            if store.sessions.isEmpty {
                Image(systemName: "sparkles")
                    .font(.system(size: 15))
                    .foregroundColor(Palette.mutedText)
                    .help("No recent AI chats")
            } else {
                HStack(alignment: .top, spacing: 6) {
                    ForEach(store.sessions) { session in
                        bubble(session)
                    }
                    Rectangle()
                        .fill(Palette.hairline)
                        .frame(width: 1, height: 35)
                        .padding(.horizontal, 1)
                    Image(systemName: pinTargeted ? "pin.fill" : "pin")
                        .font(.system(size: 14))
                        .foregroundColor(pinTargeted || draggingID != nil ? Palette.accent : Palette.mutedText)
                        .frame(width: 38, height: 44)
                        .background(Circle().fill(pinTargeted ? Palette.accent.opacity(0.15) : .clear))
                        .background(GeometryReader { geometry in
                            Color.clear.preference(key: PinFrameKey.self, value: geometry.frame(in: .global))
                        })
                        .onPreferenceChange(PinFrameKey.self) { pinFrame = $0 }
                        .help("Drag here to pin or unpin")
                    Image(systemName: trashTargeted ? "trash.fill" : "trash")
                        .font(.system(size: 15))
                        .foregroundColor(trashTargeted || draggingID != nil ? .orange : Palette.mutedText)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(trashTargeted ? Color.orange.opacity(0.12) : .clear))
                        .background(GeometryReader { geometry in
                            Color.clear.preference(key: TrashFrameKey.self, value: geometry.frame(in: .global))
                        })
                        .onPreferenceChange(TrashFrameKey.self) { trashFrame = $0 }
                        .onDrop(of: [.plainText], isTargeted: $trashTargeted) { providers in
                            guard let provider = providers.first else { return false }
                            _ = provider.loadObject(ofClass: NSString.self) { value, _ in
                                guard let id = value as? String else { return }
                                DispatchQueue.main.async {
                                    if let session = store.sessions.first(where: { $0.id == id }) {
                                        store.dismiss(session)
                                    }
                                }
                            }
                            return true
                        }
                        .help("Drag a chat here to remove it")
                }

                if let session = store.sessions.first(where: { $0.id == hoveredID }) {
                    HStack(spacing: 5) {
                        Text(session.provider.rawValue.capitalized)
                            .foregroundColor(providerColor(session.provider))
                        Text("·")
                        Text(session.title).lineLimit(1)
                        if session.status != .running, let context = context(for: session) {
                            Text("· \(context)")
                        }
                    }
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Palette.secondaryText)
                    .frame(maxWidth: 430)
                    .transition(.opacity)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: Layout.contentHeight)
        .onReceive(ticker) { _ in store.refresh() }
        .onAppear { store.refresh() }
    }

    private func bubble(_ session: AISession) -> some View {
        let tint = session.status == .blocked ? Color.orange : providerColor(session.provider)
        return VStack(spacing: 5) {
            Button {
            guard suppressedClickID != session.id else { return }
            if session.provider == .grok, session.url == nil {
                let app = URL(fileURLWithPath: "/Applications/Grok Bot.app")
                NSWorkspace.shared.openApplication(at: app, configuration: .init())
                return
            }
            guard let url = session.url,
                  ["https", "http", "codex"].contains(url.scheme?.lowercased() ?? "") else { return }
            NSWorkspace.shared.open(url)
            } label: {
            ZStack {
                Circle().fill(tint.opacity(0.13)).frame(width: 34, height: 34)
                Circle()
                    .stroke(tint.opacity(session.status == .idle ? 0.25 : 0.7), lineWidth: 1)
                    .frame(width: 34, height: 34)

                if session.status == .running {
                    Circle()
                        .trim(from: 0, to: 0.24)
                        .stroke(tint, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .frame(width: 34, height: 34)
                        .modifier(SpinningRing())
                }

                switch session.status {
                case .ready:
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Palette.accent)
                case .blocked:
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.orange)
                case .running, .idle:
                    providerMark(session)
                }

                if store.isPinned(session) {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(Palette.accent)
                        .offset(x: 14, y: -14)
                }
            }
            .frame(width: 38, height: 38)
            .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(session.url == nil && session.provider != .grok)

            if session.status == .running {
                Text(session.title)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(Palette.secondaryText)
                    .lineLimit(2)
                    .frame(width: 68)
            }
        }
        .frame(width: session.status == .running ? 68 : 38)
        .offset(draggingID == session.id ? draggingOffset : .zero)
        .zIndex(draggingID == session.id ? 1 : 0)
        .highPriorityGesture(
            DragGesture(minimumDistance: 4, coordinateSpace: .global)
                .onChanged { value in
                    draggingID = session.id
                    suppressedClickID = session.id
                    draggingOffset = value.translation
                    controller.isPinned = true
                    trashTargeted = trashFrame.insetBy(dx: -10, dy: -10).contains(value.location)
                    pinTargeted = pinFrame.insetBy(dx: -8, dy: -8).contains(value.location)
                }
                .onEnded { value in
                    if trashFrame.insetBy(dx: -10, dy: -10).contains(value.location) {
                        store.dismiss(session)
                    } else if pinFrame.insetBy(dx: -8, dy: -8).contains(value.location) {
                        store.setPinned(session, !store.isPinned(session))
                    }
                    draggingID = nil
                    draggingOffset = .zero
                    trashTargeted = false
                    pinTargeted = false
                    controller.isPinned = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        if suppressedClickID == session.id { suppressedClickID = nil }
                    }
                }
        )
        .contextMenu {
            Button(store.isPinned(session) ? "Unpin" : "Pin") {
                store.setPinned(session, !store.isPinned(session))
            }
            Button("Remove") { store.dismiss(session) }
        }
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) {
                hoveredID = hovering ? session.id : nil
            }
        }
        .help("\(session.provider.rawValue.capitalized): \(session.title)")
        .accessibilityLabel("\(session.provider.rawValue.capitalized), \(session.status.rawValue), \(session.title)")
    }

    @ViewBuilder
    private func providerMark(_ session: AISession) -> some View {
        if session.provider == .grok, let shape = session.avatarShape, !shape.isEmpty {
            GrokBotMark(shape: shape, color: session.avatarColor ?? "gray")
                .frame(width: 23, height: 23)
        } else if let icon = providerIcon(session.provider) {
            Image(nsImage: icon)
                .resizable()
                .interpolation(.high)
                .frame(width: 19, height: 19)
        } else {
            Image(systemName: session.provider == .codex ? "chevron.left.forwardslash.chevron.right" : "sparkle")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(providerColor(session.provider))
        }
    }

    private func providerIcon(_ provider: AISession.Provider) -> NSImage? {
        let appName: String
        let bundleID: String
        switch provider {
        case .claude:
            appName = "Claude"; bundleID = "com.anthropic.claudefordesktop"
        case .codex:
            appName = "ChatGPT"; bundleID = "com.openai.codex"
        case .grok:
            appName = "Grok Bot"; bundleID = "com.anysphere.sand"
        }
        let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
            ?? URL(fileURLWithPath: "/Applications/\(appName).app")
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return NSWorkspace.shared.icon(forFile: url.path)
    }

    private func providerColor(_ provider: AISession.Provider) -> Color {
        switch provider {
        case .claude: return Color(red: 0.86, green: 0.55, blue: 0.39)
        case .codex: return Color(red: 0.58, green: 0.84, blue: 0.75)
        case .grok: return Color.white.opacity(0.85)
        }
    }

    private func context(for session: AISession) -> String? {
        var details: [String] = []
        if let used = session.contextUsed, let limit = session.contextLimit, limit > 0 {
            details.append("\(Int(Double(used) / Double(limit) * 100))% context")
        }
        if let usage = session.usage, !usage.isEmpty { details.append(usage) }
        return details.isEmpty ? nil : details.joined(separator: " · ")
    }
}

private struct TrashFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) { value = nextValue() }
}

private struct PinFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) { value = nextValue() }
}

private struct GrokBotMark: View {
    let shape: String
    let color: String

    private var tint: Color {
        switch color {
        case "red": return Color(red: 0.98, green: 0.17, blue: 0.27)
        case "brown": return Color(red: 0.65, green: 0.42, blue: 0.31)
        case "cyan": return Color(red: 0.27, green: 0.82, blue: 0.88)
        case "yellow": return Color(red: 0.98, green: 0.75, blue: 0.25)
        case "orange": return Color(red: 0.98, green: 0.55, blue: 0.25)
        default: return Color(red: 0.64, green: 0.66, blue: 0.68)
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if shape == "wedge" {
                    Path { path in
                        let w = geometry.size.width, h = geometry.size.height
                        path.move(to: CGPoint(x: w * 0.38, y: h * 0.05))
                        path.addQuadCurve(to: CGPoint(x: w * 0.67, y: h * 0.14), control: CGPoint(x: w * 0.49, y: -h * 0.03))
                        path.addQuadCurve(to: CGPoint(x: w * 0.97, y: h * 0.52), control: CGPoint(x: w * 1.04, y: h * 0.39))
                        path.addQuadCurve(to: CGPoint(x: w * 0.80, y: h * 0.78), control: CGPoint(x: w * 0.98, y: h * 0.67))
                        path.addQuadCurve(to: CGPoint(x: w * 0.18, y: h * 0.98), control: CGPoint(x: w * 0.43, y: h * 0.97))
                        path.addQuadCurve(to: CGPoint(x: w * 0.05, y: h * 0.73), control: CGPoint(x: -w * 0.02, y: h * 0.91))
                        path.addLine(to: CGPoint(x: w * 0.18, y: h * 0.20))
                        path.addQuadCurve(to: CGPoint(x: w * 0.38, y: h * 0.05), control: CGPoint(x: w * 0.22, y: h * 0.02))
                    }
                    .fill(tint)
                    Capsule().fill(Color.black.opacity(0.85))
                        .frame(width: geometry.size.width * 0.21, height: geometry.size.height * 0.065)
                        .rotationEffect(.degrees(42))
                        .offset(x: geometry.size.width * 0.18, y: -geometry.size.height * 0.15)
                    Capsule().fill(Color.black.opacity(0.85))
                        .frame(width: geometry.size.width * 0.16, height: geometry.size.height * 0.055)
                        .rotationEffect(.degrees(42))
                        .offset(x: geometry.size.width * 0.41, y: -geometry.size.height * 0.21)
                } else {
                    Image(systemName: symbol)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(tint)
                        .padding(2)
                }
            }
        }
    }

    private var symbol: String {
        switch shape {
        case "heart": return "heart.fill"
        case "cloud": return "cloud.fill"
        case "clover": return "suit.club.fill"
        case "tablet", "square", "squircle": return "square.fill"
        case "star": return "star.fill"
        case "sparkle": return "sparkle"
        case "leaf": return "leaf.fill"
        default: return "circle.fill"
        }
    }
}

private struct SpinningRing: ViewModifier {
    @State private var angle = 0.0

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(angle))
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    angle = 360
                }
            }
    }
}
