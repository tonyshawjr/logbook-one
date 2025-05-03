import SwiftUI
import CoreData



struct EntryDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var entry: LogEntry
    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var isComplete: Bool = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Entry type header
                entryHeader
                
                // Entry details card
                entryDetailsCard
                
                // Client info
                if let client = entry.client {
                    clientInfoCard(client: client)
                }
                
                // Action buttons
                actionButtons
                
                Spacer()
            }
            .padding(.vertical)
        }
        .background(Color.appBackground)
        .navigationTitle(entryTypeTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingEditSheet = true }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.headline)
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            // Pass the entry to LogEntryFormView for editing
            EditEntryView(entry: entry)
                .environment(\.managedObjectContext, viewContext)
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
    
    private var entryHeader: some View {
        HStack {
            EntryTypeBadgeView(type: LogEntryType(rawValue: entry.type) ?? .task)
                .scaleEffect(1.2)
            
            Spacer()
            
            if let date = entry.date {
                Text(dateFormatter.string(from: date))
                    .font(.appSubheadline)
                    .foregroundColor(.secondaryText)
            }
        }
        .padding(.horizontal)
    }
    
    private var entryDetailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Description
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.appSubheadline)
                    .foregroundColor(.secondaryText)
                
                Text(entry.desc ?? "No description")
                    .font(.appBody)
                    .foregroundColor(.primaryText)
            }
            
            Divider()
            
            // Task completion status (if task)
            if entry.type == LogEntryType.task.rawValue {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Status")
                        .font(.appSubheadline)
                        .foregroundColor(.secondaryText)
                    
                    Toggle(isOn: $isComplete.animation()) {
                        Text(isComplete ? "Completed" : "Not Completed")
                            .font(.appBody)
                            .foregroundColor(isComplete ? .success : .primaryText)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .appAccent))
                    .onChange(of: isComplete) { oldValue, newValue in
                        entry.isComplete = newValue
                        do {
                            try viewContext.save()
                            
                            // Add haptic feedback for task completion
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                        } catch {
                            print("Error saving task completion status: \(error)")
                        }
                    }
                }
                
                Divider()
            }
            
            // Amount (for payment)
            if entry.type == LogEntryType.payment.rawValue,
               let amount = entry.amount as NSDecimalNumber?,
               amount.doubleValue > 0 {
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Amount")
                        .font(.appSubheadline)
                        .foregroundColor(.secondaryText)
                    
                    let amountValue = amount.doubleValue
                    Text("$\(amountValue, specifier: "%.2f")")
                        .font(.system(.title2, design: .default).weight(.bold))
                        .foregroundColor(.paymentColor)
                }
                
                Divider()
            }
            
            // Tag (if exists)
            if let tag = entry.tag, !tag.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tag")
                        .font(.appSubheadline)
                        .foregroundColor(.secondaryText)
                    
                    Text(tag)
                        .font(.appBody)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        .padding(.horizontal)
    }
    
    private func clientInfoCard(client: Client) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Client")
                .font(.appSubheadline)
                .foregroundColor(.secondaryText)
            
            HStack(spacing: 12) {
                // Client avatar
                ZStack {
                    Circle()
                        .fill(Color.appAccent.opacity(0.12))
                        .frame(width: 40, height: 40)
                    
                    Text(clientInitials(from: client))
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundColor(Color.appAccent)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(client.name ?? "Unnamed Client")
                        .font(.appHeadline)
                    
                    if let tag = client.tag, !tag.isEmpty {
                        Text(tag)
                            .font(.appCaption)
                            .foregroundColor(.secondaryText)
                    }
                }
                
                Spacer()
                
                NavigationLink(destination: ClientDetailView(client: client)) {
                    Text("View")
                        .font(.appCaption.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.appAccent.opacity(0.1))
                        .foregroundColor(.appAccent)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        .padding(.horizontal)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // In the future, you can add more action buttons here
            // For now, keeping it simple with just the share button
            
            Button(action: {
                // Share this entry
                let entryText = createShareText()
                let activityViewController = UIActivityViewController(
                    activityItems: [entryText],
                    applicationActivities: nil
                )
                
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = windowScene.windows.first?.rootViewController {
                    rootVC.present(activityViewController, animated: true)
                }
            }) {
                Label("Share Entry", systemImage: "square.and.arrow.up")
                    .font(.appHeadline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.cardBackground)
                    .foregroundColor(.appAccent)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }
    
    private func createShareText() -> String {
        var text = "LogbookOne Entry\n\n"
        
        let typeName = LogEntryType(rawValue: entry.type)?.displayName ?? "Unknown"
        text += "Type: " + typeName + "\n"
        
        if let date = entry.date {
            let dateStr = dateFormatter.string(from: date)
            text += "Date: " + dateStr + "\n"
        }
        
        if let client = entry.client {
            let clientName = client.name ?? "Unnamed Client"
            text += "Client: " + clientName + "\n"
        }
        
        let description = entry.desc ?? ""
        text += "Description: " + description + "\n"
        
        if entry.type == LogEntryType.payment.rawValue,
           let amount = entry.amount as NSDecimalNumber?,
           amount.doubleValue > 0 {
            let amountValue = amount.doubleValue
            let formattedAmount = String(format: "$%.2f", amountValue)
            text += "Amount: \(formattedAmount)\n"
        }
        
        if let tag = entry.tag, !tag.isEmpty {
            text += "Tag: " + tag + "\n"
        }
        
        return text
    }
    
    private var entryTypeTitle: String {
        switch LogEntryType(rawValue: entry.type) {
        case .task:
            return "Task"
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
    @State private var amount: String = ""
    @State private var tag: String = ""
    @State private var isComplete: Bool = false
    @State private var selectedClient: Client?
    @State private var entryDate: Date = Date()
    @State private var showingSavedAnimation = false
    @State private var selectedType: LogEntryType = .task
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Client.name, ascending: true)],
        animation: .default)
    private var clients: FetchedResults<Client>
    
    var body: some View {
        NavigationStack {
            ZStack {
                Form {
                    Section(header: Text("Entry Details")) {
                        Picker("Type", selection: $selectedType) {
                            ForEach(LogEntryType.allCases) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        Picker("Client", selection: $selectedClient) {
                            Text("No Client").tag(nil as Client?)
                            ForEach(clients) { client in
                                Text(client.name ?? "Unnamed Client").tag(client as Client?)
                            }
                        }
                        
                        DatePicker("Date", selection: $entryDate, displayedComponents: [.date, .hourAndMinute])
                        
                        TextField("Description", text: $description, axis: .vertical)
                            .lineLimit(3...6)
                        
                        if selectedType == .payment {
                            TextField("Amount ($)", text: $amount)
                                .keyboardType(.decimalPad)
                        }
                        
                        if selectedType == .task {
                            Toggle("Completed", isOn: $isComplete)
                        }
                        
                        TextField("Tag (optional)", text: $tag)
                    }
                }
                .navigationTitle("Edit Entry")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            saveChanges()
                        }
                    }
                }
                
                // Save confirmation overlay
                if showingSavedAnimation {
                    VStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 70))
                            .foregroundColor(.appAccent)
                        
                        Text("Saved!")
                            .font(.title2.weight(.medium))
                            .foregroundColor(.appAccent)
                            .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.2))
                    .ignoresSafeArea()
                }
            }
            .onAppear {
                // Load entry values
                loadEntryValues()
            }
        }
    }
    
    private func loadEntryValues() {
        // Set values from the entry
        selectedType = LogEntryType(rawValue: entry.type) ?? .task
        description = entry.desc ?? ""
        entryDate = entry.date ?? Date()
        tag = entry.tag ?? ""
        isComplete = entry.isComplete
        selectedClient = entry.client
        
        if let amountValue = entry.amount as NSDecimalNumber? {
            amount = amountValue.doubleValue > 0 ? String(format: "%.2f", amountValue.doubleValue) : ""
        }
    }
    
    private func saveChanges() {
        // Update entry with new values
        entry.type = selectedType.rawValue
        entry.desc = description
        entry.date = entryDate
        entry.tag = tag.isEmpty ? nil : tag
        entry.client = selectedClient
        
        if selectedType == .task {
            entry.isComplete = isComplete
        }
        
        if selectedType == .payment, let amountValue = Decimal(string: amount) {
            entry.amount = NSDecimalNumber(decimal: amountValue)
        } else {
            entry.amount = NSDecimalNumber.zero
        }
        
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

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let entry = LogEntry(context: context)
    entry.id = UUID()
    entry.type = LogEntryType.payment.rawValue
    entry.desc = "Website design project milestone completed"
    entry.date = Date()
    entry.amount = NSDecimalNumber(value: 250.00)
    entry.tag = "Design"
    
    return NavigationStack {
        EntryDetailView(entry: entry)
            .environment(\.managedObjectContext, context)
    }
} 