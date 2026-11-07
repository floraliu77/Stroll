import Foundation

// Messages between the moderator's iPhone and the participant's watch, sent over
// WatchConnectivity as JSON. The watch must be paired to the moderator's iPhone.

/// iPhone → watch.
enum RemoteCommand: Codable, Equatable {
    /// Buzz the watch and start this find (0-based). Interrupts whatever is playing.
    case trigger(find: Int)
    /// Back to the start of the walk, ready for the next participant.
    case reset
    /// Ask the watch to send its current status.
    case requestStatus
}

/// What the watch is showing. Mirrors the screens of the web prototype.
enum WalkScreen: String, Codable, Equatable {
    case setup       // before "Get ready" (earbuds and workout not started)
    case waiting     // "Keep walking", until the moderator triggers the next find
    case alert       // buzz + photo preview while the cue plays
    case prompt      // Tell me more / Skip
    case story       // reveal + story playing, with Next stop
    case finished    // story done: Continue walking
    case skipping    // "Okay, onward."
    case done        // walk complete
}

enum Outcome: String, Codable, Equatable {
    case found       // tapped Tell me more (even if they left the story early)
    case skipped
}

/// Something the participant did on the watch, for the moderator's session log.
enum ParticipantAction: String, Codable, Equatable {
    case getReady, tellMeMore, skip, nextStop, continueWalking, replay, pause, resume
}

/// Watch → iPhone.
enum WatchEvent: Codable, Equatable {
    case status(WalkStatus)
    case action(ParticipantAction, find: Int?, at: Date)
}

struct WalkStatus: Codable, Equatable {
    var screen: WalkScreen
    var find: Int?
    var paused: Bool
    /// Outcome per find, by 0-based index. Missing = not reached yet.
    var outcomes: [Int: Outcome]
}

enum RemoteCoding {
    static func encode<T: Encodable>(_ value: T) -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(value)
    }

    static func decode<T: Decodable>(_ type: T.Type, from data: Data) -> T? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(type, from: data)
    }
}
