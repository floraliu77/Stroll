import Foundation

/// The first-launch setup (Figma 01 "Welcome – setup"): which iOS permissions Stroll asks for,
/// in what order, and whether the welcome screen still needs showing. No iOS frameworks here,
/// so Tools/check-walk-model.sh can run it on a Mac.
enum SetupPermission: String, CaseIterable {
    /// Finds points of interest around you, and notices when you reach one.
    case location
    /// A walking session on the watch, so it keeps buzzing with the wrist down. Nothing is saved to Health.
    case health
    /// "Something to notice nearby" while the phone is locked or Stroll is in the background.
    case notifications

    /// The order "Get started" asks in: location first, since the map needs it straight away.
    static let order: [SetupPermission] = [.location, .health, .notifications]
}

/// Asks iOS for one permission. Returns whether it was allowed; Stroll carries on either way.
@MainActor
protocol PermissionAsker {
    /// False when the permission doesn't apply on this device (e.g. no Health on an iPad); it's skipped.
    func canAsk(_ permission: SetupPermission) -> Bool
    func ask(_ permission: SetupPermission) async -> Bool
}

@MainActor
final class SetupFlow: ObservableObject {
    static let storageKey = "setup.finished"

    /// True once "Get started" has run, whatever the answers. The welcome screen never comes back
    /// by itself after that: iOS won't show a declined prompt twice, so changes go through Settings.
    @Published private(set) var isFinished: Bool
    /// The permission being asked right now, while "Get started" is running.
    @Published private(set) var asking: SetupPermission?
    /// What each permission was answered, for the logs and checks.
    private(set) var answers: [SetupPermission: Bool] = [:]

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        isFinished = defaults.bool(forKey: Self.storageKey)
    }

    var needsWelcome: Bool { !isFinished }
    var isRunning: Bool { asking != nil }

    /// "Get started": asks for each permission in turn, one system prompt after another, then
    /// finishes. A "Don't Allow" doesn't stop the rest. Tapping again while it runs does nothing.
    func getStarted(using asker: PermissionAsker) async {
        guard !isFinished, asking == nil else { return }
        for permission in SetupPermission.order where asker.canAsk(permission) {
            asking = permission
            answers[permission] = await asker.ask(permission)
        }
        asking = nil
        isFinished = true
        defaults.set(true, forKey: Self.storageKey)
    }

    /// Developer tools: show the welcome screen again on the next look (iOS remembers the answers).
    func reset() {
        guard asking == nil else { return }
        answers = [:]
        isFinished = false
        defaults.removeObject(forKey: Self.storageKey)
    }
}
