import Foundation
import WatchConnectivity

/// One line in the moderator's session log.
struct LogEntry: Identifiable, Equatable {
    let id = UUID()
    let at: Date
    let text: String
}

/// The iPhone's end of the link: sends triggers to the watch and collects what happens there.
@MainActor
final class PhoneLink: NSObject, ObservableObject, WCSessionDelegate {
    @Published private(set) var isReachable = false
    @Published private(set) var isWatchAppInstalled = false
    @Published private(set) var status: WalkStatus?
    @Published private(set) var log: [LogEntry] = []
    @Published var sendError: String?

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func send(_ command: RemoteCommand) {
        let session = WCSession.default
        guard session.isReachable else {
            sendError = "The watch isn't reachable. Open Stroll on the watch and keep it near this iPhone."
            return
        }
        guard let data = RemoteCoding.encode(command) else { return }
        sendError = nil
        session.sendMessageData(data, replyHandler: nil) { [weak self] error in
            let message = error.localizedDescription
            Task { @MainActor in self?.sendError = "Couldn't reach the watch: \(message)" }
        }
        switch command {
        case .trigger(let find): append("Moderator buzzed find \(find + 1): \(Walk.finds[find].name)")
        case .reset: append("Moderator reset the walk")
        case .requestStatus: break
        }
    }

    func clearLog() { log = [] }

    var logText: String {
        let time = Date.FormatStyle(date: .omitted, time: .standard)
        return log.map { "\($0.at.formatted(time))  \($0.text)" }.joined(separator: "\n")
    }

    // MARK: Receiving

    private func receive(_ data: Data) {
        guard let event = RemoteCoding.decode(WatchEvent.self, from: data) else { return }
        switch event {
        case .status(let newStatus):
            status = newStatus
        case .action(let action, let find, let at):
            append(Self.describe(action, find: find), at: at)
        }
    }

    private func append(_ text: String, at: Date = Date()) {
        log.append(LogEntry(at: at, text: text))
    }

    private func refresh(_ session: WCSession) {
        isReachable = session.isReachable
        isWatchAppInstalled = session.isWatchAppInstalled
        if session.isReachable { send(.requestStatus) }
    }

    static func describe(_ action: ParticipantAction, find: Int?) -> String {
        let label = find.map { "Find \($0 + 1)" } ?? "Watch"
        switch action {
        case .getReady: return "Participant tapped Get ready"
        case .tellMeMore: return "\(label): Tell me more"
        case .skip: return "\(label): Skip"
        case .nextStop: return "\(label): Next stop (left the story early)"
        case .continueWalking: return "\(label): Continue walking (heard the whole story)"
        case .replay: return "\(label): Replay"
        case .pause: return "\(label): Pause"
        case .resume: return "\(label): Resume"
        }
    }

    // MARK: WCSessionDelegate

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        let context = session.receivedApplicationContext["status"] as? Data
        Task { @MainActor in
            self.refresh(session)
            if let context { self.receive(context) }
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in self.refresh(session) }
    }

    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in self.refresh(session) }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        Task { @MainActor in self.receive(messageData) }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard let data = applicationContext["status"] as? Data else { return }
        Task { @MainActor in self.receive(data) }
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        guard let data = userInfo["event"] as? Data else { return }
        Task { @MainActor in self.receive(data) }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate() // e.g. after switching to a different watch
    }
}
