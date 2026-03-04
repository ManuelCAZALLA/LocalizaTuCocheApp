import SwiftUI
import CoreLocation
import AVFoundation

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
                        emptyStateView
                        NewParkingSectionView(
                            parkingPhoto: parkingPhoto,
                            parkingNote: parkingNote,
                            isSaving: isSaving,
                            isLocationAvailable: locationManager.userLocation != nil,
                            onTapPhoto: { checkCameraPermission() },
                            onTapNote: { showNoteSheet = true },
                            onSave: { saveParkingWithAnimation() },
                            onRemovePhoto: { parkingPhoto = nil }
                        )
                    } else if let last = viewModel.lastParking {
                        SavedParkingSectionView(
                            parking: last,
                            note: last.note,
                            hasPhoto: last.photoData != nil,
                            onDelete: {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    viewModel.clearParkingLocation()
                                }
                            },
                            onEditPhoto: {
                                editingPhotoForSavedParking = true
                                checkCameraPermission()
                            },
                            onEditNote: {
                                showNoteSheet = true
                            },
                            showMap: $showMap
                        )
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            
            // Overlay de éxito con animación
            if showSuccessAnimation {
                ParkingSavedSuccessOverlay(isVisible: $showSuccessAnimation)
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
        
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextEditorFocused = true
            }
        }
    }
}

#Preview {
    ContentView()
}
