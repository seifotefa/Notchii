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

    @State private var draft = ""
    @FocusState private var isEditing: Bool

    var body: some View {
        VStack(spacing: 10) {
            clock

            HStack(spacing: 10) {
                Button(action: timer.toggle) {
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
            if editing {
                // Start a fresh entry rather than appending to the time shown.
                draft = ""
            } else {
                // Commit on the way out, so clicking straight onto play runs
                // the time that was just typed.
                timer.setTyped(draft)
                draft = timer.clock
            }
        }
    }

    /// Return on an empty field just starts the time already set; otherwise
    /// it takes what was typed. Anything unparseable clears so it can be
    /// retyped, rather than silently snapping back.
    private func submit() {
        let text = draft.trimmingCharacters(in: .whitespaces)
        if text.isEmpty {
            timer.start()
        } else if !timer.startTyped(text) {
            draft = ""
        }
    }

    /// Running: just the countdown. Stopped: type a time and press Return.
    @ViewBuilder
    private var clock: some View {
        if timer.isRunning {
            Text(timer.clock)
                .font(.system(size: 26, weight: .semibold).monospacedDigit())
                .foregroundColor(Palette.accent)
        } else {
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
            .onAppear { draft = timer.clock }
            .onSubmit(submit)
            .help("Type minutes and seconds, then press Return")
        }
    }
}
