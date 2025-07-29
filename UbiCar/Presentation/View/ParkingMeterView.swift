import SwiftUI

struct ParkingMeterView: View {
    let parking: ParkingLocation?
    @Binding var openParkingFromNotification: Bool
    @StateObject private var viewModel = ParkingMeterViewModel()

    @State private var selectedMinutes: Int = 15
    @State private var preEndAlertMinutes: Int = 5
    @State private var showAlert = false
    @State private var alertType: ParkingAlertType? = nil
    @State private var showMap = false
    @State private var showNoParkingAlert = false
    @State private var showPreEndAlert = false
    @State private var showFinalAlert = false

    let minuteOptions = [15,20, 30, 45, 60, 90, 120]
    let preEndOptions = [1, 3, 5, 10, 15]

    enum ParkingAlertType {
        case warning, notification
    }

    var body: some View {
        ZStack {
            Color("BackgroundColor").ignoresSafeArea()

            VStack(spacing: 32) {
                Text("🅿️ Parquímetro")
                    .font(.largeTitle.bold())
                    .foregroundColor(Color("AppPrimary"))
                    .padding(.top)

                if viewModel.hasActiveTimer {
                    VStack(spacing: 24) {
                        Text("Tiempo restante")
                            .font(.headline)
                            .foregroundColor(Color("AppPrimary"))
                        ZStack {
                            Circle()
                                .stroke(Color("AppPrimary").opacity(0.2), lineWidth: 16)
                                .frame(width: 240, height: 240)
                            Text(viewModel.timeString(from: viewModel.remainingTime))
                                .font(.system(size: 90, weight: .bold, design: .monospaced))
                                .foregroundColor(Color("AccentColor"))
                        }
                        Button(role: .destructive) {
                            viewModel.cancel()
                        } label: {
                            Label("Cancelar parquímetro", systemImage: "xmark.circle")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color("ErrorColor").opacity(0.15))
                                .foregroundColor(Color("ErrorColor"))
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: Color("AppPrimary").opacity(0.08), radius: 8, x: 0, y: 4)
                    .padding(.horizontal)
                    Spacer()
                } else {
                    VStack {
                        Spacer()
                        VStack(spacing: 32) {
                            // Duración
                            VStack(spacing: 16) {
                                Text("Duración del parquímetro")
                                    .font(.title2.bold())
                                    .foregroundColor(Color("AppPrimary"))
                                Picker("Minutos", selection: $selectedMinutes) {
                                    ForEach(minuteOptions, id: \.self) { minute in
                                        Text("\(minute) min").tag(minute)
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(height: 180)
                                .clipped()
                            }
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .cornerRadius(20)
                            .shadow(color: Color("AppPrimary").opacity(0.08), radius: 10, x: 0, y: 4)
                            .padding(.horizontal)

                            // Aviso antes de finalizar
                            VStack(spacing: 16) {
                                Text("Aviso antes de finalizar")
                                    .font(.title3.bold())
                                    .foregroundColor(Color("AppPrimary"))
                                Picker("Avisar antes", selection: $preEndAlertMinutes) {
                                    ForEach(preEndOptions, id: \.self) { min in
                                        Text("\(min) min").tag(min)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .padding(.horizontal)
                            }
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .cornerRadius(20)
                            .shadow(color: Color("AppPrimary").opacity(0.08), radius: 10, x: 0, y: 4)
                            .padding(.horizontal)
                        }
                        Spacer()
                        
                        Button {
                            viewModel.start(minutes: selectedMinutes, preEndAlert: preEndAlertMinutes)
                        } label: {
                            Text("Iniciar")
                                .bold()
                                .font(.title2)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("AccentColor"))
                                .foregroundColor(.white)
                                .cornerRadius(16)
                                .shadow(radius: 6)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 32)
                    }
                    .ignoresSafeArea(.keyboard)
                }
                Spacer()
            }
            .padding(.top, 8)

            .onAppear {
                viewModel.requestNotificationPermission()
                showAlert = false
                
                // Pre-alerta (existente)
                viewModel.onPreEndAlert = {
                    showPreEndAlert = true
                }
                
                // NUEVA: Alerta final
                viewModel.onFinalAlert = {
                    showFinalAlert = true
                }
                
                if openParkingFromNotification {
                    alertType = .notification
                    showAlert = true
                    openParkingFromNotification = false
                }
            }
            .onChange(of: openParkingFromNotification) { _, newValue in
                if newValue {
                    alertType = .notification
                    showAlert = true
                    openParkingFromNotification = false
                }
            }

            .alert(isPresented: $showAlert) {
                switch alertType {
                case .notification, .warning:
                    return Alert(
                        title: Text("alert_attention".localized),
                        message: Text("alert_parking_expired".localized),
                        primaryButton: .default(Text("go_to_car".localized)) {
                            if parking != nil {
                                showMap = true
                            } else {
                                showNoParkingAlert = true
                            }
                        },
                        secondaryButton: .cancel(Text("close".localized))
                    )
                case .none:
                    return Alert(title: Text(""))
                }
            }

            .alert("No hay aparcamiento guardado", isPresented: $showNoParkingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Primero debes guardar la ubicación de tu coche para poder volver a él.")
            }

            .alert("¡Queda poco tiempo!", isPresented: $showPreEndAlert) {
                Button("Volver al coche") {
                    if parking != nil {
                        showMap = true
                    } else {
                        showNoParkingAlert = true
                    }
                }
                Button("Seguir la cuenta atrás", role: .cancel) {}
            } message: {
                Text("¿Quieres volver al coche o seguir la cuenta atrás?")
            }
            
            .alert("⏰ ¡Se acabó el tiempo!", isPresented: $showFinalAlert) {
                Button("Ir al coche") {
                    if parking != nil {
                        showMap = true
                    } else {
                        showNoParkingAlert = true
                    }
                }
                Button("Cerrar", role: .cancel) {}
            } message: {
                Text("Tu parquímetro ha expirado. Es hora de volver al coche.")
            }

            .fullScreenCover(isPresented: $showMap) {
                if let parking = parking {
                    MapFullScreenView(parkingLocation: parking, onClose: { showMap = false })
                }
            }
        }
    }

    private var activeTimerView: some View {
        VStack(spacing: 24) {
            Text("Tiempo restante")
                .font(.title2.bold())
                .foregroundColor(Color("AppPrimary"))

            ZStack {
                Circle()
                    .stroke(Color("AppPrimary").opacity(0.15), lineWidth: 16)
                Circle()
                    .stroke(Color("AccentColor"), style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: viewModel.remainingTime)
                Text(viewModel.timeString(from: viewModel.remainingTime))
                    .font(.system(size: 64, weight: .bold, design: .monospaced))
                    .foregroundColor(Color("AccentColor"))
            }
            .frame(width: 220, height: 220)

            Button(role: .destructive) {
                viewModel.cancel()
            } label: {
                Label("Cancelar parquímetro", systemImage: "xmark.circle")
                    .font(.title3.bold())
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color("ErrorColor").opacity(0.15))
                    .foregroundColor(Color("ErrorColor"))
                    .cornerRadius(16)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        .padding(.horizontal)
    }

    private var configurationView: some View {
        VStack(spacing: 24) {
            durationPickerView
            preEndPickerView

            Button {
                viewModel.start(minutes: selectedMinutes, preEndAlert: preEndAlertMinutes)
            } label: {
                Text("Iniciar")
                    .bold()
                    .font(.title3)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("AccentColor"))
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(radius: 6)
            }
            .padding(.top, 4)
        }
        .padding(.horizontal)
    }

    private var durationPickerView: some View {
        VStack(spacing: 12) {
            Text("Duración del parquímetro")
                .font(.headline)
                .foregroundColor(Color("AppPrimary"))

            Picker("Minutos", selection: $selectedMinutes) {
                ForEach(minuteOptions, id: \.self) { Text("\($0) min").tag($0) }
            }
            .pickerStyle(WheelPickerStyle())
            .frame(height: 140)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    private var preEndPickerView: some View {
        VStack(spacing: 12) {
            Text("Aviso antes de finalizar")
                .font(.headline)
                .foregroundColor(Color("AppPrimary"))

            Picker("Avisar antes", selection: $preEndAlertMinutes) {
                ForEach(preEndOptions, id: \.self) { Text("\($0) min").tag($0) }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

#Preview {
    ParkingMeterView(
        parking: ParkingLocation(
            latitude: 40.4168,
            longitude: -3.7038,
            date: Date(),
            placeName: "Aparcado en la Gran Vía"
        ),
        openParkingFromNotification: .constant(false)
    )
}
