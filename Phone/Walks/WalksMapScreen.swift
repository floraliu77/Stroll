import MapKit
import SwiftUI

/// The Walks tab, like AllTrails: every set walk drawn on a map, grey and faint, and a sheet
/// listing them. Tap a route or a row to pick a walk: its line turns green with its numbered
/// stops, the map fits it, and a card offers Start walk or See stops. One colour for "picked",
/// so more walks later don't turn into a rainbow of routes.
struct WalksMapScreen: View {
    /// Opens a walk's detail page (See stops).
    let openDetail: (String) -> Void
    private let content = StrollContent.shared
    @EnvironmentObject private var session: ExploreSession
    @EnvironmentObject private var link: PhoneLink
    @State private var position: MapCameraPosition = .region(WalksMapScreen.allWalksRegion)
    @State private var selectedID: String?
    /// The list sheet dragged up to show every walk as a big card.
    @State private var expanded = false
    @StateObject private var heading = HeadingSource()
    /// The floating tab bar's height: everything here stays above it (this screen is inside a
    /// NavigationStack, which doesn't get the tab bar's room as safe area).
    @Environment(\.tabBarInset) private var tabBarInset
    /// The screen's height, for the expanded list (about three quarters of it).
    @State private var screenHeight: CGFloat = 800
    /// The map's fixed bottom margin: the short list's height, measured once.
    @State private var bottomMargin: CGFloat = 0

    private var selected: StrollContent.Route? { selectedID.flatMap(content.route) }

