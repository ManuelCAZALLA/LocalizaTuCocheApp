//
//  UbicarApp.swift
//  Ubicar
//
//  Created by Manuel Cazalla Colmenero on 22/6/25.
//

import SwiftUI
import FirebaseCore
import FirebaseCrashlytics
import UserNotifications


// MARK: - AppDelegate para Firebase
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        
        
        FirebaseApp.configure()
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)


         //Crash de prueba
         /*DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
             fatalError("Crash de prueba para Firebase Crashlytics")
         }*/

        return true
    }
}

// MARK: - Main App
@main
struct UbiCarApp: App {
    
    // Registro el AppDelegate para Firebase
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
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

// MARK: - Delegate de Notificaciones
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    weak var appState: AppState?
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.notification.request.identifier.contains("meterReminder") {
            DispatchQueue.main.async {
                self.appState?.openParkingFromNotification = true
            }
        }
        completionHandler()
    }
}
