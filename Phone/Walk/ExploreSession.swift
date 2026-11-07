import Foundation

/// Plays the narration. `play` returns when the clip ends or `stop()` is called.
@MainActor
protocol GuideVoice: AnyObject {
    func play(_ line: Narration) async
    func stop()
    func pause()
    func resume()
}

/// The buzz (and notification, if Stroll isn't on screen) when a point of interest comes up.
@MainActor
protocol ArrivalAlert {
    func arrived(at poi: StrollContent.POI, category: StrollContent.Category?)
}

/// Where the participant is: the demo walk now, Core Location later (docs/round1-plan.md).
/// Either way, locations go through `POIDetector`, so the demo also tests the real trigger logic.
@MainActor
protocol LocationSource: AnyObject {
    var onLocation: (@MainActor (StrollContent.Coordinate) -> Void)? { get set }
    /// No more points of interest will come from this source.
    var isFinished: Bool { get }
    /// Seconds until the next location, if one is scheduled (the demo walk). Used to remind
    /// the participant while Stroll is in the background.
    var secondsUntilNext: Double? { get }
    func start()
    func stop()
    func pause()
    func resume()
    /// The participant is free for the next point of interest. The demo walk starts its
    /// countdown; live location doesn't need it.
    func participantIsFree()
}

/// An exploring session on the phone: the phone leads, playing narration through whatever
/// headphones are connected to it, and shows the transcript.
/// Platform-free so it can be checked on a Mac (see Tools/check-walk-model.sh).
@MainActor
final class ExploreSession: ObservableObject {
    enum Phase: Equatable {
        case idle        // before Start Exploring
        case exploring   // wandering until the next point of interest
        case preview     // buzz + photo
        case prompt      // Tell me more / Skip
        case story       // reveal + story playing
        case finished    // story done: Keep exploring
        case skipping    // "Okay, onward."
        case ended       // the participant tapped End
    }

    /// A point of interest the participant chose to hear or skip.
    struct Visit: Identifiable, Equatable {
        let poiID: String
        let outcome: Outcome
        let at: Date
        var id: String { poiID }
    }

    struct Timing {
        var preview = 2.5        // photo on screen before the prompt (no cue line in round 1)
        var betweenLines = 0.7   // pause between story lines, as on the watch
    }

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var poi: StrollContent.POI?
    /// What has been said for the current point of interest, in order.
    @Published private(set) var transcript: [Narration] = []
    /// Index into `transcript` of the line being spoken.
    @Published private(set) var speaking: Int?
    @Published private(set) var paused = false
    @Published private(set) var visits: [Visit] = []

    let content: StrollContent
    var category: StrollContent.Category? { poi.flatMap { content.category($0.category) } }
    var showsStop: Bool { [.preview, .prompt, .story, .finished, .skipping].contains(phase) }
    var foundCount: Int { visits.filter { $0.outcome == .found }.count }
    /// Nothing more will come up this session.
    var everythingVisited: Bool { source.isFinished || arrived.count == content.pois.count }
    var secondsUntilNext: Double? { (phase == .exploring || phase == .finished) && !paused ? source.secondsUntilNext : nil }

    private let voice: GuideVoice
    private let alert: ArrivalAlert
    private let source: LocationSource
    private let timing: Timing
    private var task: Task<Void, Never>?
    private var arrived: Set<String> = []   // each point of interest comes up once per session
    private var pending: StrollContent.Coordinate?

    init(content: StrollContent, voice: GuideVoice, alert: ArrivalAlert, source: LocationSource, timing: Timing = Timing()) {
        self.content = content
        self.voice = voice
        self.alert = alert
        self.source = source
        self.timing = timing
        source.onLocation = { [weak self] in self?.located($0) }
    }

    // MARK: Participant

    func start() {
        guard phase == .idle else { return }
        visits = []
        arrived = []
        clearStop()
        phase = .exploring
        source.start()
        source.participantIsFree()
    }

    func tellMeMore() {
        guard phase == .prompt, let poi else { return }
        record(.found)
        let lines = [poi.reveal.narration] + poi.story.map(\.narration)
        run { [self] in try await playStory(lines) }
    }

    func skip() {
        guard phase == .prompt else { return }
        record(.skipped)
        run { [self] in
            phase = .skipping
            try await say(content.lines.skip.narration)
            backToExploring()
        }
    }

