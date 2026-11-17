import SwiftUI

/// The participant's companion app (round 1: Explore + Journal; see docs/round1-plan.md).
@main
struct StrollApp: App {
    @StateObject private var link = PhoneLink()
    @StateObject private var session = ExploreSession.live()
    @StateObject private var journal = JournalStore()
    /// The phone's real position, used when Developer tools is set to Real location.
    @StateObject private var liveLocation = LiveLocationSource()
    /// The first-launch setup: an intro screen, then one screen per permission.
    @StateObject private var setup = SetupFlow(asker: SystemPermissions())
    @AppStorage(WalkMode.storageKey) private var walkMode: WalkMode = .demo
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            Group {
                if setup.needsWelcome {
                    WelcomeView()
                        .transition(.opacity)
                } else {
                    RootTabs()
                }
            }
            .animation(.easeInOut(duration: 0.3), value: setup.needsWelcome)
            .environmentObject(setup)
            .environmentObject(link)
            .environmentObject(session)
            .environmentObject(journal)
            .environmentObject(liveLocation)
            .onAppear {
                useWalkMode()
                link.activate(mirroring: session)
                // Each point of interest goes into the Journal as soon as it's explored or skipped.
                session.onVisit = { [journal] visit in
                    journal.add(poiID: visit.poiID, outcome: visit.outcome, at: visit.at,
                                walkID: visit.walkID, tripID: visit.tripID)
                }
            }
            .onChange(of: scenePhase) { _, _ in updateReminder() }
            .onChange(of: session.phase) { _, _ in updateReminder() }
            .onChange(of: walkMode) { _, _ in useWalkMode() }
        }
    }

    /// Points the session at the demo walk or the phone's real position. Developer tools only
    /// lets the mode change before a walk starts.
    private func useWalkMode() {
        switch walkMode {
        case .real:
            session.useSource(liveLocation)
        case .demo:
            if !(session.source is DemoWalk) { session.useSource(DemoWalk(content: session.content)) }
        }
    }

    /// While Stroll is in the background, keep a reminder scheduled for the next point of interest.
    private func updateReminder() {
        ExploreNotifications.cancelReminder()
        if scenePhase != .active { ExploreNotifications.scheduleReminder(for: session) }
    }
}

/// The three tabs (Explore, Walks, Journal), with Stroll's own tab bar: a white floating bar with the selected tab in green,
/// the same in light and dark mode. (The system tab bar takes its style from the screen behind
/// it, so over the dark-mode map it couldn't stay light with a green selected tab.)
struct RootTabs: View {
    enum Tab: Hashable { case explore, walks, journal }

    @EnvironmentObject private var session: ExploreSession
    @EnvironmentObject private var link: PhoneLink
    @EnvironmentObject private var liveLocation: LiveLocationSource
    @State private var tab = Tab.explore
    /// The Walks tab's navigation: a walk's detail has its own Start walk bar instead of the tab bar (Figma 06).
    @State private var walkPath: [String] = []

    var body: some View {
        ZStack {
            // The map stays alive underneath, so switching tabs keeps it where it was. The Journal
            // is only there while it's shown: otherwise its light style sets the status bar's dark
            // text over the dark-mode map.
            ExploreView()
                .accessibilityHidden(tab != .explore)
            if tab == .walks {
                WalksView(path: $walkPath)
            }
            if tab == .journal {
                JournalView()
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if tab != .walks || walkPath.isEmpty {
                StrollTabBar(selection: $tab)
            }
        }
        .tint(.strollGreen)
        // A set walk takes the whole screen while it runs (Figma 07, no tab bar), whether it
        // was started here or the session was already on one.
        .fullScreenCover(isPresented: .constant(session.route != nil)) {
            WalkInProgressView()
                .environmentObject(session)
                .environmentObject(link)
                .environmentObject(liveLocation)
        }
    }
}

private struct StrollTabBar: View {
    @Binding var selection: RootTabs.Tab

    var body: some View {
        HStack(spacing: 4) {
            item(.explore, title: "Explore", symbol: "map", selectedSymbol: "map.fill")
            item(.walks, title: "Walks", symbol: "point.topleft.down.to.point.bottomright.curvepath",
                 selectedSymbol: "point.topleft.down.to.point.bottomright.curvepath.fill")
            item(.journal, title: "Journal", symbol: "book.closed", selectedSymbol: "book.closed.fill")
        }
        .padding(5)
        .background(.white, in: Capsule())
        .overlay(Capsule().stroke(Color.strollBorder))
        .shadow(color: .black.opacity(0.15), radius: 8, y: 2)
        .padding(.bottom, 4)
    }

    private func item(_ tab: RootTabs.Tab, title: String, symbol: String, selectedSymbol: String) -> some View {
        let isSelected = selection == tab
        return Button { selection = tab } label: {
            VStack(spacing: 2) {
                Image(systemName: isSelected ? selectedSymbol : symbol)
                    .font(.system(size: 20, weight: .semibold))
                Text(title)
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(isSelected ? Color.strollGreen : Color.strollInk)
            .frame(width: 92, height: 52)
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
