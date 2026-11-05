import Foundation
import Combine
import SQLite3

/// Local status feed written by integrations. An old update is never shown as live.
struct AISession: Codable, Identifiable {
    enum Provider: String, Codable { case claude, codex, grok }
    enum Status: String, Codable { case running, blocked, ready, idle }

    let id: String
    let provider: Provider
    let title: String
    let status: Status
    let url: URL?
    let contextUsed: Int?
    let contextLimit: Int?
    let usage: String?
    let updatedAt: Date
    let avatarShape: String?
    let avatarColor: String?
    let lastSentAt: Date?

    var sentAt: Date { lastSentAt ?? updatedAt }

    func resting() -> AISession {
        AISession(id: id, provider: provider, title: title, status: .idle, url: url,
                  contextUsed: contextUsed, contextLimit: contextLimit, usage: usage,
                  updatedAt: updatedAt, avatarShape: avatarShape, avatarColor: avatarColor,
                  lastSentAt: lastSentAt)
    }
}

final class AISessionStore: ObservableObject {
    @Published private(set) var sessions: [AISession] = []
    @Published private(set) var enabledProviders: Set<AISession.Provider>
    @Published private(set) var pinnedIDs: Set<String> = []

    private struct Feed: Decodable { let sessions: [AISession] }
    private struct Slot: Codable {
        var session: AISession
        var pinned: Bool
        var key: String { "\(session.provider.rawValue):\(session.id)" }
    }
    private let feedURL: URL
    private let defaults = UserDefaults.standard
    private var slots: [Slot]
    private var lastObserved: [String: Double]
    private let trackingStartedAt: Double

    init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        feedURL = support.appendingPathComponent("Notchii/ai-sessions.json")
        enabledProviders = Set((UserDefaults.standard.stringArray(forKey: "aiEnabledProviders") ??
            ["claude", "codex", "grok"]).compactMap(AISession.Provider.init(rawValue:)))
        slots = (UserDefaults.standard.data(forKey: "aiTrackedSlots")
            .flatMap { try? JSONDecoder().decode([Slot].self, from: $0) }) ?? []
        lastObserved = UserDefaults.standard.dictionary(forKey: "aiLastObservedMessages") as? [String: Double] ?? [:]
        trackingStartedAt = UserDefaults.standard.object(forKey: "aiTrackingStartedAt") as? Double
            ?? Date().timeIntervalSince1970
        defaults.set(trackingStartedAt, forKey: "aiTrackingStartedAt")
        refresh()
    }

    func isEnabled(_ provider: AISession.Provider) -> Bool { enabledProviders.contains(provider) }

    func setEnabled(_ provider: AISession.Provider, _ enabled: Bool) {
        if enabled { enabledProviders.insert(provider) } else { enabledProviders.remove(provider) }
        defaults.set(enabledProviders.map(\.rawValue), forKey: "aiEnabledProviders")
        refresh()
    }

    func dismiss(_ session: AISession) {
        let key = key(for: session)
        slots.removeAll { $0.key == key }
        lastObserved[key] = max(lastObserved[key] ?? 0, session.sentAt.timeIntervalSince1970)
        save()
        refresh()
    }

    func isPinned(_ session: AISession) -> Bool { pinnedIDs.contains(key(for: session)) }

    func setPinned(_ session: AISession, _ pinned: Bool) {
        guard let index = slots.firstIndex(where: { $0.key == key(for: session) }) else { return }
        slots[index].pinned = pinned
        save()
        publish()
    }

    func refresh() {
        let now = Date()
        let feed = (try? Data(contentsOf: feedURL))
            .flatMap { try? JSONDecoder.aiFeed.decode(Feed.self, from: $0) }
        let external = feed?.sessions.filter {
            !$0.id.isEmpty && now.timeIntervalSince($0.updatedAt) < 120 &&
            now.timeIntervalSince($0.updatedAt) > -30
        } ?? []
        let local = (enabledProviders.contains(.codex) ? CodexSessions.recent() : []) +
            (enabledProviders.contains(.grok) ? GrokSessions.recent() : [])
        let localKeys = Set(local.map(key(for:)))
        let candidates = (local + external).filter { enabledProviders.contains($0.provider) }
        if defaults.data(forKey: "aiTrackedSlots") == nil {
            let oldDismissed = defaults.dictionary(forKey: "aiDismissedSessions") as? [String: Double] ?? [:]
            slots = Array(candidates.filter {
                $0.sentAt.timeIntervalSince1970 > (oldDismissed[$0.id] ?? 0)
            }.sorted { $0.sentAt > $1.sentAt }.prefix(5)).map { Slot(session: $0, pinned: false) }
        }

        let ordered = candidates.sorted { $0.sentAt < $1.sentAt }
        for candidate in ordered {
            let key = key(for: candidate)
            let sent = candidate.sentAt.timeIntervalSince1970
            let previous = lastObserved[key] ?? 0
            if let index = slots.firstIndex(where: { $0.key == key }) {
                slots[index].session = candidate
            } else if candidate.lastSentAt != nil || localKeys.contains(key) {
                if sent > max(previous, trackingStartedAt) {
                    if slots.count == 5 {
                        guard let oldest = slots.indices.filter({ !slots[$0].pinned })
                            .min(by: { slots[$0].session.sentAt < slots[$1].session.sentAt }) else {
                            lastObserved[key] = max(previous, sent)
                            continue
                        }
                        slots.remove(at: oldest)
                    }
                    slots.append(Slot(session: candidate, pinned: false))
                }
            }
            lastObserved[key] = max(previous, sent)
        }
        let candidateKeys = Set(candidates.map(key(for:)))
        for index in slots.indices where !candidateKeys.contains(slots[index].key) {
            slots[index].session = slots[index].session.resting()
        }
        save()
        publish()
    }

    private func key(for session: AISession) -> String { "\(session.provider.rawValue):\(session.id)" }

    private func save() {
        defaults.set(try? JSONEncoder().encode(slots), forKey: "aiTrackedSlots")
        defaults.set(lastObserved, forKey: "aiLastObservedMessages")
    }

    private func publish() {
        pinnedIDs = Set(slots.filter(\.pinned).map(\.key))
        sessions = slots.sorted {
            if $0.pinned != $1.pinned { return $0.pinned }
            return $0.session.sentAt > $1.session.sentAt
        }.filter { enabledProviders.contains($0.session.provider) }.map(\.session)
    }
}

