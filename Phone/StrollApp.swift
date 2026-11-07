import SwiftUI

/// The participant's companion app (round 1: Explore + Journal; see docs/round1-plan.md).
@main
struct StrollApp: App {
    @StateObject private var link = PhoneLink()
    @StateObject private var session = ExploreSession.live()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            TabView {
                ExploreView()
                    .tabItem { Label("Explore", systemImage: "map") }
                JournalPlaceholderView()
                    .tabItem { Label("Journal", systemImage: "book.closed") }
            }
            .tint(.strollGreen)
            .environmentObject(link)
            .environmentObject(session)
            .onAppear { link.activate(mirroring: session) }
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

/// Stand-in until the Journal screen is built.
struct JournalPlaceholderView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ContentUnavailableView("Nothing here yet",
                                   systemImage: "book.closed",
                                   description: Text("Points of interest you find on a walk will appear here."))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // Paper in light mode; the system's dark background in dark mode, so the
                // (automatically light) text stays readable.
                .background(colorScheme == .dark ? Color(.systemBackground) : Color.strollPaper)
                .navigationTitle("Journal")
        }
    }
}

/// Temporary testing tools, opened from the settings button on the Explore map.
struct DeveloperToolsSheet: View {
    var body: some View {
        DeveloperToolsView()
            .presentationDragIndicator(.visible)
    }
}
