import Foundation

// Checks Shared/Content/stroll-content.json: every reference points at something real
// (categories, POIs, audio clips, photos) and the demo walk is usable. Run: Tools/check-walk-model.sh

let root = URL(fileURLWithPath: CommandLine.arguments[1])
var problems: [String] = []
func check(_ ok: Bool, _ message: String) { if !ok { problems.append(message) } }

let content = StrollContent.shared
let audioDir = root.appendingPathComponent("Resources/Audio")
let assets = root.appendingPathComponent("Resources/Assets.xcassets")
let fm = FileManager.default
func clipExists(_ name: String) -> Bool {
    ["mp3", "m4a"].contains { fm.fileExists(atPath: audioDir.appendingPathComponent("\(name).\($0)").path) }
}

check(Set(content.pois.map(\.id)).count == content.pois.count, "POI ids must be unique")
for poi in content.pois {
    check(content.category(poi.category) != nil, "\(poi.id): unknown category '\(poi.category)'")
    check(fm.fileExists(atPath: assets.appendingPathComponent("\(poi.image).imageset").path), "\(poi.id): no image '\(poi.image)' in the asset catalog")
    check(abs(poi.coordinate.latitude) <= 90 && abs(poi.coordinate.longitude) <= 180, "\(poi.id): coordinate out of range")
    check(poi.triggerRadiusMeters > 0, "\(poi.id): trigger radius must be positive")
    check(!poi.story.isEmpty, "\(poi.id): needs at least one story line")
    for line in [poi.prompt, poi.reveal] + poi.story {
        check(!line.text.isEmpty, "\(poi.id): empty line")
        check(clipExists(line.audio), "\(poi.id): missing audio clip '\(line.audio)'")
    }
}
for line in [content.lines.skip, content.lines.done] { check(clipExists(line.audio), "missing audio clip '\(line.audio)'") }
for route in content.walks {
    for stop in route.stops {
        check(content.poi(stop.poi) != nil, "walk '\(route.id)': unknown POI '\(stop.poi)'")
        if let cue = stop.cue { check(clipExists(cue.audio), "walk '\(route.id)': missing audio clip '\(cue.audio)'") }
    }
}
let demo = content.demoWalk
check(!demo.order.isEmpty, "demo walk has no POIs")
check(Set(demo.order).count == demo.order.count, "demo walk repeats a POI")
for id in demo.order { check(content.poi(id) != nil, "demo walk: unknown POI '\(id)'") }
check(demo.firstBuzzSeconds >= 0 && demo.gapSeconds.min >= 0 && demo.gapSeconds.min <= demo.gapSeconds.max, "demo walk timings are invalid")

if problems.isEmpty {
    print("Content OK: \(content.pois.count) points of interest, \(content.categories.count) categories, demo walk of \(demo.order.count).")
} else {
    problems.forEach { print("FAIL: \($0)") }
    exit(1)
}
