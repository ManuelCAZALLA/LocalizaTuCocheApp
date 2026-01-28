import SwiftUI
import CoreLocation

struct RecentParkingsView: View {

    // MARK: - State
    @State private var items: [ParkingLocation] = []
    @State private var selected: ParkingLocation?

    private let loadOnAppear: Bool

    // MARK: - Init
    init(loadOnAppear: Bool = true) {
        self.loadOnAppear = loadOnAppear
    }

    #if DEBUG
    init(items: [ParkingLocation]) {
        _items = State(initialValue: items)
        _selected = State(initialValue: nil)
        self.loadOnAppear = false
    }
    #endif

    // MARK: - Body
    var body: some View {
        NavigationStack {
            content
        }
    }

    // MARK: - Content
    private var content: some View {
        Group {
            if items.isEmpty {
                emptyState
            } else {
                parkingList
            }
        }
        .navigationTitle("recent_parkings".localized)
        .onAppear {
            guard loadOnAppear else { return }
            load()
        }
        .fullScreenCover(item: $selected) { parking in
            MapFullScreenView(parkingLocation: parking) {
                selected = nil
            }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "mappin.and.ellipse")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .foregroundColor(Color("AppPrimary"))
                .opacity(0.8)

            Text("no_recent_parkings".localized)
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - List
    private var parkingList: some View {
        List {
            ForEach(items) { parking in
                parkingRow(for: parking)
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Row
    @ViewBuilder
    private func parkingRow(for parking: ParkingLocation) -> some View {
        Button {
            selected = parking
        } label: {
            ParkingRow(
                parking: parking,
                onShare: { share(parking) }
            )
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                deleteParking(parking)
            } label: {
                Label("Eliminar", systemImage: "trash")
            }
        }
    }

    // MARK: - Data
    private func load() {
        items = ParkingStorage.shared.loadHistory()
    }

    private func deleteParking(_ parking: ParkingLocation) {
        guard let index = items.firstIndex(where: { $0.id == parking.id }) else { return }
        ParkingStorage.shared.removeFromHistory(id: parking.id)
        items.remove(at: index)
    }

    // MARK: - Sharing
    private func share(_ parking: ParkingLocation) {
        guard let item = shareItem(for: parking) else { return }

        let activityVC = UIActivityViewController(
            activityItems: [item],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }

    private func shareItem(for parking: ParkingLocation) -> Any? {
        mapsURL(for: parking) ?? shareText(for: parking)
    }

    private func mapsURL(for parking: ParkingLocation) -> URL? {
        let queryName = (parking.placeName ?? "")
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        let urlString =
        "http://maps.apple.com/?ll=\(parking.latitude),\(parking.longitude)" +
        (queryName.isEmpty ? "" : "&q=\(queryName)")

        return URL(string: urlString)
    }

    private func shareText(for parking: ParkingLocation) -> String {
        let title = parking.placeName?.isEmpty == false
            ? parking.placeName!
            : String(
                format: NSLocalizedString("coordinates_format", comment: ""),
                parking.latitude,
                parking.longitude
            )

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        let date = formatter.string(from: parking.date)
        let note = parking.note?.isEmpty == false ? "\n\(parking.note!)" : ""

        let format = NSLocalizedString("share_parking_message", comment: "")
        return String(format: format, title, date, parking.latitude, parking.longitude) + note
    }
    
    struct ParkingRow: View {
        let parking: ParkingLocation
        var onShare: (() -> Void)? = nil

        var body: some View {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(Color("AppPrimary"))
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
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

                Spacer()

                if let onShare = onShare {
                    Button(action: onShare) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(Color("AppPrimary"))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 6)
        }

        private var title: String {
            if let name = parking.placeName, !name.isEmpty {
                return name
            }
            return String(
                format: NSLocalizedString("coordinates_format", comment: ""),
                parking.latitude,
                parking.longitude
            )
        }

        private var dateString: String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: parking.date)
        }
    }
}

#Preview {
    RecentParkingsView()
}


