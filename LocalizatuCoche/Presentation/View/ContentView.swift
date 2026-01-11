import SwiftUI
import CoreLocation
import StoreKit
import AVFoundation

@available(iOS 16.0, *)
struct ContentView: View {
    
    @StateObject private var viewModel = ParkingViewModel()
    @StateObject private var locationManager = LocationManager.shared
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
    @State private var ratePopupAlreadyShown = false
    
    
    // Estados de animación y feedback
    @State private var isSaving = false
    @State private var showSuccessAnimation = false
    
    @AppStorage("hasRatedOrRecommended") private var hasRated = false
    @AppStorage("launchCount") private var launchCount = 0
    @State private var lastPopupDate = UserDefaults.standard.object(forKey: "lastRatePopupDate") as? Date ?? Date.distantPast

    func updateLastPopupDate(_ date: Date) {
        lastPopupDate = date
        UserDefaults.standard.set(date, forKey: "lastRatePopupDate")
    }

    private func checkRatePopupLogic() {
        guard !hasRated else { return }
        
       if !hasCountedLaunch {
            launchCount += 1
            UserDefaults.standard.set(launchCount, forKey: "launchCount")
            hasCountedLaunch = true
        }
        
        let now = Date()
        let fiveDays: TimeInterval = 5 * 24 * 60 * 60
        let shouldShowByLaunch = launchCount % 3 == 0
        let shouldShowByDate = now.timeIntervalSince(lastPopupDate) > fiveDays
        
        if (shouldShowByLaunch || shouldShowByDate) && !ratePopupAlreadyShown {
            showRatePopup = true
            updateLastPopupDate(now)
            ratePopupAlreadyShown = true
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
    
    private func saveParkingWithAnimation() {
        guard let _ = locationManager.userLocation else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            isSaving = true
        }
        
        // Simular un pequeño delay para mostrar el loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            viewModel.saveParkingLocation(
                note: parkingNote.isEmpty ? nil : parkingNote,
                photoData: parkingPhoto?.jpegData(compressionQuality: 0.8)
            )
            
            // Limpiar estados
            parkingNote = ""
            parkingPhoto = nil
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isSaving = false
                showSuccessAnimation = true
            }
            
            // Ocultar la animación después de 2 segundos
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showSuccessAnimation = false
                }
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let isIPad = geometry.size.width > 800
            
        ZStack {
            // Fondo
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemBackground),
                    Color(.systemGray6).opacity(0.3)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Header mejorado para iPad
                        HeaderView(isIPad: isIPad)
                            .padding(.top, isIPad ? 60 : 20)
                            .padding(.bottom, 20)
                    
                    // Sección de ubicación actual
                        LocationView(
                            userLocation: locationManager.userLocation,
                            placeName: viewModel.placeName,
                            authorizationStatus: locationManager.authorizationStatus,
                            isIPad: isIPad
                        )
                        .padding(.bottom, 20)
                    
                    // Contenido principal
                    if viewModel.lastParking == nil {
                        // Estado vacío cuando no hay aparcamiento
                            EmptyStateView(isIPad: isIPad)
                                .padding(.bottom, 20)
                        
                        // Sección para nuevo aparcamiento
                            NewParkingSection(
                                parkingPhoto: parkingPhoto,
                                onPhotoRemove: { parkingPhoto = nil },
                                onCameraTap: checkCameraPermission,
                                onNoteTap: { showNoteSheet = true },
                                onSave: saveParkingWithAnimation,
                                isSaveEnabled: locationManager.userLocation != nil && !isSaving,
                                isSaving: isSaving,
                                isIPad: isIPad
                            )
                            .padding(.bottom, 40)
                    } else {
                            SavedParkingSection(
                                parking: viewModel.lastParking!,
                                onDelete: {
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        viewModel.clearParkingLocation()
                                    }
                                },
                                onNavigate: { showMap = true },
                                onPhotoEdit: {
                                    editingPhotoForSavedParking = true
                                    checkCameraPermission()
                                },
                                onNoteEdit: { showNoteSheet = true },
                                showMap: $showMap,
                                isIPad: isIPad
                            )
                            .padding(.bottom, 40)
                        }
                    }
                    .frame(maxWidth: isIPad ? 600 : nil)
                    .frame(maxWidth: .infinity)
            }
            
            // Overlay de éxito con animación
            if showSuccessAnimation {
                    SuccessOverlay(isShowing: $showSuccessAnimation)
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
            Button("open_settings".localized) {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("cancel".localized, role: .cancel) {}
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
}

#Preview {
    if #available(iOS 16.0, *) {
        ContentView()
    } else {
        // Fallback on earlier versions
    }
}

// MARK: - Note Sheet
struct NoteSheet: View {
    @State private var text: String
    @FocusState private var isTextEditorFocused: Bool
    let onSave: (String) -> Void
    let onCancel: () -> Void
    
    init(initialText: String, onSave: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        _text = State(initialValue: initialText)
        self.onSave = onSave
        self.onCancel = onCancel
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color("AccentColor").opacity(0.15))
                                .frame(width: 48, height: 48)
                            Image(systemName: "pencil")
                                .font(.title2)
                                .foregroundColor(Color("AccentColor"))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("parking_note".localized)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            Text("add_helpful_details".localized)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
                .padding(.top, 8)
                
                // Text Editor
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("\(text.count)/200")
                            .font(.caption)
                            .foregroundColor(text.count > 200 ? .red : .secondary)

                    }
                    
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $text)
                            .focused($isTextEditorFocused)
                            .frame(minHeight: 120)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isTextEditorFocused ? Color("AccentColor") : Color.clear, lineWidth: 2)
                            )
                        
                        if text.isEmpty {
                            Text("note_placeholder".localized)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 20)
                                .allowsHitTesting(false)
                        }
                    }
                }
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: 16) {
                    Button(action: onCancel) {
                        Text("cancel".localized)
                            .font(.body)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(.systemGray5))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { onSave(text) }) {
                        Text("save".localized)
                            .font(.body)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color("AccentColor"))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: Color("AccentColor").opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(text.count > 200)
                }
            }
            .padding()
            .navigationBarHidden(true)
        }
        // Reemplazar presentationDetents con sheet en iOS 16
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextEditorFocused = true
            }
        }
    }
}

