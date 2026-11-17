import Foundation

/// The participant's journal: every point of interest they explored or skipped, newest first.
/// Finds from one set walk are grouped (`items`). Outside walks, each place has one entry: finding
/// it again (another session) moves it to the top instead of adding a second card. Inside a
/// walk's card, a place shows every time that walk is walked.
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
        var outcome = outcome
        if tripID == nil, let old = entries.firstIndex(where: { $0.tripID == nil && $0.poiID == poiID }) {
            // Explored before counts, even if it was skipped this time.
            if entries[old].outcome == .found { outcome = .found }
            entries.remove(at: old)
        }
        entries.insert(Entry(id: UUID(), poiID: poiID, outcome: outcome, at: date, walkID: walkID, tripID: tripID), at: 0)
        save()
    }

    /// Journals saved before one-entry-per-place: keep the newest entry for each place found
    /// outside a walk (marked explored if any of them was).
    private static func oneEntryPerPlace(_ saved: [Entry]) -> [Entry] {
        let foundOnce = Set(saved.filter { $0.tripID == nil && $0.outcome == .found }.map(\.poiID))
        var seen: Set<String> = []
        return saved.compactMap { entry in   // newest first
            guard entry.tripID == nil else { return entry }
            guard seen.insert(entry.poiID).inserted else { return nil }
            guard entry.outcome != .found, foundOnce.contains(entry.poiID) else { return entry }
            return Entry(id: entry.id, poiID: entry.poiID, outcome: .found, at: entry.at)
        }
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
        entries = Self.oneEntryPerPlace(saved)
        if entries.count != saved.count { save() }
    }

    private func save() {
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
