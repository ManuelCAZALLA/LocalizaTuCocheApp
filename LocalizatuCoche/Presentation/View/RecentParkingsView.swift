import SwiftUI
import CoreLocation

struct RecentParkingsView: View {
    @State private var items: [ParkingLocation] = []
    @State private var selected: ParkingLocation?

    var body: some View {
        NavigationView {
            Group {
                if items.isEmpty {
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
                } else {
                    List {
                        ForEach(items) { parking in
                            Button {
                                selected = parking
                            } label: {
                                ParkingRow(
                                    parking: parking,
                                    onShare: {
                                        share(parking)
                                    }
                                )
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    if let index = items.firstIndex(where: { $0.id == parking.id }) {
                                        delete(at: IndexSet(integer: index))
                                    }
                                } label: {
                                    Label("Eliminar", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("recent_parkings".localized)
            .onAppear(perform: load)
            .fullScreenCover(item: $selected) { p in
                MapFullScreenView(parkingLocation: p, onClose: {
                    selected = nil
                })
            }
        }
    }

    // MARK: - Data
    private func load() {
        items = ParkingStorage.shared.loadHistory()
    }

    private func delete(at offsets: IndexSet) {
        let ids = offsets.map { items[$0].id }
        for id in ids { ParkingStorage.shared.removeFromHistory(id: id) }
        items.remove(atOffsets: offsets)
    }

    // MARK: - Sharing
    private func share(_ parking: ParkingLocation) {
        guard let item = shareItem(for: parking) else { return }

        let activityVC = UIActivityViewController(activityItems: [item], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true, completion: nil)
        }
    }

    private func shareItem(for parking: ParkingLocation) -> Any? {
        if let url = mapsURL(for: parking) {
            return url
        }
        return shareText(for: parking)
    }

    private func mapsURL(for parking: ParkingLocation) -> URL? {
        let queryName = (parking.placeName ?? "").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "http://maps.apple.com/?ll=\(parking.latitude),\(parking.longitude)\(queryName.isEmpty ? "" : "&q=\(queryName)")"
        return URL(string: urlString)
    }

    private func shareText(for parking: ParkingLocation) -> String {
        let titlePart: String
        if let name = parking.placeName, !name.isEmpty {
            titlePart = name
        } else {
            titlePart = String(format: NSLocalizedString("coordinates_format", comment: "Coordinates fallback title"), parking.latitude, parking.longitude)
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let datePart = dateFormatter.string(from: parking.date)
        let notePart = (parking.note?.isEmpty == false) ? "\n\(parking.note!)" : ""
        let format = NSLocalizedString("share_parking_message", comment: "Share message format")
        return String(format: format, titlePart, datePart, parking.latitude, parking.longitude) + notePart
    }
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

            // 👇 Botón visible dentro de la tarjeta
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
        } else {
            return String(format: NSLocalizedString("coordinates_format", comment: ""), parking.latitude, parking.longitude)
        }
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: parking.date)
    }
}

#Preview {
    RecentParkingsView()
}
