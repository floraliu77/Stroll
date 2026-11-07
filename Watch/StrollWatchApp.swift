import SwiftUI

@main
struct StrollWatchApp: App {
    @StateObject private var app = WatchAppState()

    var body: some Scene {
        WindowGroup {
            WalkView()
                .environmentObject(app)
                .environmentObject(app.walk)
        }
    }
}

/// Wires the walk to the real watch: narration, buzz, workout session and the iPhone link.
@MainActor
final class WatchAppState: ObservableObject {
    let walk: WalkModel
    private let link = WatchLink()
    private let workout = WorkoutKeeper()

    @Published private(set) var isPreparing = false
    @Published private(set) var setupProblem: String?

    init() {
        walk = WalkModel(narrator: NarrationPlayer(), haptics: WatchHaptics())
        walk.onEvent = { [link] event in link.send(event) }
        link.onCommand = { [walk] command in walk.handle(command) }
        link.onReachable = { [walk] in walk.handle(.requestStatus) }
        link.activate()
    }

    /// "Get ready": start the workout (keeps the app running) and route audio to earbuds.
    func getReady() async {
        isPreparing = true
        defer { isPreparing = false }
        setupProblem = nil
        do {
            try await workout.start()
        } catch {
            setupProblem = "Couldn't start the walk session. Check Health permissions for Stroll."
            return
        }
        guard await EarbudAudio.activate() else {
            setupProblem = "Connect earbuds, then tap Get ready again."
            return
        }
        walk.ready()
    }

    /// For desk testing without earbuds: narration is skipped if there's no audio route.
    func continueWithoutEarbuds() {
        setupProblem = nil
        walk.ready()
    }
}
