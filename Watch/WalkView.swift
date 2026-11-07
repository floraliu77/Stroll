import SwiftUI

extension Color {
    static let strollGreen = Color(red: 0.184, green: 0.420, blue: 0.310) // brand/green #2F6B4F
}

/// Every watch screen, matching the web prototype.
struct WalkView: View {
    @EnvironmentObject private var walk: WalkModel

    var body: some View {
        if walk.paused {
            PausedScreen()
        } else {
            switch walk.screen {
            case .setup: SetupScreen()
            case .waiting: WaitingScreen()
            case .alert: AlertScreen()
            case .prompt: PromptScreen()
            case .story: StoryScreen()
            case .finished: FinishedScreen()
            case .skipping: StatusScreen(title: "Skipped", detail: "Onward")
            case .done: DoneScreen()
            }
        }
    }
}

// MARK: Screens

private struct SetupScreen: View {
    @EnvironmentObject private var app: WatchAppState

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text("Stroll").font(.title3.bold())
                Text("Put in your earbuds, then tap Get ready.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                if app.isPreparing {
                    ProgressView()
                } else {
                    PrimaryButton("Get ready") { Task { await app.getReady() } }
                }
                if let problem = app.setupProblem {
                    Text(problem)
                        .font(.footnote)
                        .foregroundStyle(Color.strollGreen)
                        .multilineTextAlignment(.center)
                    Button("Continue without earbuds") { app.continueWithoutEarbuds() }
                        .font(.footnote)
                }
            }
        }
    }
}

private struct WaitingScreen: View {
    var body: some View {
        FindScreen {
            Spacer(minLength: 0)
            Text("Keep walking").font(.headline)
            ListeningDots()
            Spacer(minLength: 0)
            ControlRow(replay: false)
        }
    }
}

private struct AlertScreen: View {
    @EnvironmentObject private var walk: WalkModel

    var body: some View {
        FindScreen {
            if let find = walk.find {
                Image(find.image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 96)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .accessibilityLabel("Preview: \(find.name)")
            }
            ControlRow(replay: false)
        }
    }
}

private struct PromptScreen: View {
    @EnvironmentObject private var walk: WalkModel

    var body: some View {
        FindScreen {
            PrimaryButton("Tell me more") { walk.tellMeMore() }
            SecondaryButton("Skip") { walk.skip() }
            ControlRow(replay: true)
        }
    }
}

private struct StoryScreen: View {
    @EnvironmentObject private var walk: WalkModel

    var body: some View {
        FindScreen {
            Spacer(minLength: 0)
            ListeningDots()
            Spacer(minLength: 0)
            SecondaryButton(walk.isLastFind ? "Finish walk" : "Next stop") { walk.nextStop() }
            ControlRow(replay: true)
        }
    }
}

private struct FinishedScreen: View {
    @EnvironmentObject private var walk: WalkModel

    var body: some View {
        FindScreen {
            Spacer(minLength: 0)
            PrimaryButton("Continue walking") { walk.continueWalking() }
            SmallButton("Replay", symbol: "arrow.counterclockwise") { walk.replay() }
        }
    }
}

private struct DoneScreen: View {
    @EnvironmentObject private var walk: WalkModel

    var body: some View {
        VStack(spacing: 8) {
            Spacer(minLength: 0)
            Text("Walk complete").font(.headline)
            Text("Check your phone").font(.footnote).foregroundStyle(.secondary)
            Spacer(minLength: 0)
            SmallButton("Replay", symbol: "arrow.counterclockwise") { walk.replay() }
        }
    }
}

private struct PausedScreen: View {
    @EnvironmentObject private var walk: WalkModel

    var body: some View {
        VStack(spacing: 12) {
            Spacer(minLength: 0)
            Text("Paused").font(.headline)
            PrimaryButton("Resume", symbol: "play.fill") { walk.resume() }
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

/// "1 of 4" and the category, above the screen's content.
private struct FindScreen<Content: View>: View {
    @EnvironmentObject private var walk: WalkModel
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let find = walk.find {
                Text("\(find.number) of \(Walk.finds.count)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.strollGreen)
                Label(find.category, systemImage: find.symbol)
                    .font(.footnote.weight(.semibold))
                    .labelStyle(GreenIconLabelStyle())
            }
            VStack(spacing: 6) { content }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct ControlRow: View {
    @EnvironmentObject private var walk: WalkModel
    let replay: Bool

    var body: some View {
        HStack(spacing: 4) {
            if replay { SmallButton("Replay", symbol: "arrow.counterclockwise") { walk.replay() } }
            SmallButton("Pause", symbol: "pause.fill") { walk.pause() }
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
