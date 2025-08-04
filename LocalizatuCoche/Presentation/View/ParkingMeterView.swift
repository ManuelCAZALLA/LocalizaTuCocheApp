import SwiftUI

struct ParkingMeterView: View {
    @ObservedObject var parkingViewModel: ParkingViewModel
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
                Text("parking_meter_emoji".localized)
                    .font(.system(size: 34, weight: .bold)) // Cambio: .largeTitle.bold() compatible
                    .foregroundColor(Color("AppPrimary"))
                    .padding(.top)
                
                if viewModel.hasActiveTimer {
                    VStack(spacing: 24) {
                        Text("time_remaining".localized)
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
                        Button(action: {
                            viewModel.cancel()
                        }) {
                            HStack {
                                Image(systemName: "xmark.circle")
                                Text("cancel_parking_meter".localized)
                            }
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
                                Text("parking_duration".localized)
                                    .font(.system(size: 22, weight: .bold)) // Cambio: .title2.bold() compatible
                                    .foregroundColor(Color("AppPrimary"))
                                Picker("Minutos", selection: $selectedMinutes) {
                                    ForEach(minuteOptions, id: \.self) { minute in
                                        Text(String(format: "minutes_format".localized, minute)).tag(minute)
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
                                Text("pre_end_alert".localized)
                                    .font(.system(size: 20, weight: .bold)) // Cambio: .title3.bold() compatible
                                    .foregroundColor(Color("AppPrimary"))
                                
                                Picker("Avisar antes", selection: $preEndAlertMinutes) {
                                    ForEach(preEndOptions, id: \.self) { min in
                                        Text(String(format: "minutes_format".localized, min)).tag(min)
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
                            Text("start".localized)
                                .font(.system(size: 22, weight: .bold)) // Cambio: .title2.bold() compatible
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
        }
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
        .onChange(of: openParkingFromNotification) { newValue in // Cambio: sintaxis iOS 16
            if newValue {
                alertType = .notification
                showAlert = true
                openParkingFromNotification = false
            }
        }
        // ALERTAS CON SINTAXIS iOS 16
        .alert(isPresented: $showAlert) {
            switch alertType {
            case .notification, .warning:
                return Alert(
                    title: Text("alert_attention".localized),
                    message: Text("alert_parking_expired".localized),
                    primaryButton: .default(Text("go_to_car".localized)) {
                        if parkingViewModel.lastParking != nil {
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
        .alert(isPresented: $showNoParkingAlert) {
            Alert(
                title: Text("no_saved_parking".localized),
                message: Text("must_save_parking_first".localized),
                dismissButton: .cancel(Text("ok".localized))
            )
        }
        .alert(isPresented: $showPreEndAlert) {
            Alert(
                title: Text("little_time_left".localized),
                message: Text("go_back_car_question".localized),
                primaryButton: .default(Text("go_back_to_car".localized)) {
                    if parkingViewModel.lastParking != nil {
                        showMap = true
                    } else {
                        showNoParkingAlert = true
                    }
                },
                secondaryButton: .cancel(Text("continue_countdown".localized))
            )
        }
        .alert(isPresented: $showFinalAlert) {
            Alert(
                title: Text("time_up".localized),
                message: Text("parking_meter_expired".localized),
                primaryButton: .default(Text("go_to_car".localized)) {
                    if parkingViewModel.lastParking != nil {
                        showMap = true
                    } else {
                        showNoParkingAlert = true
                    }
                },
                secondaryButton: .cancel(Text("close".localized))
            )
        }
        .fullScreenCover(isPresented: $showMap) {
            if let parking = parkingViewModel.lastParking {
                MapFullScreenView(parkingLocation: parking, onClose: { showMap = false })
            }
        }
    }
}

#Preview {
    ParkingMeterView(
        parkingViewModel: ParkingViewModel(),
        openParkingFromNotification: .constant(false)
    )
}
