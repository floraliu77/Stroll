import SwiftUI

/// The Journal tab: every point of interest explored or skipped, newest first. Cards expand to
/// show the photo, the story and when it was found; skipped ones hide the story and Listen
/// again (docs/round1-plan.md). Always in the light style, also in dark mode.
struct JournalView: View {
    @EnvironmentObject private var journal: JournalStore
    @EnvironmentObject private var session: ExploreSession
    @StateObject private var player = JournalPlayer()
    @State private var expanded: UUID?
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
                            ForEach(journal.entries) { entry in
                                if let poi = content.poi(entry.poiID) {
                                    JournalCard(entry: entry, poi: poi,
                                                isExpanded: expanded == entry.id,
                                                canListen: !isWalking,
                                                player: player)
                                        .onTapGesture {
                                            withAnimation(.snappy) { expanded = expanded == entry.id ? nil : entry.id }
                                        }
                                }
                            }
                        }
                        .padding(16)
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
}

private struct JournalCard: View {
    let entry: JournalStore.Entry
    let poi: StrollContent.POI
    let isExpanded: Bool
    let canListen: Bool
    @ObservedObject var player: JournalPlayer

    private var category: StrollContent.Category? { StrollContent.shared.category(poi.category) }
    private var found: Bool { entry.outcome == .found }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // The header is identical open or closed; opening only adds the details below it.
            HStack(spacing: 12) {
                Image(poi.image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 3) {
                    Text(poi.name)
                        .font(.headline)
                        .foregroundStyle(Color.strollInk)
                    if let category {
                        Label(category.name, systemImage: category.symbol)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.category(category.id))
                    }
                }
                Spacer(minLength: 0)
                Text(found ? "Explored" : "Skipped")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Capsule().fill((found ? Color.strollGreen : Color.strollMuted).opacity(0.15)))
                    .foregroundStyle(found ? Color.strollGreen : Color.strollMuted)
                Image(systemName: "chevron.down")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.strollMuted)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) { details }
                    .transition(.opacity)
            }
        }
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.strollBorder))
        .contentShape(RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .contain)
        .accessibilityHint(isExpanded ? "Collapses" : "Shows the details")
    }

    @ViewBuilder private var details: some View {
        Image(poi.image)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .accessibilityLabel("Photo of \(poi.name)")
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
            Text("Photo: \(poi.photoCredit.author), \(poi.photoCredit.license)")
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
