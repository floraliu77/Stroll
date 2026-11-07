import SwiftUI

/// The bottom panel on the Explore map once exploring has started ("Explore – walk in
/// progress"), and the point-of-interest sheet it opens. Functional placeholder styling:
/// to be matched to Figma.
struct ExploringPanel: View {
    @EnvironmentObject private var session: ExploreSession
    @State private var confirmingEnd = false

    var body: some View {
        VStack(spacing: 14) {
            Capsule().fill(Color.strollBorder).frame(width: 36, height: 5)
            if session.phase == .ended {
                ended
            } else {
                exploring
            }
        }
        .padding(.horizontal, 24).padding(.top, 10).padding(.bottom, 20)
        .frame(maxWidth: .infinity)
        .background(.white, in: UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24))
        .shadow(color: .black.opacity(0.12), radius: 10, y: -4)
        .sheet(isPresented: .constant(session.showsStop)) {
            StopSheet()
                .interactiveDismissDisabled()
                .presentationDragIndicator(.hidden)
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
struct StopSheet: View {
    @EnvironmentObject private var session: ExploreSession

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            if let poi = session.poi {
                Image(poi.image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .accessibilityLabel("Photo of a point of interest")
                if [.story, .finished].contains(session.phase) {
                    Text(poi.name)
                        .font(.title2.bold())
                        .foregroundStyle(Color.strollInk)
                }
            }
            transcript
            controls
        }
        .padding(24)
        .background(Color.strollPaper)
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
                    ForEach(Array(session.transcript.enumerated()), id: \.offset) { index, line in
                        TranscriptLine(text: line.text, isSpeaking: index == session.speaking)
                            .id(index)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .onChange(of: session.speaking) { _, index in
                guard let index else { return }
                withAnimation { proxy.scrollTo(index, anchor: .bottom) }
            }
        }
    }

    @ViewBuilder private var controls: some View {
        VStack(spacing: 10) {
            switch session.phase {
            case .preview:
                pauseButton
            case .prompt:
                PanelButton(title: "Tell me more", symbol: nil, filled: true) { session.tellMeMore() }
                PanelButton(title: "Skip", symbol: nil, filled: false) { session.skip() }
                listeningRow
            case .story:
                listeningRow
                PanelButton(title: "Keep exploring", symbol: nil, filled: false) { session.keepExploring() }
            case .finished:
                PanelButton(title: "Keep exploring", symbol: nil, filled: true) { session.keepExploring() }
                PanelButton(title: "Replay", symbol: "arrow.counterclockwise", filled: false) { session.replay() }
            default:
                EmptyView()
            }
        }
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
            }
        }
    }
}

private struct TranscriptLine: View {
    let text: String
    let isSpeaking: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Capsule()
                .fill(isSpeaking ? Color.strollGreen : .clear)
                .frame(width: 3)
            Text(text)
                .font(.body)
                .foregroundStyle(isSpeaking ? Color.strollInk : Color.strollMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct PanelButton: View {
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
