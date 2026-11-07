import Foundation

/// One stop on the walk. Text matches the web prototype word for word, and each line
/// has a recorded clip in Resources/Audio named by `clip(_:)`.
struct Find: Identifiable, Hashable {
    let id: Int          // 0-based position on the walk
    let name: String
    let category: String
    let symbol: String   // SF Symbol shown next to the category
    let image: String    // asset catalog name
    let cue: String
    let prompt: String
    let reveal: String
    let story: [String]

    var number: Int { id + 1 }

    enum Line: Hashable { case cue, prompt, reveal, story(Int) }

    /// Audio file name (without extension) for one of this find's lines.
    func clip(_ line: Line) -> String {
        switch line {
        case .cue: return "f\(number)-cue"
        case .prompt: return "f\(number)-prompt"
        case .reveal: return "f\(number)-reveal"
        case .story(let k): return "f\(number)-story\(k + 1)"
        }
    }
}

enum Walk {
    static let title = "Oakland: Things You've Walked Past"

    static let skipLine = Narration(text: "Okay, onward.", clip: "skip")
    static let doneLine = Narration(text: "Walk complete. Check your phone for your field journal.", clip: "done")

    static let finds: [Find] = [
        Find(
            id: 0,
            name: "Mellon Institute columns",
            category: "Architecture",
            symbol: "building.columns",
            image: "mellon-columns",
            cue: "Start at Fifth Avenue and Bellefield.",
            prompt: "Look at the giant columns on this building. How many stone pieces make up one column?",
            reveal: "None stacked. Each column is a single piece of stone.",
            story: [
                "Each of the 62 columns here is one solid piece of Indiana limestone, about 60 tons.",
                "When the Mellon Institute opened in 1937, they were the largest monolithic columns in the world.",
                "The building, now part of Carnegie Mellon, reaches six stories underground to bedrock, to keep lab experiments steady.",
            ]
        ),
        Find(
            id: 1,
            name: "Dippy the dinosaur",
            category: "Natural history",
            symbol: "leaf",
            image: "dippy",
            cue: "Head down Bellefield to Forbes Avenue.",
            prompt: "Spot the dinosaur outside the museum. Look closely: is it bone, or something else?",
            reveal: "It's a life-size fiberglass copy.",
            story: [
                "This is Dippy, a fiberglass copy of a Diplodocus installed in 1999, 100 years after Andrew Carnegie funded the dig that found the original.",
                "The first bone, a toe, was found in Wyoming on July 4, 1899, earning it the nickname 'the star-spangled dinosaur.'",
                "The real skeleton still stands inside, and Carnegie gave casts to museums in London, Paris, and other cities.",
            ]
        ),
        Find(
            id: 2,
            name: "“A Song to Nature” fountain",
            category: "Public art",
            symbol: "paintpalette",
            image: "song-to-nature",
            cue: "Cross Forbes toward Schenley Plaza and the Frick Fine Arts Building.",
            prompt: "At the fountain, look along the rim of the basin. Find the animals spouting water.",
            reveal: "Turtles. Four bronze turtles spout water into the basin.",
            story: [
                "This 1918 fountain honors Mary Schenley, who donated the land for Schenley Park.",
                "The figures show Humanity playing a lyre to Pan, the earth god.",
                "Its sculptor, Victor David Brenner, also designed the Lincoln penny, so you've probably carried his work in your pocket.",
            ]
        ),
        Find(
            id: 3,
            name: "Forbes Field wall",
            category: "History",
            symbol: "hourglass",
            image: "forbes-wall",
            cue: "Follow Roberto Clemente Drive to the old brick wall by Mazeroski Field.",
            prompt: "Find the numbers on this brick wall. What do you think they measure?",
            reveal: "Distances from home plate: 457 and 436 feet.",
            story: [
                "This wall is all that's left of the outfield of Forbes Field, home of the Pittsburgh Pirates from 1909 to 1970, and of the Negro League Homestead Grays.",
                "Bill Mazeroski's ninth-inning home run here won the 1960 World Series. Fans still gather at this wall every October 13 to relive it.",
                "Home plate from the last game is preserved in the lobby of Posvar Hall, just across the street.",
            ]
        ),
    ]
}

/// A line of narration: what's said, and the recorded clip that says it.
struct Narration: Hashable {
    let text: String
    let clip: String
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
