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
            sortEvents() // Sort after loading
        }
        // Request notification permission
        NotificationManager.shared.requestAuthorization()
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(events) {
            userDefaults.set(encoded, forKey: eventsKey)
        }
    }
    
    private func sortEvents() {
        events.sort { $0.date < $1.date }
    }
    
    func addEvent(_ event: Event) {
        events.append(event)
        sortEvents() // Sort after adding
        save()
        // Schedule notifications for the new event
        NotificationManager.shared.scheduleNotifications(for: event)
    }
    
    func updateEvent(_ updatedEvent: Event) {
        if let index = events.firstIndex(where: { $0.id == updatedEvent.id }) {
            events[index] = updatedEvent
            sortEvents() // Sort after updating
            save()
            // Update notifications for the modified event
            NotificationManager.shared.scheduleNotifications(for: updatedEvent)
        }
    }
    
    func removeEvent(_ event: Event) {
        events.removeAll { $0.id == event.id }
        // Sorting might not be strictly necessary here, but keeps it consistent
        sortEvents() 
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
    @State private var editNotificationOffsets: [TimeInterval] = [] // State for editing offsets
    @State private var newNotificationOffsets: [TimeInterval] = NotificationOffset.defaultOffsets // State for new event offsets
    @State private var showingAddNotificationSheet = false // Separate state for Add sheet
    @State private var showingEditNotificationSheet = false // Separate state for Edit sheet
    
    private let backgroundColor = Color(red: 0.98, green: 0.97, blue: 0.95)
    private let accentColor = Color(red: 0.4, green: 0.3, blue: 0.2)
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)
                
                if eventStore.events.isEmpty {
                    // Empty state UI
                    VStack(spacing: 20) {
                        Spacer()
                        Text("Welcome to Countdown!")
                            .font(.custom("Georgia", size: 24))
                            .foregroundColor(accentColor)
                        Text("Add an event to begin")
                            .font(.custom("Georgia", size: 18))
                            .foregroundColor(.gray)
                        
                        Button(action: {
                            newEventDate = Date() // Reset date before showing sheet
                            showingAddEvent = true
                        }) {
                            Text("Add Event")
                                .font(.custom("Georgia", size: 18))
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 30)
                                .background(accentColor)
                                .cornerRadius(10)
                        }
                        .padding(.top, 10)
                        Spacer()
                    }
                    .padding(.horizontal, 40)
                    .multilineTextAlignment(.center)
                } else {
                    // UI when events exist
                    VStack(spacing: 0) {
                        if let nextEvent = eventStore.nextEvent {
                            VStack(spacing: 20) {
                                // Conditionally format title based on length
                                if nextEvent.title.count > 15 { // Threshold for two lines
                                    Text("Time Until\n\(nextEvent.title)")
                                        .font(.custom("Georgia", size: 26)) // Slightly smaller font for two lines
                                        .multilineTextAlignment(.center)
                                } else {
                                    Text("Time Until \(nextEvent.title)")
                                        .font(.custom("Georgia", size: 28))
                                }
                                
                                // Original foreground color applied here
                                Text("") // Dummy text to apply modifier to the group above implicitly
                                    .foregroundColor(accentColor)
                                
                                HStack(spacing: 40) {
                                    VStack {
                                        Text("\(nextEvent.timeRemaining.hours)")
                                            .font(.custom("Georgia-Bold", size: 62))
                                        Text("hours")
                                            .font(.custom("Georgia", size: 18))
                                    }
                                    
                                    VStack {
                                        Text("\(nextEvent.timeRemaining.minutes)")
                                            .font(.custom("Georgia-Bold", size: 62))
                                        Text("minutes")
                                            .font(.custom("Georgia", size: 18))
                                    }
                                }
                                .foregroundColor(accentColor)
                            }
                            .padding(.vertical, 30)
                            .padding(.horizontal, 30)
                            .background(backgroundColor)
                            .cornerRadius(16)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 30)
                        }
                        
                        List {
                            ForEach(eventStore.events) { event in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(event.title)
                                            .font(.custom("Georgia", size: 18))
                                            .foregroundColor(.white)
                                        Text(event.date, style: .date)
                                            .font(.custom("Georgia", size: 14))
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                    .padding(.vertical, 8)
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 4) {
                                        if event.isPast {
                                            Text("Past Event")
                                                .font(.custom("Georgia", size: 14))
                                                .foregroundColor(.white.opacity(0.8))
                                        } else {
                                            Text("\(event.timeRemaining.hours)h \(event.timeRemaining.minutes)m")
                                                .font(.custom("Georgia-Bold", size: 16))
                                                .foregroundColor(.white)
                                            Text("remaining")
                                                .font(.custom("Georgia", size: 12))
                                                .foregroundColor(.white.opacity(0.8))
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(accentColor)
                                .cornerRadius(12)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 4)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedEvent = event
                                    editEventTitle = event.title
                                    editEventDate = event.date
                                    editNotificationOffsets = event.notificationOffsets // Load current offsets
                                    showingEditEvent = true
                                }
                                .listRowBackground(backgroundColor)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets())
                            }
                            .onDelete { indexSet in
                                indexSet.forEach { index in
                                    eventStore.removeEvent(eventStore.events[index])
                                }
                            }
                        }
                        .listStyle(PlainListStyle())
                        .background(backgroundColor)
                        .scrollContentBackground(.hidden)
                        
                        // Add Event button at the bottom
                        Button(action: {
                            newEventDate = Date() // Reset date before showing sheet
                            showingAddEvent = true
                        }) {
                            Text("Add Event")
                                .font(.custom("Georgia", size: 18))
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 30)
                                .background(accentColor)
                                .cornerRadius(10)
                        }
                        .padding(.vertical, 15)
                    }
                }
            }
            // Remove the navigation title and plus button from the top
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingAddEvent) {
            VStack(spacing: 0) {
                HStack {
                    Button("Cancel") {
                        showingAddEvent = false
                        newEventTitle = ""
                        newEventDate = Date() // Reset date on cancel
                        newNotificationOffsets = NotificationOffset.defaultOffsets // Reset offsets
                    }
                    .font(.custom("Georgia", size: 16))
                    .foregroundColor(.blue)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    
                    Spacer()
                    
                    Text("New Event")
                        .font(.custom("Georgia", size: 18))
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Button("Add") {
                        let newEvent = Event(id: UUID(), title: newEventTitle, date: newEventDate, notificationOffsets: newNotificationOffsets)
                        eventStore.addEvent(newEvent)
                        showingAddEvent = false
                        newEventTitle = ""
                        newEventDate = Date() // Reset date after adding
                        newNotificationOffsets = NotificationOffset.defaultOffsets // Reset offsets
                    }
                    .font(.custom("Georgia", size: 16))
                    .foregroundColor(newEventTitle.isEmpty ? .gray : accentColor)
                    .disabled(newEventTitle.isEmpty)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                }
                .background(Color(UIColor.systemBackground))
                
                Divider()
                
                VStack(spacing: 12) {
                    TextField("Event Title", text: $newEventTitle)
                        .font(.custom("Georgia", size: 16))
                        .padding(10)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                    
                    DatePicker("Date", selection: $newEventDate, in: Date()...)
                        .font(.custom("Georgia", size: 16))
                        .padding(10)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                    
                    // Button to show notification frequency sheet (for Add Event)
                    Button(action: { showingAddNotificationSheet = true }) {
                        HStack {
                            Text("Notify Me")
                                .font(.custom("Georgia", size: 16))
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding(10)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                    }

                    Button(action: {
                        let newEvent = Event(id: UUID(), title: newEventTitle, date: newEventDate, notificationOffsets: newNotificationOffsets)
                        eventStore.addEvent(newEvent)
                        showingAddEvent = false
                        newEventTitle = ""
                        newEventDate = Date() // Reset date after adding
                        newNotificationOffsets = NotificationOffset.defaultOffsets // Reset offsets
                    }) {
                        Text("Add Event")
                            .font(.custom("Georgia", size: 18))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(newEventTitle.isEmpty ? Color.gray.opacity(0.5) : accentColor)
                            .cornerRadius(10)
                    }
                    .disabled(newEventTitle.isEmpty)
                    .padding(.bottom, 5)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(UIColor.systemBackground))
            }
            .presentationDetents([.height(280), .medium, .large]) // Adjusted height
            .presentationDragIndicator(.visible)
            // Nested sheet for notification frequency (for Add Event)
            .sheet(isPresented: $showingAddNotificationSheet) {
                NotificationFrequencyView(
                    selectedOffsets: $newNotificationOffsets,
                    eventDate: newEventDate,
                    accentColor: accentColor
                )
                .presentationDetents([.height(450)]) // Specific height for this sheet
            }
        }
        .sheet(isPresented: $showingEditEvent) {
            VStack(spacing: 0) {
                HStack {
                    Button("Cancel") {
                        showingEditEvent = false
                    }
                    .font(.custom("Georgia", size: 16))
                    .foregroundColor(.blue)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    
                    Spacer()
                    
                    Text("Edit Event")
                        .font(.custom("Georgia", size: 18))
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Button("Save") {
                        if let event = selectedEvent {
                            // Include updated offsets when saving
                            let updatedEvent = Event(id: event.id, title: editEventTitle, date: editEventDate, notificationOffsets: editNotificationOffsets)
                            eventStore.updateEvent(updatedEvent)
                        }
                        showingEditEvent = false
                    }
                    .font(.custom("Georgia", size: 16))
                    .foregroundColor(editEventTitle.isEmpty ? .gray : accentColor)
                    .disabled(editEventTitle.isEmpty)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                }
                .background(Color(UIColor.systemBackground))
                
                Divider()
                
                VStack(spacing: 12) {
                    TextField("Event Title", text: $editEventTitle)
                        .font(.custom("Georgia", size: 16))
                        .padding(10)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                    
                    DatePicker("Date", selection: $editEventDate, in: Date()...)
                        .font(.custom("Georgia", size: 16))
                        .padding(10)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                    
                    // Button to show notification frequency sheet (for Edit Event)
                    Button(action: { showingEditNotificationSheet = true }) {
                        HStack {
                            Text("Notify Me")
                                .font(.custom("Georgia", size: 16))
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding(10)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                    }

                    Button(action: {
                        if let event = selectedEvent {
                            // Include updated offsets when saving
                            let updatedEvent = Event(id: event.id, title: editEventTitle, date: editEventDate, notificationOffsets: editNotificationOffsets)
                            eventStore.updateEvent(updatedEvent)
                        }
                        showingEditEvent = false
                    }) {
                        Text("Save Event")
                            .font(.custom("Georgia", size: 18))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(editEventTitle.isEmpty ? Color.gray.opacity(0.5) : accentColor)
                            .cornerRadius(10)
                    }
                    .disabled(editEventTitle.isEmpty)
                    .padding(.bottom, 5)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(UIColor.systemBackground))
            }
            .presentationDetents([.height(280), .medium, .large]) // Adjusted height for new button
            .presentationDragIndicator(.visible)
            // Nested sheet for notification frequency (for Edit Event)
            .sheet(isPresented: $showingEditNotificationSheet) {
                NotificationFrequencyView(
                    selectedOffsets: $editNotificationOffsets,
                    eventDate: editEventDate,
                    accentColor: accentColor
                )
                .presentationDetents([.height(450)]) // Specific height for this sheet
            }
        }
    }
}

#Preview {
    ContentView()
}
