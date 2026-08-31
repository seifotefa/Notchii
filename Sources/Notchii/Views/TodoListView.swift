import SwiftUI

/// One composer row and the tasks. Nothing else.
struct TodoListView: View {
    @EnvironmentObject private var store: TodoStore
    @EnvironmentObject private var controller: NotchController

    @State private var draft = ""
    @FocusState private var isComposerFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            composer
            ForEach(store.todos.prefix(Layout.visibleRows)) { todo in
                TodoRow(todo: todo)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, Layout.contentPadding)
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
