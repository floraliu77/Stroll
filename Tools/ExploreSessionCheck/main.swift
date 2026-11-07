import Foundation

// Runs the phone's exploring session through a fast demo walk on a Mac, with a fake voice
// and buzz, to check the flow without an iPhone. Run: Tools/check-walk-model.sh

@MainActor
final class FakeVoice: GuideVoice {
    var spoken: [String] = []
    private var pending: CheckedContinuation<Void, Never>?
    private var clip = 0
    private var isPaused = false

    func play(_ line: Narration) async {
        spoken.append(line.clip)
        clip += 1
        let mine = clip
        await withCheckedContinuation { c in
            pending = c
            // Each clip "lasts" 40 ms unless paused or stopped.
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 40_000_000)
                while self.isPaused { try? await Task.sleep(nanoseconds: 10_000_000) }
                if self.clip == mine { self.finish() }
            }
        }
    }
    func stop() { finish() }
    func pause() { isPaused = true }
    func resume() { isPaused = false }
    private func finish() { pending?.resume(); pending = nil }
}

@MainActor
final class FakeAlert: ArrivalAlert {
    var arrivals: [String] = []
    func arrived(at poi: StrollContent.POI, category: StrollContent.Category?) { arrivals.append(poi.id) }
}

@MainActor
func waitFor(_ what: String, timeout: Double = 10, _ condition: () -> Bool) async {
    let start = Date()
    while !condition() {
        if Date().timeIntervalSince(start) > timeout { fail("timed out waiting for \(what)") }
        try? await Task.sleep(nanoseconds: 10_000_000)
    }
}

func fail(_ message: String) -> Never {
    print("FAIL: \(message)")
    exit(1)
}

func check(_ condition: Bool, _ message: String) {
    if !condition { fail(message) }
    print("ok  \(message)")
}

