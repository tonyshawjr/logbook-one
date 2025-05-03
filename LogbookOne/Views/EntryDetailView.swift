import SwiftUI
import CoreData

struct EntryDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var entry: LogEntry
    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false
    
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
            // In the future, implement edit functionality
            Text("Edit functionality coming soon")
        }
        .alert("Delete Entry", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteEntry()
            }
        } message: {
            Text("Are you sure you want to delete this entry? This action cannot be undone.")
        }
    }
    
    private var entryHeader: some View {
        HStack {
            EntryTypeBadge(type: LogEntryType(rawValue: entry.type) ?? .task)
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
                        .font(.system(.title2, design: .rounded).weight(.bold))
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