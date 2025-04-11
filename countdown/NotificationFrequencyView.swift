import SwiftUI

struct NotificationFrequencyView: View {
    @Binding var selectedOffsets: [TimeInterval]
    let eventDate: Date
    let accentColor: Color
    @Environment(\.dismiss) var dismiss
    @State private var showingCustomTimeSheet = false // State for custom time picker

    // Computed property to filter available offsets
    private var availableOffsets: [TimeInterval] {
        // Filter standard options first
        let standardOptions = NotificationOffset.allOptions.filter {
            let notificationDate = eventDate.addingTimeInterval(-$0)
            return notificationDate > Date()
        }
        // Filter custom offsets (those not in allOptions)
        let customOffsets = selectedOffsets.filter { !NotificationOffset.allOptions.contains($0) }
        // Combine and sort (optional, for display consistency)
        return (standardOptions + customOffsets).sorted(by: >) // Show longer times first
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .font(.custom("Georgia", size: 16))
                .foregroundColor(.blue)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                
                Spacer()
                
                Text("Notify Me")
                    .font(.custom("Georgia", size: 18))
                    .fontWeight(.medium)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .font(.custom("Georgia", size: 16))
                .foregroundColor(accentColor)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
            }
            .background(Color(UIColor.systemGroupedBackground))
            
            Divider()

            // List of options
            List {
                // Section for Preset Times
                Section(header: Text("Presets").font(.custom("Georgia", size: 14))) {
                    ForEach(availableOffsets.filter { NotificationOffset.allOptions.contains($0) }, id: \.self) { offset in
                        HStack {
                            Text(NotificationOffset.description(for: offset))
                                .font(.custom("Georgia", size: 16))
                            Spacer()
                            if selectedOffsets.contains(offset) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            toggleSelection(for: offset)
                        }
                    }
                }
                
                // Section for Custom Times
                let customSelectedOffsets = availableOffsets.filter { !NotificationOffset.allOptions.contains($0) }
                if !customSelectedOffsets.isEmpty {
                    Section(header: Text("Custom").font(.custom("Georgia", size: 14))) {
                        ForEach(customSelectedOffsets, id: \.self) { offset in
                            HStack {
                                Text(formatCustomOffset(offset))
                                    .font(.custom("Georgia", size: 16))
                                Spacer()
                                Image(systemName: "checkmark")
                                    .foregroundColor(accentColor)
                            }
                            // Add swipe to delete for custom times
                            .swipeActions {
                                Button(role: .destructive) {
                                    removeOffset(offset)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                
                // Section for Adding Custom Time
                Section {
                    Button(action: { showingCustomTimeSheet = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(accentColor)
                            Text("Add Custom Time")
                                .font(.custom("Georgia", size: 16))
                                .foregroundColor(accentColor)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        // Sheet for Custom Time Picker
        .sheet(isPresented: $showingCustomTimeSheet) {
            CustomNotificationTimeView(
                selectedOffsets: $selectedOffsets,
                eventDate: eventDate,
                accentColor: accentColor
            )
        }
    }

    private func toggleSelection(for offset: TimeInterval) {
        // Only toggle for standard offsets
        guard NotificationOffset.allOptions.contains(offset) else { return }
        
        if let index = selectedOffsets.firstIndex(of: offset) {
            selectedOffsets.remove(at: index)
        } else {
            selectedOffsets.append(offset)
        }
    }
    
    private func removeOffset(_ offset: TimeInterval) {
        selectedOffsets.removeAll { $0 == offset }
    }
    
    // Helper to format custom offsets into readable strings
    private func formatCustomOffset(_ offset: TimeInterval) -> String {
        let notificationDate = eventDate.addingTimeInterval(-offset)
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: notificationDate)
    }
}

// Preview Provider
struct NotificationFrequencyView_Previews: PreviewProvider {
    @State static var previewOffsets: [TimeInterval] = NotificationOffset.defaultOffsets + [TimeInterval(15 * 60)] // Add a custom 15min for preview
    
    static var previews: some View {
        NotificationFrequencyView(
            selectedOffsets: $previewOffsets,
            eventDate: Date().addingTimeInterval(NotificationOffset.oneDay * 2),
            accentColor: Color(red: 0.4, green: 0.3, blue: 0.2)
        )
    }
} 