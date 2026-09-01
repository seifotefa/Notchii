import SwiftUI

/// The to-do list and the focus timer, side by side. Either column can be
/// switched off in Settings; whichever is left takes the whole width.
struct TasksView: View {
    @EnvironmentObject private var preferences: Preferences

    private var showsTodos: Bool { preferences.isEnabled(.todos) }
    private var showsTimer: Bool { preferences.isEnabled(.focusTimer) }

    var body: some View {
        HStack(spacing: 12) {
            if showsTodos {
                TodoSection()
            }
            if showsTodos, showsTimer {
                ColumnDivider()
            }
            if showsTimer {
                FocusTimerColumn()
                    .frame(width: showsTodos ? Layout.timerColumnWidth : nil)
            }
        }
        .frame(height: Layout.contentHeight)
    }
}

private struct TodoSection: View {
    @EnvironmentObject private var store: TodoStore
    @EnvironmentObject private var controller: NotchController

    @State private var draft = ""
    @FocusState private var isComposerFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            composer
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(store.todos) { todo in
                        TodoRow(todo: todo)
                    }
                }
            }
            .frame(maxHeight: .infinity)
        }
        .onChange(of: isComposerFocused) { focused in
            controller.isPinned = focused // keep the sheet open while typing
        }
        .onAppear { isComposerFocused = true }
    }

    private var composer: some View {
        HStack(spacing: 10) {
            Image(systemName: "plus")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Palette.mutedText)

            TextField("", text: $draft, prompt: Text("Add a task").foregroundColor(Palette.mutedText))
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundColor(Palette.primaryText)
                .focused($isComposerFocused)
                .onSubmit {
                    store.add(draft)
                    draft = ""
                }
        }
        .frame(height: Layout.composerHeight)
    }
}

private struct TodoRow: View {
    let todo: Todo

    @EnvironmentObject private var store: TodoStore
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 10) {
            Button {
                store.toggle(todo)
            } label: {
                Image(systemName: todo.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 12))
                    .foregroundColor(todo.isDone ? Palette.accent : Palette.mutedText)
            }
            .buttonStyle(.plain)

            Text(todo.title)
                .font(.system(size: 12))
                .foregroundColor(todo.isDone ? Palette.mutedText : Palette.secondaryText)
                .strikethrough(todo.isDone, color: Palette.mutedText)
                .lineLimit(1)

            Spacer(minLength: 8)

            Button {
                store.remove(todo)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Palette.mutedText)
            }
            .buttonStyle(.plain)
            .opacity(isHovering ? 1 : 0)
        }
        .frame(height: Layout.rowHeight)
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: 0.12), value: todo.isDone)
        .animation(.easeOut(duration: 0.12), value: isHovering)
    }
}

private struct FocusTimerColumn: View {
    @EnvironmentObject private var timer: FocusTimer
    @EnvironmentObject private var controller: NotchController

    /// Only meaningful while `isEditing`; the clock is a plain label otherwise.
    @State private var draft = ""
    @FocusState private var isEditing: Bool

    var body: some View {
        VStack(spacing: 10) {
            clock

            HStack(spacing: 10) {
                Button(action: play) {
                    Image(systemName: timer.isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Palette.primaryText.opacity(0.85))
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(Palette.primaryText.opacity(0.10)))
                }
                .buttonStyle(.plain)

                Button(action: timer.reset) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Palette.mutedText)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .help("Back to \(FocusTimer.format(timer.duration))")
            }
        }
        .frame(maxWidth: .infinity)
        .onChange(of: isEditing) { editing in
            controller.isPinned = editing // do not close while typing a time
            // Losing focus commits. Clicking play pulls focus out of the field
            // before the button's action runs, so without this the typed time
            // would be thrown away and the old one resumed.
            if !editing { commitDraft() }
        }
    }

    /// Editing: a field holding exactly what you typed.
    /// Otherwise: a label. There is no field to hold a stale value.
    @ViewBuilder
    private var clock: some View {
        if isEditing {
            TextField(
                "",
                text: $draft,
                prompt: Text(FocusTimer.format(timer.duration)).foregroundColor(Palette.mutedText)
            )
            .textFieldStyle(.plain)
            .multilineTextAlignment(.center)
            .font(.system(size: 26, weight: .semibold).monospacedDigit())
            .foregroundColor(Palette.primaryText)
            .focused($isEditing)
            .onSubmit(commit)
            .help("Type minutes and seconds, then press Return")
        } else {
            Text(timer.clock)
                .font(.system(size: 26, weight: .semibold).monospacedDigit())
                .foregroundColor(timer.isRunning ? Palette.accent : Palette.primaryText)
                .contentShape(Rectangle())
                .onTapGesture(perform: beginEditing)
                .help("Click to set a new time")
        }
    }

    private func beginEditing() {
        timer.pause()
        draft = ""
        isEditing = true
    }

    /// Applies whatever was typed, without starting it. Safe to call twice:
    /// the draft is consumed, so whichever of blur and submit lands first wins
    /// and the other becomes a no-op.
    private func commitDraft() {
        let text = draft.trimmingCharacters(in: .whitespaces)
        draft = ""
        guard !text.isEmpty else { return }
        timer.setTyped(text)
    }

    /// Return: apply the typed time and start it.
    private func commit() {
        commitDraft()
        isEditing = false
        timer.start()
    }

    /// Play always runs the time that is set, which the blur above has already
    /// updated from the field.
    private func play() {
        timer.toggle()
    }
}
