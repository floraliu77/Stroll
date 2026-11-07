import AVFoundation

/// Plays the recorded Carolyn clips from Resources/Audio, one at a time.
@MainActor
final class NarrationPlayer: NSObject, Narrator, AVAudioPlayerDelegate {
    private var player: AVAudioPlayer?
    private var continuation: CheckedContinuation<Void, Never>?

    func play(_ line: Narration) async {
        stop()
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
            if !next.play() { finish() } // no audio route: skip the line rather than stall
        }
    }

    func stop() {
        player?.stop()
        player = nil
        finish()
    }

    func pause() { player?.pause() }

    func resume() { player?.play() }

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
        guard let player, ObjectIdentifier(player) == id else { return } // an older clip
        finish()
    }
}

enum EarbudAudio {
    /// Routes narration to Bluetooth earbuds. watchOS shows its route picker if none are
    /// connected. Returns false if the participant cancels or no route is available.
    static func activate() async -> Bool {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .spokenAudio, policy: .longFormAudio, options: [])
        } catch {
            return false
        }
        return await withCheckedContinuation { c in
            session.activate(options: []) { ok, _ in c.resume(returning: ok) }
        }
    }
}
