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
    @AppStorage(WalkMode.storageKey) private var walkMode: WalkMode = .demo
    @Environment(\.dismiss) private var dismiss
    @State private var confirmingRestart = false

    var body: some View {
        NavigationStack {
            List {
                Section("Watch") {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(link.isReachable ? Color.green : Color.orange)
                            .frame(width: 10, height: 10)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(link.isReachable ? "Connected" : "Not reachable").font(.headline)
                            Text(watchDetail).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
                Section {
                    Picker("Walk mode", selection: $walkMode) {
                        ForEach(WalkMode.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .disabled(session.phase != .idle)
                } header: {
                    Text("Walk mode")
                } footer: {
                    Text(walkModeFooter)
                }
                if walkMode == .real {
                    Section("GPS") {
                        TimelineView(.periodic(from: .now, by: 1)) { context in
                            gpsRows(now: context.date)
                        }
                    }
                }
                Section {
                    Button("Restart walk", role: .destructive) { confirmingRestart = true }
                        .disabled(!canRestart)
                } header: {
                    Text("Restart")
                } footer: {
                    Text("Stops the guide and takes the phone and watch back to Start Exploring.")
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
                                    .font(.footnote).foregroundStyle(.secondary)
                            }
                        }
                        .disabled(!canArrive)
                    }
                } header: {
                    Text("Bring up a point of interest now")
                } footer: {
                    Text(canArrive
                         ? "Starts it straight away, even mid-story. The demo walk carries on afterwards."
                         : "Tap Start Exploring first.")
                }
            }
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
        LabeledContent("Status", value: statusText)
        if let fix = liveLocation.lastFix {
            LabeledContent("Accuracy") {
                Text("±\(Int(fix.accuracy.rounded())) m")
                    .foregroundStyle(fix.accuracy <= liveLocation.maxAccuracyMeters ? Color.green : Color.orange)
            }
            LabeledContent("Updated", value: "\(max(0, Int(now.timeIntervalSince(fix.at)))) s ago")
            if let nearest = nearestPlace(to: fix.coordinate) {
                LabeledContent("Nearest place") {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(nearest.poi.name)
                        Text("\(Int(nearest.meters.rounded())) m away · triggers within \(Int(nearest.poi.triggerRadiusMeters)) m")
                            .font(.caption)
                            .foregroundStyle(nearest.meters <= nearest.poi.triggerRadiusMeters ? Color.green : Color.secondary)
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
