import Foundation

// Messages between the iPhone and the watch, sent over WatchConnectivity as JSON.
// The phone leads the exploring session and plays the voice guide; the watch mirrors what the
// phone shows (buzz, photo, buttons) and sends the participant's taps back.

/// Where an exploring session is. Driven by the phone's ExploreSession, shown on both devices.
enum ExplorePhase: String, Codable, Equatable {
    case idle        // before Start Exploring
    case exploring   // wandering until the next point of interest
    case preview     // buzz + photo
    case locating    // "find" places: the locate line, waiting for Found it
    case prompt      // the question: Tell me more / Skip
    case story       // reveal + story playing
    case finished    // story done: Keep exploring
    case skipping    // "Alright, got it. Moving on."
    case ended       // the participant tapped End
}

/// Phone → watch: everything the watch needs to show. Sent whenever it changes.
struct MirrorState: Codable, Equatable {
    var phase: ExplorePhase
    var poiID: String?
    var paused: Bool
    var foundCount: Int
    var everythingVisited: Bool
    /// On a set walk: the walk (StrollContent.Route.id) and the stop being walked to or at
    /// (0-based). Both nil while exploring freely.
    var walkID: String? = nil
    var stopIndex: Int? = nil
    /// Read mode (no headphones, no sound): the watch shows the whole text instead of the dots.
    var reading = false
    /// Start was tapped without headphones: the phone asks how to listen (the watch can answer).
    var askingHowToListen = false
    /// "I'll connect them": waiting for headphones, then exploring starts by itself.
    var waitingForHeadphones = false
    /// Read mode and headphones just connected: "Turn on voice?"
    var offeringVoice = false
    /// While locating: Help me find it was used (or the place has no help line), so the watch
    /// hides the Help button.
    var helpGiven = false

    static let idle = MirrorState(phase: .idle, poiID: nil, paused: false, foundCount: 0, everythingVisited: false)
}

/// Watch → phone: a tap on the watch. The phone does exactly what the same tap does on the phone.
/// `reset` is Done after the walk (back to the start). `sync` asks the phone to send its current
/// state (e.g. when the watch reconnects). `skipStop` moves a set walk on to its next stop
/// without going there. The `listen…` actions answer "Headphones aren't connected";
/// `voiceOn` / `keepReading` answer "Turn on voice?".
enum WatchAction: String, Codable, Equatable {
    case start, tellMeMore, skip, keepExploring, replay, pause, resume, end, reset, sync, skipStop
    case listenWithHeadphones, listenByReading, listenOutLoud, cancelStart
    case voiceOn, keepReading
    case foundIt, helpMeFind   // arrival checkpoint at a "find" place
}

/// The answer to "Headphones aren't connected" when starting.
enum ListenChoice: Equatable {
    case connectHeadphones   // wait; start by itself when they connect
    case read                // no sound: the story as text
    case outLoud             // the phone's speaker (plays even with the ringer on silent)
    case cancel
}

enum Outcome: String, Codable, Equatable {
    case found       // tapped Tell me more (even if they left the story early)
    case skipped
}

enum RemoteCoding {
    static func encode<T: Encodable>(_ value: T) -> Data? {
        try? JSONEncoder().encode(value)
    }

    static func decode<T: Decodable>(_ type: T.Type, from data: Data) -> T? {
        try? JSONDecoder().decode(type, from: data)
    }
}
