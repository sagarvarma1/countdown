import SwiftUI
import UserNotifications

class EventStore: ObservableObject {
    @Published var events: [Event] = []
    
    private let userDefaults = UserDefaults.standard
    private let eventsKey = "savedEvents"
    
    init() {
        if let data = userDefaults.data(forKey: eventsKey),
           let decoded = try? JSONDecoder().decode([Event].self, from: data) {
            events = decoded.filter { !$0.isPast }
        }
        // Request notification permission
        NotificationManager.shared.requestAuthorization()
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(events) {
            userDefaults.set(encoded, forKey: eventsKey)
        }
    }
    
    func addEvent(_ event: Event) {
        events.append(event)
        save()
        // Schedule notifications for the new event
        NotificationManager.shared.scheduleNotifications(for: event)
    }
    
    func updateEvent(_ updatedEvent: Event) {
        if let index = events.firstIndex(where: { $0.id == updatedEvent.id }) {
            events[index] = updatedEvent
            save()
            // Update notifications for the modified event
            NotificationManager.shared.scheduleNotifications(for: updatedEvent)
        }
    }
    
    func removeEvent(_ event: Event) {
        events.removeAll { $0.id == event.id }
        save()
        // Remove notifications for the deleted event
        NotificationManager.shared.removeNotifications(for: event)
    }
    
    var nextEvent: Event? {
        events.filter { !$0.isPast }.min { $0.date < $1.date }
    }
}

struct ContentView: View {
    @StateObject private var eventStore = EventStore()
    @State private var showingAddEvent = false
    @State private var showingEditEvent = false
    @State private var newEventTitle = ""
    @State private var newEventDate = Date()
    @State private var selectedEvent: Event?
    @State private var editEventTitle = ""
    @State private var editEventDate = Date()
    
    private let backgroundColor = Color(red: 0.98, green: 0.97, blue: 0.95)
    private let accentColor = Color(red: 0.4, green: 0.3, blue: 0.2)
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    if let nextEvent = eventStore.nextEvent {
                        VStack(spacing: 20) {
                            Text(nextEvent.title)
                                .font(.custom("Georgia", size: 32))
                                .foregroundColor(accentColor)
                            
                            HStack(spacing: 15) {
                                VStack {
                                    Text("\(nextEvent.timeRemaining.hours)")
                                        .font(.custom("Georgia-Bold", size: 48))
                                    Text("hours")
                                        .font(.custom("Georgia", size: 18))
                                }
                                
                                VStack {
                                    Text("\(nextEvent.timeRemaining.minutes)")
                                        .font(.custom("Georgia-Bold", size: 48))
                                    Text("minutes")
                                        .font(.custom("Georgia", size: 18))
                                }
                            }
                            .foregroundColor(accentColor)
                        }
                        .padding(.vertical, 40)
                    }
                    
                    List {
                        ForEach(eventStore.events) { event in
                            VStack(alignment: .leading) {
                                Text(event.title)
                                    .font(.custom("Georgia", size: 18))
                                Text(event.date, style: .date)
                                    .font(.custom("Georgia", size: 14))
                                    .foregroundColor(.gray)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedEvent = event
                                editEventTitle = event.title
                                editEventDate = event.date
                                showingEditEvent = true
                            }
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { index in
                                eventStore.removeEvent(eventStore.events[index])
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Countdown")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(trailing: Button(action: {
                showingAddEvent = true
            }) {
                Image(systemName: "plus")
                    .foregroundColor(accentColor)
                    .font(.custom("Georgia", size: 18))
            })
        }
        .sheet(isPresented: $showingAddEvent) {
            NavigationView {
                Form {
                    TextField("Event Title", text: $newEventTitle)
                        .font(.custom("Georgia", size: 16))
                    DatePicker("Date", selection: $newEventDate, in: Date()...)
                        .font(.custom("Georgia", size: 16))
                }
                .navigationTitle("New Event")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    leading: Button("Cancel") {
                        showingAddEvent = false
                        newEventTitle = ""
                    }
                    .font(.custom("Georgia", size: 16)),
                    trailing: Button("Add") {
                        let newEvent = Event(id: UUID(), title: newEventTitle, date: newEventDate)
                        eventStore.addEvent(newEvent)
                        showingAddEvent = false
                        newEventTitle = ""
                    }
                    .font(.custom("Georgia", size: 16))
                    .disabled(newEventTitle.isEmpty)
                )
            }
        }
        .sheet(isPresented: $showingEditEvent) {
            NavigationView {
                Form {
                    TextField("Event Title", text: $editEventTitle)
                        .font(.custom("Georgia", size: 16))
                    DatePicker("Date", selection: $editEventDate, in: Date()...)
                        .font(.custom("Georgia", size: 16))
                }
                .navigationTitle("Edit Event")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    leading: Button("Cancel") {
                        showingEditEvent = false
                    }
                    .font(.custom("Georgia", size: 16)),
                    trailing: Button("Save") {
                        if let event = selectedEvent {
                            let updatedEvent = Event(id: event.id, title: editEventTitle, date: editEventDate)
                            eventStore.updateEvent(updatedEvent)
                        }
                        showingEditEvent = false
                    }
                    .font(.custom("Georgia", size: 16))
                    .disabled(editEventTitle.isEmpty)
                )
            }
        }
    }
}

#Preview {
    ContentView()
}
