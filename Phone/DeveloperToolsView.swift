import SwiftUI

/// Testing tools: the watch connection, and a way to bring up any point of interest now
/// instead of waiting for the demo walk. Everything goes through the phone's session, so the
/// watch mirrors it and only the phone speaks.
struct DeveloperToolsView: View {
    @EnvironmentObject private var link: PhoneLink
    @EnvironmentObject private var session: ExploreSession
    @Environment(\.dismiss) private var dismiss

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
        }
    }

    private var canArrive: Bool { session.phase != .idle && session.phase != .ended }

    private var watchDetail: String {
        if link.isReachable { return "Mirrors the phone: buzz, photo and buttons." }
        if link.isWatchAppInstalled { return "Open Stroll on the watch, or tap Start Exploring." }
        return "Install Stroll on the paired Apple Watch."
    }
}
