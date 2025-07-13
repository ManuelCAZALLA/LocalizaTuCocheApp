import SwiftUI
import CoreLocation
import GoogleMobileAds

struct ContentView: View {
    
    @StateObject private var viewModel = ParkingViewModel()
    @StateObject private var locationManager = LocationManager.shared
    @State private var showingSaveAlert = false
    @State private var showMap = false
    @State private var parkingNote: String = ""
    @State private var showNoteSheet = false
    
    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            VStack(spacing: 24) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.accentColor)
                        .font(.title2)
                    Text("Aparca, guarda y vuelve sin complicaciones.")
                        .font(.callout)
                        .foregroundColor(.appPrimary)
                        .multilineTextAlignment(.leading)
                }
                .padding(.top, 8)
                .padding(.bottom, 4)
                // Sección de ubicación actual
                locationSection
                // Botón principal solo si no hay aparcamiento guardado
                if viewModel.lastParking == nil {
                    ParkingButton(enabled: locationManager.userLocation != nil) {
                        if let _ = locationManager.userLocation {
                            viewModel.saveParkingLocation(note: parkingNote.isEmpty ? nil : parkingNote)
                            parkingNote = ""
                            showingSaveAlert = true
                        }
                    }
                    .padding(.horizontal)
                }
                // Botón para añadir nota
                Button(action: { showNoteSheet = true }) {
                    Label(parkingNote.isEmpty ? "Añadir nota" : "Editar nota", systemImage: "pencil")
                        .font(.subheadline)
                        .padding(8)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(8)
                        .shadow(radius: 1)
                }
                .padding(.bottom, 4)
                .sheet(isPresented: $showNoteSheet, onDismiss: {
                    if let _ = viewModel.lastParking {
                        viewModel.updateParkingNote(note: parkingNote)
                    }
                }) {
                    NavigationView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Nota para el aparcamiento:")
                                .font(.headline)
                                .foregroundColor(.appPrimary)
                            TextField("Escribe una nota...", text: $parkingNote)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.bottom, 16)
                            Spacer()
                        }
                        .padding()
                        .navigationTitle("Nota")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("OK") { showNoteSheet = false }
                            }
                        }
                    }
                }
                // Tarjeta de último aparcamiento
                if let last = viewModel.lastParking {
                    ParkingInfoCard(parking: last, onDelete: {
                        viewModel.clearParkingLocation()
                    }, onNavigate: {
                        showMap = true
                    }, note: last.note)
                    .padding(.horizontal)
                    .fullScreenCover(isPresented: $showMap) {
                        MapFullScreenView(parkingLocation: last, onClose: { showMap = false })
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "car.2.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.appPrimary)
                            .opacity(0.7)
                        Text("Aún no aparcaste hoy")
                            .font(.title2)
                            .foregroundColor(.appPrimary)
                            .multilineTextAlignment(.center)
                        Text("Guarda tu aparcamiento para encontrar tu coche fácilmente.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(.top, 0)
            .alert("location_saved".localized, isPresented: $showingSaveAlert) {
                Button("ok".localized, role: .cancel) {
                    if let root = UIApplication.shared.connectedScenes
                        .compactMap({ ($0 as? UIWindowScene)?.keyWindow }).first?.rootViewController {
                        AdManager.shared.showInterstitial(from: root)
                    }
                }
            }
        }
    }

    private var locationSection: some View {
        Group {
            if locationManager.userLocation != nil {
                HStack(spacing: 10) {
                    Image(systemName: "location.fill")
                        .foregroundColor(.appSecondary)
                    if let placeName = viewModel.placeName {
                        Text(placeName)
                            .font(.headline)
                            .foregroundColor(.appPrimary)
                    } else {
                        ProgressView("getting_place_name".localized)
                            .progressViewStyle(CircularProgressViewStyle(tint: .appPrimary))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.white.opacity(0.9))
                .cornerRadius(15)
                .shadow(color: Color.appPrimary.opacity(0.08), radius: 8, x: 0, y: 4)
                .padding(.horizontal)
            } else {
                LocationStatusView(status: locationManager.authorizationStatus)
                    .padding(.horizontal)
            }
        }
    }
}

#Preview {
    ContentView()
}
