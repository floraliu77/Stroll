import MapKit
import SwiftUI

/// Figma 07 "Walk in progress": the route with done and upcoming stops, progress at the top,
/// and the next stop with its spoken direction at the bottom. Shown over everything while a
/// set walk runs; each stop opens the same sheet as exploring freely (StopSheet).
struct WalkInProgressView: View {
    @EnvironmentObject private var session: ExploreSession
    @EnvironmentObject private var liveLocation: LiveLocationSource
    @State private var position: MapCameraPosition = .automatic
    @State private var confirmingEnd = false
    /// Height of the next-stop panel down to the bottom of the screen; the story sheet slides down
    /// to exactly this, so it covers the panel instead of sinking below it.
    @State private var panelHeight: CGFloat = 0
    private let content = StrollContent.shared

    var body: some View {
        if let walk = session.route {
            RouteMap(walk: walk, interactive: true, progress: session.stopIndex,
                     found: { session.foundStop($0) }, position: $position)
                .onAppear { position = .region(walk.region) }
                .safeAreaInset(edge: .top) { progressCard(walk) }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    VStack(alignment: .trailing, spacing: 12) {
                        RoundButton(symbol: "location.fill", label: "Show my location", tint: .blue) {
                            withAnimation { position = .userLocation(fallback: .region(walk.region)) }
                        }
                        .padding(.trailing, 16)
                        // Hidden while a stop's sheet is up, so it never shows above the slid-down
                        // sheet. The location button above stays, to find yourself on the route.
                        panel(walk)
                            .opacity(session.showsStop ? 0 : 1)
                            .allowsHitTesting(!session.showsStop)
                            .accessibilityHidden(session.showsStop)
                    }
                }
                .modifier(ListeningPrompts(place: .walk))
                .sheet(isPresented: .constant(session.showsStop)) {
                    StopSheet(collapsedHeight: panelHeight)
                        .modifier(ListeningPrompts(place: .stop))
                        .interactiveDismissDisabled()
                }
                // When a stop comes up on a real walk, follow the walker, so they can see where they
                // are on the route with the story sheet slid down. (In demo mode the phone isn't
                // on the route, so the map stays on the walk.)
                .onChange(of: session.showsStop) { _, showing in
                    if showing, liveLocation.status == .tracking {
                        withAnimation { position = .userLocation(fallback: .region(walk.region)) }
                    }
                }
                .confirmationDialog("End this walk?", isPresented: $confirmingEnd, titleVisibility: .visible) {
                    Button("End walk", role: .destructive) { session.end() }
                } message: {
                    Text("You can see what you found in your Journal.")
                }
        }
    }

    // MARK: Top: walk progress

    private func progressCard(_ walk: StrollContent.Route) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(walk.title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(statusText(walk))
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.75))
                }
                Spacer()
                if session.paused {
                    Label("Paused", systemImage: "pause.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.strollAmber)
                        .padding(.horizontal, 10).frame(height: 26)
                        .background(.white.opacity(0.14), in: Capsule())
                }
            }
            HStack(spacing: 6) {
                ForEach(walk.stops.indices, id: \.self) { index in
                    Capsule()
                        .fill(index < session.stopIndex ? Color.strollAmber : .white.opacity(0.24))
                        .frame(height: 5)
                }
            }
            .accessibilityHidden(true)
        }
        .padding(16)
        .background(Color.strollNight, in: RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    private func statusText(_ walk: StrollContent.Route) -> String {
        if session.phase == .ended { return "Walk complete" }
        let stop = min(session.stopIndex + 1, walk.stops.count)
        return "Stop \(stop) of \(walk.stops.count) · \(walk.minutesLeft(from: session.stopIndex, in: content)) min left"
    }

    // MARK: Bottom: next stop

    private func panel(_ walk: StrollContent.Route) -> some View {
        VStack(spacing: 14) {
            if session.phase == .ended {
                ended(walk)
            } else if let stop = session.currentStop {
                nextStop(walk, stop)
            }
        }
        .padding(.horizontal, 24).padding(.top, 24).padding(.bottom, 20)   // no grabber: these panels can't be dragged
        .frame(maxWidth: .infinity)
        .background {
            UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24)
                .fill(.white)
                .ignoresSafeArea(edges: .bottom)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { panelHeight = $0 }
        }
        .shadow(color: .black.opacity(0.12), radius: 10, y: -4)
    }

    private func nextStop(_ walk: StrollContent.Route, _ stop: StrollContent.Stop) -> some View {
        let category = content.poi(stop.poi).flatMap { content.category($0.category) }
        return VStack(spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: category?.symbol ?? "mappin")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.category(category?.id ?? ""), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.stopIndex == walk.stops.count - 1 ? "LAST STOP" : "NEXT STOP")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.strollMuted)
                    Text(category?.name ?? "Stop")
                        .font(.title3.bold())
                        .foregroundStyle(Color.strollInk)
                }
                Spacer()
                if let meters = distanceToNext(walk, stop) {
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(String(format: "%.1f mi", meters / 1609.344))
                        Text("\(max(1, Int((meters / StrollContent.Route.metersPerMinute).rounded(.up)))) min")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.strollGreen)
                }
            }
            .accessibilityElement(children: .combine)
            if let cue = stop.cue {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: session.reading ? "text.quote" : "headphones")
                        .foregroundStyle(Color.strollGreen)
                        .accessibilityHidden(true)
                    Text("“\(cue.text)”")
                        .font(.subheadline)
                        .foregroundStyle(Color.strollInk)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(14)
                .background(Color.strollPaper, in: RoundedRectangle(cornerRadius: 14))
            }
            HStack(spacing: 12) {
                if session.paused {
                    PanelButton(title: "Resume", symbol: "play.fill", filled: false) { session.resume() }
                } else {
                    PanelButton(title: "Pause", symbol: "pause.fill", filled: false) { session.pause() }
                }
                PanelButton(title: "End walk", symbol: nil, filled: true) { confirmingEnd = true }
            }
            Button("Skip this stop") { session.skipStop() }
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.strollMuted)
        }
    }

    private func ended(_ walk: StrollContent.Route) -> some View {
        let found = walk.stops.indices.filter { session.foundStop($0) }.count
        return VStack(spacing: 14) {
            VStack(spacing: 4) {
                Text("Walk complete")
                    .font(.title3.bold())
                    .foregroundStyle(Color.strollInk)
                Text(found == 0
                     ? "No stories heard this time. Try again another day."
                     : "You heard \(found) of \(walk.stops.count) stops. They're in your Journal.")
                    .font(.subheadline)
                    .foregroundStyle(Color.strollMuted)
                    .multilineTextAlignment(.center)
            }
            PanelButton(title: "Done", symbol: nil, filled: true) { session.reset() }
        }
    }

    /// Straight-line distance from the phone to the next stop when real location is on and
    /// accurate; otherwise the route distance from the stop before it (none before the first).
    private func distanceToNext(_ walk: StrollContent.Route, _ stop: StrollContent.Stop) -> Double? {
        guard let poi = content.poi(stop.poi) else { return nil }
        if liveLocation.status == .tracking, let fix = liveLocation.lastFix {
            return StrollContent.Route.distance(fix.coordinate, poi.coordinate)
        }
        let leg = walk.legMeters(to: session.stopIndex, in: content)
        return leg > 0 ? leg : nil
    }
}
