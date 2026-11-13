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
        let altText: String?             // what VoiceOver says about the photo; never gives away the answer
        let photoCredit: PhotoCredit
        let prompt: Line
        let reveal: Line
        let story: [Line]
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
    struct Line: Decodable, Hashable {
        let text: String
        let audio: String

        var narration: Narration { Narration(text: text, clip: audio) }
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
    }

    struct SecondsRange: Decodable {
        let min: Double
        let max: Double
    }

    /// A pre-set walk. Route directions ("cues") belong to stops, not to POIs.
    struct Route: Decodable, Identifiable {
        let id: String
        let title: String
        let stops: [Stop]
    }

    struct Stop: Decodable {
        let poi: String                  // POI.id
        let cue: Line?
    }

    func poi(_ id: String) -> POI? { pois.first { $0.id == id } }
    func category(_ id: String) -> Category? { categories.first { $0.id == id } }
    func route(_ id: String) -> Route? { walks.first { $0.id == id } }

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
