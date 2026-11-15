import Foundation

/// The participant's journal: every point of interest they explored or skipped, newest first.
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
    }

    @Published private(set) var entries: [Entry] = []

    private let url: URL

    init(url: URL = JournalStore.defaultURL) {
        self.url = url
        load()
    }

    func add(poiID: String, outcome: Outcome, at date: Date) {
        entries.insert(Entry(id: UUID(), poiID: poiID, outcome: outcome, at: date), at: 0)
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
