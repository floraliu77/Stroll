import CoreLocation
import Foundation

/// Which positions the walk uses. Chosen in Developer tools and remembered between launches.
enum WalkMode: String, CaseIterable, Identifiable {
    /// The scripted demo walk: places come up on a timer, wherever you are. For desks and demos.
    case demo
    /// The phone's real position: places come up when you walk within their trigger radius.
    case real

    static let storageKey = "walkMode"

    var id: String { rawValue }
    var title: String { self == .demo ? "Demo walk" : "Real location" }
}

/// The phone's real position, for walks outside. Feeds the same place detection as the demo walk
/// (`POIDetector`, through `ExploreSession`).
///
/// Keeps going with the phone locked in a pocket: the walk holds a background location session
/// (Phone/Info.plist lists the `location` background mode), and iOS shows the blue location
/// indicator meanwhile. The permission stays "While Using the App". Start the walk with Stroll
/// open on the phone; iOS only allows the background session to begin while the app is in use.
@MainActor
final class LiveLocationSource: NSObject, ObservableObject, LocationSource, CLLocationManagerDelegate {
    /// A position from the phone, accurate or not.
    struct Fix: Equatable {
        let coordinate: StrollContent.Coordinate
        /// Radius of uncertainty in meters (smaller is better).
        let accuracy: Double
        let at: Date
    }

    enum Status: Equatable {
        case off        // no walk running
        case waiting    // walk started, no position yet
        case weak       // positions are coming in, but too inaccurate to use
        case tracking   // using positions
        case denied     // location is off for Stroll in Settings
    }

    var onLocation: (@MainActor (StrollContent.Coordinate) -> Void)?
    var isFinished: Bool { false }        // real walks end when the participant taps End
    var secondsUntilNext: Double? { nil } // nothing is scheduled; places come up as you walk

    @Published private(set) var status: Status = .off
    @Published private(set) var lastFix: Fix?

    /// Positions less accurate than this are shown in Developer tools but don't trigger places.
    /// Tall buildings (the Cathedral of Learning, Fifth Avenue) can push accuracy past it.
    let maxAccuracyMeters = 30.0

    private let manager = CLLocationManager()
    private var updates: Task<Void, Never>?
    private var background: CLBackgroundActivitySession?
    private var paused = false

    override init() {
        super.init()
        manager.delegate = self
    }

    var isDenied: Bool { [.denied, .restricted].contains(manager.authorizationStatus) }

    func start() {
        stop()
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
        status = isDenied ? .denied : .waiting
        background = CLBackgroundActivitySession()   // keeps updates coming with the phone locked
        updates = Task { @MainActor [weak self] in
            do {
                for try await update in CLLocationUpdate.liveUpdates(.fitness) {
                    guard let self, !Task.isCancelled else { return }
                    self.received(update.location)
                }
            } catch {}   // the stream ended; Status shows what's going on
        }
    }

    func stop() {
        updates?.cancel()
        updates = nil
        background?.invalidate()
        background = nil
        paused = false
        status = .off
    }

    func pause() { paused = true }
    func resume() { paused = false }
    func participantIsFree() {}

    private func received(_ location: CLLocation?) {
        guard let location, updates != nil else { return }
        let fix = Fix(coordinate: StrollContent.Coordinate(latitude: location.coordinate.latitude,
                                                           longitude: location.coordinate.longitude),
                      accuracy: location.horizontalAccuracy,
                      at: location.timestamp)
        lastFix = fix
        guard fix.accuracy >= 0, fix.accuracy <= maxAccuracyMeters else {
            status = .weak
            return
        }
        status = .tracking
        guard !paused else { return }
        onLocation?(fix.coordinate)
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let denied = [.denied, .restricted].contains(manager.authorizationStatus)
        Task { @MainActor in
            if denied, self.updates != nil { self.status = .denied }
            else if !denied, self.status == .denied { self.status = .waiting }
        }
    }
}
