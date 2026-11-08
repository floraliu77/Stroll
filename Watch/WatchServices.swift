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
        let begun = Date()
        StrollLog.link.log("watch: starting walking session")
        try await store.requestAuthorization(toShare: [HKObjectType.workoutType()], read: [])
        StrollLog.link.log("watch: Health permission answered after \(StrollLog.ms(since: begun)) ms")
        let config = HKWorkoutConfiguration()
        config.activityType = .walking
        config.locationType = .outdoor
        let newSession = try HKWorkoutSession(healthStore: store, configuration: config)
        newSession.delegate = self
        newSession.startActivity(with: Date())
        session = newSession
        StrollLog.link.log("watch: walking session started after \(StrollLog.ms(since: begun)) ms")
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
    /// The phone replies with its state straight away, so the watch doesn't wait for a separate update.
    func send(_ action: WatchAction) -> Bool {
        let session = WCSession.default
        guard session.activationState == .activated, session.isReachable,
              let data = RemoteCoding.encode(action) else {
            StrollLog.link.log("watch: can't send \(action.rawValue, privacy: .public) (activated: \(WCSession.default.activationState == .activated), reachable: \(WCSession.default.isReachable))")
            return false
        }
        let sentAt = Date()
        StrollLog.link.log("watch: sending \(action.rawValue, privacy: .public)")
        session.sendMessageData(data, replyHandler: { [weak self] reply in
            let state = RemoteCoding.decode(MirrorState.self, from: reply)
            StrollLog.link.log("watch: reply to \(action.rawValue, privacy: .public) after \(StrollLog.ms(since: sentAt)) ms, phase \(state?.phase.rawValue ?? "?", privacy: .public)")
            guard let state else { return }
            Task { @MainActor in self?.onState?(state) }
        }, errorHandler: { error in
            StrollLog.link.error("watch: \(action.rawValue, privacy: .public) failed after \(StrollLog.ms(since: sentAt)) ms: \(error.localizedDescription, privacy: .public)")
        })
        return true
    }

    private func receive(_ data: Data, via route: String) {
        guard let state = RemoteCoding.decode(MirrorState.self, from: data) else { return }
        StrollLog.link.log("watch: got phase \(state.phase.rawValue, privacy: .public) via \(route, privacy: .public)")
        onState?(state)
    }

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        let context = session.receivedApplicationContext["state"] as? Data
        let reachable = session.isReachable
        StrollLog.link.log("watch: link activated, reachable \(reachable)")
        Task { @MainActor in
            if let context { self.receive(context, via: "saved context") }
            self.onReachabilityChange?(reachable)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        Task { @MainActor in self.receive(messageData, via: "message") }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard let data = applicationContext["state"] as? Data else { return }
        Task { @MainActor in self.receive(data, via: "context") }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        let reachable = session.isReachable
        StrollLog.link.log("watch: phone reachable \(reachable)")
        Task { @MainActor in self.onReachabilityChange?(reachable) }
    }
}
