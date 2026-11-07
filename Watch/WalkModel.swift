import Foundation
import Combine

/// Plays recorded narration. `play` returns when the clip ends or `stop()` is called.
@MainActor
protocol Narrator: AnyObject {
    func play(_ line: Narration) async
    func stop()
    func pause()
    func resume()
}

/// The wrist tap.
@MainActor
protocol Haptics {
    func buzz()
}

/// The walk, as a state machine. Same flow as the web prototype, except that each find
/// starts when the moderator triggers it from the iPhone instead of on a timer.
/// Platform-free so it can be checked without a watch (see Tools/check-walk-model.sh).
@MainActor
final class WalkModel: ObservableObject {
    @Published private(set) var screen: WalkScreen = .setup
    @Published private(set) var findIndex: Int?
    @Published private(set) var paused = false
    @Published private(set) var outcomes: [Int: Outcome] = [:]

    var find: Find? { findIndex.map { Walk.finds[$0] } }
    var isLastFind: Bool { findIndex == Walk.finds.count - 1 }

    /// Status changes and participant actions, forwarded to the moderator's iPhone.
    var onEvent: ((WatchEvent) -> Void)?

    // Timings from the web prototype, in seconds.
    static let buzzToVoice = 1.5      // buzz, then a pause before the cue
    static let cueToPrompt = 0.35
    static let betweenStoryLines = 0.7
    static let beforeDoneBuzz = 0.6

    private let narrator: Narrator
    private let haptics: Haptics
    private var task: Task<Void, Never>?
    private var replayLines: [Narration] = []
    private var isReady = false

    init(narrator: Narrator, haptics: Haptics) {
        self.narrator = narrator
        self.haptics = haptics
    }

    var status: WalkStatus {
        WalkStatus(screen: screen, find: findIndex, paused: paused, outcomes: outcomes)
    }

    // MARK: Moderator

    func handle(_ command: RemoteCommand) {
        switch command {
        case .trigger(let find): trigger(find: find)
        case .reset: reset()
        case .requestStatus: sendStatus()
        }
    }

    func trigger(find index: Int) {
        guard isReady, Walk.finds.indices.contains(index) else { return }
        let find = Walk.finds[index]
        run { [self] in
            findIndex = index
            replayLines = [find.narration(.prompt)]
            set(.alert)
            haptics.buzz()
            try await pausableSleep(Self.buzzToVoice)
            try await say(find.narration(.cue))
            set(.prompt)
            try await pausableSleep(Self.cueToPrompt)
            try await say(find.narration(.prompt))
        }
    }

    func reset() {
        cancelRun()
        findIndex = nil
        outcomes = [:]
        replayLines = []
        set(isReady ? .waiting : .setup)
    }

    // MARK: Participant

    /// Called once earbuds and the workout session are set up.
    func ready() {
        isReady = true
        record(.getReady)
        if screen == .setup { set(.waiting) }
    }

    func tellMeMore() {
        guard screen == .prompt, let index = findIndex else { return }
        record(.tellMeMore)
        outcomes[index] = .found
        let lines = Walk.finds[index].storyLines
        run { [self] in
            replayLines = lines
            try await playStory(lines)
        }
    }

    func skip() {
        guard screen == .prompt, let index = findIndex else { return }
        record(.skip)
        outcomes[index] = .skipped
        run { [self] in
            set(.skipping)
            try await say(Walk.skipLine)
            try await afterFind()
        }
    }

    /// Leave the story early. Still counts as found.
    func nextStop() {
        guard screen == .story else { return }
        record(.nextStop)
        run { [self] in try await afterFind() }
    }

    func continueWalking() {
        guard screen == .finished else { return }
        record(.continueWalking)
        run { [self] in try await afterFind() }
    }

    func replay() {
        let lines = replayLines
        guard !lines.isEmpty else { return }
        record(.replay)
        switch screen {
        case .story, .finished:
            run { [self] in try await playStory(lines) }
        case .prompt, .done:
            run { [self] in try await say(lines[0]) }
        default:
            break
        }
    }

    func pause() {
        guard !paused, screen != .setup else { return }
        paused = true
        narrator.pause()
        record(.pause)
        sendStatus()
    }

    func resume() {
        guard paused else { return }
        paused = false
        narrator.resume()
        record(.resume)
        sendStatus()
    }

    // MARK: Sequences

    private func playStory(_ lines: [Narration]) async throws {
        set(.story)
        for (k, line) in lines.enumerated() {
            if k > 0 { try await pausableSleep(Self.betweenStoryLines) }
            try await say(line)
        }
        set(.finished)
    }

    private func afterFind() async throws {
        if isLastFind {
            replayLines = [Walk.doneLine]
            set(.done)
            try await pausableSleep(Self.beforeDoneBuzz)
            haptics.buzz()
            try await pausableSleep(Self.buzzToVoice)
            try await say(Walk.doneLine)
        } else {
            set(.waiting)
        }
    }

    /// Starts a new sequence, cancelling the one in progress (and its narration).
    private func run(_ body: @escaping @MainActor () async throws -> Void) {
        cancelRun()
        task = Task { @MainActor in
            do { try await body() } catch {} // CancellationError: a newer sequence took over
        }
    }

    private func cancelRun() {
        task?.cancel()
        task = nil
        narrator.stop()
        if paused { paused = false }
    }

    private func say(_ line: Narration) async throws {
        while paused { try await Task.sleep(nanoseconds: 100_000_000) }
        try Task.checkCancellation()
        await narrator.play(line)
        try Task.checkCancellation()
    }

    /// Sleeps for `seconds` of un-paused time.
    private func pausableSleep(_ seconds: Double) async throws {
        var remaining = seconds
        while remaining > 0 {
            try await Task.sleep(nanoseconds: 100_000_000)
            if !paused { remaining -= 0.1 }
        }
    }

    // MARK: Events

    private func set(_ newScreen: WalkScreen) {
        screen = newScreen
        sendStatus()
    }

    private func sendStatus() {
        onEvent?(.status(status))
    }

    private func record(_ action: ParticipantAction) {
        onEvent?(.action(action, find: findIndex, at: Date()))
    }
}
