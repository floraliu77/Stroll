import CoreLocation
import SwiftUI

/// Which way the phone is pointing, from its compass, while a map is on screen.
/// Needs no extra permission: the compass falls under the location permission from setup.
@MainActor
final class HeadingSource: NSObject, ObservableObject, CLLocationManagerDelegate {
    /// Degrees clockwise from true north (magnetic north if true north isn't known yet), or nil
    /// with no compass reading (the simulator has no compass).
    @Published private(set) var degrees: Double?
    /// How far off the reading may be, in degrees. Larger means a wider cone.
    @Published private(set) var accuracy: Double = 30

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.headingFilter = 2   // ignore tiny wobbles
    }

    func start() {
        guard CLLocationManager.headingAvailable() else { return }
        manager.startUpdatingHeading()
    }

    func stop() { manager.stopUpdatingHeading() }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading heading: CLHeading) {
        guard heading.headingAccuracy >= 0 else { return }   // negative: no valid reading
        let degrees = heading.trueHeading >= 0 ? heading.trueHeading : heading.magneticHeading
        let accuracy = heading.headingAccuracy
        Task { @MainActor in
            self.degrees = degrees
            self.accuracy = accuracy
        }
    }
}

/// The participant on the map, like Apple Maps: a blue dot with a white ring, and a soft blue
/// cone showing which way the phone faces (wider when the compass is unsure). The map always
/// keeps north up, so the cone turns, not the map.
struct HeadingDot: View {
    let degrees: Double?
    var accuracy: Double = 30

    var body: some View {
        ZStack {
            if let degrees {
                HeadingCone(spread: min(max(accuracy * 2, 40), 100))
                    .fill(RadialGradient(colors: [.blue.opacity(0.45), .blue.opacity(0)],
                                         center: .center, startRadius: 6, endRadius: 46))
                    .frame(width: 92, height: 92)
                    .rotationEffect(.degrees(degrees))
                    .animation(.easeOut(duration: 0.2), value: degrees)
            }
            Circle()
                .fill(.blue)
                .frame(width: 18, height: 18)
                .overlay(Circle().stroke(.white, lineWidth: 3))
                .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
        }
        .frame(width: 92, height: 92)
        .allowsHitTesting(false)
        .accessibilityElement()
        .accessibilityLabel(degrees.map { "Your location, facing \(Self.compassName($0))" } ?? "Your location")
    }

    /// "north", "north-east"… for VoiceOver.
    static func compassName(_ degrees: Double) -> String {
        let names = ["north", "north-east", "east", "south-east", "south", "south-west", "west", "north-west"]
        let index = Int((degrees.truncatingRemainder(dividingBy: 360) + 382.5) / 45) % 8
        return names[index]
    }
}

/// A wedge from the middle of its frame, pointing up (north) before rotation.
private struct HeadingCone: Shape {
    let spread: Double   // degrees

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        path.move(to: center)
        // SwiftUI angles start at 3 o'clock; -90° is straight up.
        path.addArc(center: center, radius: radius,
                    startAngle: .degrees(-90 - spread / 2), endAngle: .degrees(-90 + spread / 2), clockwise: false)
        path.closeSubpath()
        return path
    }
}
