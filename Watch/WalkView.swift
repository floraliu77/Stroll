import SwiftUI

extension Color {
    static let strollGreen = Color(red: 0.184, green: 0.420, blue: 0.310) // brand/green #2F6B4F
}

/// Every watch screen. The watch mirrors the phone's exploring session: it shows what the
/// phone shows and sends taps back, so either device's buttons work.
struct WalkView: View {
    @EnvironmentObject private var mirror: MirrorModel

    var body: some View {
        NavigationStack {
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
                case .skipping: SkippingScreen()
                case .ended: DoneScreen()
                }
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
                if mirror.isStarting {
                    ProgressView()
                    Text("Starting…").font(.footnote).foregroundStyle(.secondary)
                } else {
                    PrimaryButton("Start Exploring") { mirror.send(.start) }
                }
                ProblemText()
            }
        }
    }
}

private struct ExploringScreen: View {
    @EnvironmentObject private var mirror: MirrorModel

    var body: some View {
        SpotScreen {
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
            HStack(spacing: 8) {
                SecondaryButton("Pause") { mirror.send(.pause) }
                SecondaryButton("End") { mirror.send(.end) }
            }
        }
    }
}

// Every screen for a point of interest uses SpotScreen with the photo at the same size, so
// nothing jumps between them, and the photo stays up so people can compare it with what's in
// front of them. Replay and Pause sit on the photo's top corners, away from the main buttons.

private struct PreviewScreen: View {
    var body: some View {
        SpotScreen {
            POIPhoto(controls: [.pause])
        }
    }
}

private struct PromptScreen: View {
    @EnvironmentObject private var mirror: MirrorModel

    var body: some View {
        SpotScreen {
            POIPhoto(controls: [.replay, .pause])
            PrimaryButton("Tell me more") { mirror.send(.tellMeMore) }
            SecondaryButton("Skip") { mirror.send(.skip) }
        }
    }
}

private struct StoryScreen: View {
    @EnvironmentObject private var mirror: MirrorModel

    var body: some View {
        SpotScreen {
            POIPhoto(controls: [.replay, .pause])
            ListeningDots()
            SecondaryButton("Keep exploring") { mirror.send(.keepExploring) }
        }
    }
}

private struct FinishedScreen: View {
    @EnvironmentObject private var mirror: MirrorModel

    var body: some View {
        SpotScreen {
            POIPhoto(controls: [.replay])
            PrimaryButton("Keep exploring") { mirror.send(.keepExploring) }
        }
    }
}

private struct SkippingScreen: View {
    var body: some View {
        SpotScreen {
            POIPhoto()
            Text("Skipped").font(.headline)
            Text("Onward").font(.footnote).foregroundStyle(.secondary)
        }
    }
}

private struct DoneScreen: View {
    @EnvironmentObject private var mirror: MirrorModel

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text("Walk complete").font(.headline)
                Text("Check your phone").font(.footnote).foregroundStyle(.secondary)
                PrimaryButton("Done") { mirror.send(.reset) }
                ProblemText()
            }
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

// MARK: Building blocks

/// The layout for exploring and every point-of-interest screen: the category, then the
/// content (scrolls if it doesn't fit).
private struct SpotScreen<Content: View>: View {
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

/// The current point of interest's photo, the same size on every screen, with Replay
/// (top left) and Pause (top right) on it.
private struct POIPhoto: View {
    enum Control { case replay, pause }

    @EnvironmentObject private var mirror: MirrorModel
    var controls: [Control] = []

    var body: some View {
        if let poi = mirror.poi {
            Image(poi.image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .accessibilityLabel("Photo of a point of interest")
                .overlay(alignment: .topLeading) {
                    if controls.contains(.replay) {
                        PhotoButton("Replay", symbol: "arrow.counterclockwise") { mirror.send(.replay) }
                    }
                }
                .overlay(alignment: .topTrailing) {
                    if controls.contains(.pause) {
                        PhotoButton("Pause", symbol: "pause.fill") { mirror.send(.pause) }
                    }
                }
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

/// A small round icon button on a corner of the photo.
private struct PhotoButton: View {
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
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(.black.opacity(0.55), in: Circle())
        }
        .buttonStyle(.plain)
        .padding(4)
        .accessibilityLabel(title)
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
        .controlSize(.small)   // shorter, so Skip shows under Tell me more without scrolling
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
            .controlSize(.small)
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
