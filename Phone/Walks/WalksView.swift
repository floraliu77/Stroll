import MapKit
import SwiftUI

/// Figma 05 "Walks": the set walks, as cards. Tapping one opens its detail (Figma 06).
struct WalksView: View {
    /// The walk ids shown (the detail, when one is open). RootTabs hides its tab bar on the detail.
    @Binding var path: [String]
    private let content = StrollContent.shared

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Walks")
                            .font(.largeTitle.bold())
                            .foregroundStyle(Color.strollInk)
                        Text("Guided routes, with stops chosen for you.")
                            .font(.subheadline)
                            .foregroundStyle(Color.strollMuted)
                    }
                    .padding(.horizontal, 4)
                    ForEach(content.walks) { walk in
                        NavigationLink(value: walk.id) {
                            WalkCard(walk: walk)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(Color.strollPaper)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: String.self) { id in
                if let walk = content.route(id) { WalkDetailView(walk: walk) }
            }
        }
    }
}

/// A walk's card: cover photo, title, "4 stops · 16 min · 0.4 mi", and its categories.
struct WalkCard: View {
    let walk: StrollContent.Route
    private let content = StrollContent.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(walk.cover)
                .resizable()
                .scaledToFill()
                .frame(height: 150)
                .frame(maxWidth: .infinity)
                .clipped()
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text(walk.title)
                    .font(.title3.bold())
                    .foregroundStyle(Color.strollInk)
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
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
        .accessibilityElement(children: .combine)
    }
}

/// Figma 06 "Walk detail": cover, time / distance / stops, summary, route preview, the stops
/// (category and street only: what's there stays a surprise), and Start walk.
struct WalkDetailView: View {
    let walk: StrollContent.Route
    private let content = StrollContent.shared
    @EnvironmentObject private var session: ExploreSession
    @EnvironmentObject private var link: PhoneLink
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Image(walk.cover)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 290)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .overlay(alignment: .top) {
                        LinearGradient(colors: [.black.opacity(0.35), .clear], startPoint: .top, endPoint: .bottom)
                            .frame(height: 120)
                    }
                    .accessibilityHidden(true)
                details
                    .padding(.top, -28)
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Color.strollPaper)
        .overlay(alignment: .topLeading) {
            RoundButton(symbol: "chevron.left", label: "Back") { dismiss() }
                .padding(.leading, 16)
                .padding(.top, 4)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { startBar }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(walk.title)
                .font(.title.bold())
                .foregroundStyle(Color.strollInk)
            HStack(spacing: 16) {
                Meta(symbol: "clock", text: "\(walk.minutes) min")
                Meta(symbol: "point.topleft.down.to.point.bottomright.curvepath", text: walk.milesText)
                Meta(symbol: "mappin", text: "\(walk.stops.count) stops")
            }
            Text(walk.summary)
                .font(.body)
                .foregroundStyle(Color.strollMuted)
                .fixedSize(horizontal: false, vertical: true)
            RouteMap(walk: walk, interactive: false)
                .frame(height: 210)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            Text("Stops")
                .font(.title3.bold())
                .foregroundStyle(Color.strollInk)
            VStack(spacing: 0) {
                ForEach(Array(walk.stops.enumerated()), id: \.offset) { index, stop in
                    if index > 0 { Divider().padding(.leading, 60) }
                    StopRow(number: index + 1, stop: stop)
                }
            }
            .background(.white, in: RoundedRectangle(cornerRadius: 16))
            Text("What's at each stop stays a surprise until you get there.")
                .font(.footnote)
                .foregroundStyle(Color.strollMuted)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.strollPaper, in: UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28))
    }

    private var startBar: some View {
        VStack(spacing: 8) {
            Button {
                ExploreNotifications.requestPermission()
                session.start(walk: walk)
                link.launchWatchApp()
            } label: {
                Text("Start walk")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .foregroundStyle(.white)
                    .background(session.phase == .idle ? Color.strollGreen : Color.strollMuted, in: Capsule())
            }
            .disabled(session.phase != .idle)
            Text(session.phase == .idle
                 ? "Put your phone away. Stroll guides you through your watch and earbuds."
                 : "You're exploring on the Explore tab. End that first to start this walk.")
                .font(.caption)
                .foregroundStyle(Color.strollMuted)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24).padding(.top, 14).padding(.bottom, 8)
        .background(.white)
    }
}

private struct Meta: View {
    let symbol: String
    let text: String

    var body: some View {
        Label(text, systemImage: symbol)
            .font(.subheadline.weight(.semibold))
            .labelStyle(GreenIconLabel())
    }
}

private struct StopRow: View {
    let number: Int
    let stop: StrollContent.Stop
    private let content = StrollContent.shared

