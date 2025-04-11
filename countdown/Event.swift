import Foundation

// Define common time intervals for notifications
struct NotificationOffset {
    static let oneHour: TimeInterval = 3600
    static let twelveHours: TimeInterval = 12 * oneHour
    static let oneDay: TimeInterval = 24 * oneHour
    static let twoDays: TimeInterval = 2 * oneDay
    static let threeDays: TimeInterval = 3 * oneDay
    static let thirtyMinutes: TimeInterval = 30 * 60
    static let atEventTime: TimeInterval = 0

    // Default offsets (all options selected initially)
    static let defaultOffsets: [TimeInterval] = [
        threeDays, twoDays, oneDay, twelveHours, oneHour, thirtyMinutes, atEventTime
    ]
    
    // Helper to get descriptions for intervals
    static func description(for offset: TimeInterval) -> String {
        switch offset {
            case threeDays: return "72 hours before"
            case twoDays: return "48 hours before"
            case oneDay: return "24 hours before"
            case twelveHours: return "12 hours before"
            case oneHour: return "1 hour before"
            case thirtyMinutes: return "30 minutes before"
            case atEventTime: return "At event time"
            default: return "Custom offset"
        }
    }
    
    // Provide all selectable offsets in order
    static let allOptions: [TimeInterval] = [
        threeDays, twoDays, oneDay, twelveHours, oneHour, thirtyMinutes, atEventTime
    ]
}

struct Event: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var date: Date
    var notificationOffsets: [TimeInterval]

    // Initializer with default notification offsets
    init(id: UUID = UUID(), title: String, date: Date, notificationOffsets: [TimeInterval] = NotificationOffset.defaultOffsets) {
        self.id = id
        self.title = title
        self.date = date
        self.notificationOffsets = notificationOffsets
    }
    
    var timeRemaining: (hours: Int, minutes: Int) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: Date(), to: date)
        return (hours: components.hour ?? 0, minutes: components.minute ?? 0)
    }
    
    var isPast: Bool {
        date < Date()
    }
    
    static func == (lhs: Event, rhs: Event) -> Bool {
        lhs.id == rhs.id
    }
}
