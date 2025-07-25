import SwiftUI
import CoreLocation
import StoreKit
import AVFoundation


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
    @State private var showCameraDeniedAlert = false
    @State private var hasCountedLaunch = false
    
    @AppStorage("hasRatedOrRecommended") private var hasRated = false
    @AppStorage("launchCount") private var launchCount = 0
    @AppStorage("lastRatePopupDate") private var lastPopupDate = Date.distantPast
    @State private var ratePopupAlreadyShown = false
    
    private func checkRatePopupLogic() {
        guard !hasRated else { return }

        launchCount += 1

        let now = Date()
        let fiveDays: TimeInterval = 5 * 24 * 60 * 60
        let shouldShowByLaunch = launchCount % 3 == 0
        let shouldShowByDate = now.timeIntervalSince(lastPopupDate) > fiveDays

        if shouldShowByLaunch || shouldShowByDate {
            showRatePopup = true
            
            lastPopupDate = now
        }
    }

    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showImagePicker = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        showImagePicker = true
                    } else {
                        showCameraDeniedAlert = true
                    }
                }
            }
        case .denied, .restricted:
            showCameraDeniedAlert = true
        @unknown default:
            showCameraDeniedAlert = true
        }
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(.systemGray6), Color(.white)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            VStack(spacing: 24) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundColor(Color("AccentColor"))
                        .font(.title2)
                    Text("main_slogan".localized)
                        .font(.callout)
                        .foregroundColor(Color("AppPrimary"))
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
                    // Botones de añadir foto y añadir nota
                    HStack(spacing: 16) {
                        Button {
                            checkCameraPermission()
                        } label: {
                            HStack {
                                Image(systemName: "camera")
                                    .font(.title2)
                                Text(parkingPhoto == nil ? "add_photo".localized : "change_photo".localized)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 22)
                            .background(Color("AccentColor"))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color("AccentColor"), lineWidth: 1.5)
                            )
                            .shadow(radius: 2)
                        }
                        Button(action: { showNoteSheet = true }) {
                            HStack {
                                Image(systemName: "pencil")
                                    .font(.title2)
                                Text(parkingNote.isEmpty ? "add_note".localized : "edit_note".localized)
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
                                    Text(last.photoData == nil ? "add_photo".localized : "change_photo".localized)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 22)
                                .background(Color("AccentColor"))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color("AccentColor"), lineWidth: 1.5)
                                )
                                .shadow(radius: 2)
                            }
                            .frame(maxWidth: .infinity)
                            
                            Button(action: { showNoteSheet = true }) {
                                HStack {
                                    Image(systemName: "pencil")
                                        .font(.title2)
                                    Text(last.note == nil || last.note!.isEmpty ? "add_note".localized : "edit_note".localized)
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
                            .foregroundColor(Color("AppPrimary"))
                            .opacity(0.7)
                        Text("no_parking_today".localized)
                            .font(.title2)
                            .foregroundColor(Color("AppPrimary"))
                            .multilineTextAlignment(.center)
                        Text("save_parking_hint".localized)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .padding(.horizontal, 24)
                    .background(Color.white.opacity(0.92))
                    .cornerRadius(20)
                    .shadow(color: Color("AppPrimary").opacity(0.08), radius: 8, x: 0, y: 4)
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
        .alert("camera_permission_denied".localized, isPresented: $showCameraDeniedAlert) {
            Button("ok".localized, role: .cancel) {}
        } message: {
            Text("camera_permission_message".localized)
        }
        .sheet(isPresented: $showNoteSheet) {
            NoteSheet(
                initialText: viewModel.lastParking?.note ?? parkingNote,
                onSave: { note in
                    if viewModel.lastParking != nil {
                        viewModel.updateParkingNote(note: note)
                    } else {
                        parkingNote = note
                    }
                    showNoteSheet = false
                },
                onCancel: {
                    showNoteSheet = false
                }
            )
        }
    }

    private var locationSection: some View {
        Group {
            if locationManager.userLocation != nil {
                HStack(spacing: 10) {
                    Image(systemName: "location.fill")
                        .foregroundColor(Color("AppSecondary"))
                    if let placeName = viewModel.placeName {
                        Text(placeName)
                            .font(.headline)
                            .foregroundColor(Color("AppPrimary"))
                    } else {
                        ProgressView("getting_place_name".localized)
                            .progressViewStyle(CircularProgressViewStyle(tint: Color("AppPrimary")))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.white.opacity(0.9))
                .cornerRadius(15)
                .shadow(color: Color("AppPrimary").opacity(0.08), radius: 8, x: 0, y: 4)
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

struct NoteSheet: View {
    @State private var text: String
    let onSave: (String) -> Void
    let onCancel: () -> Void
    
    init(initialText: String, onSave: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        _text = State(initialValue: initialText)
        self.onSave = onSave
        self.onCancel = onCancel
    }
    
    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Image(systemName: "pencil")
                    .font(.title)
                    .foregroundColor(Color("AccentColor"))
                Text("Nota para tu aparcamiento")
                    .font(.title3.bold())
            }
            .padding(.top, 8)
            TextEditor(text: $text)
                .frame(height: 120)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color("AccentColor").opacity(0.2), lineWidth: 1)
                )
            Spacer()
            HStack(spacing: 16) {
                Button(action: onCancel) {
                    Text("Cancelar")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundColor(.red)
                        .cornerRadius(10)
                }
                Button(action: { onSave(text) }) {
                    Text("Guardar")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("AccentColor"))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .presentationDetents([.medium, .large])
    }
}
