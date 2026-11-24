import Foundation

/// A line of narration: what's said, and the recorded clip that says it.
/// (The old pre-set watch walk that also lived here was unused and was removed with the arrival
/// checkpoints, Nov 2026.)
struct Narration: Hashable {
    let text: String
    /// Recorded clip name; empty when the line has no recording yet (the iPhone voice reads it).
    let clip: String

    var usesIPhoneVoice: Bool { clip.isEmpty }
}
