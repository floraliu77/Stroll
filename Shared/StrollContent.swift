import Foundation

/// Everything Stroll says and shows about its points of interest, read from
/// `Shared/Content/stroll-content.json` (bundled into both the iPhone and watch apps).
///
/// Edit the JSON, not this file, to change content. The JSON is meant to be generated from
/// the team's research sheet (see docs/location-research-guide.md).
struct StrollContent: Decodable {
    let version: Int
    let categories: [Category]
    let pois: [POI]
    let lines: Lines
    let demoWalk: DemoWalk
    let walks: [Route]
    /// The places Stroll covers, for the map's area picker (the pill at the top of Explore).
    let areas: [Area]

    /// A city area, e.g. "Oakland, Pittsburgh". Its points of interest are the ones within
    /// `radiusMeters` of `center`.
    struct Area: Decodable, Identifiable, Hashable {
        let id: String
        let name: String
        let center: Coordinate
        let radiusMeters: Double
    }

    struct Category: Decodable, Identifiable, Hashable {
        let id: String       // e.g. "natural-history"
        let name: String     // e.g. "Natural history"
        let symbol: String   // SF Symbol used on the watch
    }

    struct POI: Decodable, Identifiable, Hashable {
        let id: String
        let name: String
        let category: String             // Category.id
        let coordinate: Coordinate
        let coordinateStatus: String     // "placeholder" until the location research confirms it
        let triggerRadiusMeters: Double
        let image: String                // asset catalog name
        /// What the photo shows, read by VoiceOver. Describes the photo without naming the place or
        /// giving away the prompt's answer, since it's read before the reveal. Optional.
        let altText: String?
        let photoCredit: PhotoCredit
        let prompt: Line
        let reveal: Line
        let story: [Line]
        /// "Alright, got it. Moving on." after Skip, when this place uses a different voice from the shared
        /// `lines.skip` (e.g. the generated Sky voice). Optional.
        let skipLine: Line?
    }

    struct Coordinate: Decodable, Hashable {
        let latitude: Double
        let longitude: Double
    }

    struct PhotoCredit: Decodable, Hashable {
        let author: String
        let license: String
        let licenseUrl: String
        let source: String
    }

    /// A line of narration and its recorded clip in Resources/Audio (file name without extension).
    /// A line without a recording (`"audio": null` in the content file) is read aloud by the
    /// iPhone's built-in voice for now; `audio` is then empty. Tools/check-walk-model.sh lists
    /// these lines so they can be recorded later.
    struct Line: Decodable, Hashable {
        let text: String
        let audio: String

        var hasRecording: Bool { !audio.isEmpty }
        var narration: Narration { Narration(text: text, clip: audio) }

