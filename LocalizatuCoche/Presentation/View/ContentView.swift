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
    
    @State private var showImagePicker = false
    @State private var parkingPhoto: UIImage? = nil
    @State private var editingPhotoForSavedParking = false
    @State private var showCameraDeniedAlert = false
    
    @State private var isSaving = false
    @State private var showSuccessAnimation = false
    @State private var pulseAnimation = false
    
    @AppStorage("isPro") private var isPro = false
    @AppStorage("hasSeenProPromoV1") private var hasSeenProPromo = false
    @AppStorage("hasShownOnboardingV1") private var hasShownOnboarding = false
    
    @State private var showCoachMarks = false
    @State private var coachSteps: [CoachMark] = []
    @State private var currentCoachIndex: Int = 0
    @State private var coachTargets: [String: Anchor<CGRect>] = [:]
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12: return "Buenos días 🌤️"
        case 12..<18: return "Buenas tardes ☀️"
        default: return "Buenas noches 🌙"
        }
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showImagePicker = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted { showImagePicker = true } else { showCameraDeniedAlert = true }
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
        withAnimation(.easeInOut(duration: 0.3)) { isSaving = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            viewModel.saveParkingLocation(
                note: parkingNote.isEmpty ? nil : parkingNote,
                photoData: parkingPhoto?.jpegData(compressionQuality: 0.8)
            )
            parkingNote = ""
            parkingPhoto = nil
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isSaving = false
                showSuccessAnimation = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.3)) { showSuccessAnimation = false }
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Fondo degradado sutil
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemBackground),
                    Color("AppPrimary").opacity(0.04)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    headerSection
                    locationSection
                    
                    if viewModel.lastParking == nil {
                        emptyStateView
                        newParkingSection
                    } else {
                        savedParkingSection
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
            
            if showSuccessAnimation { successOverlay }
            
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
        .onAppear { prepareCoachMarksIfNeeded() }
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
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
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
                onCancel: { showNoteSheet = false }
            )
        }
        .overlayPreferenceValue(CoachMarkTargetsKey.self) { value in
            GeometryReader { _ in
                Color.clear
                    .onAppear { coachTargets = value }
                    .onChange(of: value) { newValue in coachTargets = newValue }
            }
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("main_slogan".localized)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color("AppPrimary"))
            }
            Spacer()
            // Badge Pro
            if isPro {
                HStack(spacing: 4) {
                    Image(systemName: "crown.fill")
                        .font(.caption)
                    Text("PREMIUM")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    LinearGradient(
                        colors: [Color("AccentColor"), Color("AppPrimary")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Location Section
    private var locationSection: some View {
        Group {
            if locationManager.userLocation != nil {
                HStack(spacing: 14) {
                    // Indicador pulsante
                    ZStack {
                        Circle()
                            .fill(Color("AppSecondary").opacity(0.15))
                            .frame(width: 44, height: 44)
                        Circle()
                            .fill(Color("AppSecondary").opacity(0.1))
                            .frame(width: 44, height: 44)
                            .scaleEffect(pulseAnimation ? 1.4 : 1.0)
                            .opacity(pulseAnimation ? 0 : 0.6)
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false), value: pulseAnimation)
                        Image(systemName: "location.fill")
                            .foregroundColor(Color("AppSecondary"))
                            .font(.body)
                    }
                    .onAppear { pulseAnimation = true }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("current_location".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if let placeName = viewModel.placeName {
                            Text(placeName)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color("AppPrimary"))
                                .lineLimit(1)
                        } else {
                            HStack(spacing: 6) {
                                ProgressView().scaleEffect(0.7)
                                Text("getting_place_name".localized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    Spacer()
                    
                    // Indicador verde activo
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                        .shadow(color: Color.green.opacity(0.5), radius: 3)
                }
                .padding(14)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
                .padding(.horizontal)
            } else {
                LocationStatusView(status: locationManager.authorizationStatus)
                    .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            // Ilustración con capas
            ZStack {
                Circle()
                    .fill(Color("AppPrimary").opacity(0.06))
                    .frame(width: 120, height: 120)
                Circle()
                    .fill(Color("AppPrimary").opacity(0.1))
                    .frame(width: 90, height: 90)
                Image(systemName: "car.2.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(Color("AppPrimary"))
            }
            
            VStack(spacing: 8) {
                Text("no_parking_today".localized)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color("AppPrimary"))
                    .multilineTextAlignment(.center)
                Text("no_parking_today_funny".localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .padding(.horizontal, 24)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 6)
        .padding(.horizontal)
    }
    
    // MARK: - New Parking Section
    private var newParkingSection: some View {
        VStack(spacing: 14) {
            if let image = parkingPhoto { photoPreview(image: image) }
            
            // Botones de acción
            HStack(spacing: 12) {
                actionButton(
                    icon: parkingPhoto == nil ? "camera" : "camera.fill",
                    title: parkingPhoto == nil ? "add_photo".localized : "change_photo".localized,
                    color: Color("AccentColor"),
                    coachId: "photoButton"
                ) { checkCameraPermission() }
                
                actionButton(
                    icon: parkingNote.isEmpty ? "pencil" : "pencil.circle.fill",
                    title: parkingNote.isEmpty ? "add_note".localized : "edit_note".localized,
                    color: Color.orange,
                    coachId: "noteButton"
                ) { showNoteSheet = true }
            }
            
            // Botón principal
            ParkingButton(enabled: locationManager.userLocation != nil && !isSaving) {
                saveParkingWithAnimation()
            }
            .coachMarkTarget(id: "saveButton")
        }
        .padding(.horizontal)
    }
    
    // MARK: - Action Button Helper
    private func actionButton(icon: String, title: String, color: Color, coachId: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.body)
                    .fontWeight(.semibold)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(color.opacity(0.12))
            .foregroundColor(color)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(color.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .coachMarkTarget(id: coachId)
    }
    
    // MARK: - Saved Parking Section
    private var savedParkingSection: some View {
        VStack(spacing: 14) {
            if let last = viewModel.lastParking {
                ParkingInfoCard(
                    parking: last,
                    onDelete: {
                        withAnimation(.easeOut(duration: 0.3)) { viewModel.clearParkingLocation() }
                    },
                    onNavigate: {
                        AdsService.shared.showInterstitial { showMap = true }
                    },
                    note: last.note
                )
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
                
                // Botones edición
                HStack(spacing: 12) {
                    actionButton(
                        icon: last.photoData == nil ? "camera" : "camera.fill",
                        title: last.photoData == nil ? "add_photo".localized : "change_photo".localized,
                        color: Color("AccentColor"),
                        coachId: "editPhoto"
                    ) {
                        editingPhotoForSavedParking = true
                        checkCameraPermission()
                    }
                    
                    actionButton(
                        icon: (last.note?.isEmpty ?? true) ? "pencil" : "pencil.circle.fill",
                        title: (last.note?.isEmpty ?? true) ? "add_note".localized : "edit_note".localized,
                        color: Color.orange,
                        coachId: "editNote"
                    ) { showNoteSheet = true }
                }
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
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 180)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            
            Button(action: { withAnimation { parkingPhoto = nil } }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.3), radius: 4)
            }
            .padding(10)
        }
    }
    
    // MARK: - Success Overlay
    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.3)) { showSuccessAnimation = false }
                }
            
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 100, height: 100)
                    Circle()
                        .fill(Color.green.opacity(0.08))
                        .frame(width: 100, height: 100)
                        .scaleEffect(showSuccessAnimation ? 1.5 : 1.0)
                        .opacity(showSuccessAnimation ? 0 : 1)
                        .animation(.easeOut(duration: 1.0).repeatForever(autoreverses: false), value: showSuccessAnimation)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 52))
                        .foregroundColor(.green)
                        .scaleEffect(showSuccessAnimation ? 1.0 : 0.3)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: showSuccessAnimation)
                }
                
                VStack(spacing: 6) {
                    Text("parking_saved_success_title".localized)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text("parking_saved_success_subtitle".localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(showSuccessAnimation ? 1.0 : 0.0)
                .animation(.easeInOut.delay(0.3), value: showSuccessAnimation)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.15), radius: 30, x: 0, y: 10)
            )
            .scaleEffect(showSuccessAnimation ? 1.0 : 0.85)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showSuccessAnimation)
        }
        .transition(.opacity)
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
            withAnimation(.easeInOut(duration: 0.25)) { showCoachMarks = true }
        }
    }
    
    private func advanceCoachStep() {
        let next = currentCoachIndex + 1
        if next < coachSteps.count {
            withAnimation(.easeInOut(duration: 0.25)) { currentCoachIndex = next }
        } else {
            finishCoach()
        }
    }
    
    private func finishCoach() {
        withAnimation(.easeInOut(duration: 0.25)) { showCoachMarks = false }
        hasShownOnboarding = true
    }
}

#Preview {
    if #available(iOS 16.0, *) {
        ContentView()
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
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Spacer()
                        Text("\(text.count)/200")
                            .font(.caption)
                            .foregroundColor(text.count > 180 ? .orange : (text.count > 200 ? .red : .secondary))
                    }
                    
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $text)
                            .focused($isTextEditorFocused)
                            .frame(minHeight: 120)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(isTextEditorFocused ? Color("AccentColor") : Color.clear, lineWidth: 2)
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
                
                HStack(spacing: 12) {
                    Button(action: onCancel) {
                        Text("cancel".localized)
                            .font(.body)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(.systemGray5))
                            .foregroundColor(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { onSave(text) }) {
                        Text("save".localized)
                            .font(.body)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(text.count > 200 ? Color.gray : Color("AccentColor"))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: Color("AccentColor").opacity(text.count > 200 ? 0 : 0.3), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(text.count > 200)
                }
            }
            .padding()
            .navigationBarHidden(true)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { isTextEditorFocused = true }
        }
    }
}
