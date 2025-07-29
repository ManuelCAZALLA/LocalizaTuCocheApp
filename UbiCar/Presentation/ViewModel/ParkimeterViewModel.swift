import Foundation
import UserNotifications

final class ParkingMeterViewModel: ObservableObject {
    @Published var endTime: Date?
    @Published var remainingTime: TimeInterval?
    @Published var hasActiveTimer: Bool = false
    var onPreEndAlert: (() -> Void)?
    var onFinalAlert: (() -> Void)?

    private var timer: Timer?
    private var preEndAlertSeconds: Int = 0
    private var preEndAlertTriggered: Bool = false

    // MARK: - Start meter countdown
    func start(minutes: Int, preEndAlert: Int) {
        endTime = Date().addingTimeInterval(Double(minutes * 60))
        hasActiveTimer = true
        updateRemainingTime()
        preEndAlertSeconds = preEndAlert * 60
        preEndAlertTriggered = false
        
        // SIEMPRE iniciar la cuenta atrás (independiente de permisos)
        startCountdown()
        
        // INTENTAR programar notificaciones (pero sin parar si falla)
        checkPermissionsAndScheduleNotifications(preEndAlert: preEndAlert)
    }
    
    // NUEVA FUNCIÓN: Gestión inteligente de permisos
    private func checkPermissionsAndScheduleNotifications(preEndAlert: Int) {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            switch settings.authorizationStatus {
            case .authorized:
                // Ya tiene permisos, programar directamente
                DispatchQueue.main.async {
                    self?.scheduleNotification()
                    self?.schedulePreEndNotification(preEndAlert)
                }
                
            case .notDetermined:
                // Primera vez, pedir permisos
                self?.requestPermissionAndSchedule(preEndAlert: preEndAlert)
                
            case .denied, .provisional:
                // Sin permisos, solo mostrar alert local (sin parar cuenta atrás)
                print("⚠️ Sin permisos de notificación, solo alertas locales")
                
            case .ephemeral:
                // "Permitir una vez" - programar y no volver a pedir
                DispatchQueue.main.async {
                    self?.scheduleNotification()
                    self?.schedulePreEndNotification(preEndAlert)
                }
                
            @unknown default:
                print("⚠️ Estado de permisos desconocido")
            }
        }
    }
    
    // FUNCIÓN MEJORADA: Pedir permisos sin parar cuenta atrás
    private func requestPermissionAndSchedule(preEndAlert: Int) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                if granted {
                    self?.scheduleNotification()
                    self?.schedulePreEndNotification(preEndAlert)
                    print("✅ Permisos concedidos, notificaciones programadas")
                } else {
                    print("❌ Permisos denegados: \(error?.localizedDescription ?? "Sin error")")
                    // La cuenta atrás SIGUE funcionando, solo sin notificaciones
                }
            }
        }
    }

    // MARK: - Cancel meter
    func cancel() {
        endTime = nil
        remainingTime = nil
        hasActiveTimer = false
        timer?.invalidate()
        timer = nil
        removeNotification()
    }

    // MARK: - Internal countdown (NUNCA se para por permisos)
    private func startCountdown() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateRemainingTime()
        }
    }

    private func updateRemainingTime() {
        guard let end = endTime else { return }
        let timeLeft = end.timeIntervalSinceNow
        
        // Alert local de pre-fin (independiente de notificaciones)
        if !preEndAlertTriggered, preEndAlertSeconds > 0, Int(timeLeft) <= preEndAlertSeconds, Int(timeLeft) > 0 {
            preEndAlertTriggered = true
            DispatchQueue.main.async {
                self.onPreEndAlert?()
            }
        }
        
        if timeLeft <= 0 {
            remainingTime = 0
            hasActiveTimer = false
            timer?.invalidate()
            timer = nil
            
            // Alert final local (siempre se ejecuta)
            DispatchQueue.main.async {
                self.showFinalAlert()
            }
        } else {
            remainingTime = timeLeft
        }
    }
    
    // NUEVA FUNCIÓN: Alert final local
    private func showFinalAlert() {
        print("🚨 ¡TIEMPO TERMINADO! Parquímetro expirado")
        // Ejecutar callback para mostrar alert en la UI
        DispatchQueue.main.async {
            self.onFinalAlert?()
        }
    }

    // MARK: - Notification scheduling
    private func scheduleNotification() {
        guard let end = endTime else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "⏰ ¡Se acabó el tiempo!"
        content.body = "Tu parquímetro ha expirado. Vuelve al coche."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: end.timeIntervalSinceNow,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "meterReminder",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error programando notificación: \(error)")
            } else {
                print("✅ Notificación final programada")
            }
        }
    }
    
    private func schedulePreEndNotification(_ preEndAlert: Int) {
        guard let end = endTime, preEndAlert > 0 else { return }
        
        let preEndDate = end.addingTimeInterval(Double(-preEndAlert * 60))
        let timeInterval = preEndDate.timeIntervalSinceNow
        guard timeInterval > 0 else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "⏰ ¡Queda poco tiempo!"
        content.body = "Tu parquímetro expirará en \(preEndAlert) minutos."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: "meterPreEndReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error programando pre-notificación: \(error)")
            } else {
                print("✅ Pre-notificación programada para \(preEndAlert) min antes")
            }
        }
    }

    func timeString(from interval: TimeInterval?) -> String {
        guard let interval = interval else { return "--:--" }
        let totalSeconds = Int(interval)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func removeNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["meterReminder", "meterPreEndReminder"])
    }

    // MARK: - Permission check (call this once on app start)
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("✅ Permisos de notificación concedidos al inicio")
                } else {
                    print("❌ Permisos de notificación denegados: \(error?.localizedDescription ?? "Sin error")")
                }
            }
        }
    }
    
    // MARK: - Estado de permisos para debugging
    func checkCurrentPermissions() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized:
                    print("🟢 Permisos: AUTORIZADOS")
                case .denied:
                    print("🔴 Permisos: DENEGADOS")
                case .notDetermined:
                    print("🟡 Permisos: NO DETERMINADOS")
                case .provisional:
                    print("🟠 Permisos: PROVISIONAL")
                case .ephemeral:
                    print("🟣 Permisos: EPHEMERAL (Permitir una vez)")
                @unknown default:
                    print("❓ Permisos: DESCONOCIDO")
                }
            }
        }
    }
}
