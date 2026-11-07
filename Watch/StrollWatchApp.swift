import HealthKit
import SwiftUI
import WatchKit

@main
struct StrollWatchApp: App {
    @WKApplicationDelegateAdaptor private var delegate: StrollWatchDelegate
    @StateObject private var mirror = MirrorModel.shared

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            WalkView()
                .environmentObject(mirror)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { mirror.sync() }
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
    /// Start Exploring was tapped on the watch and the phone hasn't confirmed yet.
    @Published private(set) var isStarting = false

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
            guard reachable else { return }
            self?.problem = nil
            _ = self?.link.send(.sync)   // catch up straight away rather than waiting for the phone
        }
        link.activate()
    }

    func send(_ action: WatchAction) {
        if action == .start {
            start()
            return
        }
        guard link.send(action) else {
            problem = "Can't reach your iPhone. Keep it nearby with Stroll open."
            return
        }
        problem = nil
        // Show the result straight away; the phone's reply confirms or corrects it.
        switch action {
        case .pause:
            var next = state
            next.paused = true
            apply(next)
        case .resume:
            var next = state
            next.paused = false
            apply(next)
        case .reset where state.phase == .ended:
            apply(.idle)
        default:
            break
        }
    }

    /// Start Exploring on the watch: show "Starting…" at once, then ask the phone. The phone's
    /// reply (normally within a second) switches the screen.
    private func start() {
        guard state.phase == .idle, !isStarting else { return }
        isStarting = true
        problem = nil
        Task {
            await Task.yield()   // let "Starting…" appear before talking to the phone
            guard link.send(.start) else {
                isStarting = false
                problem = "Can't reach your iPhone. Keep it nearby with Stroll open."
                return
            }
            try? await Task.sleep(nanoseconds: 8_000_000_000)
            if isStarting {
                isStarting = false
                problem = "Your iPhone didn't answer. Open Stroll on your iPhone and try again."
            }
        }
    }

    /// Ask the phone for its current state, e.g. when the watch app comes back to the screen.
    func sync() {
        _ = link.send(.sync)
    }

    func startWorkout() {
        Task {
            do { try await workout.start() } catch {
                problem = "Allow Health access for Stroll so the watch keeps buzzing with your wrist down."
            }
        }
    }

    private func apply(_ new: MirrorState) {
        let wasBuzzedFor = buzzedFor
        if new.phase != .idle { isStarting = false }
        state = new   // update the screen first; starting the walking session can take a moment
        switch new.phase {
        case .idle:
            buzzedFor = nil
            workout.end()
        case .ended:
            workout.end()
        default:
            if !workout.isRunning {
                // Let the new screen appear before the walking session starts up.
                Task {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    startWorkout()
                }
            }
        }
        // Buzz once when a point of interest comes up (the state may be sent more than once).
        if new.phase == .preview, let id = new.poiID, id != wasBuzzedFor {
            buzzedFor = id
            haptics.buzz()
        }
    }
}
