// Asks Apple Maps for walking directions between each set walk's stops and prints the
// street-following lines as JSON ({"walk id": [[lat, lon], ...]}). Tools/walk-routes.sh runs
// this and saves the lines into each walk's "path". The stop's own point is kept at both ends of
// its legs, so the line reaches the pin even when the pin sits off the sidewalk.
import Foundation
import MapKit

struct Content: Decodable {
    struct Coordinate: Decodable { let latitude: Double; let longitude: Double }
    struct POI: Decodable { let id: String; let coordinate: Coordinate }
    struct Stop: Decodable { let poi: String }
    struct Walk: Decodable { let id: String; let stops: [Stop] }
    let pois: [POI]
    let walks: [Walk]
}

func fail(_ message: String) -> Never {
    FileHandle.standardError.write((message + "\n").data(using: .utf8)!)
    exit(1)
}

guard let path = CommandLine.arguments.dropFirst().first else { fail("usage: walk-routes <stroll-content.json> [walk id ...]") }
let only = Set(CommandLine.arguments.dropFirst(2))
let content = try JSONDecoder().decode(Content.self, from: Data(contentsOf: URL(fileURLWithPath: path)))

func point(_ id: String) -> CLLocationCoordinate2D {
    guard let poi = content.pois.first(where: { $0.id == id }) else { fail("Unknown POI '\(id)'") }
    return CLLocationCoordinate2D(latitude: poi.coordinate.latitude, longitude: poi.coordinate.longitude)
}

func walkingLine(from a: CLLocationCoordinate2D, to b: CLLocationCoordinate2D) async throws -> [CLLocationCoordinate2D] {
    let request = MKDirections.Request()
    request.source = MKMapItem(location: CLLocation(latitude: a.latitude, longitude: a.longitude), address: nil)
    request.destination = MKMapItem(location: CLLocation(latitude: b.latitude, longitude: b.longitude), address: nil)
    request.transportType = .walking
    guard let route = try await MKDirections(request: request).calculate().routes.first else { return [] }
    var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: route.polyline.pointCount)
    route.polyline.getCoordinates(&coords, range: NSRange(location: 0, length: coords.count))
    return coords
}

var result: [String: [[Double]]] = [:]
for walk in content.walks where only.isEmpty || only.contains(walk.id) {
    let stops = walk.stops.map { point($0.poi) }
    var line = [stops[0]]
    for (a, b) in zip(stops, stops.dropFirst()) {
        line += try await walkingLine(from: a, to: b)
        line.append(b)
        try await Task.sleep(nanoseconds: 300_000_000)   // gentle on Apple's servers
    }
    // Drop points closer than about a meter to the one before (where legs meet).
    var kept: [CLLocationCoordinate2D] = []
    for c in line {
        if let last = kept.last, abs(last.latitude - c.latitude) < 0.00001, abs(last.longitude - c.longitude) < 0.00001 { continue }
        kept.append(c)
    }
    result[walk.id] = kept.map { [($0.latitude * 1e6).rounded() / 1e6, ($0.longitude * 1e6).rounded() / 1e6] }
}
let out = try JSONSerialization.data(withJSONObject: result, options: [.sortedKeys])
print(String(data: out, encoding: .utf8)!)
