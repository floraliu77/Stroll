import HealthKit
import WatchConnectivity
import WatchKit

/// The real wrist tap, replacing the web prototype's simulated buzz.
struct WatchHaptics: Haptics {
    func buzz() { WKInterfaceDevice.current().play(.notification) }
}

/// Runs a walking workout for the length of the session. Without it, watchOS suspends
/// the app when the wrist drops, which would stop narration and the moderator's triggers.
/// Nothing is saved to Health: the session is never handed to a workout builder.
@MainActor
final class WorkoutKeeper: NSObject, HKWorkoutSessionDelegate {
    private let store = HKHealthStore()
    private var session: HKWorkoutSession?

    var isRunning: Bool { session != nil }

    func start() async throws {
        guard session == nil, HKHealthStore.isHealthDataAvailable() else { return }
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

/// The watch's end of the link to the moderator's iPhone.
@MainActor
final class WatchLink: NSObject, WCSessionDelegate {
    var onCommand: ((RemoteCommand) -> Void)?
    /// Called when the iPhone becomes reachable, so the watch can resend its status.
    var onReachable: (() -> Void)?

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func send(_ event: WatchEvent) {
        let session = WCSession.default
        guard session.activationState == .activated, let data = RemoteCoding.encode(event) else { return }
        if session.isReachable {
            session.sendMessageData(data, replyHandler: nil, errorHandler: nil)
        } else if case .status = event {
            try? session.updateApplicationContext(["status": data]) // only the latest matters
        } else {
            session.transferUserInfo(["event": data]) // queued, so the log stays complete
        }
    }

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    nonisolated func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        guard let command = RemoteCoding.decode(RemoteCommand.self, from: messageData) else { return }
        Task { @MainActor in self.onCommand?(command) }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        guard session.isReachable else { return }
        Task { @MainActor in self.onReachable?() }
    }
}
