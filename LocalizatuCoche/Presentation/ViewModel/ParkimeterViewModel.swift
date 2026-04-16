import Foundation
import Combine
import UserNotifications

final class ParkingMeterViewModel: ObservableObject {
    @Published var remainingTime: TimeInterval = 0
    @Published var hasActiveTimer = false
    
    private var timer: Timer?
    private var endDate: Date?
    private var preEndAlertDate: Date?
    private var preEndAlertSent = false
    
    var onPreEndAlert: (() -> Void)?
    var onFinalAlert: (() -> Void)?
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    func requestNotificationPermission() {
        notificationCenter.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Error al pedir permiso notificaciones: \(error.localizedDescription)")
            }
        }
    }
    
    func start(minutes: Int, preEndAlert: Int) {
        cancel()
        
        let now = Date()
        endDate = now.addingTimeInterval(TimeInterval(minutes * 60))
        preEndAlertDate = endDate?.addingTimeInterval(TimeInterval(-preEndAlert * 60))
        
        guard let endDate = endDate, let preEndAlertDate = preEndAlertDate else { return }
        
        remainingTime = endDate.timeIntervalSince(now)
        preEndAlertSent = false
        hasActiveTimer = true
        
        scheduleNotifications(endDate: endDate, preEndAlertDate: preEndAlertDate)
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    private func tick() {
        guard let endDate = endDate else { return }
        
        let now = Date()
        remainingTime = endDate.timeIntervalSince(now)
        
        if remainingTime <= 0 {
            timer?.invalidate()
            timer = nil
            hasActiveTimer = false
            onFinalAlert?()
            return
        }
        
        if let preEndAlertDate = preEndAlertDate,
           !preEndAlertSent,
           now >= preEndAlertDate {
            preEndAlertSent = true
            onPreEndAlert?()
        }
    }
    
    func cancel() {
        timer?.invalidate()
        timer = nil
        hasActiveTimer = false
        remainingTime = 0
        preEndAlertSent = false
        endDate = nil
        preEndAlertDate = nil
        
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["preEndAlert", "finalAlert"])
    }
    
    func timeString(from interval: TimeInterval) -> String {
        let seconds = max(0, Int(interval))
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
    
    private func scheduleNotifications(endDate: Date, preEndAlertDate: Date) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["preEndAlert", "finalAlert"])
        
        // Pre-end alert notification
        if preEndAlertDate > Date() {
            let preEndContent = UNMutableNotificationContent()
            preEndContent.title = "⏰ Tiempo casi terminado"
            preEndContent.body = "Tu parquímetro termina pronto. ¡Ve a tu coche!"
            preEndContent.sound = .default
            
            let preEndTrigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second], from: preEndAlertDate), repeats: false)
            
            let preEndRequest = UNNotificationRequest(identifier: "preEndAlert", content: preEndContent, trigger: preEndTrigger)
            
            notificationCenter.add(preEndRequest) { error in
                if let error = error {
                    print("Error al programar pre-end alert: \(error.localizedDescription)")
                }
            }
        }
        
        // Final alert notification
        if endDate > Date() {
            let finalContent = UNMutableNotificationContent()
            finalContent.title = "⏰ Tiempo terminado"
            finalContent.body = "El tiempo de tu parquímetro ha terminado. ¡Ve a tu coche!"
            finalContent.sound = .default
            
            let finalTrigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second], from: endDate), repeats: false)
            
            let finalRequest = UNNotificationRequest(identifier: "finalAlert", content: finalContent, trigger: finalTrigger)
            
            notificationCenter.add(finalRequest) { error in
                if let error = error {
                    print("Error al programar final alert: \(error.localizedDescription)")
                }
            }
        }
    }
}
