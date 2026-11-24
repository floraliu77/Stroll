import SwiftUI

/// The Journal tab: every point of interest explored or skipped, newest first. A set walk is one
/// card that opens to its places; places found while exploring freely each have their own card.
/// Place cards expand to show the photo, the story and when it was found; skipped ones hide the
/// story and Listen again (docs/round1-plan.md). Always in the light style, also in dark mode.
struct JournalView: View {
    @EnvironmentObject private var journal: JournalStore
    @EnvironmentObject private var session: ExploreSession
    @StateObject private var player = JournalPlayer()
    @State private var expanded: UUID?
    @State private var openWalks: Set<UUID> = []
    @State private var confirmingClear = false

    private let content = StrollContent.shared

    var body: some View {
        NavigationStack {
            Group {
                if journal.entries.isEmpty {
                    ContentUnavailableView("Nothing here yet",
                                           systemImage: "book.closed",
                                           description: Text("Points of interest you find on a walk will appear here."))
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(journal.items) { item in
                                switch item {
                                case .place(let entry):
                                    placeCard(entry)
                                case .walk(let trip, let walkID, let entries):
                                    WalkJournalCard(walk: content.route(walkID), entries: entries,
                                                    isOpen: openWalks.contains(trip)) {
                                        withAnimation(.snappy) {
                                            if openWalks.contains(trip) { openWalks.remove(trip) } else { openWalks.insert(trip) }
                                        }
                                    } place: { entry in
                                        placeCard(entry, nested: true)
                                    }
                                }
                            }
                        }
                        .padding(16)
                        // Room under the last card so it can scroll up past the floating tab bar.
                        .padding(.bottom, 100)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.strollPaper)
            .navigationTitle("Journal")
            .toolbar {
                if !journal.entries.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear") { confirmingClear = true }
                    }
                }
            }
            .confirmationDialog("Clear the journal?", isPresented: $confirmingClear, titleVisibility: .visible) {
                Button("Clear journal", role: .destructive) {
                    player.stop()
                    journal.clear()
                }
            } message: {
                Text("Removes everything found so far, e.g. before the next participant.")
            }
        }
        .environment(\.colorScheme, .light)
        .onDisappear { player.stop() }
        .onChange(of: isWalking) { _, walking in if walking { player.stop() } }
    }

    /// While a walk is going, the guide owns the audio, so Listen again waits.
    private var isWalking: Bool { session.phase != .idle && session.phase != .ended }

    @ViewBuilder private func placeCard(_ entry: JournalStore.Entry, nested: Bool = false) -> some View {
        if let poi = content.poi(entry.poiID) {
            JournalCard(entry: entry, poi: poi,
                        isExpanded: expanded == entry.id,
                        canListen: !isWalking,
                        nested: nested,
                        player: player) {
                withAnimation(.snappy) { expanded = expanded == entry.id ? nil : entry.id }
            }
        }
    }
}

/// One set walk in the Journal: the walk's photo, name, date and how many places were explored.
/// Opens to the walk's places, in the order they were found.
private struct WalkJournalCard<Place: View>: View {
    let walk: StrollContent.Route?
    let entries: [JournalStore.Entry]
    let isOpen: Bool
    let onToggle: () -> Void
    @ViewBuilder let place: (JournalStore.Entry) -> Place

    /// One row per stop on the route, in route order: the saved find, or nil for a stop that was
    /// passed by ("Skip this stop") or never reached (the walk was ended first).
    private var rows: [(stop: Int, entry: JournalStore.Entry?)] {
        guard let walk else { return entries.enumerated().map { ($0.offset, $0.element) } }
        return walk.stops.enumerated().map { index, stop in (index, entries.first { $0.poiID == stop.poi }) }
    }

