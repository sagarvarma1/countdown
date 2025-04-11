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
            
            // Remove any existing notifications for this event first
            self.removeNotifications(for: event)
            
            // Use the offsets stored in the event
            for offset in event.notificationOffsets {
                let content = UNMutableNotificationContent()
                content.title = event.title
                
                let timeRemainingDescription = self.timeRemainingString(from: offset)
                if offset == NotificationOffset.atEventTime {
                    content.body = "\(event.title) is starting now!"
                } else {
                    content.body = "\(timeRemainingDescription) until \(event.title)"
                }
                content.sound = .default
                
                // Calculate notification date by subtracting offset from event date
                let notificationDate = event.date.addingTimeInterval(-offset)
                
                // Only schedule if the notification date is in the future
                guard notificationDate > Date() else { continue }
                
                let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: notificationDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                
                // Create unique identifier for this notification using the offset
                let identifier = "\(event.id)-\(offset)"
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
        // We need to remove all *possible* notifications, not just the currently selected ones
        // because the user might have changed the frequency.
        let possibleIdentifiers = NotificationOffset.allOptions.map { "\(event.id)-\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: possibleIdentifiers)
    }
    
    // Helper function to create readable time remaining string
    private func timeRemainingString(from offset: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.unitsStyle = .full // e.g., "3 days", "12 hours", "30 minutes"
        formatter.maximumUnitCount = 2 // Show more detail if needed
        // Use `.brief` or `.abbreviated` if you prefer shorter strings like "3d", "1h"
        // formatter.unitsStyle = .abbreviated
        return formatter.string(from: offset) ?? "Custom time"
    }
}
