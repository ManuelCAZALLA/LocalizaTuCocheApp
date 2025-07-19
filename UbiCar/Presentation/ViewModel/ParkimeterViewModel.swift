//
//  ParkimeterModel.swift
//  UbiCar
//
//  Created by Manuel Cazalla Colmenero on 30/6/25.
//

import Foundation
import UserNotifications

final class ParkingMeterViewModel: ObservableObject {
    @Published var endTime: Date?
    @Published var remainingTime: TimeInterval?
    @Published var hasActiveTimer: Bool = false
    var onPreEndAlert: (() -> Void)?

    private var timer: Timer?
    private var preEndAlertSeconds: Int = 0
    private var preEndAlertTriggered: Bool = false

    // MARK: - Start meter countdown
    func start(minutes: Int, preEndAlert: Int) {
        endTime = Date().addingTimeInterval(Double(minutes * 60))
        hasActiveTimer = true
        updateRemainingTime()
        scheduleNotification()
        schedulePreEndNotification(preEndAlert)
        preEndAlertSeconds = preEndAlert * 60
        preEndAlertTriggered = false
        startCountdown()
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

    // MARK: - Internal countdown
    private func startCountdown() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateRemainingTime()
        }
    }

    private func updateRemainingTime() {
        guard let end = endTime else { return }
        let timeLeft = end.timeIntervalSinceNow
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
        } else {
            remainingTime = timeLeft
        }
    }

    // MARK: - Notification
    private func scheduleNotification() {
        let content = UNMutableNotificationContent()
        content.title = "⏰ ¡Se acabó el tiempo!"
        content.body = "Tu parquímetro ha expirado. Vuelve al coche."
        content.sound = .default

        guard let end = endTime else { return }

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: end.timeIntervalSinceNow,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "meterReminder",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }
    
    private func schedulePreEndNotification(_ preEndAlert: Int) {
        guard let end = endTime else { return }
        let preEndDate = end.addingTimeInterval(Double(-preEndAlert * 60))
        let timeInterval = preEndDate.timeIntervalSinceNow
        guard timeInterval > 0 else { return }
        let content = UNMutableNotificationContent()
        content.title = "⏰ ¡Queda poco tiempo!"
        content.body = "Tu parquímetro expirará en \(preEndAlert) minutos."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: "meterPreEndReminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
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

    // MARK: - Permission (call this once on app start)
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
}
