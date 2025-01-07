import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestAuthorization(completion: @escaping (Bool) -> Void = { _ in }) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    DispatchQueue.main.async {
                        completion(granted)
                    }
                }
            case .denied:
                DispatchQueue.main.async {
                    completion(false)
                }
            case .authorized, .provisional, .ephemeral:
                DispatchQueue.main.async {
                    completion(true)
                }
            @unknown default:
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
    
    func scheduleNotifications(for event: Event) {
        // First check if we have permission
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            
            // Remove any existing notifications for this event
            self.removeNotifications(for: event)
            
            let notificationDays = [3, 2, 1]
            
            for days in notificationDays {
                let content = UNMutableNotificationContent()
                content.title = event.title
                content.body = "\(days) day\(days == 1 ? "" : "s") until \(event.title)"
                content.sound = .default
                
                // Calculate notification date
                let notificationDate = Calendar.current.date(byAdding: .day, value: -days, to: event.date)!
                
                // Only schedule if the notification date is in the future
                guard notificationDate > Date() else { continue }
                
                let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                
                // Create unique identifier for this notification
                let identifier = "\(event.id)-\(days)days"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("Error scheduling notification: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    func removeNotifications(for event: Event) {
        let identifiers = [3, 2, 1].map { "\(event.id)-\(String($0))days" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}
