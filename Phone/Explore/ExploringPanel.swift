import SwiftUI

/// The bottom panel on the Explore map once exploring has started ("Explore – walk in
/// progress"), and the point-of-interest sheet it opens. Functional placeholder styling:
/// to be matched to Figma.
struct ExploringPanel: View {
    @EnvironmentObject private var session: ExploreSession
    @State private var confirmingEnd = false
    /// Height of this panel from its top edge to the bottom of the screen: the story sheet slides
    /// down to exactly this, so it covers the panel instead of sinking below it.
    @State private var panelHeight: CGFloat = 0

    var body: some View {
        VStack(spacing: 14) {
            if session.phase == .ended {
                ended
            } else {
                exploring
            }
        }
        .padding(.horizontal, 24).padding(.top, 24).padding(.bottom, 20)   // no grabber: these panels can't be dragged
        .frame(maxWidth: .infinity)
        // The card runs down behind the floating tab bar, so the map doesn't show through.
        .background {
            UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24)
                .fill(Color.strollPaper)
                .ignoresSafeArea(edges: .bottom)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { panelHeight = $0 }
        }
        .shadow(color: .black.opacity(0.12), radius: 10, y: -4)
        // While a place's sheet is up, this panel is hidden, so it never shows above the sheet
        // when the sheet is slid down.
        .opacity(session.showsStop ? 0 : 1)
        .allowsHitTesting(!session.showsStop)
        .accessibilityHidden(session.showsStop)
        .sheet(isPresented: .constant(session.showsStop)) {
            StopSheet(collapsedHeight: panelHeight)
                .interactiveDismissDisabled()
        }
        .confirmationDialog("End exploring?", isPresented: $confirmingEnd, titleVisibility: .visible) {
            Button("End", role: .destructive) { session.end() }
        } message: {
            Text("You can see what you found in your Journal.")
        }
    }

    private var exploring: some View {
        VStack(spacing: 14) {
            VStack(spacing: 4) {
                Text(session.paused ? "Paused" : "Exploring")
                    .font(.title3.bold())
                    .foregroundStyle(Color.strollInk)
                Text(statusText)
                    .font(.subheadline)
                    .foregroundStyle(Color.strollMuted)
                    .multilineTextAlignment(.center)
                if !session.visits.isEmpty {
                    Text(foundText)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.strollGreen)
                }
            }
            HStack(spacing: 12) {
                if session.paused {
                    PanelButton(title: "Resume", symbol: "play.fill", filled: true) { session.resume() }
                } else {
                    PanelButton(title: "Pause", symbol: "pause.fill", filled: false) { session.pause() }
                }
                PanelButton(title: "End", symbol: "stop.fill", filled: false) { confirmingEnd = true }
            }
        }
    }

    private var ended: some View {
        VStack(spacing: 14) {
            VStack(spacing: 4) {
                Text("Walk complete")
                    .font(.title3.bold())
                    .foregroundStyle(Color.strollInk)
                Text(session.visits.isEmpty ? "Nothing found this time." : foundText)
                    .font(.subheadline)
                    .foregroundStyle(Color.strollMuted)
            }
            PanelButton(title: "Done", symbol: nil, filled: true) { session.reset() }
        }
    }

    private var statusText: String {
        if session.everythingVisited {
            return "That's every point of interest nearby. Tap End when you're done."
        }
        return "Wander anywhere. Your phone will buzz when you're near a point of interest."
    }

    private var foundText: String {
        let n = session.foundCount
        return n == 1 ? "1 point of interest found" : "\(n) points of interest found"
    }
}

/// One point of interest: photo, then the prompt, then the story, with the transcript of
/// everything said so far.
///
/// A sheet that can be dragged, like a place in Google Maps: full height to read, half to see
/// the map too, or slid down to a small bar (photo, title, the line being read, and the main
/// buttons) with the map behind it usable. People felt lost listening with the map hidden.
struct StopSheet: View {
    @EnvironmentObject private var session: ExploreSession
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverOn
    @AccessibilityFocusState private var focusedControl: MainControl?
    private enum MainControl { case tellMeMore, pause, keepExploring }
    /// Opens full height, as before; the participant can slide it down.
    @State private var detent: PresentationDetent = .large
    /// The panel behind the sheet (Exploring, or the walk's next stop): slid down, the sheet is
    /// exactly as tall, so the two never show at once.
    var collapsedHeight: CGFloat = 0
    private var collapsed: PresentationDetent { .height(max(collapsedHeight, 220)) }

