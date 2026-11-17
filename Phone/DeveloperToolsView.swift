import SwiftUI

/// Testing tools: the watch connection, demo walk or real location (with a GPS readout for
/// outdoor tests), restarting the walk (e.g. for the next participant), and a way to bring up
/// any point of interest now instead of waiting. Everything goes through the phone's session, so the
/// watch mirrors it and only the phone speaks.
struct DeveloperToolsView: View {
    @EnvironmentObject private var link: PhoneLink
    @EnvironmentObject private var session: ExploreSession
    @EnvironmentObject private var journal: JournalStore
    @EnvironmentObject private var liveLocation: LiveLocationSource
    @EnvironmentObject private var setup: SetupFlow
    @AppStorage(WalkMode.storageKey) private var walkMode: WalkMode = .demo
    @Environment(\.dismiss) private var dismiss
    @State private var confirmingRestart = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(link.isReachable ? Color.devGreen : Color.devOrange)
                            .frame(width: 10, height: 10)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(link.isReachable ? "Connected" : "Not reachable").font(.headline)
                            Text(watchDetail).font(.subheadline).foregroundStyle(Color.devSecondary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                } header: {
                    Text("Watch").foregroundStyle(Color.devSecondary)
                }
                Section {
                    Picker("Walk mode", selection: $walkMode) {
                        ForEach(WalkMode.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .disabled(session.phase != .idle)
                } header: {
                    Text("Walk mode").foregroundStyle(Color.devSecondary)
                } footer: {
                    Text(walkModeFooter).foregroundStyle(Color.devSecondary)
                }
                if walkMode == .real {
                    Section {
                        TimelineView(.periodic(from: .now, by: 1)) { context in
                            gpsRows(now: context.date)
                        }
                    } header: {
                        Text("GPS").foregroundStyle(Color.devSecondary)
                    }
                }
                Section {
                    Button {
                        dismiss()
                        setup.reset()
                    } label: {
                        Text("Show welcome screen again")
                            .foregroundStyle(session.phase == .idle ? Color.devGreen : Color.devSecondary)
                    }
                    .disabled(session.phase != .idle)
                } header: {
                    Text("Welcome screen").foregroundStyle(Color.devSecondary)
                } footer: {
                    Text("For testing first launch. iOS remembers earlier answers, so its prompts only appear again after deleting and reinstalling Stroll.")
                        .foregroundStyle(Color.devSecondary)
                }
                Section {
                    Button(role: .destructive) { confirmingRestart = true } label: {
                        Text("Restart walk").foregroundStyle(canRestart ? Color.devRed : Color.devSecondary)
                    }
                    .disabled(!canRestart)
                } header: {
                    Text("Restart").foregroundStyle(Color.devSecondary)
                } footer: {
                    Text("Stops the guide and takes the phone and watch back to Start Exploring.")
                        .foregroundStyle(Color.devSecondary)
                }
                Section {
                    ForEach(session.content.pois) { poi in
                        Button {
                            session.arriveNow(poi.id)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(poi.name).foregroundStyle(Color.primary)
                                Text(session.content.category(poi.category)?.name ?? "")
                                    // A fixed colour, not .secondary: the rows are disabled until exploring
                                    // starts, which dimmed grey text to nearly invisible. ~7:1 contrast in
                                    // light and dark mode.
                                    .font(.footnote).foregroundStyle(Color.devSecondary)
                            }
                        }
                        .disabled(!canArrive)
                    }
                } header: {
                    Text("Bring up a point of interest now").foregroundStyle(Color.devSecondary)
                } footer: {
                    Text(canArrive
                         ? "Starts it straight away, even mid-story. The demo walk carries on afterwards."
                         : "Tap Start Exploring first.")
                        .foregroundStyle(Color.devSecondary)
                }
            }
            .tint(Color.devGreen)   // buttons; the app's green is too dark on the dark-mode sheet
            .navigationTitle("Developer tools")
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Restart the walk?", isPresented: $confirmingRestart, titleVisibility: .visible) {
                if isWalking {
                    Button("Restart, keep journal") { restart(clearJournal: false) }
                }
                if !journal.entries.isEmpty {
                    Button("Restart and clear journal", role: .destructive) { restart(clearJournal: true) }
                }
            } message: {
                Text("Clear the journal too when a new participant is starting.")
            }
        }
    }

    private func restart(clearJournal: Bool) {
        session.reset()   // the watch follows the phone back to the start
        if clearJournal { journal.clear() }
        dismiss()
    }

    private var isWalking: Bool { session.phase != .idle }
    /// Something to restart: a walk going (or just ended), or a journal to clear.
    private var canRestart: Bool { isWalking || !journal.entries.isEmpty }

    private var canArrive: Bool { session.phase != .idle && session.phase != .ended }

    private var walkModeFooter: String {
        let about = walkMode == .demo
            ? "Places come up on a timer, wherever you are. Use it indoors and for demos."
            : "Places come up when you walk within their trigger radius. Start the walk with Stroll open on your phone; it keeps going with the phone locked."
        return session.phase == .idle ? about : about + " End the walk to change the mode."
    }

    @ViewBuilder
    private func gpsRows(now: Date) -> some View {
        LabeledContent("Status") { Text(statusText).foregroundStyle(Color.devSecondary) }   // the default grey is too faint
        if let fix = liveLocation.lastFix {
            LabeledContent("Accuracy") {
                Text("±\(Int(fix.accuracy.rounded())) m")
                    .foregroundStyle(fix.accuracy <= liveLocation.maxAccuracyMeters ? Color.devGreen : Color.devOrange)
            }
            LabeledContent("Updated") { Text("\(max(0, Int(now.timeIntervalSince(fix.at)))) s ago").foregroundStyle(Color.devSecondary) }
            if let nearest = nearestPlace(to: fix.coordinate) {
                LabeledContent("Nearest place") {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(nearest.poi.name).foregroundStyle(Color.primary)
                        Text("\(Int(nearest.meters.rounded())) m away · triggers within \(Int(nearest.poi.triggerRadiusMeters)) m")
                            .font(.caption)
                            .foregroundStyle(nearest.meters <= nearest.poi.triggerRadiusMeters ? Color.devGreen : Color.devSecondary)
                    }
                }
            }
        }
    }

    private var statusText: String {
        switch liveLocation.status {
        case .off: "Starts with Start Exploring"
        case .waiting: "Finding your position…"
        case .weak: "Weak signal: waiting for better accuracy"
        case .tracking: "Tracking"
        case .denied: "Location is off for Stroll. Settings → Stroll → Location → While Using the App"
        }
    }

    private func nearestPlace(to coordinate: StrollContent.Coordinate) -> (poi: StrollContent.POI, meters: Double)? {
        session.content.pois
            .map { (poi: $0, meters: POIDetector.distance(coordinate, $0.coordinate)) }
            .min { $0.meters < $1.meters }
    }

    private var watchDetail: String {
        if link.isReachable { return "Mirrors the phone: buzz, photo and buttons." }
        if link.isWatchAppInstalled { return "Open Stroll on the watch, or tap Start Exploring." }
        return "Install Stroll on the paired Apple Watch."
    }
}

/// Developer tools colours: readable first (looks don't matter here). Each passes WCAG AA
/// (4.5:1) on the sheet's backgrounds in light mode (#FFFFFF, #F2F2F7) and dark mode
/// (#000000, #1C1C1E, #2C2C2E). Checked Nov 16, 2026: green 4.9 / 7.7, red 5.4 / 4.9,
/// orange 5.0 / 7.8, secondary 7.9 / 8.3. The system's grey (3.1) and red (3.2) fail in light
/// mode, and the app's green fails in dark mode (2.5), so they aren't used here.
private extension Color {
    static let devGreen = Color(light: 0x007949, dark: 0x5ED69A)
    static let devRed = Color(light: 0xC4141B, dark: 0xFF6961)
    static let devOrange = Color(light: 0xA35200, dark: 0xFFB340)
    static let devSecondary = Color(light: 0x4A4A50, dark: 0xC7C7CC)

    init(light: UInt32, dark: UInt32) {
        func ui(_ hex: UInt32) -> UIColor {
            UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                    blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
        }
        self.init(uiColor: UIColor { $0.userInterfaceStyle == .dark ? ui(dark) : ui(light) })
    }
}
