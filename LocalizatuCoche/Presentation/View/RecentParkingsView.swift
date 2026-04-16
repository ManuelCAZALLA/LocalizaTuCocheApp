import SwiftUI
import CoreLocation
import MapKit

struct RecentParkingsView: View {
    
    @State private var items: [ParkingLocation] = []
    @State private var selected: ParkingLocation?
    @State private var searchText: String = ""
    
    @AppStorage("favoriteParkings") private var favoriteIDsData: Data = Data()
    
    private let loadOnAppear: Bool
    
    init(loadOnAppear: Bool = true) {
        self.loadOnAppear = loadOnAppear
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                
                // Fondo
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color("AppPrimary").opacity(0.04)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if filteredItems.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            
                            // ⭐ Favoritos
                            if !favoriteItems.isEmpty {
                                section(title: "⭐ Favoritos", items: favoriteItems)
                            }
                            
                            // 📅 Resto agrupado
                            ForEach(groupedItems.keys.sorted(by: >), id: \.self) { date in
                                section(
                                    title: sectionTitle(for: date),
                                    items: groupedItems[date] ?? []
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("recent_parkings".localized)
            .searchable(text: $searchText, prompt: "Buscar aparcamiento")
            .onAppear {
                guard loadOnAppear else { return }
                load()
            }
            .fullScreenCover(item: $selected) { p in
                MapFullScreenView(parkingLocation: p) {
                    selected = nil
                }
            }
        }
    }
    
    // MARK: - Sections
    
    private func section(title: String, items: [ParkingLocation]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
            
            ForEach(items) { parking in
                ParkingHistoryCard(
                    parking: parking,
                    isFavorite: isFavorite(parking),
                    onTap: { selected = parking },
                    onShare: { share(parking) },
                    onDelete: { deleteParking(parking) },
                    onFavorite: { toggleFavorite(parking) }
                )
            }
        }
    }
    
    // MARK: - Data
    
    private func load() {
        items = ParkingStorage.shared.loadHistory()
    }
    
    private func deleteParking(_ parking: ParkingLocation) {
        if let index = items.firstIndex(where: { $0.id == parking.id }) {
            ParkingStorage.shared.removeFromHistory(id: parking.id)
            items.remove(at: index)
        }
    }
    
    // MARK: - Filtering
    
    private var filteredItems: [ParkingLocation] {
        if searchText.isEmpty { return items }
        
        return items.filter {
            ($0.placeName?.localizedCaseInsensitiveContains(searchText) ?? false)
            || ($0.note?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    private var favoriteItems: [ParkingLocation] {
        filteredItems.filter { isFavorite($0) }
    }
    
    private var groupedItems: [Date: [ParkingLocation]] {
        let nonFavorites = filteredItems.filter { !isFavorite($0) }
        
        return Dictionary(grouping: nonFavorites) {
            Calendar.current.startOfDay(for: $0.date)
        }
    }
    
    // MARK: - Favorites
    
    private var favoriteIDs: Set<String> {
        (try? JSONDecoder().decode(Set<String>.self, from: favoriteIDsData)) ?? []
    }
    
    private func isFavorite(_ parking: ParkingLocation) -> Bool {
        favoriteIDs.contains(parking.id.uuidString)
    }
    
    private func toggleFavorite(_ parking: ParkingLocation) {
        var ids = favoriteIDs
        let key = parking.id.uuidString
        
        if ids.contains(key) {
            ids.remove(key)
        } else {
            ids.insert(key)
        }
        
        favoriteIDsData = (try? JSONEncoder().encode(ids)) ?? Data()
    }
    
    // MARK: - Section Title
    
    private func sectionTitle(for date: Date) -> String {
        let cal = Calendar.current
        
        if cal.isDateInToday(date) { return "Hoy" }
        if cal.isDateInYesterday(date) { return "Ayer" }
        
        let f = DateFormatter()
        f.dateFormat = "E d MMM"
        return f.string(from: date)
    }
    
    // MARK: - Empty
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "car.fill")
                .font(.system(size: 42))
                .foregroundColor(Color("AppPrimary"))
            
            Text("no_recent_parkings".localized)
                .font(.headline)
        }
        .padding()
    }
    
    // MARK: - Share
    
    private func share(_ parking: ParkingLocation) {
        let url = URL(string: "http://maps.apple.com/?ll=\(parking.latitude),\(parking.longitude)")!
        
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(vc, animated: true)
        }
    }
}

struct ParkingHistoryCard: View {
    
    let parking: ParkingLocation
    let isFavorite: Bool
    
    var onTap: () -> Void
    var onShare: () -> Void
    var onDelete: () -> Void
    var onFavorite: () -> Void
    
    @State private var region: MKCoordinateRegion
    
    init(
        parking: ParkingLocation,
        isFavorite: Bool,
        onTap: @escaping () -> Void,
        onShare: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        onFavorite: @escaping () -> Void
    ) {
        self.parking = parking
        self.isFavorite = isFavorite
        self.onTap = onTap
        self.onShare = onShare
        self.onDelete = onDelete
        self.onFavorite = onFavorite
        
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: parking.latitude,
                longitude: parking.longitude
            ),
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        ))
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                
                // Imagen o mapa
                ZStack(alignment: .topTrailing) {
                    
                    if let data = parking.photoData,
                       let image = UIImage(data: data) {
                        
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 160)
                            .clipped()
                        
                    } else {
                        Map(coordinateRegion: $region, annotationItems: [parking]) { item in
                            MapMarker(coordinate: CLLocationCoordinate2D(
                                latitude: item.latitude,
                                longitude: item.longitude
                            ))
                        }
                    }
                    
                    // ⭐ Favorito
                    Button(action: onFavorite) {
                        Image(systemName: isFavorite ? "star.fill" : "star")
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .padding(8)
                }
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.headline)
                    
                    Text(dateString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let note = parking.note, !note.isEmpty {
                        Text(note)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                HStack {
                    Spacer()
                    
                    Button(action: onShare) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    
                    Button(role: .destructive, action: onDelete) {
                        Image(systemName: "trash")
                    }
                }
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
    
    private var title: String {
        parking.placeName?.isEmpty == false
        ? parking.placeName!
        : "\(parking.latitude), \(parking.longitude)"
    }
    
    private var dateString: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: parking.date)
    }
}
