import SwiftUI

struct TodoListView: View {
    @EnvironmentObject private var store: TodoStore
    @EnvironmentObject private var controller: NotchController

    @State private var draft = ""
    @FocusState private var isComposerFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            header
            composer
            list
            footer
        }
        .onChange(of: isComposerFocused) { focused in
            // Keep the panel open while the user is typing.
            controller.isPinned = focused
        }
    }

    private var header: some View {
        HStack {
            Text("Notchi")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(Palette.primaryText)
            Spacer()
            Text(store.remainingCount == 0 ? "all clear" : "\(store.remainingCount) left")
                .font(.system(size: 11))
                .foregroundColor(Palette.secondaryText)
        }
        .frame(height: Layout.headerHeight)
    }

    private var composer: some View {
        HStack(spacing: 8) {
            Image(systemName: "plus")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Palette.mutedText)

            TextField("Add a task", text: $draft)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .foregroundColor(Palette.primaryText)
                .focused($isComposerFocused)
                .onSubmit(commit)
        }
        .padding(.horizontal, 10)
        .frame(height: Layout.composerHeight - 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Palette.primaryText.opacity(0.07))
        )
    }

    private var list: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(store.todos) { todo in
                    TodoRow(todo: todo)
                }
            }
        }
        .frame(height: Layout.listHeight(rowCount: store.todos.count))
        .overlay(alignment: .center) {
            if store.todos.isEmpty {
                Text("Nothing on the list")
                    .font(.system(size: 11))
                    .foregroundColor(Palette.mutedText)
            }
        }
    }

    private var footer: some View {
        HStack {
            Spacer()
            if store.todos.contains(where: { $0.isDone }) {
                Button("Clear completed", action: store.clearCompleted)
                    .buttonStyle(.plain)
                    .font(.system(size: 10))
                    .foregroundColor(Palette.secondaryText)
            }
        }
        .frame(height: Layout.footerHeight)
    }

    private func commit() {
        store.add(draft)
        draft = ""
    }
}

private struct TodoRow: View {
    let todo: Todo

    @EnvironmentObject private var store: TodoStore
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 9) {
            Button {
                store.toggle(todo)
            } label: {
                Image(systemName: todo.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 13))
                    .foregroundColor(todo.isDone ? Palette.accent : Palette.mutedText)
            }
            .buttonStyle(.plain)

            Text(todo.title)
                .font(.system(size: 12))
                .foregroundColor(todo.isDone ? Palette.mutedText : Palette.primaryText)
                .strikethrough(todo.isDone, color: Palette.mutedText)
                .lineLimit(1)

            Spacer(minLength: 4)

            if isHovering {
                Button {
                    store.remove(todo)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Palette.mutedText)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 6)
        .frame(height: Layout.rowHeight)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovering ? Palette.primaryText.opacity(0.06) : .clear)
        )
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: 0.12), value: todo.isDone)
    }
}
