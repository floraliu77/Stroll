import Foundation

// Messages between the iPhone and the watch, sent over WatchConnectivity as JSON.
// The phone leads the exploring session and plays the voice guide; the watch mirrors what the
// phone shows (buzz, photo, buttons) and sends the participant's taps back.

/// Where an exploring session is. Driven by the phone's ExploreSession, shown on both devices.
enum ExplorePhase: String, Codable, Equatable {
    case idle        // before Start Exploring
    case exploring   // wandering until the next point of interest
    case preview     // buzz + photo
    case prompt      // Tell me more / Skip
    case story       // reveal + story playing
    case finished    // story done: Keep exploring
    case skipping    // "Okay, onward."
    case ended       // the participant tapped End
}

/// Phone → watch: everything the watch needs to show. Sent whenever it changes.
struct MirrorState: Codable, Equatable {
    var phase: ExplorePhase
    var poiID: String?
    var paused: Bool
    var foundCount: Int
    var everythingVisited: Bool

    static let idle = MirrorState(phase: .idle, poiID: nil, paused: false, foundCount: 0, everythingVisited: false)
}

/// Watch → phone: a tap on the watch. The phone does exactly what the same tap does on the phone.
/// `sync` asks the phone to send its current state (e.g. when the watch reconnects).
enum WatchAction: String, Codable, Equatable {
    case start, tellMeMore, skip, keepExploring, replay, pause, resume, end, sync
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
