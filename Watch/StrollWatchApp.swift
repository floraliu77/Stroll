import HealthKit
import SwiftUI
import WatchKit

@main
struct StrollWatchApp: App {
    @WKApplicationDelegateAdaptor private var delegate: StrollWatchDelegate
    @StateObject private var mirror = MirrorModel.shared

    var body: some Scene {
        WindowGroup {
            WalkView()
                .environmentObject(mirror)
        }
    }
}

/// Opened by the phone when exploring starts (HKHealthStore.startWatchApp): start the
/// walking session straight away so the watch stays awake.
@MainActor
final class StrollWatchDelegate: NSObject, WKApplicationDelegate {
    func handle(_ workoutConfiguration: HKWorkoutConfiguration) {
        MirrorModel.shared.startWorkout()
    }
}

/// What the watch shows: a mirror of the phone's exploring session. The phone leads and
/// speaks; the watch buzzes, shows the photo and buttons, and sends taps back.
@MainActor
final class MirrorModel: ObservableObject {
    static let shared = MirrorModel()

    @Published private(set) var state = MirrorState.idle
    @Published private(set) var phoneReachable = false
    @Published private(set) var problem: String?

    let content = StrollContent.shared
    var poi: StrollContent.POI? { state.poiID.flatMap { content.poi($0) } }
    var category: StrollContent.Category? { poi.flatMap { content.category($0.category) } }

    private let link = WatchLink()
    private let workout = WorkoutKeeper()
    private let haptics = WatchHaptics()
    private var buzzedFor: String?

    private init() {
        link.onState = { [weak self] in self?.apply($0) }
        link.onReachabilityChange = { [weak self] reachable in
            self?.phoneReachable = reachable
            if reachable { self?.problem = nil }
        }
        link.activate()
    }

    func send(_ action: WatchAction) {
        problem = link.send(action) ? nil : "Can't reach your iPhone. Keep it nearby with Stroll open."
    }

    func startWorkout() {
        Task {
            do { try await workout.start() } catch {
                problem = "Allow Health access for Stroll so the watch keeps buzzing with your wrist down."
            }
        }
    }

    private func apply(_ new: MirrorState) {
        switch new.phase {
        case .idle:
            buzzedFor = nil
            workout.end()
        case .ended:
            workout.end()
        default:
            if !workout.isRunning { startWorkout() }
        }
        // Buzz once when a point of interest comes up (the state may be sent more than once).
        if new.phase == .preview, let id = new.poiID, id != buzzedFor {
            buzzedFor = id
            haptics.buzz()
        }
        state = new
    }
}
