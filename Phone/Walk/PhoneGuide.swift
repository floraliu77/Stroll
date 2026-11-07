import AVFoundation
import UIKit
import UserNotifications

/// Plays the recorded narration clips (Resources/Audio) through whatever the iPhone is using:
/// connected headphones of any brand, or the speaker.
@MainActor
final class AudioGuide: NSObject, GuideVoice, AVAudioPlayerDelegate {
    var onInterrupted: (@MainActor () -> Void)?
    private var player: AVAudioPlayer?
    private var continuation: CheckedContinuation<Void, Never>?
    private var observers: [NSObjectProtocol] = []

    override init() {
        super.init()
        let center = NotificationCenter.default
        // A timer, alarm or call takes the audio: iOS pauses the clip, so pause the walk too.
        observers.append(center.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] note in
            let type = (note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt).flatMap(AVAudioSession.InterruptionType.init)
            guard type == .began else { return }
            Task { @MainActor in self?.interrupted() }
        })
        // Headphones disconnected: pause rather than carry on out loud.
        observers.append(center.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main) { [weak self] note in
            let reason = (note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt).flatMap(AVAudioSession.RouteChangeReason.init)
            guard reason == .oldDeviceUnavailable else { return }
            Task { @MainActor in self?.interrupted() }
        })
    }

    private func interrupted() {
        player?.pause()
        onInterrupted?()
    }

    func play(_ line: Narration) async {
        stop()
        activateSession()
        guard let url = Bundle.main.url(forResource: line.clip, withExtension: "mp3")
                ?? Bundle.main.url(forResource: line.clip, withExtension: "m4a"),
              let next = try? AVAudioPlayer(contentsOf: url) else {
            assertionFailure("Missing narration clip \(line.clip)")
            return
        }
        next.delegate = self
        player = next
        await withCheckedContinuation { c in
            continuation = c
            if !next.play() { finish() }   // no audio route: skip the line rather than stall
        }
    }

    func stop() {
        player?.stop()
        player = nil
        finish()
    }

    func pause() { player?.pause() }

    func resume() {
        guard let player else { return }
        activateSession()   // after an interruption the audio session has to be reactivated
        if !player.play() { finish() }   // still can't play: move on rather than stall
    }

    /// Spoken audio that keeps playing with the screen locked or the ringer switch on silent.
    private func activateSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio)
        try? session.setActive(true)
    }

    private func finish() {
        continuation?.resume()
        continuation = nil
    }

    nonisolated func audioPlayerDidFinishPlaying(_ finished: AVAudioPlayer, successfully flag: Bool) {
        let id = ObjectIdentifier(finished)
        Task { @MainActor in self.clipEnded(id) }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ failed: AVAudioPlayer, error: Error?) {
        let id = ObjectIdentifier(failed)
        Task { @MainActor in self.clipEnded(id) }
    }

    private func clipEnded(_ id: ObjectIdentifier) {
        guard let player, ObjectIdentifier(player) == id else { return }   // an older clip
        finish()
    }
}

/// The phone's buzz, plus a notification when Stroll isn't on screen.
@MainActor
struct PhoneArrivalAlert: ArrivalAlert {
    func arrived(at poi: StrollContent.POI, category: StrollContent.Category?) {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        guard UIApplication.shared.applicationState != .active else { return }
        ExploreNotifications.post(id: ExploreNotifications.arrivalID, after: nil, category: category)
    }
}

/// Local notifications for exploring. While Stroll is in the background, iOS pauses it during
/// the quiet gaps between points of interest, so a reminder is scheduled for when the next one
/// is due; opening Stroll then plays it.
enum ExploreNotifications {
    static let arrivalID = "stroll.arrival"
    static let upcomingID = "stroll.upcoming"

    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    /// Call when the app moves to the background.
    @MainActor
    static func scheduleReminder(for session: ExploreSession) {
        guard let seconds = session.secondsUntilNext else { return }
        post(id: upcomingID, after: max(1, seconds), category: nil)
    }

    /// Call when the app comes back to the foreground.
    static func cancelReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [upcomingID])
    }

    static func post(id: String, after seconds: Double?, category: StrollContent.Category?) {
        let content = UNMutableNotificationContent()
        content.title = "Something to notice nearby"
        content.body = category.map { "\($0.name). Open Stroll to listen." } ?? "Open Stroll to listen."
        content.sound = .default
        let trigger = seconds.map { UNTimeIntervalNotificationTrigger(timeInterval: $0, repeats: false) }
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
}

extension ExploreSession {
    /// The session the app uses: demo walk, narration on the phone, phone buzz.
    static func live() -> ExploreSession {
        let content = StrollContent.shared
        return ExploreSession(content: content, voice: AudioGuide(), alert: PhoneArrivalAlert(), source: DemoWalk(content: content))
    }
}
