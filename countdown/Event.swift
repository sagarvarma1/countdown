import Foundation

struct Event: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var date: Date
    
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
