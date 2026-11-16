import Foundation

/// Plays the narration. `play` returns when the clip ends or `stop()` is called.
@MainActor
protocol GuideVoice: AnyObject {
    /// Something else took the audio (a timer, a call) or the headphones were disconnected.
    var onInterrupted: (@MainActor () -> Void)? { get set }
    func play(_ line: Narration) async
    func stop()
    func pause()
    func resume()
    /// This place's narration is over (story finished, skipped, or left): give the audio back so
    /// music that Stroll paused can carry on, even while Keep exploring is still on screen.
    func placeDone()
}

/// The buzz (and notification, if Stroll isn't on screen) when a point of interest comes up.
@MainActor
protocol ArrivalAlert {
    func arrived(at poi: StrollContent.POI, category: StrollContent.Category?)
}

/// Where the participant is: the scripted demo walk (`DemoWalk`) or the phone's real position
/// (`LiveLocationSource`). Either way, locations go through `POIDetector`, so the demo also tests
/// the real trigger logic.
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
    /// countdown; live location doesn't need it (the session's quiet gap covers it).
    func participantIsFree()
    /// A set walk's stops, in order, or nil for exploring freely. Called before `start()`.
    /// The demo walk visits these instead of its own list; real location doesn't need them.
    func follow(_ stops: [StrollContent.Coordinate]?)
}

extension LocationSource {
    func follow(_ stops: [StrollContent.Coordinate]?) {}
}