/// Grok Bot keeps local roster and transcript snapshots in named JSON blobs.
/// Only these two slices are read; account and secret slices are ignored.
private enum GrokSessions {
    static func recent() -> [AISession] {
        let directory = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Grok Bot/sand-client-persistence")
        guard let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else { return [] }
        var roster: [[String: Any]] = []
        var transcripts: [String: [[String: Any]]] = [:]
        for file in files where file.pathExtension == "blob" {
            guard let key = decodeKey(file.deletingPathExtension().lastPathComponent) else { continue }
            let isRoster = key.hasSuffix("roster.last-roster")
            let marker = "transcript.replicas."
            guard isRoster || key.contains(marker) else { continue }
            guard let data = try? Data(contentsOf: file),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let value = json["value"] as? [String: Any] else { continue }
            if isRoster {
                roster = value["rows"] as? [[String: Any]] ?? []
            } else if let id = key.components(separatedBy: marker).last {
                transcripts[id.lowercased()] = value["entries"] as? [[String: Any]] ?? []
            }
        }

        return roster.compactMap { row in
            guard let id = row["id"] as? String,
                  let name = row["name"] as? String,
                  let entries = transcripts[id.lowercased()] else { return nil }
            let sent = entries.filter { $0["kind"] as? String == "message" && $0["role"] as? String == "user" }
                .compactMap { $0["timestampMs"] as? Double }.max() ?? 0
            guard sent > 0, Date().timeIntervalSince1970 - sent / 1000 < 7 * 86400 else { return nil }
            let reply = entries.filter { $0["kind"] as? String == "send-message" }
                .compactMap { $0["timestampMs"] as? Double }.max() ?? 0
            let age = Date().timeIntervalSince1970 - sent / 1000
            let status: AISession.Status = reply < sent && age < 7200 ? .running :
                (reply >= sent && Date().timeIntervalSince1970 - reply / 1000 < 45 ? .ready : .idle)
            return AISession(
                id: id, provider: .grok, title: name, status: status,
                url: nil, contextUsed: nil, contextLimit: nil, usage: nil,
                updatedAt: Date(timeIntervalSince1970: sent / 1000),
                avatarShape: row["avatarShape"] as? String,
                avatarColor: row["avatarColor"] as? String,
                lastSentAt: Date(timeIntervalSince1970: sent / 1000)
            )
        }.sorted { $0.updatedAt > $1.updatedAt }
    }

