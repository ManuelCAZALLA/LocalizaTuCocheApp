import SwiftUI
import CoreLocation
import StoreKit


struct ContentView: View {
    
    @StateObject private var viewModel = ParkingViewModel()
    @StateObject private var locationManager = LocationManager.shared
    @State private var showingSaveAlert = false
    @State private var showMap = false
    @State private var parkingNote: String = ""
    @State private var showNoteSheet = false
    @State private var showRatePopup = false
    // Estados para la foto
    @State private var showImagePicker = false
    @State private var parkingPhoto: UIImage? = nil
    @State private var editingPhotoForSavedParking = false
    
    private func checkRatePopupLogic() {
        let hasRated = UserDefaults.standard.bool(forKey: "hasRatedOrRecommended")
        guard !hasRated else { return }
        let launches = UserDefaults.standard.integer(forKey: "launchCount") + 1
        UserDefaults.standard.set(launches, forKey: "launchCount")
        let lastShown = UserDefaults.standard.object(forKey: "lastRatePopupDate") as? Date
        let now = Date()
        let fiveDays: TimeInterval = 5 * 24 * 60 * 60
        let shouldShowByLaunch = launches % 3 == 0
        let shouldShowByDate = lastShown == nil || (now.timeIntervalSince(lastShown!) > fiveDays)
        if shouldShowByLaunch || shouldShowByDate {
            showRatePopup = true
            UserDefaults.standard.set(now, forKey: "lastRatePopupDate")
        }
    }
    
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
                    // Mostrar la foto seleccionada antes de guardar
                    if let image = parkingPhoto {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 180)
                            .clipped()
                            .cornerRadius(12)
                            .padding(.bottom, 8)
                    }
                    // Botones de añadir foto y añadir nota juntos
                    HStack(spacing: 16) {
                        Button {
                            showImagePicker = true
                        } label: {
                            HStack {
                                Image(systemName: "camera")
                                    .font(.title2)
                                Text(parkingPhoto == nil ? "Añadir foto" : "Cambiar foto")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 22)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.accentColor, lineWidth: 1.5)
                            )
                            .shadow(radius: 2)
                        }
                        Button(action: { showNoteSheet = true }) {
                            HStack {
                                Image(systemName: "pencil")
                                    .font(.title2)
                                Text(parkingNote.isEmpty ? "Añadir nota" : "Editar nota")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 22)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.orange, lineWidth: 1.5)
                            )
                            .shadow(radius: 2)
                        }
                    }
                    .padding(.bottom, 4)
                    // Botón guardar
                    ParkingButton(enabled: locationManager.userLocation != nil) {
                        if let _ = locationManager.userLocation {
                            viewModel.saveParkingLocation(note: parkingNote.isEmpty ? nil : parkingNote, photoData: parkingPhoto?.jpegData(compressionQuality: 0.8))
                            parkingNote = ""
                            parkingPhoto = nil
                            showingSaveAlert = true
                        }
                    }
                    .padding(.horizontal)
                }
                // Tarjeta de último aparcamiento
                if let last = viewModel.lastParking {
                    VStack(spacing: 8) {
                        ParkingInfoCard(parking: last, onDelete: {
                            viewModel.clearParkingLocation()
                        }, onNavigate: {
                            showMap = true
                        }, note: last.note)
                        .padding(.horizontal)
                        // Botones para editar foto y nota si ya hay aparcamiento guardado
                        HStack(spacing: 16) {
                            Button {
                                editingPhotoForSavedParking = true
                                showImagePicker = true
                            } label: {
                                HStack {
                                    Image(systemName: last.photoData == nil ? "camera" : "camera.fill")
                                        .font(.title2)
                                    Text(last.photoData == nil ? "Añadir foto" : "Editar foto")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 22)
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.accentColor, lineWidth: 1.5)
                                )
                                .shadow(radius: 2)
                            }
                            Button(action: { showNoteSheet = true }) {
                                HStack {
                                    Image(systemName: "pencil")
                                        .font(.title2)
                                    Text(last.note == nil || last.note!.isEmpty ? "Añadir nota" : "Editar nota")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 22)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.orange, lineWidth: 1.5)
                                )
                                .shadow(radius: 2)
                            }
                        }
                        .padding(.top, 4)
                        .padding(.horizontal)
                    }
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
                    if (UIApplication.shared.connectedScenes
                        .compactMap({ ($0 as? UIWindowScene)?.keyWindow }).first?.rootViewController) != nil {
                    }
                }
            }
        }
        .onAppear {
            checkRatePopupLogic()
        }
        .overlay(
            RateOrRecommendPopup(isPresented: $showRatePopup) {
                showRatePopup = false
            }
        )
        // Sheet para el ImagePicker
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: .camera, selectedImage: $parkingPhoto)
                .onDisappear {
                    if editingPhotoForSavedParking, let image = parkingPhoto {
                        viewModel.updateParkingPhoto(photoData: image.jpegData(compressionQuality: 0.8))
                        parkingPhoto = nil
                        editingPhotoForSavedParking = false
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
