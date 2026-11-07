import Combine
import Foundation
import HealthKit
import WatchConnectivity

/// The iPhone's end of the link to the watch: sends the exploring session's state so the watch
/// can mirror it, and passes the watch's taps to the session. The phone always leads.
@MainActor
final class PhoneLink: NSObject, ObservableObject, WCSessionDelegate {
    @Published private(set) var isReachable = false
    @Published private(set) var isWatchAppInstalled = false

    private weak var session: ExploreSession?
    private var lastSent: MirrorState?
    private var observer: AnyCancellable?
    private let health = HKHealthStore()

    func activate(mirroring session: ExploreSession) {
        self.session = session
        // objectWillChange fires before the change; read the new state on the next main-queue turn.
        observer = session.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.sendState() }
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// Opens Stroll on the watch and starts its walking session, so the watch stays awake with
    /// the wrist down. Called when exploring starts on the phone.
    func launchWatchApp() {
        guard WCSession.isSupported(), WCSession.default.isPaired, WCSession.default.isWatchAppInstalled else { return }
        let config = HKWorkoutConfiguration()
        config.activityType = .walking
        config.locationType = .outdoor
        health.startWatchApp(with: config) { _, _ in }
    }

    private func sendState(force: Bool = false) {
        guard let state = session?.mirrorState, force || state != lastSent,
              WCSession.isSupported(), WCSession.default.activationState == .activated,
              let data = RemoteCoding.encode(state) else { return }
        lastSent = state
        let wc = WCSession.default
        try? wc.updateApplicationContext(["state": data])   // the latest state, for when the watch app opens
        if wc.isReachable {
            wc.sendMessageData(data, replyHandler: nil, errorHandler: nil)
        }
    }

    private func refresh(_ wc: WCSession) {
        isReachable = wc.isReachable
        isWatchAppInstalled = wc.isWatchAppInstalled
        sendState(force: true)
    }

    // MARK: WCSessionDelegate

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in self.refresh(session) }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in self.refresh(session) }
    }

    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in self.refresh(session) }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        guard let action = RemoteCoding.decode(WatchAction.self, from: messageData) else { return }
        Task { @MainActor in
            if action == .sync {
                self.sendState(force: true)
            } else {
                self.session?.handle(action)
            }
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()   // e.g. after switching to a different watch
    }
}