@MainActor
func runChecks() async {
    let content = StrollContent.shared
    let order = content.demoWalk.order
    let voice = FakeVoice()
    let alert = FakeAlert()
    let demo = DemoWalk(stops: order.compactMap { content.poi($0)?.coordinate }, firstSeconds: 0.2, gapSeconds: 0.2...0.3)
    let session = ExploreSession(content: content, voice: voice, alert: alert, source: demo,
                                 timing: .init(preview: 0.05, betweenLines: 0.01))

    // Detector
    let first = content.poi(order[0])!
    check(POIDetector.poi(near: first.coordinate, in: content.pois, excluding: []) == first, "detector finds a POI at its own coordinate")
    check(POIDetector.poi(near: first.coordinate, in: content.pois, excluding: [first.id]) == nil, "detector skips POIs already visited")
    check(POIDetector.poi(near: .init(latitude: 0, longitude: 0), in: content.pois, excluding: []) == nil, "detector finds nothing far away")

    // Start: nothing until the first countdown ends
    session.start()
    check(session.phase == .exploring, "Start Exploring begins exploring")
    check(session.secondsUntilNext != nil, "first arrival is scheduled")
    check(alert.arrivals.isEmpty, "nothing arrives straight away")

    // First POI: buzz, photo, then the prompt (no cue line)
    await waitFor("first arrival") { session.phase == .preview }
    check(alert.arrivals == [order[0]], "first POI in the demo order arrives with a buzz")
    await waitFor("prompt") { session.phase == .prompt }
    await waitFor("prompt spoken") { voice.spoken.last == first.prompt.audio }
    check(voice.spoken == [first.prompt.audio], "only the prompt is spoken (no cue)")
    check(session.transcript.map(\.clip) == [first.prompt.audio], "transcript shows the prompt")

    // Tell me more: reveal + story, transcript grows, then finished
    session.tellMeMore()
    await waitFor("story finished") { session.phase == .finished }
    let storyClips = [first.reveal.audio] + first.story.map(\.audio)
    check(Array(voice.spoken.suffix(storyClips.count)) == storyClips, "reveal and story play in order")
    check(session.transcript.map(\.clip) == [first.prompt.audio] + storyClips, "transcript holds prompt, reveal and story")
    check(session.visits.last?.outcome == .found, "POI recorded as found")
    check(session.secondsUntilNext != nil, "next countdown starts when the story finishes")

    // Second POI arrives while the finished story is still open
    await waitFor("second arrival") { alert.arrivals.count == 2 }
    check(alert.arrivals[1] == order[1], "second POI follows the demo order")
    await waitFor("second prompt") { session.phase == .prompt }

    // Skip
    session.skip()
    check(session.visits.last?.outcome == .skipped, "Skip records the POI as skipped")
    await waitFor("skip line") { voice.spoken.last == content.lines.skip.audio }
    await waitFor("back to exploring") { session.phase == .exploring }
    check(session.poi == nil && session.transcript.isEmpty, "the stop closes after skipping")

    // Pause holds the countdown
    session.pause()
    let held = alert.arrivals.count
    try? await Task.sleep(nanoseconds: 500_000_000)
    check(alert.arrivals.count == held, "nothing arrives while paused")
    session.resume()

    // Third POI: leave the story early
    await waitFor("third prompt") { session.phase == .prompt && alert.arrivals.count == 3 }
    session.tellMeMore()
    await waitFor("story playing") { session.phase == .story }
    session.keepExploring()
    check(session.phase == .exploring, "Keep exploring leaves the story early")
    check(session.visits.last?.outcome == .found, "leaving early still counts as found")

    // Fourth POI: hear the whole story
    await waitFor("fourth prompt") { session.phase == .prompt && alert.arrivals.count == 4 }
    session.tellMeMore()
    await waitFor("fourth story finished") { session.phase == .finished }
    check(session.everythingVisited, "every POI has come up")

    // Each POI only once; after the last, nothing more until End
    try? await Task.sleep(nanoseconds: 500_000_000)
    check(alert.arrivals.count == order.count && Set(alert.arrivals).count == order.count, "each POI comes up once")

    // End
    session.keepExploring()
    session.end()
    check(session.phase == .ended, "End finishes the session")
    await waitFor("done line") { voice.spoken.last == content.lines.done.audio }
    check(alert.arrivals.count == order.count, "End doesn't buzz")
    session.reset()
    check(session.phase == .idle && session.poi == nil, "reset goes back to the map")

    // A new session starts from the first POI again
    session.start()
    await waitFor("first arrival again") { alert.arrivals.count == order.count + 1 }
    check(alert.arrivals.last == order[0], "a new session starts over")
    session.end()
    session.reset()

    await checkBusyArrivals(content)
    print("All exploring checks passed.")
}

/// A location source driven by hand, like live GPS.
@MainActor
final class ManualSource: LocationSource {
    var onLocation: (@MainActor (StrollContent.Coordinate) -> Void)?
    var isFinished = false
    var secondsUntilNext: Double? { nil }
    func start() {}
    func stop() {}
    func pause() {}
    func resume() {}
    func participantIsFree() {}
}

/// A location that comes in mid-story waits, then arrives once the participant is free.
@MainActor
func checkBusyArrivals(_ content: StrollContent) async {
    let voice = FakeVoice()
    let alert = FakeAlert()
    let source = ManualSource()
    let session = ExploreSession(content: content, voice: voice, alert: alert, source: source,
                                 timing: .init(preview: 0.05, betweenLines: 0.01))
    let a = content.pois[0], b = content.pois[1]
    session.start()
    source.onLocation?(a.coordinate)
    await waitFor("prompt") { session.phase == .prompt }
    session.tellMeMore()
    await waitFor("story") { session.phase == .story }
    source.onLocation?(b.coordinate)
    check(alert.arrivals == [a.id], "a location mid-story doesn't interrupt it")
    await waitFor("waiting arrival") { alert.arrivals.count == 2 }
    check(alert.arrivals == [a.id, b.id], "it arrives once the story finishes")
    source.onLocation?(a.coordinate)
    try? await Task.sleep(nanoseconds: 300_000_000)
    check(alert.arrivals.count == 2, "returning to a visited POI doesn't buzz again")
    session.end()
}

await runChecks()
