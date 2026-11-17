import CoreLocation
import HealthKit
import UserNotifications

/// Asks iOS for the setup permissions (see SetupFlow). Each one waits for the participant's
/// answer before the next prompt appears, so they come one at a time.
@MainActor
final class SystemPermissions: NSObject, PermissionAsker, CLLocationManagerDelegate {
    private let location = CLLocationManager()
    private let health = HKHealthStore()
    private var locationAnswer: CheckedContinuation<Bool, Never>?

    override init() {
        super.init()
        location.delegate = self
    }

    func canAsk(_ permission: SetupPermission) -> Bool {
        switch permission {
        case .location, .notifications: true
        case .health: HKHealthStore.isHealthDataAvailable()
        }
    }

    func ask(_ permission: SetupPermission) async -> Bool {
        let allowed: Bool
        switch permission {
        case .location: allowed = await askLocation()
        case .health: allowed = await askHealth()
        case .notifications: allowed = await askNotifications()
        }
        StrollLog.link.log("setup: \(permission.rawValue, privacy: .public) \(allowed ? "allowed" : "not allowed", privacy: .public)")
        return allowed
    }

    // MARK: Location

    private func askLocation() async -> Bool {
        guard location.authorizationStatus == .notDetermined else { return Self.isAllowed(location.authorizationStatus) }
        return await withCheckedContinuation { c in
            locationAnswer = c
            location.requestWhenInUseAuthorization()
        }
    }

    private static func isAllowed(_ status: CLAuthorizationStatus) -> Bool {
        status == .authorizedWhenInUse || status == .authorizedAlways
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            // Also called when the manager is created; only an actual answer ends the wait.
            guard status != .notDetermined, let answer = self.locationAnswer else { return }
            self.locationAnswer = nil
            answer.resume(returning: Self.isAllowed(status))
        }
    }

    // MARK: Health

    /// The same walking-session permission the watch asks for (WorkoutKeeper). Asking here means
    /// a walk started from the watch doesn't stop for a Health prompt. iOS never says whether
    /// sharing was declined, so this only reports whether the question was answered.
    private func askHealth() async -> Bool {
        do {
            try await health.requestAuthorization(toShare: [HKObjectType.workoutType()], read: [])
            return health.authorizationStatus(for: HKObjectType.workoutType()) == .sharingAuthorized
        } catch {
            return false
        }
    }

    // MARK: Notifications

    private func askNotifications() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
    }
}
