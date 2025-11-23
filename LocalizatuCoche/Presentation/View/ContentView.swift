import SwiftUI
import CoreLocation
import AVFoundation
import GoogleMobileAds


@available(iOS 16.0, *)
struct ContentView: View {
    
    @StateObject private var viewModel = ParkingViewModel()
    @StateObject private var locationManager = LocationManager.shared
    @State private var showMap = false
    @State private var parkingNote: String = ""
    @State private var showNoteSheet = false
    
    // Estados para la foto
    @State private var showImagePicker = false
    @State private var parkingPhoto: UIImage? = nil
    @State private var editingPhotoForSavedParking = false
    @State private var showCameraDeniedAlert = false
    
    // Estados de animación y feedback
    @State private var isSaving = false
    @State private var showSuccessAnimation = false
    
    
    @AppStorage("isPro") private var isPro = false
    @AppStorage("hasSeenProPromoV1") private var hasSeenProPromo = false
    
    @AppStorage("hasShownOnboardingV1") private var hasShownOnboarding = false
    @State private var showCoachMarks = false
    @State private var coachSteps: [CoachMark] = []
    @State private var currentCoachIndex: Int = 0
    @State private var coachTargets: [String: Anchor<CGRect>] = [:]
    
    
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
                VStack(spacing: 28) {
                    // Header mejorado
                    headerSection
                    
                    // Sección de ubicación actual
                    locationSection
                    
                    // Contenido principal
                    if viewModel.lastParking == nil {
                        // Estado vacío cuando no hay aparcamiento
                        emptyStateView
                        
                        // Sección para nuevo aparcamiento
                        newParkingSection
                    } else {
                        savedParkingSection
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            
            // Overlay de éxito con animación
            if showSuccessAnimation {
                successOverlay
            }
            // Overlay de coach marks
            if showCoachMarks, currentCoachIndex < coachSteps.count {
                CoachMarksOverlay(
                    step: coachSteps[currentCoachIndex],
                    targets: coachTargets,
                    onNext: advanceCoachStep,
                    onSkip: finishCoach
                )
                .allowsHitTesting(true)
                .transition(.opacity)
            }
        }
        .onAppear {
            prepareCoachMarksIfNeeded()
            AdsService.shared.start()
        }
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
        // Captura de anchors para coach marks
        .overlayPreferenceValue(CoachMarkTargetsKey.self) { value in
            GeometryReader { _ in
                Color.clear
                    .onAppear { coachTargets = value }
                    .onChange(of: value) { newValue in
                        coachTargets = newValue
                        if showCoachMarks, let first = coachSteps.first, newValue[first.id] != nil {
                            // ...
                        }
                    }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .foregroundColor(Color("AccentColor"))
                    .font(.title2)
                    .scaleEffect(1.2)
                    
                Text("main_slogan".localized)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(Color("AppPrimary"))
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Location Section
    private var locationSection: some View {
        Group {
            if locationManager.userLocation != nil {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color("AppSecondary").opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: "location.fill")
                            .foregroundColor(Color("AppSecondary"))
                            .font(.title3)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("current_location".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            
                        if let placeName = viewModel.placeName {
                            Text(placeName)
                                .font(.headline)
                                .foregroundColor(Color("AppPrimary"))
                                .lineLimit(2)
                        } else {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("getting_place_name".localized)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(16)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                .padding(.horizontal)
            } else {
                LocationStatusView(status: locationManager.authorizationStatus)
                    .padding(.horizontal)
            }
        }
    }
    
    // MARK: - New Parking Section
    private var newParkingSection: some View {
        VStack(spacing: 20) {
            // Preview de foto si existe
            if let image = parkingPhoto {
                photoPreview(image: image)
            }
            
            // Botones de acción mejorados
            actionButtonsRow
            
            // Botón principal de guardar usando ParkingButton
            ParkingButton(enabled: locationManager.userLocation != nil && !isSaving) {
                saveParkingWithAnimation()
            }
            .coachMarkTarget(id: "saveButton")
        }
        .padding(.horizontal)
    }
    
    // MARK: - Saved Parking Section
    private var savedParkingSection: some View {
        VStack(spacing: 16) {
            if let last = viewModel.lastParking {
                ParkingInfoCard(
                    parking: last,
                    onDelete: {
                        withAnimation(.easeOut(duration: 0.3)) {
                            viewModel.clearParkingLocation()
                        }
                    },
                    onNavigate: {
                        // Obtener la vista raíz
                        if let root = UIApplication.shared.connectedScenes
                            .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
                            .first?
                            .rootViewController
                        {
                            AdsService.shared.showInterstitial(from: root) {
                                // 🌟 Corrección Clave: Asegurar la transición en el hilo principal
                                DispatchQueue.main.async {
                                    showMap = true
                                }
                            }
                        } else {
                            showMap = true
                        }
                    },
                    note: last.note
                )
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
                
                // Botones de edición
                editButtonsRow(for: last)
            }
        }
        .padding(.horizontal)
        .fullScreenCover(isPresented: $showMap) {
            if let last = viewModel.lastParking {
                MapFullScreenView(parkingLocation: last, onClose: { showMap = false })
            }
        }
    }
    
    // MARK: - Photo Preview
    private func photoPreview(image: UIImage) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("photo_preview".localized)
                    .font(.headline)
                    .foregroundColor(Color("AppPrimary"))
                Spacer()
                Button(action: { parkingPhoto = nil }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
            }
            
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 200)
                .clipped()
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
    
    // MARK: - Action Buttons Row
    private var actionButtonsRow: some View {
        HStack(spacing: 16) {
            // Botón de foto
            Button(action: checkCameraPermission) {
                HStack(spacing: 8) {
                    Image(systemName: parkingPhoto == nil ? "camera" : "camera.fill")
                        .font(.title3)
                    Text(parkingPhoto == nil ? "add_photo".localized : "change_photo".localized)
                        .font(.body)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color("AccentColor"))
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: Color("AccentColor").opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
            .coachMarkTarget(id: "photoButton")
            
            // Botón de nota
            Button(action: { showNoteSheet = true }) {
                HStack(spacing: 8) {
                    Image(systemName: parkingNote.isEmpty ? "pencil" : "pencil.circle.fill")
                        .font(.title3)
                    Text(parkingNote.isEmpty ? "add_note".localized : "edit_note".localized)
                        .font(.body)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: Color.orange.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
            .coachMarkTarget(id: "noteButton")
        }
    }
    
    // MARK: - Edit Buttons Row
    private func editButtonsRow(for parking: ParkingLocation) -> some View {
        HStack(spacing: 16) {
            Button(action: {
                editingPhotoForSavedParking = true
                checkCameraPermission()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: parking.photoData == nil ? "camera" : "camera.fill")
                        .font(.body)
                    Text(parking.photoData == nil ? "add_photo".localized : "change_photo".localized)
                        .font(.body)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color("AccentColor"))
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: Color("AccentColor").opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: { showNoteSheet = true }) {
                HStack(spacing: 8) {
                    Image(systemName: (parking.note?.isEmpty ?? true) ? "pencil" : "pencil.circle.fill")
                        .font(.body)
                    Text((parking.note?.isEmpty ?? true) ? "add_note".localized : "edit_note".localized)
                        .font(.body)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: Color.orange.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Success Overlay
    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showSuccessAnimation = false
                    }
                }
            
            VStack(spacing: 20) {
                // Ícono animado
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .scaleEffect(showSuccessAnimation ? 1.0 : 0.5)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showSuccessAnimation)
                        
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                        .scaleEffect(showSuccessAnimation ? 1.0 : 0.3)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: showSuccessAnimation)
                }
                
                VStack(spacing: 8) {
                    Text("¡Aparcamiento guardado!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        
                    Text("Tu ubicación ha sido guardada correctamente")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(showSuccessAnimation ? 1.0 : 0.0)
                .animation(.easeInOut.delay(0.3), value: showSuccessAnimation)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
            )
            .scaleEffect(showSuccessAnimation ? 1.0 : 0.8)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showSuccessAnimation)
        }
        .transition(.opacity)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "car.2.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(Color("AppPrimary"))
                .opacity(0.7)
                
            VStack(spacing: 8) {
                Text("no_parking_today".localized)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("AppPrimary"))
                    .multilineTextAlignment(.center)
            }
            Text("no_parking_today_funny".localized)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 32)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 6)
        .padding(.horizontal)
    }
}

// MARK: - Coach Marks Logic
extension ContentView {
    private func prepareCoachMarksIfNeeded() {
        guard !hasShownOnboarding else { return }
        coachSteps = [
            CoachMark(id: "photoButton", textKey: "coach_photo"),
            CoachMark(id: "noteButton", textKey: "coach_note"),
            CoachMark(id: "saveButton", textKey: "coach_save")
        ]
        currentCoachIndex = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeInOut(duration: 0.25)) {
                showCoachMarks = true
            }
        }
    }
    private func advanceCoachStep() {
        let next = currentCoachIndex + 1
        if next < coachSteps.count {
            withAnimation(.easeInOut(duration: 0.25)) {
                currentCoachIndex = next
            }
        } else {
            finishCoach()
        }
    }
    private func finishCoach() {
        withAnimation(.easeInOut(duration: 0.25)) {
            showCoachMarks = false
        }
        hasShownOnboarding = true
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
