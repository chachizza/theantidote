import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    private init() {
        requestAuthorization()
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification authorization: \(error)")
            }
        }
    }
    
    func scheduleWarningNotification(minutesLeft: Int) {
        let content = UNMutableNotificationContent()
        content.title = "App Limit Warning"
        content.body = "You have \(minutesLeft) minutes left before your selected apps are blocked."
        content.sound = .default
        content.categoryIdentifier = "warning"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "limitWarning", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling warning: \(error)")
            }
        }
    }
    
    func scheduleChallengeAvailableNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Challenge Available"
        content.body = "Complete a mindful challenge to unlock your apps for 5 minutes."
        content.sound = .default
        content.categoryIdentifier = "challenge"
        content.userInfo = ["deepLink": "antidote://challenge"]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "challengeAvailable", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling challenge notification: \(error)")
            }
        }
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    func cancelNotification(with identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func setupNotificationCategories() {
        let challengeAction = UNNotificationAction(
            identifier: "CHALLENGE_NOW",
            title: "Start Challenge",
            options: [.foreground]
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE",
            title: "Snooze",
            options: []
        )
        
        let challengeCategory = UNNotificationCategory(
            identifier: "challenge",
            actions: [challengeAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([challengeCategory])
    }
    
    func handleNotificationResponse(_ response: UNNotificationResponse) {
        switch response.actionIdentifier {
        case "CHALLENGE_NOW":
            // Handle challenge action
            NotificationCenter.default.post(name: .showChallenge, object: nil)
        case "SNOOZE":
            // Handle snooze action
            scheduleChallengeAvailableNotification()
        default:
            break
        }
    }
}

extension Notification.Name {
    static let showChallenge = Notification.Name("showChallenge")
}

extension UNUserNotificationCenter: @retroactive UNUserNotificationCenterDelegate {
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        NotificationManager.shared.handleNotificationResponse(response)
        completionHandler()
    }
}