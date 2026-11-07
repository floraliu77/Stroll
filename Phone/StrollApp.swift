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
            RootTabs()
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

/// The two tabs, with Stroll's own tab bar: a white floating bar with the selected tab in green,
/// the same in light and dark mode. (The system tab bar takes its style from the screen behind
/// it, so over the dark-mode map it couldn't stay light with a green selected tab.)
struct RootTabs: View {
    enum Tab: Hashable { case explore, journal }

    @State private var tab = Tab.explore

    var body: some View {
        ZStack {
            // The map stays alive underneath, so switching tabs keeps it where it was. The Journal
            // is only there while it's shown: otherwise its light style sets the status bar's dark
            // text over the dark-mode map.
            ExploreView()
                .accessibilityHidden(tab != .explore)
            if tab == .journal {
                JournalView()
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            StrollTabBar(selection: $tab)
        }
        .tint(.strollGreen)
    }
}

private struct StrollTabBar: View {
    @Binding var selection: RootTabs.Tab

    var body: some View {
        HStack(spacing: 4) {
            item(.explore, title: "Explore", symbol: "map")
            item(.journal, title: "Journal", symbol: "book.closed")
        }
        .padding(5)
        .background(.white, in: Capsule())
        .overlay(Capsule().stroke(Color.strollBorder))
        .shadow(color: .black.opacity(0.15), radius: 8, y: 2)
        .padding(.bottom, 4)
    }

    private func item(_ tab: RootTabs.Tab, title: String, symbol: String) -> some View {
        let isSelected = selection == tab
        return Button { selection = tab } label: {
            VStack(spacing: 2) {
                Image(systemName: isSelected ? symbol + ".fill" : symbol)
                    .font(.system(size: 20, weight: .semibold))
                Text(title)
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(isSelected ? Color.strollGreen : Color.strollInk)
            .frame(width: 96, height: 52)
            .background(isSelected ? Color.strollGreen.opacity(0.12) : .clear, in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Temporary testing tools, opened from the settings button on the Explore map.
struct DeveloperToolsSheet: View {
    var body: some View {
        DeveloperToolsView()
            .presentationDragIndicator(.visible)
    }
}