    private var explored: Int { entries.filter { $0.outcome == .found }.count }
    private var skipped: Int { entries.filter { $0.outcome == .skipped }.count }
    private var notVisited: Int { rows.filter { $0.entry == nil }.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onToggle) { header }
                .buttonStyle(.plain)
                .accessibilityHint(isOpen ? "Hides the places" : "Shows the places")
            if isOpen {
                VStack(spacing: 0) {
                    ForEach(rows, id: \.stop) { row in
                        Divider().overlay(Color.strollBorder)
                        if let entry = row.entry {
                            place(entry)
                        } else if let walk {
                            MysteryStopRow(category: StrollContent.shared.poi(walk.stops[row.stop].poi)?.category)
                        }
                    }
                }
                .padding(.top, 12)
                .transition(.opacity)
            }
        }
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.strollBorder))
    }

    private var header: some View {
        HStack(spacing: 12) {
            Group {
                if let walk {
                    Image(walk.cover).resizable().scaledToFill()
                } else {
                    Color.strollGreen.opacity(0.15).overlay(Image(systemName: "figure.walk").foregroundStyle(Color.strollGreen))
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(walk?.title ?? "Walk")
                    .font(JournalFont.title)
                    .foregroundStyle(Color.strollInk)
                Text(summary)
                    .font(JournalFont.category)
                    .foregroundStyle(Color.strollMuted)
                if let first = entries.first {
                    Text(first.at.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(Color.strollMuted)
                }
            }
            Spacer(minLength: 0)
            Text("Walk")
                .font(JournalFont.tag).fixedSize()
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(Capsule().fill(Color.strollGreen.opacity(0.15)))
                .foregroundStyle(Color.strollGreen)
            Image(systemName: "chevron.down")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.strollMuted)
                .rotationEffect(.degrees(isOpen ? 180 : 0))
        }
        .contentShape(Rectangle())
    }

    private var summary: String {
        var parts = ["\(explored) explored"]
        if skipped > 0 { parts.append("\(skipped) skipped") }
        if notVisited > 0 { parts.append("\(notVisited) not visited") }
        return parts.joined(separator: " · ")
    }
}

/// A walk stop that wasn't visited. Shows nothing about the place (the same grey picture and
/// "Mystery location" for every one), only its category, so it's still a surprise next time.
private struct MysteryStopRow: View {
    let category: String?

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.strollMuted.opacity(0.15))
                .frame(width: 56, height: 56)
                .overlay(Image(systemName: "questionmark").font(.title3.weight(.semibold)).foregroundStyle(Color.strollMuted))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text("Mystery location")
                    .font(JournalFont.title)
                    .foregroundStyle(Color.strollInk)
                if let category = category.flatMap({ StrollContent.shared.category($0) }) {
                    Label(category.name, systemImage: category.symbol)
                        .labelStyle(JournalCategoryLabel())
                        .foregroundStyle(Color.category(category.id))
                }
            }
            Spacer(minLength: 0)
            Text("Not visited")
                .font(JournalFont.tag)
                .fixedSize()
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(Capsule().fill(Color.strollMuted.opacity(0.15)))
                .foregroundStyle(Color.strollMuted)
        }
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }
}

/// Journal card text sizes, a step smaller than the system defaults so names fit on narrow cards.
/// Still follows the phone's text size setting.
enum JournalFont {
    static let title = Font.subheadline.weight(.semibold)      // 15 pt (was 17)
    static let category = Font.footnote.weight(.semibold)     // 13 pt: 11 pt was too small to read (testing, Nov 24)
    static let categoryIcon = Font.caption2.weight(.semibold) // 11 pt: the icons stay as they were
    static let tag = Font.caption2.weight(.semibold)          // 11 pt (was 12)
}

/// A category on a journal card: the name at `JournalFont.category`, the icon kept smaller.
struct JournalCategoryLabel: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.icon.font(JournalFont.categoryIcon)
            configuration.title.font(JournalFont.category)
        }
    }
}

private struct JournalCard: View {
    let entry: JournalStore.Entry
    let poi: StrollContent.POI
    let isExpanded: Bool
    let canListen: Bool
    /// Inside a walk card: no card of its own, just a row.
    var nested = false
    @ObservedObject var player: JournalPlayer
    /// Opens or closes the card. Only the top row does this, so taps on the details (like
    /// Listen again) never close it by accident.
    let onToggle: () -> Void

