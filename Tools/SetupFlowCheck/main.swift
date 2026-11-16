import Foundation

// Checks the first-launch setup screens (Phone/Onboarding/SetupFlow.swift) on a Mac, with a
// fake permission asker in place of the iOS prompts. Run: Tools/check-walk-model.sh

@MainActor
final class FakeAsker: PermissionAsker {
    var answers: [SetupPermission: Bool] = [:]
    var unavailable: Set<SetupPermission> = []
    var asked: [SetupPermission] = []
    /// Lets a check look at the flow while a prompt is "on screen".
    var whileAsking: ((SetupPermission) -> Void)?

    func canAsk(_ permission: SetupPermission) -> Bool { !unavailable.contains(permission) }

    func ask(_ permission: SetupPermission) async -> Bool {
        asked.append(permission)
        whileAsking?(permission)
        await Task.yield()
        return answers[permission] ?? true
    }
}

var failures = 0
func check(_ ok: Bool, _ name: String) {
    print(ok ? "ok  \(name)" : "FAIL \(name)")
    if !ok { failures += 1 }
}

func freshDefaults() -> UserDefaults {
    let name = "stroll-setup-check-\(UUID().uuidString)"
    let d = UserDefaults(suiteName: name)!
    d.removePersistentDomain(forName: name)
    return d
}

@MainActor
func run() async {
    // First launch: intro, then one screen per permission
    let defaults = freshDefaults()
    let asker = FakeAsker()
    let flow = SetupFlow(asker: asker, defaults: defaults)
    check(flow.needsWelcome && flow.step == .intro, "setup starts on the intro screen on first launch")
    check(flow.steps == [.intro, .permission(.location), .permission(.health), .permission(.notifications)],
          "there's an intro screen, then Location, Health and Notifications screens")

    flow.continueFromIntro()
    check(flow.step == .permission(.location) && asker.asked.isEmpty, "Continue opens the Location screen without prompting yet")

    var askingSeen: [Bool] = []
    asker.whileAsking = { _ in askingSeen.append(flow.isAsking) }
    await flow.allow()
    check(asker.asked == [.location] && askingSeen == [true], "Allow shows the location prompt, and the screen knows it's up")
    check(flow.step == .permission(.health) && !flow.isAsking, "after the location answer, the Health screen shows")
    await flow.allow()
    check(flow.step == .permission(.notifications), "after the Health answer, the Notifications screen shows")
    await flow.allow()
    check(asker.asked == SetupPermission.order, "each permission is asked once, on its own screen, in order")
    check(!flow.needsWelcome, "setup goes away after the last permission screen")
    check(!SetupFlow(asker: FakeAsker(), defaults: defaults).needsWelcome, "setup doesn't come back on the next launch")

    // Declining
    let saysNo = FakeAsker()
    saysNo.answers = [.location: false, .health: false, .notifications: false]
    let declined = SetupFlow(asker: saysNo, defaults: freshDefaults())
    declined.continueFromIntro()
    for _ in SetupPermission.order { await declined.allow() }
    check(saysNo.asked == SetupPermission.order, "a Don't Allow still moves on to the next screen")
    check(!declined.needsWelcome, "Stroll opens even if every permission is declined")
    check(declined.answers[.location] == false, "a declined permission is remembered as declined")

    // Not now
    let skipping = FakeAsker()
    let notNow = SetupFlow(asker: skipping, defaults: freshDefaults())
    notNow.continueFromIntro()
    notNow.notNow()
    check(notNow.step == .permission(.health) && skipping.asked.isEmpty, "Not now moves on without a prompt")
    notNow.notNow()
    await notNow.allow()
    check(skipping.asked == [.notifications] && !notNow.needsWelcome, "skipped screens aren't asked; setup still finishes")
    check(notNow.answers[.location] == nil, "a skipped permission has no answer")

    // Health not available on this device
    let noHealthAsker = FakeAsker()
    noHealthAsker.unavailable = [.health]
    let noHealth = SetupFlow(asker: noHealthAsker, defaults: freshDefaults())
    check(!noHealth.steps.contains(.permission(.health)), "no Health screen where the device has no Health")
    noHealth.continueFromIntro()
    await noHealth.allow()
    check(noHealth.step == .permission(.notifications), "Location goes straight on to Notifications without Health")

    // Double tap on Allow
    let counter = FakeAsker()
    let twice = SetupFlow(asker: counter, defaults: freshDefaults())
    twice.continueFromIntro()
    async let first: Void = twice.allow()
    async let second: Void = twice.allow()
    _ = await (first, second)
    check(counter.asked == [.location] && twice.step == .permission(.health), "tapping Allow twice asks only once")

    // Buttons do nothing on the wrong screen
    let early = FakeAsker()
    let wrongScreen = SetupFlow(asker: early, defaults: freshDefaults())
    await wrongScreen.allow()
    wrongScreen.notNow()
    check(wrongScreen.step == .intro && early.asked.isEmpty, "Allow and Not now do nothing on the intro screen")

    // After finishing, nothing is asked again
    let again = FakeAsker()
    let finished = SetupFlow(asker: again, defaults: defaults)
    finished.continueFromIntro()
    await finished.allow()
    check(again.asked.isEmpty, "nothing is asked once setup is finished")

    // Developer tools: show it again
    flow.reset()
    check(flow.needsWelcome && flow.step == .intro && SetupFlow(asker: FakeAsker(), defaults: defaults).needsWelcome,
          "Show welcome screen again brings setup back from the intro")
}

await run()
if failures > 0 {
    print("\(failures) setup check(s) failed.")
    exit(1)
}
print("All setup checks passed.")
