import MapKit
import SwiftUI

/// Figma 02 "Explore – map": points of interest as category-only pins, category filters,
/// and the Start Exploring panel.
struct ExploreView: View {
    private let content = StrollContent.shared
    @EnvironmentObject private var session: ExploreSession
    @EnvironmentObject private var link: PhoneLink
    @State private var filter: String?          // nil = All
    /// Starts on the participant's location; until it's known (or without permission), central Oakland.
    @State private var position: MapCameraPosition = .userLocation(fallback: .region(ExploreView.oakland))
    @State private var showingSettings = false
    /// Only reads the last known position (Setup asks for location permission).
    @State private var location = CLLocationManager()
    /// The map has been set to street level around the participant (once per "show my location").
    @State private var centeredOnUser = false
    /// Pins visible on screen (between the top bar and the bottom panel), or nil before the map has drawn.
    @State private var visibleCount: Int?
    /// Where the map shows between the top bar and the bottom panel, on screen (global coordinates).
    @State private var mapWidth: CGFloat = 0
    @State private var topBarBottom: CGFloat = 0
    @State private var panelTop: CGFloat = 0
    /// The area the map is showing, named in the pill at the top. nil when the map is far from all of them.
    @State private var shownArea: StrollContent.Area? = StrollContent.shared.area(near: ExploreView.oakland.center.coordinate)
    /// The pin tapped before exploring starts (its card shows at the bottom), or nil.
    @State private var selectedID: String?
    /// How far the map is zoomed out, kept so a tapped pin can be centred without changing the zoom.
    @State private var cameraDistance: Double?
    /// The compass, for the cone on the participant's dot.
    @StateObject private var heading = HeadingSource()

