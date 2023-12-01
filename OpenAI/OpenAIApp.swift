//
//  OpenAIApp.swift
//  OpenAI
//
//  Created by Reid Chatham on 1/20/23.
//

import SwiftUI
import UserNotifications
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@main
struct OpenAIApp: App {
    let persistenceController = PersistenceController.shared
    let notificationManager = NotificationManager.shared

    #if canImport(UIKit)
    @UIApplicationDelegateAdaptor(AppDelegate.self) static var delegate
    #elseif canImport(AppKit)
    @NSApplicationDelegateAdaptor(AppDelegate.self) static var delegate
    #endif

    var body: some Scene {
        WindowGroup {
            InboxView(conversationService: persistenceController.conversationService)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }

    init() {
//        notificationManager.requestPushNotificationPermission()
    }
}

class NotificationManager {
    static let shared = NotificationManager()

    private init() { }

    func requestPushNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge], completionHandler: handleRequestAuthorization)
    }

    func handleRequestAuthorization(granted: Bool, error: Error?) {
        if let error = error {
            print("Error requesting authorization for push notifications: \(error.localizedDescription)")
            return
        }

        guard granted else {
            return print("Permission denied for push notifications")
        }
        print("Permission granted for push notifications")
        DispatchQueue.main.async {
            #if canImport(UIKit)
            UIApplication.shared.registerForRemoteNotifications()
            #elseif canImport(AppKit)
            NSApplication.shared.registerForRemoteNotifications()
            #endif
        }
    }
}

#if canImport(UIKit)
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        application.registerForRemoteNotifications()
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        handleDeviceToken(deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        handleRemoteNotificationRegistrationError(error)
    }
}
#elseif canImport(AppKit)
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.registerForRemoteNotifications()
    }

    func application(_ application: NSApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        handleDeviceToken(deviceToken)
    }

    func application(_ application: NSApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        handleRemoteNotificationRegistrationError(error)
    }
}
#endif

func handleDeviceToken(_ deviceToken: Data) {
    let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
    let token = tokenParts.joined()
    UserDefaults.deviceToken = token
    print("Device Token: \(token)")
}

func handleRemoteNotificationRegistrationError(_ error: Error) {
    print("Failed to register for remote notifications: \(error.localizedDescription)")
}
