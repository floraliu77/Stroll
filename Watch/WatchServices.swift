import HealthKit
import WatchConnectivity
import WatchKit

/// The wrist tap when a point of interest comes up.
struct WatchHaptics {
    func buzz() { WKInterfaceDevice.current().play(.notification) }
}

/// Runs a walking workout for the length of the session. Without it, watchOS suspends
/// the app when the wrist drops, and the watch would miss the phone's buzzes.
/// Nothing is saved to Health: the session is never handed to a workout builder.
@MainActor
final class WorkoutKeeper: NSObject, HKWorkoutSessionDelegate {
    private let store = HKHealthStore()
    private var session: HKWorkoutSession?
    private var starting = false

    var isRunning: Bool { session != nil }

    func start() async throws {
        guard session == nil, !starting, HKHealthStore.isHealthDataAvailable() else { return }
        starting = true
        defer { starting = false }
        try await store.requestAuthorization(toShare: [HKObjectType.workoutType()], read: [])
        let config = HKWorkoutConfiguration()
        config.activityType = .walking
        config.locationType = .outdoor
        let newSession = try HKWorkoutSession(healthStore: store, configuration: config)
        newSession.delegate = self
        newSession.startActivity(with: Date())
        session = newSession
    }

    func end() {
        session?.end()
        session = nil
    }

    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {}

    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        Task { @MainActor in self.session = nil }
    }
}

/// The watch's end of the link to the iPhone: receives what the phone is showing, and sends
/// the participant's taps.
@MainActor
final class WatchLink: NSObject, WCSessionDelegate {
    var onState: ((MirrorState) -> Void)?
    var onReachabilityChange: ((Bool) -> Void)?

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// Sends a tap to the phone. Returns false if the phone can't be reached right now; taps
    /// aren't queued, because a late "Tell me more" would apply to the wrong moment.
    func send(_ action: WatchAction) -> Bool {
        let session = WCSession.default
        guard session.activationState == .activated, session.isReachable,
              let data = RemoteCoding.encode(action) else { return false }
        session.sendMessageData(data, replyHandler: nil, errorHandler: nil)
        return true
    }

    private func receive(_ data: Data) {
        guard let state = RemoteCoding.decode(MirrorState.self, from: data) else { return }
        onState?(state)
    }

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        let context = session.receivedApplicationContext["state"] as? Data
        let reachable = session.isReachable
        Task { @MainActor in
            if let context { self.receive(context) }
            self.onReachabilityChange?(reachable)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        Task { @MainActor in self.receive(messageData) }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard let data = applicationContext["state"] as? Data else { return }
        Task { @MainActor in self.receive(data) }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        let reachable = session.isReachable
        Task { @MainActor in self.onReachabilityChange?(reachable) }
    }
}