    /// One voice at a time: while the guide is talking, VoiceOver doesn't read the transcript
    /// (it's the same words). Paused or finished, everything can be read again.
    private var guideTalking: Bool { voiceOverOn && session.narrating && !session.paused }

    var body: some View {
        Group {
            if detent == collapsed { compact } else { full }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color.strollPaper)
        .presentationDetents([collapsed, .medium, .large], selection: $detent)
        .presentationDragIndicator(.visible)
        // Half height or less, the map behind can be moved and zoomed.
        .presentationBackgroundInteraction(.enabled(upThrough: .medium))
        .presentationBackground(Color.strollPaper)
    }

    /// Slid down: one row with the photo, title and the line being read, then the main buttons.
    /// The room above and below the content row is shared evenly, so the bar looks balanced at
    /// whatever height the panel behind it has.
    private var compact: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 20)
            HStack(alignment: .center, spacing: 14) {
                if let poi = session.poi {
                    Image(poi.image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 4) {
                    header
                    Text(title)
                        .font(.title3.bold())
                        .foregroundStyle(Color.strollInk)
                        .lineLimit(1)
                    if let line = currentLine {
                        Text(line)
                            .font(.subheadline)
                            .foregroundStyle(Color.strollMuted)
                            .lineLimit(2)
                            .accessibilityHidden(guideTalking)
                    }
                }
            }
            Spacer(minLength: 16)
            compactControls
            Spacer(minLength: 12)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)   // below the grabber
        .padding(.bottom, 8)
    }

    /// The place's name once the story starts; before that, it stays unnamed, as in the full sheet.
    private var title: String {
        if let poi = session.poi, [.story, .finished].contains(session.phase) { return poi.name }
        return "Something to notice nearby"
    }

    private var currentLine: String? {
        if let index = session.speaking, lines.indices.contains(index) { return lines[index].text }
        return lines.last?.text
    }

    @ViewBuilder private var compactControls: some View {
        HStack(spacing: 10) {
            switch session.phase {
            case .preview:
                pauseButton
            case .prompt:
                PanelButton(title: "Tell me more", symbol: nil, filled: true) { session.tellMeMore() }
                PanelButton(title: "Skip", symbol: nil, filled: false) { session.skip() }
            case .story:
                pauseButton
                PanelButton(title: continueTitle, symbol: nil, filled: false) { session.keepExploring() }
            case .finished:
                PanelButton(title: continueTitle, symbol: nil, filled: true) { session.keepExploring() }
            default:
                EmptyView()
            }
        }
    }

    private var full: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            if let poi = session.poi {
                // At half height the photo makes way for the text and buttons (the small bar and
                // the full sheet both show it).
                if detent == .large {
                    FillPhoto(name: poi.image, height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .accessibilityLabel(poi.altText.map { "Photo: \($0)" } ?? "Photo of a point of interest")
                }
                if [.story, .finished].contains(session.phase) {
                    Text(poi.name)
                        .font(.title2.bold())
                        .foregroundStyle(Color.strollInk)
                }
            }
            transcript
                .accessibilityHidden(guideTalking)
                .layoutPriority(-1)   // the transcript scrolls, so it gives up room first, never the header
            controls
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)   // clear of the grabber at every height, so the category never touches the edge
        .padding(.bottom, 24)
        // The buttons change with each phase. Without this, VoiceOver jumps to whatever is
        // left, often a long line of text, and reads it over the guide. Landing on the main
        // button only says its short name ("Keep exploring" also signals the story is over).
        .onChange(of: session.phase) { _, phase in
            guard voiceOverOn else { return }
            switch phase {
            case .prompt: focusedControl = .tellMeMore
            case .story: focusedControl = .pause   // not Keep exploring: a stray tap would skip the story
            case .finished: focusedControl = .keepExploring
            default: break
            }
        }
    }

    private var header: some View {
        HStack {
            if let category = session.category {
                Label(category.name, systemImage: category.symbol)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.category(category.id))
            }
            Spacer()
            if session.paused {
                Label("Paused", systemImage: "pause.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color.strollGreen, in: Capsule())
            }
        }
    }

    private var transcript: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if session.phase == .preview {
                        Text("Something to notice nearby…")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Color.strollInk)
                    }
                    ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                        TranscriptLine(text: line.text,
                                       isSpeaking: index == session.speaking,
                                       isDark: index == session.speaking || session.phase == .finished || session.reading)
                            .id(index)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .onChange(of: session.speaking) { _, index in
                guard let index else { return }
                // Keep the line being read in view at the bottom; scroll up for what's been
                // said and down for what's coming.
                withAnimation { proxy.scrollTo(index, anchor: .bottom) }
            }
        }
    }

    /// Once the story starts, every line is shown at once (the line being read is dark, the
    /// rest grey), so people can read ahead. Before that only what's been said, so the
    /// question doesn't give away its answer.
    private var lines: [Narration] {
        guard let poi = session.poi, session.phase == .story || session.phase == .finished else {
            return session.transcript
        }
        return [poi.prompt.narration, poi.reveal.narration] + poi.story.map(\.narration)
    }

    @ViewBuilder private var controls: some View {
        VStack(spacing: 10) {
            switch session.phase {
            case .preview:
                pauseButton
            case .prompt:
                PanelButton(title: "Tell me more", symbol: nil, filled: true) { session.tellMeMore() }
                    .accessibilityFocused($focusedControl, equals: .tellMeMore)
                PanelButton(title: "Skip", symbol: nil, filled: false) { session.skip() }
                listeningRow
            case .story:
                listeningRow
                PanelButton(title: continueTitle, symbol: nil, filled: false) { session.keepExploring() }
            case .finished:
                PanelButton(title: continueTitle, symbol: nil, filled: true) { session.keepExploring() }
                    .accessibilityFocused($focusedControl, equals: .keepExploring)
                PanelButton(title: "Replay", symbol: "arrow.counterclockwise", filled: false) { session.replay() }
            default:
                EmptyView()
            }
        }
    }

    /// Keep exploring, or on a set walk Continue walk (Finish walk at the last stop).
    private var continueTitle: String {
        guard let route = session.route else { return "Keep exploring" }
        return session.stopIndex >= route.stops.count - 1 ? "Finish walk" : "Continue walk"
    }

    /// Replay and Pause side by side, while narration is playing.
    private var listeningRow: some View {
        HStack(spacing: 10) {
            PanelButton(title: "Replay", symbol: "arrow.counterclockwise", filled: false) { session.replay() }
            pauseButton
        }
    }

    private var pauseButton: some View {
        Group {
            if session.paused {
                PanelButton(title: "Resume", symbol: "play.fill", filled: true) { session.resume() }
            } else {
                PanelButton(title: "Pause", symbol: "pause.fill", filled: false) { session.pause() }
                    .accessibilityFocused($focusedControl, equals: .pause)
            }
        }
    }
}

private struct TranscriptLine: View {
    let text: String
    let isSpeaking: Bool
    var isDark = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Capsule()
                .fill(isSpeaking ? Color.strollGreen : .clear)
                .frame(width: 3)
            Text(text)
                .font(.body)
                .foregroundStyle(isDark ? Color.strollInk : Color.strollMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct PanelButton: View {
    let title: String
    let symbol: String?
    let filled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if let symbol { Label(title, systemImage: symbol) } else { Text(title) }
            }
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 50)
            .foregroundStyle(filled ? .white : Color.strollGreen)
            .background(filled ? Color.strollGreen : .white, in: Capsule())
            .overlay(Capsule().stroke(filled ? .clear : Color.strollGreen, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }
}
