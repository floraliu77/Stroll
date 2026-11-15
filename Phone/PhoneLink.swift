import Combine
import Foundation
import HealthKit
import UIKit
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
        guard WCSession.isSupported(), WCSession.default.isPaired, WCSession.default.isWatchAppInstalled,
              !WCSession.default.isReachable else { return }   // already open: relaunching it makes it stall
        StrollLog.link.log("phone: opening Stroll on the watch")
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
        // Try a live message even if isReachable says no: it's often out of date while the phone
        // is in a pocket. If the watch really can't be reached, the message just fails.
        StrollLog.link.log("phone: sending phase \(state.phase.rawValue, privacy: .public) (watch reachable: \(wc.isReachable))")
        wc.sendMessageData(data, replyHandler: nil, errorHandler: { error in
            StrollLog.link.log("phone: live message didn't arrive: \(error.localizedDescription, privacy: .public)")
        })
    }

    /// Whether Stroll is on the iPhone's screen, for the timing logs.
    private var appState: String {
        switch UIApplication.shared.applicationState {
        case .active: "on screen"
        case .inactive: "inactive"
        case .background: "in background"
        @unknown default: "unknown"
        }
    }

    private func refresh(_ wc: WCSession) {
        if wc.isReachable != isReachable { StrollLog.link.log("phone: watch reachable \(wc.isReachable)") }
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
        StrollLog.link.log("phone: got \(action.rawValue, privacy: .public) (no reply wanted)")
        Task { @MainActor in
            if action == .sync {
                self.sendState(force: true)
            } else {
                self.session?.handle(action)
            }
        }
    }

    /// A tap from the watch that wants an answer: handle it, then reply with the new state.
    nonisolated func session(_ session: WCSession, didReceiveMessageData messageData: Data, replyHandler: @escaping (Data) -> Void) {
        guard let action = RemoteCoding.decode(WatchAction.self, from: messageData) else {
            replyHandler(Data())
            return
        }
        let receivedAt = Date()
        StrollLog.link.log("phone: got \(action.rawValue, privacy: .public) from the watch")
        Task { @MainActor in
            StrollLog.link.log("phone: handling \(action.rawValue, privacy: .public) \(StrollLog.ms(since: receivedAt)) ms after it arrived, Stroll \(self.appState, privacy: .public)")
            if action != .sync { self.session?.handle(action) }
            let state = self.session?.mirrorState ?? .idle
            self.lastSent = state
            replyHandler(RemoteCoding.encode(state) ?? Data())
            StrollLog.link.log("phone: replied to \(action.rawValue, privacy: .public) with phase \(state.phase.rawValue, privacy: .public), \(StrollLog.ms(since: receivedAt)) ms after it arrived")
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()   // e.g. after switching to a different watch
    }
}
