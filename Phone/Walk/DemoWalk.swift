import Foundation

/// Finds the point of interest a location is in range of. Used for the demo walk now and
/// for live location later.
enum POIDetector {
    /// The closest point of interest within its trigger radius, skipping `excluded` ids.
    static func poi(near location: StrollContent.Coordinate, in pois: [StrollContent.POI], excluding excluded: Set<String>) -> StrollContent.POI? {
        pois.filter { !excluded.contains($0.id) }
            .map { (poi: $0, meters: distance(location, $0.coordinate)) }
            .filter { $0.meters <= $0.poi.triggerRadiusMeters }
            .min { $0.meters < $1.meters }?
            .poi
    }

    /// Great-circle distance in meters.
    static func distance(_ a: StrollContent.Coordinate, _ b: StrollContent.Coordinate) -> Double {
        let r = 6_371_000.0
        let lat1 = a.latitude * .pi / 180, lat2 = b.latitude * .pi / 180
        let dLat = lat2 - lat1, dLon = (b.longitude - a.longitude) * .pi / 180
        let h = sin(dLat / 2) * sin(dLat / 2) + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        return 2 * r * asin(min(1, sqrt(h)))
    }
}

/// The scripted demo walk (docs/round1-plan.md): pretends the participant walks up to each
/// point of interest in `demoWalk.order`, wherever they really are. The first arrives
/// `firstBuzzSeconds` after Start Exploring; each next one a random `gapSeconds` after the
/// participant is free again. Pausing pauses the countdown.
@MainActor
final class DemoWalk: LocationSource {
    var onLocation: (@MainActor (StrollContent.Coordinate) -> Void)?

    private let stops: [StrollContent.Coordinate]
    private let firstSeconds: Double
    private let gapSeconds: ClosedRange<Double>
    private var next = 0
    private var countdown: Task<Void, Never>?
    private var remaining: Double?
    private var paused = false

    init(stops: [StrollContent.Coordinate], firstSeconds: Double, gapSeconds: ClosedRange<Double>) {
        self.stops = stops
        self.firstSeconds = firstSeconds
        self.gapSeconds = gapSeconds
    }

    convenience init(content: StrollContent) {
        let demo = content.demoWalk
        self.init(stops: demo.order.compactMap { content.poi($0)?.coordinate },
                  firstSeconds: demo.firstBuzzSeconds,
                  gapSeconds: demo.gapSeconds.min...demo.gapSeconds.max)
    }

    var isFinished: Bool { next >= stops.count && countdown == nil }
    var secondsUntilNext: Double? { remaining }

    func start() {
        stop()
        next = 0
    }

    func stop() {
        countdown?.cancel()
        countdown = nil
        remaining = nil
        paused = false
    }

    func pause() { paused = true }

    func resume() { paused = false }

    func participantIsFree() {
        guard countdown == nil, next < stops.count else { return }   // already counting down, or done
        remaining = next == 0 ? firstSeconds : Double.random(in: gapSeconds)
        countdown = Task { @MainActor [weak self] in
            await self?.countDown()
        }
    }

    private func countDown() async {
        var last = Date()
        while let left = remaining, left > 0 {
            do { try await Task.sleep(nanoseconds: 100_000_000) } catch { return }   // stopped
            let now = Date()
            if !paused { remaining = left - now.timeIntervalSince(last) }
            last = now
        }
        guard !Task.isCancelled else { return }
        let stop = stops[next]
        next += 1
        remaining = nil
        countdown = nil
        onLocation?(stop)
    }
}