    /// Leave the story early, or close it once it's finished. Leaving early still counts as found.
    func keepExploring() {
        guard phase == .story || phase == .finished else { return }
        cancelRun()
        backToExploring()
    }

    func replay() {
        guard let poi else { return }
        switch phase {
        case .prompt:
            run { [self] in try await say(poi.prompt.narration, restart: true) }
        case .story, .finished:
            let lines = [poi.reveal.narration] + poi.story.map(\.narration)
            run { [self] in try await playStory(lines) }
        default:
            break
        }
    }

    func pause() {
        guard !paused, phase != .idle, phase != .ended else { return }
        paused = true
        voice.pause()
        source.pause()
    }

    func resume() {
        guard paused else { return }
        paused = false
        voice.resume()
        source.resume()
    }

    func end() {
        guard phase != .idle, phase != .ended else { return }
        cancelRun()
        source.stop()
        clearStop()
        phase = .ended
        run { [self] in
            try await say(content.lines.done.narration)   // no buzz: the participant chose to end
        }
    }

    /// Back to the map, ready for the next participant or session.
    func reset() {
        cancelRun()
        source.stop()
        clearStop()
        phase = .idle
    }

    // MARK: Arriving

    private func located(_ coordinate: StrollContent.Coordinate) {
        // Arrive only when free: wandering, or still reading a finished story.
        guard phase == .exploring || phase == .finished else {
            if showsStop { pending = coordinate }
            return
        }
        guard let next = POIDetector.poi(near: coordinate, in: content.pois, excluding: arrived) else { return }
        arrive(at: next)
    }

    private func arrive(at next: StrollContent.POI) {
        arrived.insert(next.id)
        run { [self] in
            poi = next
            transcript = []
            speaking = nil
            phase = .preview
            alert.arrived(at: next, category: content.category(next.category))
            try await pausableSleep(timing.preview)
            phase = .prompt
            try await say(next.prompt.narration)
        }
    }

    // MARK: Sequences

    private func playStory(_ lines: [Narration]) async throws {
        phase = .story
        if let prompt = poi?.prompt.narration { transcript = [prompt] }
        for (k, line) in lines.enumerated() {
            if k > 0 { try await pausableSleep(timing.betweenLines) }
            try await say(line)
        }
        speaking = nil
        phase = .finished
        source.participantIsFree()   // the next countdown starts once the story is done
        arrivePending()
    }

    private func backToExploring() {
        let waiting = pending
        clearStop()
        pending = waiting
        phase = .exploring
        source.participantIsFree()
        arrivePending()
    }

    /// A location that came in while the participant was busy (e.g. replaying a story).
    private func arrivePending() {
        guard let coordinate = pending else { return }
        pending = nil
        located(coordinate)
    }

    private func clearStop() {
        pending = nil
        poi = nil
        transcript = []
        speaking = nil
    }

    /// Starts a new sequence, cancelling the one in progress (and its narration).
    private func run(_ body: @escaping @MainActor () async throws -> Void) {
        cancelRun()
        task = Task { @MainActor in
            do { try await body() } catch {}   // CancellationError: a newer sequence took over
        }
    }

    private func cancelRun() {
        task?.cancel()
        task = nil
        voice.stop()
        if paused {
            paused = false
            source.resume()
        }
    }

    /// Speaks a line and adds it to the transcript. With `restart`, the transcript starts over
    /// from this line (replaying the prompt).
    private func say(_ line: Narration, restart: Bool = false) async throws {
        while paused { try await Task.sleep(nanoseconds: 100_000_000) }
        try Task.checkCancellation()
        if restart { transcript = [] }
        transcript.append(line)
        speaking = transcript.count - 1
        await voice.play(line)
        try Task.checkCancellation()
    }

    /// Sleeps for `seconds` of un-paused time. Measured by the clock, so time spent with the
    /// app suspended counts too.
    private func pausableSleep(_ seconds: Double) async throws {
        var remaining = seconds
        var last = Date()
        while remaining > 0 {
            try await Task.sleep(nanoseconds: 50_000_000)
            let now = Date()
            if !paused { remaining -= now.timeIntervalSince(last) }
            last = now
        }
    }

    private func record(_ outcome: Outcome) {
        guard let poi else { return }
        visits.append(Visit(poiID: poi.id, outcome: outcome, at: Date()))
    }
}
