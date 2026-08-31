import Combine
import Foundation

/// Tasks are kept in a single JSON file under Application Support.
/// Small enough to load synchronously at launch and rewrite on every change.
final class TodoStore: ObservableObject {
    @Published var todos: [Todo] = [] {
        didSet { save() }
    }

    private let fileURL: URL
    private let encoder = JSONEncoder()

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? Storage.url(for: "todos.json")
        encoder.outputFormatting = .prettyPrinted
        todos = load()
    }

    // MARK: - Mutations

    func add(_ title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        todos.insert(Todo(title: trimmed), at: 0)
    }

    func toggle(_ todo: Todo) {
        guard let index = todos.firstIndex(where: { $0.id == todo.id }) else { return }
        todos[index].isDone.toggle()
    }

    func remove(_ todo: Todo) {
        todos.removeAll { $0.id == todo.id }
    }

    func clearCompleted() {
        todos.removeAll { $0.isDone }
    }

    var remainingCount: Int {
        todos.filter { !$0.isDone }.count
    }

    // MARK: - Persistence

    private func load() -> [Todo] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? JSONDecoder().decode([Todo].self, from: data)) ?? []
    }

    private func save() {
        guard let data = try? encoder.encode(todos) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
