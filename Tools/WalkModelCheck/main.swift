import Foundation

// Runs the walk's state machine on a Mac with a fake narrator and buzz, to check the
// flow without a watch. Run: Tools/check-walk-model.sh

@MainActor
final class FakeNarrator: Narrator {
    var spoken: [String] = []
    private var pending: CheckedContinuation<Void, Never>?
    private var isPaused = false

    func play(_ line: Narration) async {
        spoken.append(line.clip)
        await withCheckedContinuation { c in
            pending = c
            // Each clip "lasts" 50 ms unless paused or stopped.
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 50_000_000)
                while self.isPaused { try? await Task.sleep(nanoseconds: 10_000_000) }
                self.finish()
            }
        }
    }
    func stop() { finish() }
    func pause() { isPaused = true }
    func resume() { isPaused = false }
    private func finish() { pending?.resume(); pending = nil }
}

@MainActor
final class FakeHaptics: Haptics {
    var buzzes = 0
    func buzz() { buzzes += 1 }
}

@MainActor
func waitFor(_ what: String, timeout: Double = 15, _ condition: () -> Bool) async {
    let start = Date()
    while !condition() {
        if Date().timeIntervalSince(start) > timeout { fail("timed out waiting for \(what)") }
        try? await Task.sleep(nanoseconds: 20_000_000)
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
    let narrator = FakeNarrator()
    let haptics = FakeHaptics()
    let model = WalkModel(narrator: narrator, haptics: haptics)
    var events: [WatchEvent] = []
    model.onEvent = { events.append($0) }

    model.trigger(find: 0)
    check(model.screen == .setup, "a trigger before Get ready is ignored")

    model.ready()
    check(model.screen == .waiting, "Get ready shows Keep walking")

    // Find 1: buzz, cue, prompt, Tell me more, full story, Continue walking.
    model.trigger(find: 0)
    await waitFor("alert") { model.screen == .alert }
    check(haptics.buzzes == 1, "trigger buzzes the wrist")
    await waitFor("prompt") { model.screen == .prompt && narrator.spoken.last == "f1-prompt" }
    check(narrator.spoken == ["f1-cue", "f1-prompt"], "cue then prompt are spoken")
    model.tellMeMore()
    await waitFor("story to finish") { model.screen == .finished }
    check(narrator.spoken.suffix(4) == ["f1-reveal", "f1-story1", "f1-story2", "f1-story3"], "reveal and three story lines play")
    model.continueWalking()
    await waitFor("waiting") { model.screen == .waiting }
    check(model.outcomes[0] == .found, "find 1 recorded as found")

    // Find 2: Tell me more, then Next stop partway through the story.
    model.trigger(find: 1)
    await waitFor("prompt 2") { model.screen == .prompt && narrator.spoken.last == "f2-prompt" }
    model.tellMeMore()
    await waitFor("story 2") { narrator.spoken.last == "f2-reveal" }
    model.nextStop()
    await waitFor("waiting after Next stop") { model.screen == .waiting }
    try? await Task.sleep(nanoseconds: 300_000_000)
    check(!narrator.spoken.contains("f2-story3"), "Next stop cuts the story short")
    check(model.outcomes[1] == .found, "leaving early still counts as found")

    // Find 3: Skip.
    model.trigger(find: 2)
    await waitFor("prompt 3") { model.screen == .prompt }
    model.skip()
    await waitFor("waiting after skip") { model.screen == .waiting }
    check(narrator.spoken.last == "skip", "Skip says 'Okay, onward.'")
    check(model.outcomes[2] == .skipped, "find 3 recorded as skipped")

    // Pause during the buzz-to-voice gap holds the cue back until Resume.
    model.trigger(find: 3)
    await waitFor("alert 4") { model.screen == .alert }
    model.pause()
    let before = narrator.spoken.count
    try? await Task.sleep(nanoseconds: 2_000_000_000)
    check(narrator.spoken.count == before, "nothing plays while paused")
    model.resume()
    await waitFor("prompt 4") { model.screen == .prompt && narrator.spoken.last == "f4-prompt" }
    check(true, "resume continues to the cue and prompt")

    // Last find: Next stop finishes the walk.
    model.tellMeMore()
    await waitFor("story 4") { model.screen == .story }
    model.nextStop()
    await waitFor("done line") { narrator.spoken.last == "done" }
    check(model.screen == .done, "Next stop on the last find completes the walk")
    check(haptics.buzzes == 5, "walk complete buzzes (4 finds + done)")

    // A trigger mid-story interrupts it.
    model.reset()
    check(model.screen == .waiting && model.outcomes.isEmpty, "reset clears the walk")
    model.trigger(find: 0)
    await waitFor("prompt") { model.screen == .prompt }
    model.tellMeMore()
    await waitFor("story") { model.screen == .story }
    model.trigger(find: 1)
    await waitFor("new prompt") { model.screen == .prompt && model.findIndex == 1 }
    check(true, "a trigger interrupts the story and starts the next find")

    let actions = events.compactMap { e -> ParticipantAction? in
        if case .action(let a, _, _) = e { return a } else { return nil }
    }
    check(actions.first == .getReady && actions.contains(.nextStop) && actions.contains(.skip), "participant actions are logged for the moderator")
    check(RemoteCoding.encode(events.last!).flatMap { RemoteCoding.decode(WatchEvent.self, from: $0) } == events.last!, "events survive a JSON round trip")
    check(RemoteCoding.encode(RemoteCommand.trigger(find: 2)).flatMap { RemoteCoding.decode(RemoteCommand.self, from: $0) } == .trigger(find: 2), "commands survive a JSON round trip")

    print("All checks passed.")
    exit(0)
}

Task { @MainActor in await runChecks() }
RunLoop.main.run()
