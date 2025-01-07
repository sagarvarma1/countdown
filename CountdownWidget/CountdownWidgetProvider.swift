import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    private let userDefaults = UserDefaults(suiteName: "group.com.countdown.app")
    private let eventsKey = "savedEvents"
    
    private func loadEvents() -> [Event]? {
        guard let data = userDefaults?.data(forKey: eventsKey),
              let decoded = try? JSONDecoder().decode([Event].self, from: data) else {
            return nil
        }
        return decoded.filter { !$0.isPast }
    }
    
    private func getNextEvent() -> Event? {
        guard let events = loadEvents() else { return nil }
        return events.filter { !$0.isPast }.min { $0.date < $1.date }
    }
    
    func placeholder(in context: Context) -> CountdownEntry {
        CountdownEntry(date: Date(), event: Event(id: UUID(), title: "Next Event", date: Date().addingTimeInterval(3600)))
    }

    func getSnapshot(in context: Context, completion: @escaping (CountdownEntry) -> ()) {
        if let nextEvent = getNextEvent() {
            let entry = CountdownEntry(date: Date(), event: nextEvent)
            completion(entry)
        } else {
            let entry = CountdownEntry(date: Date(), event: Event(id: UUID(), title: "No Events", date: Date().addingTimeInterval(3600)))
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [CountdownEntry] = []
        let currentDate = Date()
        
        if let nextEvent = getNextEvent() {
            // Create entries for every minute until the event
            let endDate = nextEvent.date
            var entryDate = currentDate
            
            while entryDate < endDate {
                let entry = CountdownEntry(date: entryDate, event: nextEvent)
                entries.append(entry)
                entryDate = Calendar.current.date(byAdding: .minute, value: 1, to: entryDate) ?? entryDate
            }
        } else {
            // If no events, just create a single entry
            let entry = CountdownEntry(date: currentDate, event: Event(id: UUID(), title: "No Events", date: Date().addingTimeInterval(3600)))
            entries.append(entry)
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct CountdownEntry: TimelineEntry {
    let date: Date
    let event: Event
}

struct CountdownWidgetEntryView : View {
    var entry: Provider.Entry
    
    private let accentColor = Color(red: 0.4, green: 0.3, blue: 0.2)
    private let backgroundColor = Color(red: 0.98, green: 0.97, blue: 0.95)
    
    var body: some View {
        ZStack {
            backgroundColor
            
            VStack(spacing: 8) {
                Text(entry.event.title)
                    .font(.custom("Georgia", size: 16))
                    .foregroundColor(accentColor)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text("\(entry.event.timeRemaining.hours)h")
                        .font(.custom("Georgia-Bold", size: 24))
                    Text("\(entry.event.timeRemaining.minutes)m")
                        .font(.custom("Georgia-Bold", size: 24))
                }
                .foregroundColor(accentColor)
            }
            .padding()
        }
    }
}

struct CountdownWidget: Widget {
    let kind: String = "CountdownWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            CountdownWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Countdown")
        .description("Shows time until your next event")
        .supportedFamilies([.systemSmall])
    }
}
