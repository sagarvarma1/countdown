import SwiftUI

struct CustomNotificationTimeView: View {
    @Binding var selectedOffsets: [TimeInterval]
    let eventDate: Date
    let accentColor: Color
    @Environment(\.dismiss) var dismiss

    @State private var customNotificationDate: Date

    init(selectedOffsets: Binding<[TimeInterval]>, eventDate: Date, accentColor: Color) {
        self._selectedOffsets = selectedOffsets
        self.eventDate = eventDate
        self.accentColor = accentColor
        let defaultTime = eventDate.addingTimeInterval(-NotificationOffset.oneHour)
        // Initialize to defaultTime if it's in the future, otherwise initialize slightly after Date()
        let initialDate = defaultTime > Date() ? defaultTime : Date().addingTimeInterval(1) // Add 1 second to avoid >= Date() issue
        // Ensure the initial date is not after the event date
        self._customNotificationDate = State(initialValue: min(initialDate, eventDate.addingTimeInterval(-1))) 
    }
    
    // Computed properties for validation
    private var isTimeBeforeEvent: Bool {
        // Allow selection up to 1 second before the event
        customNotificationDate < eventDate.addingTimeInterval(-1) 
    }
    private var isTimeInFuture: Bool {
        customNotificationDate > Date()
    }
    private var isSelectionValid: Bool {
        isTimeBeforeEvent && isTimeInFuture
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") { dismiss() }
                    .font(.custom("Georgia", size: 16))
                    .foregroundColor(.blue)
                    .padding()

                Spacer()
                Text("Custom Time")
                    .font(.custom("Georgia", size: 18))
                    .fontWeight(.medium)
                Spacer()

                Button("Add") { addCustomOffset() }
                    .font(.custom("Georgia", size: 16))
                    .foregroundColor(isSelectionValid ? accentColor : .gray)
                    .disabled(!isSelectionValid)
                    .padding()
            }
            .background(Color(UIColor.systemGroupedBackground))

            Divider()

            // Date Picker
            Form {
                DatePicker(
                    "Notify At",
                    selection: $customNotificationDate,
                    // Allow picking dates from now up to 1 second before the event
                    in: Date()...eventDate.addingTimeInterval(-1), 
                    displayedComponents: [.date, .hourAndMinute]
                )
                .font(.custom("Georgia", size: 16))
                .datePickerStyle(.graphical)
                .padding(.vertical)
                
                // Display specific error messages
                if !isTimeBeforeEvent {
                    Text("Notification time must be before the event starts.")
                        .font(.custom("Georgia", size: 12))
                        .foregroundColor(.red)
                } else if !isTimeInFuture {
                    Text("Notification time must be in the future.")
                        .font(.custom("Georgia", size: 12))
                        .foregroundColor(.red)
                }
            }
        }
        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }

    // Calculate and add the custom offset
    private func addCustomOffset() {
        guard isSelectionValid else { return }
        
        let offset = eventDate.timeIntervalSince(customNotificationDate)
        if !selectedOffsets.contains(offset) {
            selectedOffsets.append(offset)
        }
        dismiss()
    }
}

// Preview Provider
struct CustomNotificationTimeView_Previews: PreviewProvider {
    @State static var previewOffsets: [TimeInterval] = []
    static let previewDate = Date().addingTimeInterval(NotificationOffset.oneDay * 3)
    
    static var previews: some View {
        CustomNotificationTimeView(
            selectedOffsets: $previewOffsets,
            eventDate: previewDate,
            accentColor: Color(red: 0.4, green: 0.3, blue: 0.2)
        )
    }
} 