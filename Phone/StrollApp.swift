import SwiftUI

/// The participant's companion app (round 1: Explore + Journal; see docs/round1-plan.md).
@main
struct StrollApp: App {
    @StateObject private var link = PhoneLink()
    @StateObject private var session = ExploreSession.live()
    @StateObject private var journal = JournalStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            TabView {
                // The tab bar keeps its light style in dark mode too, so it stays readable over
                // the white card.
                ExploreView()
                    .tabItem { Label("Explore", systemImage: "map") }
                    .toolbarColorScheme(.light, for: .tabBar)
                JournalView()
                    .tabItem { Label("Journal", systemImage: "book.closed") }
                    .toolbarColorScheme(.light, for: .tabBar)
            }
            .tint(.strollGreen)
            .environmentObject(link)
            .environmentObject(session)
            .environmentObject(journal)
            .onAppear {
                link.activate(mirroring: session)
                // Each point of interest goes into the Journal as soon as it's explored or skipped.
                session.onVisit = { [journal] visit in
                    journal.add(poiID: visit.poiID, outcome: visit.outcome, at: visit.at)
                }
            }
            .onChange(of: scenePhase) { _, _ in updateReminder() }
            .onChange(of: session.phase) { _, _ in updateReminder() }
        }
    }

    /// While Stroll is in the background, keep a reminder scheduled for the next point of interest.
    private func updateReminder() {
        ExploreNotifications.cancelReminder()
        if scenePhase != .active { ExploreNotifications.scheduleReminder(for: session) }
    }
}

/// Temporary testing tools, opened from the settings button on the Explore map.
struct DeveloperToolsSheet: View {
    var body: some View {
        DeveloperToolsView()
            .presentationDragIndicator(.visible)
    }
}
