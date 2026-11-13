import Foundation

/// One stop on the walk, as the watch plays it. Built from `StrollContent` (the bundled
/// stroll-content.json); edit the JSON to change text, photos or clips.
struct Find: Identifiable, Hashable {
    let id: Int          // 0-based position on the walk
    let poiID: String    // StrollContent.POI.id
    let name: String
    let category: String
    let symbol: String   // SF Symbol shown next to the category
    let image: String    // asset catalog name
    let cue: String      // route direction; empty if the stop has none
    let prompt: String
    let reveal: String
    let story: [String]
    fileprivate let clips: Clips

    fileprivate struct Clips: Hashable {
        let cue: String?
        let prompt: String
        let reveal: String
        let story: [String]
    }

    var number: Int { id + 1 }

    enum Line: Hashable { case cue, prompt, reveal, story(Int) }

    /// Audio file name (without extension) for one of this find's lines.
    func clip(_ line: Line) -> String {
        switch line {
        case .cue: return clips.cue ?? ""
        case .prompt: return clips.prompt
        case .reveal: return clips.reveal
        case .story(let k): return clips.story[k]
        }
    }
}

enum Walk {
    /// The watch still plays the pre-set Oakland walk until its exploring-mode changes land
    /// (docs/WATCH-EXPLORING-CHANGES.md).
    static let routeID = "oakland"

    static var title: String { StrollContent.shared.route(routeID)?.title ?? "" }

    static let skipLine = StrollContent.shared.lines.skip.narration
    static let doneLine = StrollContent.shared.lines.done.narration

    static let finds: [Find] = {
        let content = StrollContent.shared
        guard let route = content.route(routeID) else { fatalError("No walk '\(routeID)' in stroll-content.json") }
        return route.stops.enumerated().map { index, stop in
            guard let poi = content.poi(stop.poi), let category = content.category(poi.category) else {
                fatalError("Walk '\(routeID)' refers to unknown POI or category: \(stop.poi)")
            }
            return Find(
                id: index,
                poiID: poi.id,
                name: poi.name,
                category: category.name,
                symbol: category.symbol,
                image: poi.image,
                cue: stop.cue?.text ?? "",
                prompt: poi.prompt.text,
                reveal: poi.reveal.text,
                story: poi.story.map(\.text),
                clips: .init(cue: stop.cue?.audio, prompt: poi.prompt.audio, reveal: poi.reveal.audio, story: poi.story.map(\.audio))
            )
        }
    }()
}

/// A line of narration: what's said, and the recorded clip that says it.
struct Narration: Hashable {
    let text: String
    /// Recorded clip name; empty when the line has no recording yet (the iPhone voice reads it).
    let clip: String

    var usesIPhoneVoice: Bool { clip.isEmpty }
}

extension Find {
    func narration(_ line: Line) -> Narration {
        let text: String
        switch line {
        case .cue: text = cue
        case .prompt: text = prompt
        case .reveal: text = reveal
        case .story(let k): text = story[k]
        }
        return Narration(text: text, clip: clip(line))
    }

    /// Reveal followed by the story, in order.
    var storyLines: [Narration] {
        [narration(.reveal)] + story.indices.map { narration(.story($0)) }
    }
}
