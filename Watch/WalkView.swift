import SwiftUI

extension Color {
    static let strollGreen = Color(red: 0.184, green: 0.420, blue: 0.310) // brand/green #2F6B4F
}

/// Every watch screen. The watch mirrors the phone's exploring session: it shows what the
/// phone shows and sends taps back, so either device's buttons work.
struct WalkView: View {
    @EnvironmentObject private var mirror: MirrorModel

    var body: some View {
        if mirror.state.paused {
            PausedScreen()
        } else {
            switch mirror.state.phase {
            case .idle: StartScreen()
            case .exploring: ExploringScreen()
            case .preview: PreviewScreen()
            case .prompt: PromptScreen()
            case .story: StoryScreen()
            case .finished: FinishedScreen()
            case .skipping: StatusScreen(title: "Skipped", detail: "Onward")
            case .ended: DoneScreen()
            }
        }
    }
}

// MARK: Screens

private struct StartScreen: View {
    @EnvironmentObject private var mirror: MirrorModel

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text("Stroll").font(.title3.bold())
                Text("Start exploring here or on your iPhone. Your iPhone plays the guide.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                PrimaryButton("Start Exploring") { mirror.send(.start) }
                ProblemText()
            }
        }
    }
}

private struct ExploringScreen: View {
    @EnvironmentObject private var mirror: MirrorModel

    var body: some View {
        FindScreen {
            Spacer(minLength: 0)
            Text("Keep exploring").font(.headline)
            if mirror.state.everythingVisited {
                Text("That's everything nearby")
                    .font(.footnote).foregroundStyle(.secondary)
            } else {
                ListeningDots()
            }
            if mirror.state.foundCount > 0 {
                Text("\(mirror.state.foundCount) found")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.strollGreen)
            }
            Spacer(minLength: 0)
            ControlRow(replay: false, end: true)
        }
    }
}

private struct PreviewScreen: View {
    var body: some View {
        FindScreen {
            POIPhoto(height: 96)
            ControlRow(replay: false)
        }
    }
}

// The photo stays on screen through the question and the story, so people can compare it with
// what's in front of them. Scroll down (or turn the crown) for the buttons.

private struct PromptScreen: View {
    @EnvironmentObject private var mirror: MirrorModel

    var body: some View {
        ScrollingFindScreen {
            POIPhoto(height: 80)
            PrimaryButton("Tell me more") { mirror.send(.tellMeMore) }
            SecondaryButton("Skip") { mirror.send(.skip) }
            ControlRow(replay: true)
        }
    }
}

private struct StoryScreen: View {
    @EnvironmentObject private var mirror: MirrorModel

    var body: some View {
        ScrollingFindScreen {
            POIPhoto(height: 80)
            ListeningDots()
            SecondaryButton("Keep exploring") { mirror.send(.keepExploring) }
            ControlRow(replay: true)
        }
    }
}

private struct FinishedScreen: View {
    @EnvironmentObject private var mirror: MirrorModel

    var body: some View {
        ScrollingFindScreen {
            POIPhoto(height: 80)
            PrimaryButton("Keep exploring") { mirror.send(.keepExploring) }
            SmallButton("Replay", symbol: "arrow.counterclockwise") { mirror.send(.replay) }
        }
    }
}

private struct DoneScreen: View {
    var body: some View {
        VStack(spacing: 8) {
            Spacer(minLength: 0)
            Text("Walk complete").font(.headline)
            Text("Check your phone").font(.footnote).foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
    }
}

private struct PausedScreen: View {
    @EnvironmentObject private var mirror: MirrorModel

    var body: some View {
        VStack(spacing: 12) {
            Spacer(minLength: 0)
            Text("Paused").font(.headline)
            PrimaryButton("Resume", symbol: "play.fill") { mirror.send(.resume) }
            ProblemText()
        }
    }
}

private struct StatusScreen: View {
    let title: String
    let detail: String

    var body: some View {
        FindScreen {
            Spacer(minLength: 0)
            Text(title).font(.headline)
            Text(detail).font(.footnote).foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
    }
}

// MARK: Building blocks

/// The category above the screen's content, and a note if the phone can't be reached.
private struct FindScreen<Content: View>: View {
    @EnvironmentObject private var mirror: MirrorModel
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let category = mirror.category {
                Label(category.name, systemImage: category.symbol)
                    .font(.footnote.weight(.semibold))
                    .labelStyle(GreenIconLabelStyle())
            }
            VStack(spacing: 6) {
                content
                ProblemText()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

/// Like FindScreen, but scrolls, for screens with the photo and buttons.
private struct ScrollingFindScreen<Content: View>: View {
    @EnvironmentObject private var mirror: MirrorModel
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                if let category = mirror.category {
                    Label(category.name, systemImage: category.symbol)
                        .font(.footnote.weight(.semibold))
                        .labelStyle(GreenIconLabelStyle())
                }
                VStack(spacing: 6) {
                    content
                    ProblemText()
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

/// The current point of interest's photo.
private struct POIPhoto: View {
    @EnvironmentObject private var mirror: MirrorModel
    let height: CGFloat

    var body: some View {
        if let poi = mirror.poi {
            Image(poi.image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .accessibilityLabel("Photo of a point of interest")
        }
    }
}

/// Shown when a tap couldn't reach the phone.
private struct ProblemText: View {
    @EnvironmentObject private var mirror: MirrorModel

    var body: some View {
        if let problem = mirror.problem {
            Text(problem)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

private struct ControlRow: View {
    @EnvironmentObject private var mirror: MirrorModel
    let replay: Bool
    var end = false

    var body: some View {
        HStack(spacing: 4) {
            if replay { SmallButton("Replay", symbol: "arrow.counterclockwise") { mirror.send(.replay) } }
            SmallButton("Pause", symbol: "pause.fill") { mirror.send(.pause) }
            if end { SmallButton("End", symbol: "stop.fill") { mirror.send(.end) } }
        }
    }
}

private struct PrimaryButton: View {
    let title: String
    let symbol: String?
    let action: () -> Void

    init(_ title: String, symbol: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.symbol = symbol
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            if let symbol { Label(title, systemImage: symbol) } else { Text(title) }
        }
        .font(.body.weight(.bold))
        .foregroundStyle(Color.white)
        .tint(.strollGreen)
        .buttonStyle(.borderedProminent)
    }
}

private struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(title, action: action)
            .font(.body.weight(.bold))
            .buttonStyle(.bordered)
    }
}

private struct SmallButton: View {
    let title: String
    let symbol: String
    let action: () -> Void

    init(_ title: String, symbol: String, action: @escaping () -> Void) {
        self.title = title
        self.symbol = symbol
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.strollGreen)
                .frame(minHeight: 32)
        }
        .buttonStyle(.plain)
    }
}

private struct GreenIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.icon.foregroundStyle(Color.strollGreen)
            configuration.title
        }
    }
}

/// Three green dots that blink in turn while narration plays.
struct ListeningDots: View {
    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.4)) { context in
            let step = Int(context.date.timeIntervalSinceReferenceDate / 0.4) % 3
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color.strollGreen)
                        .frame(width: 6, height: 6)
                        .opacity(i == step ? 1 : 0.3)
                }
            }
        }
        .accessibilityHidden(true)
    }
}
