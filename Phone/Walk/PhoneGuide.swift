import AVFoundation
import UIKit
import UserNotifications

/// Plays the recorded narration clips (Resources/Audio) through whatever the iPhone is using:
/// connected headphones of any brand, or the speaker. Lines without a recording yet are read
/// by the iPhone's built-in voice instead (a placeholder until they're recorded; see
/// docs/content-drafts/README.md).
@MainActor
final class AudioGuide: NSObject, GuideVoice, AVAudioPlayerDelegate, AVSpeechSynthesizerDelegate {
    var onInterrupted: (@MainActor () -> Void)?
    private var player: AVAudioPlayer?
    private let speech = AVSpeechSynthesizer()
    private var utterance: AVSpeechUtterance?
    /// The best installed English voice: premium, then enhanced, then the default.
    private lazy var voice: AVSpeechSynthesisVoice? = {
        let english = AVSpeechSynthesisVoice.speechVoices().filter { $0.language == "en-US" }
        return english.first { $0.quality == .premium }
            ?? english.first { $0.quality == .enhanced }
            ?? AVSpeechSynthesisVoice(language: "en-US")
    }()
    private var continuation: CheckedContinuation<Void, Never>?
    private var observers: [NSObjectProtocol] = []

    override init() {
        super.init()
        speech.delegate = self
        let center = NotificationCenter.default
        // A timer, alarm or call takes the audio: iOS pauses the clip, so pause the walk too.
        // (Music starting in another app doesn't count: Stroll shares the audio with it.)
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
        if speech.isSpeaking { speech.pauseSpeaking(at: .word) }
        onInterrupted?()
    }

    func play(_ line: Narration) async {
        stop()
        activateSession()
        guard !line.usesIPhoneVoice,
              let url = Bundle.main.url(forResource: line.clip, withExtension: "mp3")
                ?? Bundle.main.url(forResource: line.clip, withExtension: "m4a"),
              let next = try? AVAudioPlayer(contentsOf: url) else {
            await speak(line.text)   // no recording yet: the iPhone voice reads it
            return
        }
        next.delegate = self
        player = next
        await withCheckedContinuation { c in
            continuation = c
            if !next.play() { finish() }   // no audio route: skip the line rather than stall
        }
    }

    private func speak(_ text: String) async {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.postUtteranceDelay = 0.1
        self.utterance = utterance
        await withCheckedContinuation { c in
            continuation = c
            speech.speak(utterance)
        }
    }

    func stop() {
        player?.stop()
        player = nil
        utterance = nil
        if speech.isSpeaking || speech.isPaused { speech.stopSpeaking(at: .immediate) }
        finish()
        releaseSessionSoon()   // play() cancels this when the next line starts right away
    }

    func pause() {
        player?.pause()
        if speech.isSpeaking { speech.pauseSpeaking(at: .word) }
        releaseSessionSoon()   // paused: let music come back to full volume
    }

    func resume() {
        activateSession()   // after an interruption the audio session has to be reactivated
        if speech.isPaused {
            if !speech.continueSpeaking() { finish() }
            return
        }
        guard let player else { return }
        if !player.play() { finish() }   // still can't play: move on rather than stall
    }

    /// Spoken audio that keeps playing with the screen locked or the ringer switch on silent.
    /// It shares the audio with other apps instead of taking it over: music gets quieter while
    /// Stroll talks (podcasts and other spoken audio pause), then comes back. iOS lets a locked,
    /// background app do this, but not stop another app's music, which used to skip the line.
    /// Because it shares, starting music again no longer interrupts the walk.
    private func activateSession() {
        releaseTask?.cancel()
        releaseTask = nil
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio,
                                 options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers])
        try? session.setActive(true)
    }

    /// Gives the audio back so music returns to full volume. Waits a moment so it doesn't swell
    /// up and down between the lines of one story.
    private var releaseTask: Task<Void, Never>?
    private func releaseSessionSoon() {
        releaseTask?.cancel()
        releaseTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            guard let self, !Task.isCancelled else { return }
            if self.player?.isPlaying == true || self.speech.isSpeaking { return }
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    private func finish() {
        guard let continuation else { return }
        continuation.resume()
        self.continuation = nil
        releaseSessionSoon()
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

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in self.speechEnded(id) }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in self.speechEnded(id) }
    }

    private func speechEnded(_ id: ObjectIdentifier) {
        guard let utterance, ObjectIdentifier(utterance) == id else { return }   // an older line
        self.utterance = nil
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