    /// Street level: about a 5–10 minute walk across the visible map.
    static let streetSpan = MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
    /// Central Oakland (by the Cathedral of Learning) at street level: where the map starts
    /// until the participant's location is known.
    static let oakland = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 40.4443, longitude: -79.9532), span: streetSpan)

    /// Street level around `center`. If no point of interest would be in view, zooms out (still
    /// centred on `center`) just far enough to show the nearest one.
    static func startRegion(around center: CLLocationCoordinate2D, pois: [StrollContent.POI]) -> MKCoordinateRegion {
        let nearest = pois.map(\.coordinate).min { a, b in
            hypot(a.latitude - center.latitude, (a.longitude - center.longitude) * 0.76)
                < hypot(b.latitude - center.latitude, (b.longitude - center.longitude) * 0.76)
        }
        guard let nearest else { return MKCoordinateRegion(center: center, span: streetSpan) }
        // The top bar and bottom panel cover part of the map, so keep the pin well inside the
        // middle (margin 2.6×). 0.76 ≈ cos(latitude) in Pittsburgh: a degree of longitude is shorter.
        let needLat = abs(nearest.latitude - center.latitude) * 2.6
        let needLon = abs(nearest.longitude - center.longitude) * 2.6
        let scale = max(1, needLat / streetSpan.latitudeDelta, needLon / streetSpan.longitudeDelta)
        return MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: streetSpan.latitudeDelta * scale,
                                                                         longitudeDelta: streetSpan.longitudeDelta * scale))
    }

    /// The whole area, with all its points of interest in the open part of the map.
    static func region(showing pois: [StrollContent.POI], around center: CLLocationCoordinate2D) -> MKCoordinateRegion {
        let lats = pois.map(\.coordinate.latitude), lons = pois.map(\.coordinate.longitude)
        guard let minLat = lats.min(), let maxLat = lats.max(), let minLon = lons.min(), let maxLon = lons.max() else {
            return MKCoordinateRegion(center: center, span: streetSpan)
        }
        // The top bar and the taller bottom panel cover part of the map: leave extra height, and
        // put the map's middle a little south so the places sit in the open part.
        let latSpan = max((maxLat - minLat) * 2.2, streetSpan.latitudeDelta)
        let lonSpan = max((maxLon - minLon) * 1.3, streetSpan.longitudeDelta)
        let middle = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2 - latSpan * 0.08, longitude: (minLon + maxLon) / 2)
        return MKCoordinateRegion(center: middle, span: MKCoordinateSpan(latitudeDelta: latSpan, longitudeDelta: lonSpan))
    }

    private var visiblePOIs: [StrollContent.POI] {
        content.pois.filter { filter == nil || $0.category == filter }
    }

    private var selectedPOI: StrollContent.POI? { selectedID.flatMap(content.poi) }

    /// Pins can be tapped before exploring starts. Tapping empty map clears the selection
    /// (the map does that itself); once exploring, taps are ignored so the walk panel stays.
    private var selection: Binding<String?> {
        Binding(get: { selectedID }, set: { id in
            guard session.phase == .idle || id == nil else { return }
            if selectedID != nil, id != nil {
                // From one pin to another: swap the card at once, without sliding the text around.
                var instant = Transaction()
                instant.disablesAnimations = true
                withTransaction(instant) { selectedID = id }
            } else {
                withAnimation(.snappy) { selectedID = id }   // the card slides up, or away
            }
            if let id, let poi = content.poi(id) { center(on: poi) }
        })
    }

    var body: some View {
        MapReader { proxy in
            // North always stays up (no rotate or tilt), so the heading cone, not the map, turns.
            Map(position: $position, interactionModes: [.pan, .zoom], selection: selection) {
                ForEach(visiblePOIs) { poi in
                    // Category on the pin; tap it to see the place's name and photo on a card.
                    Annotation(content.category(poi.category)?.name ?? "", coordinate: poi.coordinate.location, anchor: .center) {
                        CategoryPin(category: poi.category, symbol: content.category(poi.category)?.symbol ?? "mappin",
                                    selected: poi.id == selectedID)
                    }
                    .annotationTitles(.hidden)
                    .tag(poi.id)
                }
                UserAnnotation(anchor: .center) {
                    HeadingDot(degrees: heading.degrees, accuracy: heading.accuracy)
                }
            }
            .mapStyle(.standard(pointsOfInterest: .excludingAll))   // keep Apple's own places out of the way
            .mapControls { }
            .tint(.blue)                                              // "you are here" stays system blue, as in Figma
            .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).width } action: { mapWidth = $0 }
            .safeAreaInset(edge: .top) {
                topBar.onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).maxY } action: { topBarBottom = $0 }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(alignment: .trailing, spacing: 12) {
                    // Always there, above whatever is at the bottom (panel, card, or the slid-down
                    // story sheet), so people can find themselves again.
                    RoundButton(symbol: "location.fill", label: "Show my location", tint: .blue) { showNearMe() }
                        .padding(.trailing, 16)
                    Group {
                        // A set walk has its own full-screen view (WalkInProgressView), over this one.
                        if let poi = selectedPOI, session.phase == .idle {
                            PlaceCard(poi: poi) { withAnimation(.snappy) { selectedID = nil } }
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        } else if session.phase == .idle || session.route != nil {
                            startPanel
                        } else {
                            ExploringPanel()
                        }
                    }
                    .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).minY } action: { panelTop = $0 }
                }
            }
            .onAppear { heading.start() }
            .onDisappear { heading.stop() }
            .onChange(of: session.phase) { _, phase in
                if phase != .idle { selectedID = nil }
            }
            // When a place comes up, follow the participant on the map, so they can see where
            // they are with the story sheet slid down.
            .onChange(of: session.showsStop) { _, showing in
                if showing { showingSettings = false }   // never leave Developer tools waiting to reappear
                if showing, session.route == nil { withAnimation { position = .userLocation(fallback: position) } }
            }
            .onMapCameraChange(frequency: .onEnd) { context in
                cameraDistance = context.camera.distance
                centerOnUserIfNeeded(context.camera.centerCoordinate)
                countVisible(proxy)
                shownArea = content.area(near: context.camera.centerCoordinate.coordinate)
            }
            .onChange(of: filter) { _, _ in countVisible(proxy) }
            .onChange(of: panelTop) { _, _ in countVisible(proxy) }
        }
        .sheet(isPresented: $showingSettings) { DeveloperToolsSheet() }
    }

    /// The first time the map finds the participant (or after Show my location), set street level
    /// around them, zoomed out just enough to show the nearest point of interest if none is close.
    /// Once they pan or zoom themselves, the map is theirs.
    private func centerOnUserIfNeeded(_ center: CLLocationCoordinate2D) {
        guard !centeredOnUser, position.followsUserLocation, let user = location.location?.coordinate else { return }
        centeredOnUser = true
        withAnimation { position = .region(Self.startRegion(around: user, pois: content.pois)) }
    }

    /// Counts the pins the participant can see: inside the map, not under the top bar or the panel.
    private func countVisible(_ proxy: MapProxy) {
        guard mapWidth > 0, panelTop > topBarBottom else { return }
        let visible = CGRect(x: 0, y: topBarBottom, width: mapWidth, height: panelTop - topBarBottom)
        visibleCount = visiblePOIs.filter { poi in
            proxy.convert(poi.coordinate.location, to: .global).map { visible.contains($0) } ?? false
        }.count
    }

    /// Moves a tapped pin to the middle of the map, at the same zoom, so the card doesn't cover it.
    private func center(on poi: StrollContent.POI) {
        centeredOnUser = true   // the participant moved the map on purpose
        withAnimation { position = .camera(MapCamera(centerCoordinate: poi.coordinate.location, distance: cameraDistance ?? 1500)) }
    }

    /// Back to the participant, at street level, as when the map first opens.
    private func showNearMe() {
        centeredOnUser = false
        withAnimation { position = .userLocation(fallback: .region(Self.oakland)) }
    }

    private func show(_ area: StrollContent.Area) {
        centeredOnUser = true   // the map stays on the area, not back on the participant
        shownArea = area
        let places = content.pois(in: area)
        guard let first = places.first else { return }
        withAnimation { position = .region(Self.region(showing: places, around: first.coordinate.location)) }
    }

    // MARK: Top: area, settings, filters

    private var topBar: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                areaPicker
                Spacer()
                RoundButton(symbol: "slider.horizontal.3", label: "Settings") { showingSettings = true }
            }
            .padding(.horizontal, 16)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(title: "All", isSelected: filter == nil) { filter = nil }
                    ForEach(content.categories) { category in
                        FilterChip(title: category.name, isSelected: filter == category.id) { filter = category.id }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 2)
            }
        }
        .padding(.top, 4)
    }

    /// The pill names the area on the map; tapping it lists the areas Stroll covers. A list rather
    /// than a search field while there are only a few.
    private var areaPicker: some View {
        Menu {
            Button { showNearMe() } label: { Label("Near me", systemImage: "location.fill") }
            Section("Areas") {
                ForEach(content.areas) { area in
                    Button { show(area) } label: {
                        if area == shownArea { Label(area.name, systemImage: "checkmark") } else { Text(area.name) }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "location").foregroundStyle(Color.strollGreen)
                Text(shownArea?.name ?? "Choose an area").foregroundStyle(Color.strollInk)
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.strollInk)
            }
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 14).frame(height: 40)
            .background(.white, in: Capsule())
            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
        }
        .accessibilityLabel("Area: \(shownArea?.name ?? "none")")
        .accessibilityHint("Shows the areas you can explore")
    }

    // MARK: Bottom: Start Exploring panel (the locate button sits above it, in body)

    private var startPanel: some View {
        VStack(alignment: .trailing, spacing: 12) {
            VStack(spacing: 14) {
                VStack(spacing: 4) {
                    Text(countText)
                        .font(.title3.bold())
                        .foregroundStyle(Color.strollInk)
                    Text("Start exploring and wander anywhere. You'll feel a buzz when you're near one.")
                        .font(.subheadline)
                        .foregroundStyle(Color.strollMuted)
                        .multilineTextAlignment(.center)
                }
                Button {
                    session.requestStart()   // asks how to listen first if there are no headphones
                    link.launchWatchApp()   // only when started on the phone: the watch is already open otherwise
                } label: {
                    Text("Start Exploring")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .foregroundStyle(.white)
                        .background(Color.strollGreen, in: Capsule())
                }
            }
            .padding(.horizontal, 24).padding(.top, 24).padding(.bottom, 20)   // no grabber: these panels can't be dragged
            .frame(maxWidth: .infinity)
            // The card runs down behind the floating tab bar, so the map doesn't show through.
            .background {
                UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24)
                    .fill(Color.strollPaper)   // light beige, like the Walks and Journal tabs
                    .ignoresSafeArea(edges: .bottom)
            }
            .shadow(color: .black.opacity(0.12), radius: 10, y: -4)
        }
    }

    /// The pins on screen now (it changes as the map moves).
    private var countText: String {
        switch visibleCount {
        case nil: return "Points of interest nearby"
        case 0: return "No points of interest here. Zoom out to see more."
        case 1: return "1 point of interest nearby"
        case let n?: return "\(n) points of interest nearby"
        }
    }
}

