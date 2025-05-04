import SwiftUI
import CoreData

struct EntryDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var entry: LogEntry
    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var showingReschedulePicker = false
    @State private var isComplete: Bool = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Task description card with completion circle (for tasks)
                if entry.type == LogEntryType.task.rawValue {
                    taskCard
                } else {
                    // For non-task entries, show description without completion circle
                    VStack(alignment: .leading, spacing: 12) {
                        Text(entry.desc ?? "No description")
                            .font(.system(.title3, design: .rounded))
                            .foregroundColor(.themePrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.themeCard)
                            .cornerRadius(16)
                    }
                    .padding(.horizontal)
                }
                
                // Client section (if assigned)
                if let client = entry.client {
                    clientSection(client: client)
                }
                
                // Amount section (for payments)
                if entry.type == LogEntryType.payment.rawValue,
                   let amount = entry.amount as NSDecimalNumber?,
                   amount.doubleValue > 0 {
                    amountSection(amount: amount)
                }
                
                // Tag section (if exists)
                if let tag = entry.tag, !tag.isEmpty {
                    tagSection(tag: tag)
                }
                
                Spacer(minLength: 40)
                
                // Reschedule button (for tasks)
                if entry.type == LogEntryType.task.rawValue {
                    rescheduleButton
                }
            }
            .padding(.vertical, 16)
        }
        .background(Color.themeBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if entry.type != LogEntryType.task.rawValue {
                    // Only show the type for notes and payments
                    Text(entryTypeTitle)
                        .font(.headline)
                        .foregroundColor(.themePrimary)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingEditSheet = true }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.headline)
                        .foregroundColor(.themePrimary)
                        .padding(8)
                        .contentShape(Rectangle())
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            // Pass the entry to EditEntryView for editing
            EditEntryView(entry: entry)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showingReschedulePicker) {
            TaskDatePickerView(selectedDate: Binding(
                get: { entry.date ?? Date() },
                set: { newDate in
                    entry.date = newDate
                    try? viewContext.save()
                }
            ))
            .presentationDragIndicator(.hidden)
            .presentationBackground(Color(uiColor: .systemBackground))
            .presentationCornerRadius(24)
        }
        .alert("Delete Entry", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteEntry()
            }
        } message: {
            Text("Are you sure you want to delete this entry? This action cannot be undone.")
        }
        .onAppear {
            isComplete = entry.isComplete
        }
    }
    
    // Task card with completion circle and due date
    private var taskCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Completion circle and description on the same line
            HStack(alignment: .top, spacing: 12) {
                Button(action: toggleCompletion) {
                    ZStack {
                        Circle()
                            .stroke(isComplete ? Color.themeAccent : Color.gray.opacity(0.4), lineWidth: 2)
                            .frame(width: 28, height: 28)
                        
                        if isComplete {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.themeAccent)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // Task description
                Text(entry.desc ?? "No description")
                    .font(.system(.title3, design: .rounded))
                    .foregroundColor(isComplete ? .secondary : .themePrimary)
                    .strikethrough(isComplete)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            // Due date (if set)
            if let dueDate = entry.date {
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 14))
                        .foregroundColor(.themeAccent)
                    
                    Text(dateFormatter.string(from: dueDate))
                        .font(.subheadline)
                        .foregroundColor(.themeSecondary)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .padding(.leading, 40) // Align with the description text
            }
        }
        .background(Color.themeCard)
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    // Client section
    private func clientSection(client: Client) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Client")
                .font(.subheadline)
                .foregroundColor(.themeSecondary)
                .padding(.horizontal)
            
            NavigationLink(destination: ClientDetailView(client: client)) {
                HStack(spacing: 12) {
                    // Client avatar
                    ZStack {
                        Circle()
                            .fill(Color.themeAccent.opacity(0.12))
                            .frame(width: 36, height: 36)
                        
                        Text(clientInitials(from: client))
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundColor(Color.themeAccent)
                    }
                    
                    Text(client.name ?? "Unnamed Client")
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.themePrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.themeCard)
                .cornerRadius(16)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal)
    }
    
    // Amount section for payments
    private func amountSection(amount: NSDecimalNumber) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Amount")
                .font(.subheadline)
                .foregroundColor(.themeSecondary)
                .padding(.horizontal)
            
            HStack {
                Text("$\(amount.doubleValue, specifier: "%.2f")")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundColor(.themeAccent)
                
                Spacer()
            }
            .padding()
            .background(Color.themeCard)
            .cornerRadius(16)
        }
        .padding(.horizontal)
    }
    
    // Tag section
    private func tagSection(tag: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tag")
                .font(.subheadline)
                .foregroundColor(.themeSecondary)
                .padding(.horizontal)
            
            HStack {
                Text(tag)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.themePrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.themeAccent.opacity(0.1))
                    )
                
                Spacer()
            }
            .padding()
            .background(Color.themeCard)
            .cornerRadius(16)
        }
        .padding(.horizontal)
    }
    
    // Reschedule button at the bottom
    private var rescheduleButton: some View {
        Button(action: { showingReschedulePicker = true }) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                Text("Reschedule")
            }
            .font(.system(.headline, design: .rounded))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.themeAccent)
            )
            .padding(.horizontal)
        }
    }
    
    // MARK: - Helper Functions
    
    private func toggleCompletion() {
        withAnimation {
            isComplete.toggle()
            entry.isComplete = isComplete
            
            do {
                try viewContext.save()
                
                // Add haptic feedback
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            } catch {
                print("Error saving task completion status: \(error)")
            }
        }
    }
    
    private var entryTypeTitle: String {
        switch LogEntryType(rawValue: entry.type) {
        case .task:
            return ""
        case .note:
            return "Note"
        case .payment:
            return "Payment"
        default:
            return "Entry"
        }
    }
    
    private func clientInitials(from client: Client) -> String {
        guard let name = client.name, !name.isEmpty else { return "?" }
        
        let components = name.components(separatedBy: " ")
        if components.count > 1, 
           let firstLetter = components[0].first,
           let secondLetter = components[1].first {
            return String(firstLetter) + String(secondLetter)
        } else if let firstLetter = name.first {
            return String(firstLetter)
        } else {
            return "?"
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func deleteEntry() {
        viewContext.delete(entry)
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error deleting entry: \(error)")
        }
    }
}