    private static func decodeKey(_ encoded: String) -> String? {
        let alphabet = Array("abcdefghijklmnopqrstuvwxyz234567")
        var bits = 0
        var count = 0
        var bytes: [UInt8] = []
        for character in encoded.lowercased() {
            guard let value = alphabet.firstIndex(of: character) else { return nil }
            bits = (bits << 5) | value
            count += 5
            if count >= 8 {
                count -= 8
                bytes.append(UInt8((bits >> count) & 255))
                bits &= (1 << count) - 1
            }
        }
        return String(bytes: bytes, encoding: .utf8)
    }
}

/// Read-only discovery of local Codex Desktop threads. The database schema is
/// owned by Codex, so an unavailable or changed database simply yields no rows.
private enum CodexSessions {
    static func recent() -> [AISession] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let base = home.appendingPathComponent(".codex")
        let state = base.appendingPathComponent("state_5.sqlite")
        let history = base.appendingPathComponent("thread_history_1.sqlite")
        var stateDB: OpaquePointer?
        var historyDB: OpaquePointer?
        guard sqlite3_open_v2(state.path, &stateDB, SQLITE_OPEN_READONLY, nil) == SQLITE_OK,
              sqlite3_open_v2(history.path, &historyDB, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            if stateDB != nil { sqlite3_close(stateDB) }
            if historyDB != nil { sqlite3_close(historyDB) }
            return []
        }
        defer { sqlite3_close(stateDB); sqlite3_close(historyDB) }

        let query = """
            SELECT id, COALESCE(NULLIF(name, ''), title) FROM threads
            WHERE archived = 0 AND source = 'vscode'
            ORDER BY updated_at_ms DESC LIMIT 100
            """
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(stateDB, query, -1, &statement, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(statement) }
        var result: [AISession] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let idText = sqlite3_column_text(statement, 0),
                  let titleText = sqlite3_column_text(statement, 1) else { continue }
            let id = String(cString: idText)
            let title = String(cString: titleText).components(separatedBy: .newlines).first ?? "Codex chat"
            guard let sent = latestMessage(in: historyDB, threadID: id),
                  Date().timeIntervalSince(sent) < 7 * 86400 else { continue }
            guard let turn = latestTurn(in: historyDB, threadID: id) else { continue }
            let status: AISession.Status
            if turn.status == "inProgress" && Date().timeIntervalSince(turn.started) < 7200 {
                status = .running
            } else if turn.status == "completed" || turn.status == "inProgress" {
                status = turn.completed.map { Date().timeIntervalSince($0) < 45 } == true ? .ready : .idle
            } else {
                continue
            }
            result.append(AISession(
                id: id, provider: .codex,
                title: String(title.prefix(36)), status: status,
                url: URL(string: "codex://threads/\(id)"),
                contextUsed: nil, contextLimit: nil, usage: nil,
                updatedAt: sent, avatarShape: nil, avatarColor: nil, lastSentAt: sent
            ))
        }
        return result.sorted { $0.updatedAt > $1.updatedAt }
    }

    private static func latestMessage(in db: OpaquePointer?, threadID: String) -> Date? {
        let query = "SELECT MAX(created_at_ms) FROM thread_items WHERE thread_id = ? AND item_type = 'userMessage'"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(statement) }
        sqlite3_bind_text(statement, 1, threadID, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        guard sqlite3_step(statement) == SQLITE_ROW, sqlite3_column_type(statement, 0) != SQLITE_NULL else { return nil }
        return Date(timeIntervalSince1970: Double(sqlite3_column_int64(statement, 0)) / 1000)
    }

    private static func latestTurn(in db: OpaquePointer?, threadID: String) -> (status: String, started: Date, completed: Date?)? {
        let query = "SELECT status, started_at, completed_at FROM thread_turns WHERE thread_id = ? ORDER BY started_at DESC LIMIT 1"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(statement) }
        sqlite3_bind_text(statement, 1, threadID, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        guard sqlite3_step(statement) == SQLITE_ROW,
              let statusText = sqlite3_column_text(statement, 0) else { return nil }
        let completed = sqlite3_column_type(statement, 2) == SQLITE_NULL ? nil :
            Date(timeIntervalSince1970: Double(sqlite3_column_int64(statement, 2)))
        return (String(cString: statusText), Date(timeIntervalSince1970: Double(sqlite3_column_int64(statement, 1))), completed)
    }
}

private extension JSONDecoder {
    static var aiFeed: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
