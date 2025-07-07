//
//  UbiCarApp.swift
//  UbiCar
//
//  Created by Manuel Cazalla Colmenero on 22/6/25.
//

import SwiftUI
import UserNotifications
import Combine

@main

struct UbiCarApp: App {
   
    let appState = AppState()
    
    init() {
        UIView.appearance().overrideUserInterfaceStyle = .light
        NotificationDelegate.shared.appState = appState
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    weak var appState: AppState?
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.notification.request.identifier.contains("meterReminder") {
            DispatchQueue.main.async {
                self.appState?.openParkingFromNotification = true
            }
        }
        completionHandler()
    }
}
