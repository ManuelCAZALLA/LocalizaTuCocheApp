import SwiftUI

struct ParkingMeterView: View {
    @ObservedObject var parkingViewModel: ParkingViewModel
    @Binding var openParkingFromNotification: Bool
    @StateObject private var viewModel = ParkingMeterViewModel()
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedMinutes: Int = 15
    @State private var preEndAlertMinutes: Int = 5
    @State private var showMap = false
    @State private var activeAlert: ActiveAlert?
    @State private var pulseTimer = false
    
    let minuteOptions = [15, 20, 30, 45, 60, 90, 120, 150, 180]
    let preEndOptions = [1, 3, 5, 10, 15, 20]
    
    enum ActiveAlert: Identifiable {
        case preEnd, final, noParking, notification
        var id: Int { hashValue }
    }
    
    init(parkingViewModel: ParkingViewModel, openParkingFromNotification: Binding<Bool>) {
        self.parkingViewModel = parkingViewModel
        self._openParkingFromNotification = openParkingFromNotification
    }
    
    private var cardBackground: Color {
        colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemBackground),
                    Color("AppPrimary").opacity(0.04)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                headerSection
                
                if viewModel.hasActiveTimer {
                    activeTimerView
                } else {
                    setupTimerView
                }
                
                Spacer()
            }
            .padding(.top, 8)
        }
        .onAppear {
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" { return }
            viewModel.requestNotificationPermission()
            setupCallbacks()
            if openParkingFromNotification {
                activeAlert = .notification
                openParkingFromNotification = false
            }
        }
        .onChange(of: openParkingFromNotification) { newValue in
            if newValue {
                activeAlert = .notification
                openParkingFromNotification = false
            }
        }
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .preEnd:
                return Alert(
                    title: Text("little_time_left".localized),
                    message: Text("go_back_car_question".localized),
                    primaryButton: .default(Text("go_back_to_car".localized)) { goToCar() },
                    secondaryButton: .cancel(Text("continue_countdown".localized))
                )
            case .final:
                return Alert(
                    title: Text("time_up".localized),
                    message: Text("parking_meter_expired".localized),
                    primaryButton: .default(Text("go_to_car".localized)) { goToCar() },
                    secondaryButton: .cancel(Text("close".localized))
                )
            case .noParking:
                return Alert(
                    title: Text("no_saved_parking".localized),
                    message: Text("must_save_parking_first".localized),
                    dismissButton: .cancel(Text("ok".localized))
                )
            case .notification:
                return Alert(
                    title: Text("alert_attention".localized),
                    message: Text("alert_parking_expired".localized),
                    primaryButton: .default(Text("go_to_car".localized)) { goToCar() },
                    secondaryButton: .cancel(Text("close".localized))
                )
            }
        }
        .fullScreenCover(isPresented: $showMap) {
            if let parking = parkingViewModel.lastParking {
                MapFullScreenView(parkingLocation: parking, onClose: { showMap = false })
            }
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("parking_meter_emoji".localized)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color("AppPrimary"))
                Text(viewModel.hasActiveTimer ? "Temporizador en marcha" : "Configura tu tiempo")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            
            HStack(spacing: 6) {
                Circle()
                    .fill(viewModel.hasActiveTimer ? Color.green : Color.secondary.opacity(0.4))
                    .frame(width: 8, height: 8)
                    .shadow(color: viewModel.hasActiveTimer ? Color.green.opacity(0.5) : .clear, radius: 3)
                Text(viewModel.hasActiveTimer ? "Activo" : "Inactivo")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(viewModel.hasActiveTimer ? .green : .secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(viewModel.hasActiveTimer ? Color.green.opacity(0.12) : Color(.systemGray5))
            )
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    // MARK: - Active Timer View
    private var activeTimerView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Color("AppPrimary").opacity(0.06), lineWidth: 20)
                    .frame(width: 260, height: 260)
                
                Circle()
                    .stroke(Color("AppPrimary").opacity(0.12), lineWidth: 16)
                    .frame(width: 240, height: 240)
                
                Circle()
                    .stroke(Color("AccentColor").opacity(0.15), lineWidth: 2)
                    .frame(width: 240, height: 240)
                    .scaleEffect(pulseTimer ? 1.08 : 1.0)
                    .opacity(pulseTimer ? 0 : 1)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false), value: pulseTimer)
                    .onAppear { pulseTimer = true }
                
                VStack(spacing: 6) {
                    Text("time_remaining".localized)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(1)
                    
                    Text(viewModel.timeString(from: viewModel.remainingTime))
                        .font(.system(size: 68, weight: .bold, design: .monospaced))
                        .foregroundColor(Color("AccentColor"))
                        .minimumScaleFactor(0.7)
                }
            }
            .padding(.top, 8)
            
            // Info pills
            HStack(spacing: 20) {
                timerInfoPill(icon: "timer", label: "Alerta previa", value: "\(preEndAlertMinutes) min")
                Divider().frame(height: 30)
                timerInfoPill(icon: "bell.fill", label: "Notificación", value: "Activada")
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0 : 0.05), radius: 10, x: 0, y: 4)
            .padding(.horizontal)
            
            // Botón cancelar
            Button(action: { viewModel.cancel() }) {
                HStack(spacing: 8) {
                    Image(systemName: "xmark.circle.fill").font(.body)
                    Text("cancel_parking_meter".localized).fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color("ErrorColor").opacity(0.1))
                .foregroundColor(Color("ErrorColor"))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color("ErrorColor").opacity(0.2), lineWidth: 1)
                )
            }
            .padding(.horizontal)
        }
    }
    
    private func timerInfoPill(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.caption).foregroundColor(Color("AccentColor"))
                Text(label).font(.caption).foregroundColor(.secondary)
            }
            Text(value).font(.subheadline).fontWeight(.semibold).foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Setup Timer View
    private var setupTimerView: some View {
        VStack(spacing: 16) {
            // Card duración
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(Color("AppPrimary"))
                        .font(.body)
                    Text("parking_duration".localized)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color("AppPrimary"))
                    Spacer()
                    Text("\(selectedMinutes) min")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("AccentColor"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color("AccentColor").opacity(0.1))
                        .clipShape(Capsule())
                }
                
                Picker("Minutos", selection: $selectedMinutes) {
                    ForEach(minuteOptions, id: \.self) { minute in
                        Text(String(format: "minutes_format".localized, minute)).tag(minute)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(height: 150)
                .clipped()
            }
            .padding(18)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0 : 0.06), radius: 10, x: 0, y: 4)
            .padding(.horizontal)
            
            // Card alerta previa
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "bell.fill")
                        .foregroundColor(Color("AppPrimary"))
                        .font(.body)
                    Text("pre_end_alert".localized)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color("AppPrimary"))
                    Spacer()
                }
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                    ForEach(preEndOptions, id: \.self) { min in
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) { preEndAlertMinutes = min }
                        }) {
                            Text(String(format: "minutes_format".localized, min))
                                .font(.subheadline)
                                .fontWeight(preEndAlertMinutes == min ? .bold : .regular)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(preEndAlertMinutes == min ? Color("AccentColor") : Color(.systemGray5))
                                .foregroundColor(preEndAlertMinutes == min ? .white : .primary)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(18)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0 : 0.06), radius: 10, x: 0, y: 4)
            .padding(.horizontal)
            
            Spacer()
            
            // Botón iniciar
            Button {
                viewModel.start(minutes: selectedMinutes, preEndAlert: preEndAlertMinutes)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "timer").font(.body).fontWeight(.semibold)
                    Text("start".localized).font(.title3).fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [Color("AccentColor"), Color("AppPrimary")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color("AccentColor").opacity(0.35), radius: 10, x: 0, y: 5)
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .ignoresSafeArea(.keyboard)
    }
    
    private func setupCallbacks() {
        viewModel.onPreEndAlert = { DispatchQueue.main.async { self.activeAlert = .preEnd } }
        viewModel.onFinalAlert = { DispatchQueue.main.async { self.activeAlert = .final } }
    }
    
    private func goToCar() {
        if parkingViewModel.lastParking != nil { showMap = true } else { activeAlert = .noParking }
    }
}

#Preview {
    ParkingMeterView(
        parkingViewModel: ParkingViewModel(),
        openParkingFromNotification: .constant(false)
    )
}