    /// Every walk in view: the walks are all in Oakland for now.
    static var allWalksRegion: MKCoordinateRegion {
        let points = StrollContent.shared.walks.flatMap(\.path)
        guard let minLat = points.map(\.latitude).min(), let maxLat = points.map(\.latitude).max(),
              let minLon = points.map(\.longitude).min(), let maxLon = points.map(\.longitude).max() else {
            return ExploreView.oakland
        }
        // Extra room below for the list sheet.
        let latSpan = (maxLat - minLat) * 2.4 + 0.002, lonSpan = (maxLon - minLon) * 1.4 + 0.003
        return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2 - latSpan * 0.15,
                                                                 longitude: (minLon + maxLon) / 2),
                                  span: MKCoordinateSpan(latitudeDelta: latSpan, longitudeDelta: lonSpan))
    }

    var body: some View {
        MapReader { proxy in
            Map(position: $position, interactionModes: [.pan, .zoom]) {
                // Grey ones first, so the picked walk is drawn on top.
                ForEach(content.walks.filter { $0.id != selectedID }) { walk in
                    MapPolyline(coordinates: walk.path.map(\.location))
                        .stroke(Color.strollMuted.opacity(0.4), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                    if let start = walk.path.first {
                        // Where the walk starts: a grey pin the size of the Explore pins, easy to tap.
                        Annotation(walk.title, coordinate: start.location, anchor: .center) {
                            Button { select(walk.id) } label: {
                                WalkPin(symbol: "figure.walk", fill: .strollMuted)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(walk.title) walk")
                        }
                        .annotationTitles(.hidden)
                    }
                }
                if let walk = selected {
                    MapPolyline(coordinates: walk.path.map(\.location))
                        .stroke(Color.strollGreen, style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
                    ForEach(Array(walk.stops.enumerated()), id: \.offset) { index, stop in
                        if let poi = content.poi(stop.poi) {
                            Annotation("Stop \(index + 1)", coordinate: poi.coordinate.location, anchor: .center) {
                                WalkPin(number: index + 1, fill: .category(poi.category))
                                    .allowsHitTesting(false)
                                    .accessibilityLabel("Stop \(index + 1)")
                            }
                            .annotationTitles(.hidden)
                        }
                    }
                }
                UserAnnotation(anchor: .center) {
                    HeadingDot(degrees: heading.degrees, accuracy: heading.accuracy)
                }
            }
            .mapStyle(.standard(pointsOfInterest: .excludingAll))
            .mapControls { }
            .tint(.blue)
            // Tap on or near a route to pick it; tap empty map to let go.
            .onTapGesture { point in select(walk(near: point, proxy: proxy)) }
            // A fixed bottom margin (the short list's height) and the panels floating over the map:
            // when the list turned into the card, the map used to resize, jump and flash black.
            .safeAreaInset(edge: .bottom) { Color.clear.frame(height: bottomMargin) }
            .overlay(alignment: .bottom) {
                VStack(alignment: .trailing, spacing: 12) {
                    RoundButton(symbol: "location.fill", label: "Show my location", tint: .blue) {
                        withAnimation { position = .userLocation(fallback: .region(Self.allWalksRegion)) }
                    }
                    .padding(.trailing, 16)
                    if let walk = selected {
                        WalkMapCard(walk: walk, start: { start(walk) }, seeStops: { openDetail(walk.id) },
                                    close: { select(nil) })
                            .padding(.bottom, tabBarInset)   // above the floating tab bar
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        listSheet
                            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
                                if !expanded { bottomMargin = max(bottomMargin, height) }
                            }
                    }
                }
            }
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { screenHeight = $0 }
        .onAppear { heading.start() }
        .onDisappear { heading.stop() }
    }

    // MARK: Picking a walk

    private func select(_ id: String?) {
        if selectedID != nil, id != nil {
            // From one walk to another: swap at once, as with the Explore cards.
            var instant = Transaction()
            instant.disablesAnimations = true
            withTransaction(instant) { selectedID = id }
        } else {
            withAnimation(.snappy) { selectedID = id }
        }
        if let id, let walk = content.route(id) {
            expanded = false
            withAnimation { position = .region(Self.fitted(walk.region)) }
        }
    }

    /// The route with room below it for the card.
    private static func fitted(_ region: MKCoordinateRegion) -> MKCoordinateRegion {
        let latSpan = region.span.latitudeDelta * 1.6
        return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: region.center.latitude - latSpan * 0.15,
                                                                 longitude: region.center.longitude),
                                  span: MKCoordinateSpan(latitudeDelta: latSpan, longitudeDelta: region.span.longitudeDelta * 1.2))
    }

    /// The walk whose line passes within a finger's width of `point` (on screen), if any.
    private func walk(near point: CGPoint, proxy: MapProxy) -> String? {
        var best: (id: String, distance: CGFloat)?
        for walk in content.walks {
            let points = walk.path.compactMap { proxy.convert($0.location, to: .local) }
            for (a, b) in zip(points, points.dropFirst()) {
                let d = Self.distance(from: point, toSegment: a, b)
                if d < 28, d < (best?.distance ?? .infinity) { best = (walk.id, d) }
            }
        }
        return best?.id
    }

    private static func distance(from p: CGPoint, toSegment a: CGPoint, _ b: CGPoint) -> CGFloat {
        let dx = b.x - a.x, dy = b.y - a.y
        let lengthSquared = dx * dx + dy * dy
        guard lengthSquared > 0 else { return hypot(p.x - a.x, p.y - a.y) }
        let t = max(0, min(1, ((p.x - a.x) * dx + (p.y - a.y) * dy) / lengthSquared))
        return hypot(p.x - (a.x + t * dx), p.y - (a.y + t * dy))
    }

    private func start(_ walk: StrollContent.Route) {
        ExploreNotifications.requestPermission()
        session.requestStart(walk: walk)   // asks how to listen first if there are no headphones
        link.launchWatchApp()
    }

    // MARK: The list sheet

    /// "2 walks in Oakland, Pittsburgh" (the area of the first walk's first stop).
    private var title: String {
        let count = content.walks.count
        let area = content.walks.first?.stops.first.flatMap { content.poi($0.poi) }.flatMap { content.area($0.area) }
        let walks = count == 1 ? "1 walk" : "\(count) walks"
        return area.map { "\(walks) in \($0.name)" } ?? walks
    }

    /// Drags up for every walk as a big card, down for a short list. The grabber is real: this
    /// sheet moves.
    private var listSheet: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button { withAnimation(.snappy) { expanded.toggle() } } label: {
                Capsule().fill(Color.strollBorder).frame(width: 36, height: 5)
                    .frame(maxWidth: .infinity, minHeight: 20)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(expanded ? "Show more map" : "Show all walks")
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(Color.strollInk)
            if expanded {
                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(content.walks) { walk in
                            Button { select(walk.id) } label: { WalkCard(walk: walk) }
                                .buttonStyle(.plain)
                        }
                    }
                    .padding(.bottom, 8)
                }
                // The sheet reaches about three quarters of the screen; the cards scroll inside it.
                .frame(maxHeight: max(220, screenHeight * 0.75 - 90 - tabBarInset))
            } else {
                VStack(spacing: 12) {
                    ForEach(content.walks) { walk in
                        Button { select(walk.id) } label: { WalkRow(walk: walk) }
                            .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, 24).padding(.top, 6)
        .padding(.bottom, 20 + tabBarInset)   // the rows end above the floating tab bar
        .frame(maxWidth: .infinity, alignment: .leading)
        // The sheet itself runs down behind the tab bar, so the map doesn't show through.
        .background {
            UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24)
                .fill(Color.strollPaper)
                .ignoresSafeArea(edges: .bottom)
        }
        .shadow(color: .black.opacity(0.12), radius: 10, y: -4)
        .gesture(DragGesture(minimumDistance: 12).onEnded { drag in
            if drag.translation.height < -40 { withAnimation(.snappy) { expanded = true } }
            if drag.translation.height > 40 { withAnimation(.snappy) { expanded = false } }
        })
    }
}

