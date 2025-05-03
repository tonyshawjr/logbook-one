import SwiftUI
import CoreData

struct LogEntryFormView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedType: LogEntryType
    @State private var description: String = ""
    @State private var amount: String = ""
    @State private var tag: String = ""
    @State private var isComplete: Bool = false
    @State private var selectedClient: Client?
    @State private var entryDate: Date = Date()
    @State private var showingSavedAnimation = false
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Client.name, ascending: true)],
        animation: .default)
    private var clients: FetchedResults<Client>
    
    var client: Client?
    
    init(selectedType: LogEntryType = .task, client: Client? = nil) {
        self._selectedType = State(initialValue: selectedType)
        self.client = client
    }
    
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
                        
                        if client == nil {
                            Picker("Client", selection: $selectedClient) {
                                Text("No Client").tag(nil as Client?)
                                ForEach(clients) { client in
                                    Text(client.name ?? "Unnamed Client").tag(client as Client?)
                                }
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
                .navigationTitle(selectedType.displayName + " Entry")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            save()
                        }
                        .disabled(description.isEmpty)
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
                .onAppear {
                    selectedClient = client
                }
                
                // Success Animation Overlay
                if showingSavedAnimation {
                    VStack {
                        ZStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 80, height: 80)
                                .shadow(radius: 5)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .transition(.scale.combined(with: .opacity))
                        
                        Text("Entry Saved")
                            .font(.appHeadline)
                            .foregroundColor(.white)
                            .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.4))
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)
                }
            }
        }
    }
    
    private func save() {
        let entry = LogEntry(context: viewContext)
        entry.id = UUID()
        entry.type = selectedType.rawValue
        entry.desc = description
        entry.tag = tag.isEmpty ? nil : tag
        entry.date = entryDate
        entry.client = selectedClient ?? client
        
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        } catch {
            print("Error saving entry: \(error)")
        }
    }
}

#Preview {
    LogEntryFormView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 
