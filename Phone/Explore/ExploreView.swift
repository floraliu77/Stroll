import MapKit
import SwiftUI

/// Figma 02 "Explore – map": points of interest as category-only pins, category filters,
/// and the Start Exploring panel.
struct ExploreView: View {
    private let content = StrollContent.shared
    @EnvironmentObject private var session: ExploreSession
    @EnvironmentObject private var link: PhoneLink
    @State private var filter: String?          // nil = All
    @State private var position: MapCameraPosition = .region(ExploreView.pilotArea)
    @State private var showingSettings = false
    @State private var location = CLLocationManager()

    /// Shows every point of interest (the pilot area in Oakland).
    static var pilotArea: MKCoordinateRegion {
        let coords = StrollContent.shared.pois.map(\.coordinate)
        let lats = coords.map(\.latitude), lons = coords.map(\.longitude)
        let center = CLLocationCoordinate2D(latitude: (lats.min()! + lats.max()!) / 2, longitude: (lons.min()! + lons.max()!) / 2)
        let span = MKCoordinateSpan(latitudeDelta: (lats.max()! - lats.min()!) * 2.2 + 0.002, longitudeDelta: (lons.max()! - lons.min()!) * 1.6 + 0.002)
        return MKCoordinateRegion(center: center, span: span)
    }

    private var visiblePOIs: [StrollContent.POI] {
        content.pois.filter { filter == nil || $0.category == filter }
    }

    var body: some View {
        Map(position: $position) {
            ForEach(visiblePOIs) { poi in
                // Category only: the name and photo stay a surprise until it's found.
                Annotation(content.category(poi.category)?.name ?? "", coordinate: poi.coordinate.location, anchor: .center) {
                    CategoryPin(category: poi.category, symbol: content.category(poi.category)?.symbol ?? "mappin")
                }
                .annotationTitles(.hidden)
            }
            UserAnnotation()
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))   // keep Apple's own places out of the way
        .mapControls { }
        .tint(.blue)                                              // "you are here" stays system blue, as in Figma
        .safeAreaInset(edge: .top) { topBar }
        .safeAreaInset(edge: .bottom) {
            if session.phase == .idle { startPanel } else { ExploringPanel() }
        }
        .onAppear { location.requestWhenInUseAuthorization() }
        .sheet(isPresented: $showingSettings) { DeveloperToolsSheet() }
    }

    // MARK: Top: location, settings, filters

    private var topBar: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Oakland, Pittsburgh", systemImage: "location")
                    .font(.subheadline.weight(.semibold))
                    .labelStyle(GreenIconLabel())
                    .padding(.horizontal, 14).frame(height: 40)
                    .background(.white, in: Capsule())
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
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

    // MARK: Bottom: locate button and Start Exploring panel

    private var startPanel: some View {
        VStack(alignment: .trailing, spacing: 12) {
            RoundButton(symbol: "location.fill", label: "Show my location", tint: .blue) {
                withAnimation { position = .userLocation(fallback: .region(Self.pilotArea)) }
            }
            .padding(.trailing, 16)
            VStack(spacing: 14) {
                Capsule().fill(Color.strollBorder).frame(width: 36, height: 5)
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
                    ExploreNotifications.requestPermission()
                    session.start()
                    link.launchWatchApp()   // only when started on the phone: the watch is already open otherwise
                } label: {
                    Text("Start Exploring")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .foregroundStyle(.white)
                        .background(Color.strollGreen, in: Capsule())
                }
            }
            .padding(.horizontal, 24).padding(.top, 10).padding(.bottom, 20)
            .frame(maxWidth: .infinity)
            .background(.white, in: UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24))
            .shadow(color: .black.opacity(0.12), radius: 10, y: -4)
        }
    }

    private var countText: String {
        let n = visiblePOIs.count
        return n == 1 ? "1 point of interest nearby" : "\(n) points of interest nearby"
    }
}

// MARK: - Pieces

/// A map pin: a category-coloured circle with the category's icon, white ring and shadow.
struct CategoryPin: View {
    let category: String
    let symbol: String

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 40, height: 40)
            .background(Color.category(category), in: Circle())
            .overlay(Circle().stroke(.white, lineWidth: 3))
            .shadow(color: .black.opacity(0.25), radius: 3, y: 2)
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