    private var category: StrollContent.Category? { StrollContent.shared.category(poi.category) }
    private var found: Bool { entry.outcome == .found }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // The header is identical open or closed; opening only adds the details below it.
            Button(action: onToggle) { header }
                .buttonStyle(.plain)
                .accessibilityHint(isExpanded ? "Closes the details" : "Shows the details")
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) { details }
                    .transition(.opacity)
            }
        }
        .padding(nested ? .vertical : .all, nested ? 12 : 14)
        .background(nested ? .clear : .white, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(nested ? .clear : Color.strollBorder))
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(poi.image)
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 3) {
                Text(poi.name)
                    .font(JournalFont.title)
                    .foregroundStyle(Color.strollInk)
                if let category {
                    Label(category.name, systemImage: category.symbol)
                        .labelStyle(JournalCategoryLabel())
                        .foregroundStyle(Color.category(category.id))
                }
            }
            Spacer(minLength: 0)
            Text(found ? "Explored" : "Skipped")
                .font(JournalFont.tag).fixedSize()
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(Capsule().fill((found ? Color.strollGreen : Color.strollMuted).opacity(0.15)))
                .foregroundStyle(found ? Color.strollGreen : Color.strollMuted)
            Image(systemName: "chevron.down")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.strollMuted)
                .rotationEffect(.degrees(isExpanded ? 180 : 0))
        }
        .contentShape(Rectangle())   // the whole top row is tappable, including the gaps
    }

    @ViewBuilder private var details: some View {
        FillPhoto(name: poi.image, height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .accessibilityLabel("Photo of \(poi.name)" + (poi.altText.map { ". \($0)" } ?? ""))
        if found {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(([poi.reveal] + poi.story).enumerated()), id: \.offset) { _, line in
                    Text(line.text)
                        .font(.body)
                        .foregroundStyle(Color.strollInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            listenButton
        } else {
            Text("You skipped this one.")
                .font(.subheadline)
                .foregroundStyle(Color.strollMuted)
        }
        VStack(alignment: .leading, spacing: 2) {
            Text("\(found ? "Found" : "Skipped") \(entry.at.formatted(date: .abbreviated, time: .shortened))")
            PhotoCreditLine(credit: poi.photoCredit)
        }
        .font(.caption)
        .foregroundStyle(Color.strollMuted)
    }

    private var listenButton: some View {
        let isPlaying = player.playing == entry.id
        return Button {
            if isPlaying {
                player.stop()
            } else {
                player.play(entry.id, lines: [poi.reveal.narration] + poi.story.map(\.narration))
            }
        } label: {
            Label(isPlaying ? "Stop" : "Listen again", systemImage: isPlaying ? "stop.fill" : "play.fill")
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 46)
                .foregroundStyle(Color.strollGreen)
                .overlay(Capsule().stroke(Color.strollGreen, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
        .disabled(!canListen)
        .opacity(canListen ? 1 : 0.4)
    }
}

/// Plays a journal entry's story again, outside a walk.
@MainActor
final class JournalPlayer: ObservableObject {
    @Published private(set) var playing: UUID?
    private let voice = AudioGuide()
    private var task: Task<Void, Never>?

    func play(_ id: UUID, lines: [Narration]) {
        stop()
        playing = id
        task = Task { @MainActor [weak self] in
            for line in lines {
                guard let self, !Task.isCancelled else { return }
                await self.voice.play(line)
            }
            if !Task.isCancelled { self?.playing = nil }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
        voice.stop()
        playing = nil
    }
}

/// "Photo: author, licence" under a photo, linking to the photo's page (Wikimedia Commons), which
/// is what CC BY and CC BY-SA licences ask for. All photos are also listed in Settings → Photo credits.
struct PhotoCreditLine: View {
    let credit: StrollContent.PhotoCredit

    var body: some View {
        if let url = URL(string: credit.source) {
            Link(destination: url) {
                Text("Photo: \(credit.author), \(credit.license)") + Text(" · Source").underline()
            }
            .accessibilityHint("Opens the photo's page")
        } else {
            Text("Photo: \(credit.author), \(credit.license)")
        }
    }
}