/// An exploring session on the phone: the phone leads, playing narration through whatever
/// headphones are connected to it, and shows the transcript.
///
/// Two kinds of walk share it: exploring freely (any point of interest comes up when you're
/// near it) and a set walk (`route`), where only the route's stops come up, in order, with a
/// spoken direction ("cue") on the way to each. Both go through the same `POIDetector` check
/// and the same buzz → photo → question → story flow.
/// Platform-free so it can be checked on a Mac (see Tools/check-walk-model.sh).
@MainActor
final class ExploreSession: ObservableObject {
    typealias Phase = ExplorePhase

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
        /// After a stop ends (Keep exploring or Skip), nothing new comes up for this long, so
        /// places close together don't fire back to back. Pausing pauses it too.
        var quietAfterStop = 30.0
    }

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var poi: StrollContent.POI?
    /// What has been said for the current point of interest, in order.
    @Published private(set) var transcript: [Narration] = []
    /// Index into `transcript` of the line being spoken.
    @Published private(set) var speaking: Int?
    @Published private(set) var paused = false
    @Published private(set) var visits: [Visit] = []
    /// The set walk being followed, or nil while exploring freely.
    @Published private(set) var route: StrollContent.Route?
    /// On a set walk: the stop being walked to, or the one open now (0-based).
    @Published private(set) var stopIndex = 0
    /// Called as each point of interest is explored or skipped (the Journal listens).
    var onVisit: (@MainActor (Visit) -> Void)?

    let content: StrollContent
    var category: StrollContent.Category? { poi.flatMap { content.category($0.category) } }
    var showsStop: Bool { [.preview, .prompt, .story, .finished, .skipping].contains(phase) }
    var foundCount: Int { visits.filter { $0.outcome == .found }.count }
    /// Nothing more will come up this session.
    /// Exploring freely only: a set walk ends by itself after its last stop.
    var everythingVisited: Bool { route == nil && (source.isFinished || arrived.count == content.pois.count) }
    /// On a set walk, the stop being walked to or at.
    var currentStop: StrollContent.Stop? {
        guard let route, stopIndex < route.stops.count else { return nil }
        return route.stops[stopIndex]
    }
    /// On a set walk: whether the participant heard the story at stop `index`.
    func foundStop(_ index: Int) -> Bool {
        guard let route, index < route.stops.count else { return false }
        return visits.contains { $0.poiID == route.stops[index].poi && $0.outcome == .found }
    }
    var secondsUntilNext: Double? { phase == .exploring && !paused ? source.secondsUntilNext : nil }
    /// What the watch shows.
    var mirrorState: MirrorState {
        MirrorState(phase: phase, poiID: poi?.id, paused: paused, foundCount: foundCount, everythingVisited: everythingVisited,
                    walkID: route?.id, stopIndex: route == nil ? nil : stopIndex)
    }

    private let voice: GuideVoice
    private let alert: ArrivalAlert
    /// Where locations come from. Swapped with `useSource` (Developer tools), only before a walk.
    private(set) var source: LocationSource
    private let timing: Timing
    private var task: Task<Void, Never>?
    /// Running during the quiet gap after a stop.
    private var quietTask: Task<Void, Never>?
    private var arrived: Set<String> = []   // each point of interest comes up once per session
    private var pending: StrollContent.Coordinate?

    init(content: StrollContent, voice: GuideVoice, alert: ArrivalAlert, source: LocationSource, timing: Timing = Timing()) {
        self.content = content
        self.voice = voice
        self.alert = alert
        self.source = source
        self.timing = timing
        source.onLocation = { [weak self] in self?.located($0) }
        // Pause, so the participant can pick up where they left off with Resume.
        voice.onInterrupted = { [weak self] in self?.pause() }
    }

    /// Switches between the demo walk and real location. Only before a walk starts.
    @discardableResult
    func useSource(_ newSource: LocationSource) -> Bool {
        guard phase == .idle else { return false }
        guard newSource !== source else { return true }
        source.stop()
        source.onLocation = nil
        source = newSource
        newSource.onLocation = { [weak self] in self?.located($0) }
        return true
    }

    // MARK: Participant

    /// Starts exploring freely, or the set walk `walk`.
    func start(walk: StrollContent.Route? = nil) {
        guard phase == .idle else { return }
        cancelQuiet()
        visits = []
        arrived = []
        clearStop()
        route = walk
        stopIndex = 0
        phase = .exploring
        source.follow(walk.map { $0.stops.compactMap { content.poi($0.poi)?.coordinate } })
        source.start()
        source.participantIsFree()
        sayCue()
    }

    /// Set walk: move on to the next stop without going to this one (it isn't in the Journal).
    /// After the last stop, the walk ends.
    func skipStop() {
        guard phase == .exploring, let route, stopIndex < route.stops.count else { return }
        stopIndex += 1
        if stopIndex >= route.stops.count {
            end()
        } else {
            sayCue()
        }
    }

    func tellMeMore() {
        guard phase == .prompt, let poi else { return }
        record(.found)
        phase = .story   // switch now, so a quick next tap (e.g. Keep exploring) lands on the story
        let lines = [poi.reveal.narration] + poi.story.map(\.narration)
        run { [self] in try await playStory(lines) }
    }

    func skip() {
        guard phase == .prompt else { return }
        record(.skipped)
        // "Okay, onward." in the same voice as this place (its own line), else the shared one.
        let line = poi?.skipLine ?? content.lines.skip
        run { [self] in
            phase = .skipping
            try await say(line.narration)
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
        cancelQuiet()
        cancelRun()
        source.stop()
        clearStop()
        phase = .ended
        run { [self] in
            try await say(content.lines.done.narration)   // no buzz: the participant chose to end
            voice.placeDone()
        }
    }

    /// Back to the map, ready for the next participant or session.
    func reset() {
        cancelQuiet()
        cancelRun()
        source.stop()
        clearStop()
        voice.placeDone()
        route = nil
        stopIndex = 0
        phase = .idle
    }

    /// A tap on the watch.
    func handle(_ action: WatchAction) {
        switch action {
        case .start: start()
        case .tellMeMore: tellMeMore()
        case .skip: skip()
        case .keepExploring: keepExploring()
        case .replay: replay()
        case .pause: pause()
        case .resume: resume()
        case .end: end()
        case .reset: if phase == .ended { reset() }
        case .skipStop: skipStop()
        case .sync: break   // answered by PhoneLink
        }
    }

    /// Developer tools: bring up a point of interest now, wherever the participant is.
    func arriveNow(_ poiID: String) {
        guard phase != .idle, phase != .ended, let next = content.poi(poiID) else { return }
        reachStop(next)
        arrive(at: next)
    }

    // MARK: Arriving

    private func located(_ coordinate: StrollContent.Coordinate) {
        // Arrive only when free: back to wandering, not while a point of interest is open.
        guard phase == .exploring else {
            if showsStop { pending = coordinate }
            return
        }
        // During the quiet gap, keep the latest position; it's checked again when the gap ends,
        // so a place still in range comes up then and one already walked past is let go.
        if quietTask != nil {
            pending = coordinate
            return
        }
        guard let next = POIDetector.poi(near: coordinate, in: candidates, excluding: arrived) else {
            // Demo walk on a set walk: that was a stop already skipped; go on to the next one.
            if route != nil { source.participantIsFree() }
            return
        }
        reachStop(next)
        arrive(at: next)
    }

    /// What can come up now: on a set walk, the stops not reached yet (so walking to a later
    /// stop first jumps ahead to it); otherwise every point of interest.
    private var candidates: [StrollContent.POI] {
        guard let route else { return content.pois }
        return route.stops.dropFirst(stopIndex).compactMap { content.poi($0.poi) }
    }

    /// Set walk: arriving at a later stop skips the ones in between.
    private func reachStop(_ poi: StrollContent.POI) {
        guard let route, let k = route.stops.firstIndex(where: { $0.poi == poi.id }), k >= stopIndex else { return }
        stopIndex = k
    }

    /// Set walk: the direction to the current stop, then the music can come back.
    private func sayCue() {
        guard let cue = currentStop?.cue else { return }
        run { [self] in
            try await say(cue.narration)
            transcript = []
            speaking = nil
            voice.placeDone()
        }
    }

    private func arrive(at next: StrollContent.POI) {
        cancelQuiet()
        pending = nil
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
        phase = .finished   // the next countdown starts when they tap Keep exploring
        voice.placeDone()   // music can come back while Keep exploring waits
    }

    private func backToExploring() {
        let waiting = pending
        let leftStop = currentStop.map { $0.poi == poi?.id } ?? false
        clearStop()
        pending = waiting
        voice.placeDone()
        phase = .exploring
        guard let route else {
            source.participantIsFree()
            startQuiet()
            return
        }
        // Set walk: on to the next stop, or the end of the walk. No quiet gap: only the next
        // stop can come up, and its direction plays first.
        if leftStop { stopIndex += 1 }
        if stopIndex >= route.stops.count {
            end()
            return
        }
        source.participantIsFree()
        sayCue()
        arrivePending()
    }

    /// The quiet gap after a stop. When it ends, the latest position is checked again.
    private func startQuiet() {
        cancelQuiet()
        guard timing.quietAfterStop > 0 else {
            arrivePending()
            return
        }
        let seconds = timing.quietAfterStop
        quietTask = Task { @MainActor [weak self] in
            do { try await self?.pausableSleep(seconds) } catch { return }   // cancelled
            guard let self, !Task.isCancelled else { return }
            self.quietTask = nil
            self.arrivePending()
        }
    }

    private func cancelQuiet() {
        quietTask?.cancel()
        quietTask = nil
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
            guard !Task.isCancelled else { return }   // replaced before it even started
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
        let visit = Visit(poiID: poi.id, outcome: outcome, at: Date())
        visits.append(visit)
        onVisit?(visit)
    }
}
