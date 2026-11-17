import Foundation

/// The first-launch setup (from Figma 01 "Welcome – setup", split into one screen per step): an
/// intro that explains Stroll, then one screen for each iOS permission. No iOS frameworks here,
/// so Tools/check-walk-model.sh can run it on a Mac.
enum SetupPermission: String, CaseIterable {
    /// Finds points of interest around you, and notices when you reach one.
    case location
    /// A walking session on the watch, so it keeps buzzing with the wrist down. Nothing is saved to Health.
    case health
    /// "Something to notice nearby" while the phone is locked or Stroll is in the background.
    case notifications

    /// The order of the permission screens: location first, since the map needs it straight away.
    static let order: [SetupPermission] = [.location, .health, .notifications]
}

/// One screen of the setup.
enum SetupStep: Equatable {
    /// What Stroll is and how a walk works.
    case intro
    /// One iOS permission: why Stroll needs it, then "Allow" (the system prompt) or "Not now".
    case permission(SetupPermission)
}

/// Asks iOS for one permission. Returns whether it was allowed; Stroll carries on either way.
@MainActor
protocol PermissionAsker {
    /// False when the permission doesn't apply on this device (e.g. no Health on an iPad); its screen is skipped.
    func canAsk(_ permission: SetupPermission) -> Bool
    func ask(_ permission: SetupPermission) async -> Bool
}

@MainActor
final class SetupFlow: ObservableObject {
    static let storageKey = "setup.finished"

    /// True once the last setup screen is done, whatever the answers. The setup never comes back
    /// by itself after that: iOS won't show a declined prompt twice, so changes go through Settings.
    @Published private(set) var isFinished: Bool
    /// The screen showing now.
    @Published private(set) var step: SetupStep = .intro
    /// True while the system prompt for the current screen is up.
    @Published private(set) var isAsking = false
    /// What each permission was answered; a "Not now" leaves it out. For the logs and checks.
    private(set) var answers: [SetupPermission: Bool] = [:]

    private let defaults: UserDefaults
    private let asker: PermissionAsker

    init(asker: PermissionAsker, defaults: UserDefaults = .standard) {
        self.asker = asker
        self.defaults = defaults
        isFinished = defaults.bool(forKey: Self.storageKey)
    }

    var needsWelcome: Bool { !isFinished }

    /// Every screen this device will show, in order, for the progress dots.
    var steps: [SetupStep] {
        [.intro] + SetupPermission.order.filter(asker.canAsk).map(SetupStep.permission)
    }

    /// "Continue" on the intro screen.
    func continueFromIntro() {
        guard !isFinished, step == .intro else { return }
        moveOn(after: nil)
    }

    /// "Allow" on a permission screen: shows the iOS prompt, then moves on whatever the answer.
    /// Tapping again while the prompt is up does nothing.
    func allow() async {
        guard !isFinished, !isAsking, case .permission(let permission) = step else { return }
        isAsking = true
        answers[permission] = await asker.ask(permission)
        isAsking = false
        moveOn(after: permission)
    }

    /// "Not now" on a permission screen: no system prompt, and Stroll carries on without it.
    func notNow() {
        guard !isFinished, !isAsking, case .permission(let permission) = step else { return }
        moveOn(after: permission)
    }

    /// Developer tools: show the setup again from the intro (iOS remembers the answers).
    func reset() {
        guard !isAsking else { return }
        answers = [:]
        step = .intro
        isFinished = false
        defaults.removeObject(forKey: Self.storageKey)
    }

    private func moveOn(after permission: SetupPermission?) {
        let remaining = SetupPermission.order
            .drop { permission != nil && $0 != permission }
            .dropFirst(permission == nil ? 0 : 1)
        if let next = remaining.first(where: asker.canAsk) {
            step = .permission(next)
        } else {
            isFinished = true
            defaults.set(true, forKey: Self.storageKey)
        }
    }
}
