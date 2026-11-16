import Foundation

/// The participant's journal: every point of interest they explored or skipped, newest first.
/// Finds from one set walk are grouped (`items`).
/// Filled live as they tap Tell me more or Skip, and saved on the phone so it's still there
/// after the walk and after closing the app.
/// Platform-free so it can be checked on a Mac (see Tools/check-walk-model.sh).
@MainActor
final class JournalStore: ObservableObject {
    struct Entry: Codable, Identifiable, Equatable {
        let id: UUID
        let poiID: String
        let outcome: Outcome
        let at: Date
        /// Set walk finds: the walk, and the time it was walked. Nil for finds while exploring
        /// freely (and for entries saved before walks were grouped).
        var walkID: String? = nil
        var tripID: UUID? = nil
    }

    /// What the Journal shows, newest first: a set walk as one item holding its finds, and each
    /// find made while exploring freely on its own.
    enum Item: Identifiable, Equatable {
        case place(Entry)
        case walk(tripID: UUID, walkID: String, entries: [Entry])   // entries in the order found

        var id: UUID {
            switch self {
            case .place(let entry): return entry.id
            case .walk(let tripID, _, _): return tripID
            }
        }
    }

    var items: [Item] {
        var result: [Item] = []
        var walkIndex: [UUID: Int] = [:]
        for entry in entries {   // newest first
            guard let trip = entry.tripID, let walk = entry.walkID else {
                result.append(.place(entry))
                continue
            }
            if let i = walkIndex[trip], case .walk(_, _, let found) = result[i] {
                result[i] = .walk(tripID: trip, walkID: walk, entries: [entry] + found)
            } else {
                walkIndex[trip] = result.count
                result.append(.walk(tripID: trip, walkID: walk, entries: [entry]))
            }
        }
        return result
    }

    @Published private(set) var entries: [Entry] = []

    private let url: URL

    init(url: URL = JournalStore.defaultURL) {
        self.url = url
        load()
    }

    func add(poiID: String, outcome: Outcome, at date: Date, walkID: String? = nil, tripID: UUID? = nil) {
        entries.insert(Entry(id: UUID(), poiID: poiID, outcome: outcome, at: date, walkID: walkID, tripID: tripID), at: 0)
        save()
    }

    /// Empties the journal, e.g. before the next participant.
    func clear() {
        entries = []
        save()
    }

    nonisolated static var defaultURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("journal.json")
    }

    private func load() {
        guard let data = try? Data(contentsOf: url),
              let saved = try? JSONDecoder().decode([Entry].self, from: data) else { return }
        entries = saved
    }

    private func save() {
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