struct EditEntryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var entry: LogEntry
    
    @State private var description: String = ""
    @State private var selectedClient: Client?
    @State private var entryDate: Date = Date()
    @State private var showDueDate: Bool = false
    @State private var showDatePicker: Bool = false
    @State private var showClientPicker: Bool = false
    @State private var showingSavedAnimation = false
    
    // For auto-focusing the text field
    @FocusState private var isDescriptionFocused: Bool
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Client.name, ascending: true)],
        animation: .default)
    private var clients: FetchedResults<Client>
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        ZStack {
            // Full-screen background
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with close and save buttons
                HStack {
                    Text("Edit Task")
                        .font(.headline)
                        .foregroundColor(.themePrimary)
                    
                    Spacer()
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
                
                // Description field
                TextField("Description", text: $description, axis: .vertical)
                    .font(.title3)
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .focused($isDescriptionFocused)
                    .frame(height: 120)
                
                Spacer()
                
                // Bottom area with client and date selection on same line
                VStack(spacing: 16) {
                    // Client and date row
                    HStack(spacing: 12) {
                        // Client selection
                        Button(action: {
                            showClientPicker = true
                        }) {
                            HStack {
                                Text(selectedClient?.name ?? "Select Client")
                                    .foregroundColor(selectedClient != nil ? .primary : .secondary)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(height: 44)
                            .padding(.horizontal, 12)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                        }
                        
                        // Due date selection
                        if showDueDate {
                            Button(action: {
                                showDatePicker = true
                            }) {
                                HStack {
                                    if Calendar.current.isDateInToday(entryDate) {
                                        Text("Today")
                                            .foregroundColor(.themeAccent)
                                    } else if Calendar.current.isDateInTomorrow(entryDate) {
                                        Text("Tomorrow")
                                            .foregroundColor(.themeAccent)
                                    } else {
                                        Text(formattedDate(entryDate))
                                            .foregroundColor(.themeAccent)
                                            .lineLimit(1)
                                    }
                                    
                                    Image(systemName: "calendar")
                                        .foregroundColor(.themeAccent)
                                        .font(.system(size: 14))
                                        .padding(.leading, 2)
                                }
                                .padding(.horizontal, 12)
                                .frame(height: 44)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(8)
                            }
                            
                            // Delete date button
                            Button(action: {
                                showDueDate = false
                                entryDate = Date()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 18))
                            }
                            .padding(.leading, -8)
                        } else {
                            // Add due date button
                            Button(action: {
                                showDueDate = true
                                showDatePicker = true
                            }) {
                                HStack {
                                    Image(systemName: "calendar.badge.plus")
                                        .foregroundColor(.themeAccent)
                                    Text("Add Due Date")
                                        .foregroundColor(.themeAccent)
                                }
                                .padding(.horizontal, 12)
                                .frame(height: 44)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Save button
                    Button(action: saveChanges) {
                        Text("Save Changes")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.themeAccent)
                            )
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .padding(.bottom, 16)
            }
            
            // Save confirmation overlay
            if showingSavedAnimation {
                VStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 70))
                        .foregroundColor(.themeAccent)
                    
                    Text("Saved!")
                        .font(.title2.weight(.medium))
                        .foregroundColor(.themeAccent)
                        .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.2))
                .ignoresSafeArea()
            }
        }
        .sheet(isPresented: $showDatePicker) {
            TaskDatePickerView(selectedDate: $entryDate)
                .presentationDragIndicator(.hidden)
                .presentationBackground(Color(uiColor: .systemBackground))
                .presentationCornerRadius(24)
        }
        .sheet(isPresented: $showClientPicker) {
            TaskClientPickerView(selectedClient: $selectedClient)
        }
        .onAppear {
            // Load entry values
            loadEntryValues()
            
            // Auto-focus the description field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isDescriptionFocused = true
            }
        }
    }
    
    private func loadEntryValues() {
        // Set values from the entry
        description = entry.desc ?? ""
        selectedClient = entry.client
        
        // Handle date
        if let date = entry.date {
            entryDate = date
            showDueDate = true
        } else {
            showDueDate = false
            entryDate = Date().addingTimeInterval(86400) // Tomorrow
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDate(date, equalTo: Date(), toGranularity: .year) {
            formatter.dateFormat = "MMM d"
        } else {
            formatter.dateFormat = "MMM d, yyyy"
        }
        return formatter.string(from: date)
    }
    
    private func saveChanges() {
        // Update entry with new values
        entry.desc = description
        entry.date = showDueDate ? entryDate : nil
        entry.client = selectedClient
        // We're not updating tag or isComplete here
        
        do {
            try viewContext.save()
            
            // Show success animation
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showingSavedAnimation = true
            }
            
            // Add success haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            // Dismiss after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                dismiss()
            }
        } catch {
            print("Error saving edited entry: \(error)")
        }
    }
}

// Helper view for client selection
struct TaskClientPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var selectedClient: Client?
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Client.name, ascending: true)],
        animation: .default)
    private var clients: FetchedResults<Client>
    
    var body: some View {
        NavigationStack {
            List {
                Button(action: {
                    selectedClient = nil
                    dismiss()
                }) {
                    HStack {
                        Text("No Client")
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedClient == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.themeAccent)
                        }
                    }
                }
                
                ForEach(clients) { client in
                    Button(action: {
                        selectedClient = client
                        dismiss()
                    }) {
                        HStack {
                            Text(client.name ?? "Unnamed Client")
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedClient == client {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.themeAccent)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let entry = LogEntry(context: context)
    entry.id = UUID()
    entry.type = LogEntryType.task.rawValue
    entry.desc = "Design new landing page for client website with modern aesthetic and improved user flows"
    entry.date = Date().addingTimeInterval(86400) // Tomorrow
    entry.tag = "Design"
    
    // Create a client
    let client = Client(context: context)
    client.id = UUID()
    client.name = "Acme Corp"
    client.tag = "Tech"
    
    // Assign client to entry
    entry.client = client
    
    return NavigationStack {
        EntryDetailView(entry: entry)
            .environment(\.managedObjectContext, context)
    }
} 