        private enum CodingKeys: String, CodingKey { case text, audio }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            text = try c.decode(String.self, forKey: .text)
            audio = try c.decodeIfPresent(String.self, forKey: .audio) ?? ""
        }
    }

    struct Lines: Decodable {
        let skip: Line
        let done: Line
    }

    /// The scripted demo walk used for testing before live location (see docs/round1-plan.md).
    struct DemoWalk: Decodable {
        let order: [String]              // POI ids, in the order they're triggered
        let firstBuzzSeconds: Double
        let gapSeconds: SecondsRange
        /// On a set walk: seconds from Continue walk to the next stop coming up. Exact, not random,
        /// so a demo of a walk runs at a steady pace.
        let walkGapSeconds: Double
    }

    struct SecondsRange: Decodable {
        let min: Double
        let max: Double
    }

    /// A set walk: a route past chosen points of interest, in order (the Walks tab).
    /// Route directions ("cues") belong to stops, not to POIs: the cue is said on the way *to* that stop.
    struct Route: Decodable, Identifiable {
        let id: String
        let title: String
        let summary: String
        let cover: String                // asset catalog name of the card and detail photo
        /// The line drawn on the map, from the first stop to the last. Distance and time come from it.
        let path: [Coordinate]
        let stops: [Stop]
    }

    struct Stop: Decodable {
        let poi: String                  // POI.id
        /// Where the stop is, for the stops list ("Fifth Ave & Bellefield"). Never the place's name:
        /// what's at each stop stays a surprise.
        let street: String
        let cue: Line?
    }

    func poi(_ id: String) -> POI? { pois.first { $0.id == id } }
    func category(_ id: String) -> Category? { categories.first { $0.id == id } }
    func route(_ id: String) -> Route? { walks.first { $0.id == id } }

    // MARK: Areas

    /// How far from an area's places the map can be and still count as looking at that area.
    static let areaReachMeters = 15_000.0

    func pois(in area: Area) -> [POI] {
        pois.filter { Route.distance($0.coordinate, area.center) <= area.radiusMeters }
    }

    /// The area around `point` (e.g. the middle of the map), or nil far from all of them.
    func area(near point: Coordinate) -> Area? {
        areas.filter { Route.distance(point, $0.center) <= $0.radiusMeters + Self.areaReachMeters }
            .min { Route.distance(point, $0.center) < Route.distance(point, $1.center) }
    }

    // MARK: Loading

    static let fileName = "stroll-content"

    /// The bundled content. A missing or broken file is a build mistake, so this stops the app
    /// with a clear message rather than running without content.
    static let shared: StrollContent = {
        do {
            return try load(from: bundledURL())
        } catch {
            fatalError("Couldn't load \(fileName).json: \(error)")
        }
    }()

    static func load(from url: URL) throws -> StrollContent {
        try JSONDecoder().decode(StrollContent.self, from: Data(contentsOf: url))
    }

    /// In the apps the file is a bundle resource. Command-line checks (Tools/) point to it
    /// with the STROLL_CONTENT environment variable instead.
    private static func bundledURL() throws -> URL {
        if let url = Bundle.main.url(forResource: fileName, withExtension: "json") { return url }
        if let path = ProcessInfo.processInfo.environment["STROLL_CONTENT"] { return URL(fileURLWithPath: path) }
        throw CocoaError(.fileNoSuchFile)
    }
}

// MARK: Set walk distances

extension StrollContent.Route {
    /// Walking pace for time estimates: about 3 mph.
    static let metersPerMinute = 80.0
    /// Rough time spent at each stop (buzz, question, story).
    static let minutesPerStop = 2.0

    /// Length of the route line, in meters.
    var meters: Double { Self.length(path) }

    /// Walking plus listening time, rounded up to the minute.
    var minutes: Int { Self.minutes(meters: meters, stops: stops.count) }

    var miles: Double { meters / 1609.344 }

    /// For each stop, its position along `path` (index of the closest path point).
    func pathIndex(of stop: Int, in content: StrollContent) -> Int {
        guard let poi = content.poi(stops[stop].poi), !path.isEmpty else { return 0 }
        return path.indices.min { Self.distance(path[$0], poi.coordinate) < Self.distance(path[$1], poi.coordinate) } ?? 0
    }

    /// Meters along the route from the stop before `stop` to `stop` (0 for the first stop:
    /// the walk starts there).
    func legMeters(to stop: Int, in content: StrollContent) -> Double {
        guard stop > 0, stop < stops.count else { return 0 }
        let from = pathIndex(of: stop - 1, in: content), to = pathIndex(of: stop, in: content)
        guard to > from else { return 0 }
        return Self.length(Array(path[from...to]))
    }

    /// Time left, with `next` the stop being walked to (or at). Stops already passed don't count.
    func minutesLeft(from next: Int, in content: StrollContent) -> Int {
        guard next < stops.count else { return 0 }
        let meters = (next..<stops.count).map { legMeters(to: $0, in: content) }.reduce(0, +)
        return Self.minutes(meters: meters, stops: stops.count - next)
    }

    static func minutes(meters: Double, stops: Int) -> Int {
        Int((meters / metersPerMinute + Double(stops) * minutesPerStop).rounded(.up))
    }

    static func length(_ points: [StrollContent.Coordinate]) -> Double {
        zip(points, points.dropFirst()).map { distance($0, $1) }.reduce(0, +)
    }

    /// Great-circle distance in meters (the same formula as POIDetector, which the watch doesn't build).
    static func distance(_ a: StrollContent.Coordinate, _ b: StrollContent.Coordinate) -> Double {
        let r = 6_371_000.0
        let lat1 = a.latitude * .pi / 180, lat2 = b.latitude * .pi / 180
        let dLat = lat2 - lat1, dLon = (b.longitude - a.longitude) * .pi / 180
        let h = sin(dLat / 2) * sin(dLat / 2) + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        return 2 * r * asin(min(1, sqrt(h)))
    }
}