    var body: some View {
        let category = content.poi(stop.poi).flatMap { content.category($0.category) }
        HStack(spacing: 12) {
            Image(systemName: category?.symbol ?? "mappin")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(Color.category(category?.id ?? ""), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text("\(number). \(category?.name ?? "Stop")")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.strollInk)
                Text(stop.street)
                    .font(.footnote)
                    .foregroundStyle(Color.strollMuted)
            }
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Route map

/// A set walk's route on the map with numbered stops. In progress (`session` on a walk), stops
/// already passed show a check (found) or are greyed, the next one is larger with a ring, and
/// the route still to walk is dotted.
struct RouteMap: View {
    let walk: StrollContent.Route
    var interactive: Bool
    var progress: Int? = nil          // the next stop, during the walk
    var found: (Int) -> Bool = { _ in false }
    @Binding var position: MapCameraPosition
    private let content = StrollContent.shared

    init(walk: StrollContent.Route, interactive: Bool, progress: Int? = nil, found: @escaping (Int) -> Bool = { _ in false },
         position: Binding<MapCameraPosition>? = nil) {
        self.walk = walk
        self.interactive = interactive
        self.progress = progress
        self.found = found
        _position = position ?? .constant(.region(walk.region))
    }

    var body: some View {
        Map(position: $position, interactionModes: interactive ? .all : []) {
            let split = progress.map { $0 > 0 ? walk.pathIndex(of: $0 - 1, in: content) : 0 } ?? 0
            if split > 0 {
                MapPolyline(coordinates: walk.path[0...split].map(\.location))
                    .stroke(Color.strollGreen, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
            }
            MapPolyline(coordinates: walk.path[split...].map(\.location))
                .stroke(Color.strollGreen, style: progress == nil
                        ? StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                        : StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round, dash: [1, 8]))
            ForEach(Array(walk.stops.enumerated()), id: \.offset) { index, stop in
                if let poi = content.poi(stop.poi) {
                    Annotation("Stop \(index + 1)", coordinate: poi.coordinate.location, anchor: .center) {
                        StopBadge(number: index + 1, category: poi.category, state: state(index))
                    }
                    .annotationTitles(.hidden)
                }
            }
            if interactive { UserAnnotation() }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .mapControls { }
        .tint(.blue)
    }

    private func state(_ index: Int) -> StopBadge.State {
        guard let progress else { return .preview }
        if index < progress { return found(index) ? .found : .passed }
        return index == progress ? .next : .later
    }
}

struct StopBadge: View {
    enum State { case preview, found, passed, next, later }
    let number: Int
    let category: String
    let state: State

    var body: some View {
        ZStack {
            if state == .next {
                Circle().fill(Color.category(category).opacity(0.18)).frame(width: 64, height: 64)
            }
            Group {
                switch state {
                case .found:
                    Image(systemName: "checkmark").font(.system(size: 13, weight: .bold))
                case .passed:
                    Image(systemName: "minus").font(.system(size: 13, weight: .bold))
                default:
                    Text("\(number)").font(.system(size: size * 0.42, weight: .bold))
                }
            }
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(fill, in: Circle())
            .overlay(Circle().stroke(.white, lineWidth: state == .preview ? 2 : 3))
            .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
        }
        .accessibilityLabel(label)
    }

    private var size: CGFloat {
        switch state {
        case .preview: 22
        case .next: 40
        default: 30
        }
    }

    private var fill: Color {
        switch state {
        case .found: .strollGreen
        case .passed: .strollMuted
        default: .category(category)
        }
    }

    private var label: String {
        switch state {
        case .found: "Stop \(number), found"
        case .passed: "Stop \(number), passed"
        case .next: "Stop \(number), next"
        default: "Stop \(number)"
        }
    }
}

// MARK: - Helpers

extension StrollContent.Route {
    /// "4 stops · 16 min · 0.4 mi"
    var metaText: String { "\(stops.count) stops · \(minutes) min · \(milesText)" }

    var milesText: String { String(format: "%.1f mi", miles) }

    /// The categories of its stops, in route order, without repeats.
    func categoryIDs(in content: StrollContent) -> [String] {
        var seen: [String] = []
        for stop in stops {
            if let id = content.poi(stop.poi)?.category, !seen.contains(id) { seen.append(id) }
        }
        return seen
    }

    /// The whole route with a margin.
    var region: MKCoordinateRegion {
        let lats = path.map(\.latitude), lons = path.map(\.longitude)
        let center = CLLocationCoordinate2D(latitude: (lats.min()! + lats.max()!) / 2, longitude: (lons.min()! + lons.max()!) / 2)
        let span = MKCoordinateSpan(latitudeDelta: (lats.max()! - lats.min()!) * 1.5 + 0.001,
                                    longitudeDelta: (lons.max()! - lons.min()!) * 1.5 + 0.003)
        return MKCoordinateRegion(center: center, span: span)
    }
}
