import SwiftUI

/// The moderator's remote: buzz each find as the participant reaches it, and keep a log.
struct RemoteView: View {
    @EnvironmentObject private var link: PhoneLink
    @State private var confirmingReset = false

    var body: some View {
        NavigationStack {
            List {
                watchSection
                findsSection
                logSection
            }
            .navigationTitle("Developer tools")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Reset", role: .destructive) { confirmingReset = true }
                        .disabled(!link.isReachable)
                }
            }
            .confirmationDialog("Reset the walk on the watch?", isPresented: $confirmingReset, titleVisibility: .visible) {
                Button("Reset walk", role: .destructive) { link.send(.reset) }
            } message: {
                Text("Clears this participant's progress so the next one starts at find 1. The log stays.")
            }
        }
    }

    // MARK: Watch

    private var watchSection: some View {
        Section("Watch") {
            HStack(spacing: 10) {
                Circle()
                    .fill(link.isReachable ? Color.green : Color.orange)
                    .frame(width: 10, height: 10)
                VStack(alignment: .leading, spacing: 2) {
                    Text(link.isReachable ? "Connected" : "Not reachable")
                        .font(.headline)
                    Text(statusText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .combine)
            if let error = link.sendError {
                Text(error).font(.footnote).foregroundStyle(.orange)
            }
        }
    }

    private var statusText: String {
        guard link.isWatchAppInstalled || link.isReachable else {
            return "Install Stroll on the paired Apple Watch."
        }
        guard let status = link.status else {
            return "Open Stroll on the watch."
        }
        let find = status.find.map { "Find \($0 + 1)" } ?? ""
        let text: String
        switch status.screen {
        case .setup: text = "Waiting for the participant to tap Get ready"
        case .waiting: text = "Keep walking: ready for the next find"
        case .alert: text = "\(find): buzzed, playing directions"
        case .prompt: text = "\(find): Tell me more or Skip"
        case .story: text = "\(find): playing the story"
        case .finished: text = "\(find): story finished, waiting for Continue walking"
        case .skipping: text = "\(find): skipped"
        case .done: text = "Walk complete"
        }
        return status.paused ? "\(text) (paused)" : text
    }

    // MARK: Finds

    private var findsSection: some View {
        Section {
            ForEach(Walk.finds) { find in
                Button {
                    link.send(.trigger(find: find.id))
                } label: {
                    FindRow(find: find,
                            outcome: link.status?.outcomes[find.id],
                            isCurrent: link.status?.find == find.id && link.status?.screen != .waiting,
                            isNext: find.id == nextFind)
                }
                .disabled(!canTrigger)
            }
        } header: {
            Text("Buzz a find")
        } footer: {
            Text("Tap a find when the participant reaches it. The watch buzzes, shows the photo and plays the directions. Tapping one mid-story interrupts it.")
        }
    }

    private var canTrigger: Bool {
        guard link.isReachable, let status = link.status else { return false }
        return status.screen != .setup
    }

    /// The first find the participant hasn't done yet.
    private var nextFind: Int? {
        guard let status = link.status else { return 0 }
        return Walk.finds.first { status.outcomes[$0.id] == nil && status.find != $0.id }?.id
    }

    // MARK: Log

    private var logSection: some View {
        Section {
            if link.log.isEmpty {
                Text("Taps on the watch appear here.").foregroundStyle(.secondary)
            }
            ForEach(link.log.reversed()) { entry in
                HStack(alignment: .firstTextBaseline) {
                    Text(entry.at, format: .dateTime.hour().minute().second())
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                    Text(entry.text).font(.subheadline)
                }
            }
        } header: {
            HStack {
                Text("Session log")
                Spacer()
                if !link.log.isEmpty {
                    ShareLink(item: link.logText) { Label("Export", systemImage: "square.and.arrow.up") }
                        .labelStyle(.iconOnly)
                    Button("Clear") { link.clearLog() }
                }
            }
        }
    }
}

private struct FindRow: View {
    let find: Find
    let outcome: Outcome?
    let isCurrent: Bool
    let isNext: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text("\(find.number)")
                .font(.headline)
                .frame(width: 32, height: 32)
                .background(Circle().fill(isNext ? Color.accentColor : Color.secondary.opacity(0.2)))
                .foregroundStyle(isNext ? Color.white : Color.primary)
            VStack(alignment: .leading, spacing: 2) {
                Text(find.name).font(.body.weight(.semibold)).foregroundStyle(Color.primary)
                Text(find.category).font(.footnote).foregroundStyle(.secondary)
            }
            Spacer()
            if isCurrent {
                Text("Now").badgeStyle(.blue)
            } else if let outcome {
                Text(outcome == .found ? "Explored" : "Skipped")
                    .badgeStyle(outcome == .found ? .green : .gray)
            }
        }
        .padding(.vertical, 4)
    }
}

private extension Text {
    func badgeStyle(_ color: Color) -> some View {
        self.font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(color.opacity(0.18)))
            .foregroundStyle(color)
    }
}
