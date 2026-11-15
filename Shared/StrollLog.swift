import Foundation
import os

/// Timing logs for the phone–watch link, to find where the watch's Start Exploring lag comes from.
/// To read them: open Console on the Mac, pick the iPhone (and then the watch) in the sidebar,
/// press Start, and search for `subsystem:com.teamgreen.stroll`. Each line shows the device's time.
enum StrollLog {
    static let link = Logger(subsystem: "com.teamgreen.stroll", category: "link")
    /// Whether Stroll paused other apps' music or could only lower it (search `category:audio`).
    static let audio = Logger(subsystem: "com.teamgreen.stroll", category: "audio")

    /// Milliseconds since `start`, for "took 1234 ms" style lines.
    static func ms(since start: Date) -> Int {
        Int(Date().timeIntervalSince(start) * 1000)
    }
}
