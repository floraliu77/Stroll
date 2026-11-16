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

/// Lines with no recording yet, read by the iPhone voice for now: place id -> number of lines.
var iPhoneVoice: [String: Int] = [:]
check(Set(content.pois.map(\.id)).count == content.pois.count, "POI ids must be unique")
for poi in content.pois {
    check(content.category(poi.category) != nil, "\(poi.id): unknown category '\(poi.category)'")
    check(fm.fileExists(atPath: assets.appendingPathComponent("\(poi.image).imageset").path), "\(poi.id): no image '\(poi.image)' in the asset catalog")
    check(abs(poi.coordinate.latitude) <= 90 && abs(poi.coordinate.longitude) <= 180, "\(poi.id): coordinate out of range")
    check(poi.triggerRadiusMeters > 0, "\(poi.id): trigger radius must be positive")
    check(!poi.story.isEmpty, "\(poi.id): needs at least one story line")
    for line in [poi.prompt, poi.reveal] + poi.story {
        check(!line.text.isEmpty, "\(poi.id): empty line")
        if line.hasRecording {
            check(clipExists(line.audio), "\(poi.id): missing audio clip '\(line.audio)'")
        } else {
            iPhoneVoice[poi.id, default: 0] += 1
        }
    }
    if let skip = poi.skipLine {
        check(!skip.text.isEmpty, "\(poi.id): empty skip line")
        if skip.hasRecording { check(clipExists(skip.audio), "\(poi.id): missing audio clip '\(skip.audio)'") }
        else { iPhoneVoice[poi.id, default: 0] += 1 }
    }
}
for line in [content.lines.skip, content.lines.done] { check(clipExists(line.audio), "missing audio clip '\(line.audio)'") }
// Set walks (the Walks tab)
/// Set-walk directions with no recording yet: walk id -> number of lines.
var iPhoneVoiceCues: [String: Int] = [:]
/// A stop must lie on its walk's route line: within this many meters of a path point.
let maxStopOffPath = 60.0
check(Set(content.walks.map(\.id)).count == content.walks.count, "walk ids must be unique")
for route in content.walks {
    let w = "walk '\(route.id)'"
    check(!route.title.isEmpty && !route.summary.isEmpty, "\(w): needs a title and a summary")
    check(fm.fileExists(atPath: assets.appendingPathComponent("\(route.cover).imageset").path), "\(w): no cover image '\(route.cover)' in the asset catalog")
    check(route.stops.count >= 2, "\(w): needs at least two stops")
    check(Set(route.stops.map(\.poi)).count == route.stops.count, "\(w): repeats a stop")
    check(route.path.count >= 2, "\(w): its route line needs at least two points")
    for point in route.path {
        check(abs(point.latitude) <= 90 && abs(point.longitude) <= 180, "\(w): route point out of range")
    }
    var lastPathIndex = -1
    for (k, stop) in route.stops.enumerated() {
        guard let poi = content.poi(stop.poi) else {
            check(false, "\(w): unknown POI '\(stop.poi)'")
            continue
        }
        check(!stop.street.isEmpty, "\(w): stop \(k + 1) needs a street")
        check(!stop.street.localizedCaseInsensitiveContains(poi.name), "\(w): stop \(k + 1)'s street gives away its name")
        let nearest = route.path.map { StrollContent.Route.distance($0, poi.coordinate) }.min() ?? .infinity
        check(nearest <= maxStopOffPath, "\(w): stop \(k + 1) (\(poi.id)) is \(Int(nearest)) m from the route line")
        let index = route.pathIndex(of: k, in: content)
        check(index > lastPathIndex, "\(w): stop \(k + 1) comes before the stop ahead of it along the route line")
        lastPathIndex = index
        if let cue = stop.cue {
            check(!cue.text.isEmpty, "\(w): stop \(k + 1) has an empty direction")
            if cue.hasRecording { check(clipExists(cue.audio), "\(w): missing audio clip '\(cue.audio)'") }
            else { iPhoneVoiceCues[route.id, default: 0] += 1 }
        }
    }
    check(route.minutes > 0, "\(w): time estimate must be positive")
}
let demo = content.demoWalk
check(!demo.order.isEmpty, "demo walk has no POIs")
check(Set(demo.order).count == demo.order.count, "demo walk repeats a POI")
for id in demo.order { check(content.poi(id) != nil, "demo walk: unknown POI '\(id)'") }
check(demo.firstBuzzSeconds >= 0 && demo.gapSeconds.min >= 0 && demo.gapSeconds.min <= demo.gapSeconds.max, "demo walk timings are invalid")
check(demo.walkGapSeconds >= 0, "demo walk: walkGapSeconds can't be negative")

if problems.isEmpty {
    print("Content OK: \(content.pois.count) points of interest, \(content.categories.count) categories, demo walk of \(demo.order.count).")
    for route in content.walks {
        print("Set walk '\(route.id)': \(route.stops.count) stops, \(String(format: "%.1f", route.miles)) mi, about \(route.minutes) min.")
    }
    if !iPhoneVoice.isEmpty {
        let lines = iPhoneVoice.values.reduce(0, +)
        print("To record later: \(lines) lines in \(iPhoneVoice.count) places use the iPhone voice as a placeholder:")
        for id in content.pois.map(\.id) where iPhoneVoice[id] != nil {
            print("  - \(id): \(iPhoneVoice[id]!) lines")
        }
    }
    for (id, n) in iPhoneVoiceCues.sorted(by: { $0.key < $1.key }) {
        print("To record later: walk '\(id)' has \(n) directions read by the iPhone voice.")
    }
} else {
    problems.forEach { print("FAIL: \($0)") }
    exit(1)
}