/// A pin on the Walks map, the same size as the Explore pins (40 pt, white ring, shadow): a
/// walk's start (an icon) or, on the picked walk, a numbered stop.
private struct WalkPin: View {
    var symbol: String? = nil
    var number: Int? = nil
    let fill: Color

    var body: some View {
        Group {
            if let number {
                Text("\(number)").font(.system(size: 17, weight: .bold))
            } else {
                Image(systemName: symbol ?? "mappin").font(.system(size: 17, weight: .semibold))
            }
        }
        .foregroundStyle(.white)
        .frame(width: 40, height: 40)
        .background(fill, in: Circle())
        .overlay(Circle().stroke(.white, lineWidth: 3))
        .shadow(color: .black.opacity(0.25), radius: 3, y: 2)
    }
}

/// A walk in the short list: thumbnail, title, and stops · time · distance.
private struct WalkRow: View {
    let walk: StrollContent.Route

    var body: some View {
        HStack(spacing: 12) {
            Image(walk.cover)
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(walk.title)
                    .font(.headline)
                    .foregroundStyle(Color.strollInk)
                Text(walk.metaText)
                    .font(.subheadline)
                    .foregroundStyle(Color.strollMuted)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.strollMuted)
                .accessibilityHidden(true)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// The card for a picked walk, above the tab bar: photo, title, stops · time · distance and its
/// categories, then Start walk and See stops. The × (or tapping empty map) lets it go.
private struct WalkMapCard: View {
    let walk: StrollContent.Route
    let start: () -> Void
    let seeStops: () -> Void
    let close: () -> Void
    @EnvironmentObject private var session: ExploreSession
    private let content = StrollContent.shared

    var body: some View {
        VStack(spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                Image(walk.cover)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(walk.title)
                        .font(.headline)
                        .foregroundStyle(Color.strollInk)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(walk.metaText)
                        .font(.subheadline)
                        .foregroundStyle(Color.strollMuted)
                    HStack(spacing: 6) {
                        ForEach(walk.categoryIDs(in: content), id: \.self) { id in
                            Image(systemName: content.category(id)?.symbol ?? "mappin")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.category(id))
                                .accessibilityLabel(content.category(id)?.name ?? "")
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
                Button(action: close) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.strollInk)
                        .frame(width: 30, height: 30)
                        .background(Color.strollInk.opacity(0.08), in: Circle())
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.top, -8).padding(.trailing, -8)
                .accessibilityLabel("Close")
            }
            HStack(spacing: 10) {
                PanelButton(title: "Start walk", symbol: nil, filled: true, action: start)
                    .disabled(session.phase != .idle)
                    .opacity(session.phase == .idle ? 1 : 0.5)
                PanelButton(title: "See stops", symbol: nil, filled: false, action: seeStops)
            }
            if session.phase != .idle {
                Text("You're exploring on the Explore tab. End that first to start this walk.")
                    .font(.caption)
                    .foregroundStyle(Color.strollMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(14)
        .background(Color.strollPaper, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }
}