// MARK: - Pieces

/// A map pin: a category-coloured circle with the category's icon, white ring and shadow.
/// Selected, it just grows (no outline or glow, by the team's choice after testing).
struct CategoryPin: View {
    let category: String
    let symbol: String
    var selected = false

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: selected ? 22 : 17, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: selected ? 52 : 40, height: selected ? 52 : 40)
            .background(Color.category(category), in: Circle())
            .overlay(Circle().stroke(.white, lineWidth: 3))
            .shadow(color: .black.opacity(selected ? 0.35 : 0.25), radius: selected ? 6 : 3, y: 2)
            .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }
}

/// The card for a tapped pin, above the tab bar: photo on the left, name, category and area on
/// the right. The × (or tapping empty map) closes it.
struct PlaceCard: View {
    let poi: StrollContent.POI
    let close: () -> Void
    private let content = StrollContent.shared

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(poi.image)
                .resizable()
                .scaledToFill()
                .frame(width: 88, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .accessibilityLabel(poi.altText.map { "Photo: \($0)" } ?? "Photo of \(poi.name)")
            VStack(alignment: .leading, spacing: 4) {
                Text(poi.name)
                    .font(.headline)
                    .foregroundStyle(Color.strollInk)
                    .fixedSize(horizontal: false, vertical: true)
                if let category = content.category(poi.category) {
                    Label(category.name, systemImage: category.symbol)
                        .font(.subheadline)
                        .labelStyle(CategoryIconLabel(category: category.id))
                }
                if let area = content.area(poi.area) {
                    Text(area.name)
                        .font(.subheadline)
                        .foregroundStyle(Color.strollMuted)
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
                    .frame(width: 44, height: 44)   // a full-size tap target around the small circle
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, -8).padding(.trailing, -8)
            .accessibilityLabel("Close")
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(Color.strollPaper, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }
}

/// The category icon in its colour, the name in dark text (category colours are for icons and
/// pins; dark text reads best on the beige card).
private struct CategoryIconLabel: LabelStyle {
    let category: String

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.icon.foregroundStyle(Color.category(category))
            configuration.title.foregroundStyle(Color.strollInk)
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? .white : Color.strollInk)
                .padding(.horizontal, 14).frame(height: 34)
                .background(isSelected ? Color.strollGreen : .white, in: Capsule())
                .overlay(Capsule().stroke(isSelected ? .clear : Color.strollBorder))
                .shadow(color: .black.opacity(0.08), radius: 1.5, y: 1)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct RoundButton: View {
    let symbol: String
    let label: String
    var tint: Color = .strollInk
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(tint)
                .frame(width: 44, height: 44)
                .background(.white, in: Circle())
                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

struct GreenIconLabel: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.icon.foregroundStyle(Color.strollGreen)
            configuration.title.foregroundStyle(Color.strollInk)
        }
    }
}

extension StrollContent.Coordinate {
    var location: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: latitude, longitude: longitude) }
}

extension CLLocationCoordinate2D {
    var coordinate: StrollContent.Coordinate { StrollContent.Coordinate(latitude: latitude, longitude: longitude) }
}
