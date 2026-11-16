import Foundation

// Checks the first-launch welcome flow (Phone/Onboarding/SetupFlow.swift) on a Mac, with a
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
    // First launch
    let defaults = freshDefaults()
    let flow = SetupFlow(defaults: defaults)
    check(flow.needsWelcome, "the welcome screen shows on first launch")

    let asker = FakeAsker()
    var askingSeen: [SetupPermission?] = []
    asker.whileAsking = { _ in askingSeen.append(flow.asking) }
    await flow.getStarted(using: asker)
    check(asker.asked == [.location, .health, .notifications], "Get started asks for location, then Health, then notifications")
    check(askingSeen == [.location, .health, .notifications], "the screen knows which permission is being asked")
    check(!flow.needsWelcome && flow.asking == nil, "the welcome screen goes away after Get started")
    check(!SetupFlow(defaults: defaults).needsWelcome, "the welcome screen doesn't come back on the next launch")

    // Declining
    let declined = SetupFlow(defaults: freshDefaults())
    let saysNo = FakeAsker()
    saysNo.answers = [.location: false, .health: false, .notifications: false]
    await declined.getStarted(using: saysNo)
    check(saysNo.asked == SetupPermission.order, "a Don't Allow doesn't stop the next prompt")
    check(!declined.needsWelcome, "Stroll opens even if every permission is declined")
    check(declined.answers[.location] == false, "a declined permission is remembered as declined")

    // Health not available on this device
    let noHealth = SetupFlow(defaults: freshDefaults())
    let skipper = FakeAsker()
    skipper.unavailable = [.health]
    await noHealth.getStarted(using: skipper)
    check(skipper.asked == [.location, .notifications], "Health is skipped where the device has none")

    // Double tap
    let twice = SetupFlow(defaults: freshDefaults())
    let counter = FakeAsker()
    async let first: Void = twice.getStarted(using: counter)
    async let second: Void = twice.getStarted(using: counter)
    _ = await (first, second)
    check(counter.asked == SetupPermission.order, "tapping Get started twice asks only once")

    // After finishing, nothing is asked again
    let again = FakeAsker()
    await flow.getStarted(using: again)
    check(again.asked.isEmpty, "Get started does nothing once setup is finished")

    // Developer tools: show it again
    flow.reset()
    check(flow.needsWelcome && SetupFlow(defaults: defaults).needsWelcome, "Show welcome screen again brings it back")
}

await run()
if failures > 0 {
    print("\(failures) setup check(s) failed.")
    exit(1)
}
print("All setup checks passed.")
