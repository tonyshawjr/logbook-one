import SwiftUI
import CoreData

struct ClientFormView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var tag: String = ""
    @State private var hourlyRate: String = ""
    @State private var showingSavedAnimation = false
    
    // For auto-focusing the name field
    @FocusState private var isNameFocused: Bool
    
    var client: Client?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with close button
            HStack {
                Text(client == nil ? "Add Client" : "Edit Client")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    ZStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 24)
            
            // Main input form
            VStack(spacing: 16) {
                // Name field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Client Name")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("", text: $name)
                        .placeholder(when: name.isEmpty) {
                            Text("Enter client name")
                                .foregroundColor(.secondary)
                        }
                        .font(.title3)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                        .focused($isNameFocused)
                }
                .padding(.horizontal)
                
                // Tag field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tag (Optional)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("", text: $tag)
                        .placeholder(when: tag.isEmpty) {
                            Text("e.g. Design, Web Development")
                                .foregroundColor(.secondary)
                        }
                        .font(.body)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                
                // Hourly rate field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Hourly Rate (Optional)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("$")
                            .foregroundColor(.secondary)
                            .font(.headline)
                        
                        TextField("0.00", text: $hourlyRate)
                            .keyboardType(.decimalPad)
                            .font(.headline)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Save button
                Button(action: save) {
                    Text("Save Client")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isFormValid ? Color.green : Color.green.opacity(0.5))
                        .cornerRadius(12)
                }
                .disabled(!isFormValid)
                .padding()
            }
        }
        .background(Color(UIColor.systemBackground))
        .overlay {
            if showingSavedAnimation {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                    .overlay {
                        VStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                            
                            Text("Saved!")
                                .font(.title3.weight(.medium))
                                .foregroundColor(.green)
                                .padding(.top, 4)
                        }
                    }
            }
        }
        .onAppear {
            // Auto-focus the name field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isNameFocused = true
            }
            
            // Populate fields if editing an existing client
            if let client = client {
                name = client.name ?? ""
                tag = client.tag ?? ""
                if let rate = client.hourlyRate as NSDecimalNumber?, rate.doubleValue > 0 {
                    hourlyRate = String(format: "%.2f", rate.doubleValue)
                } else {
                    hourlyRate = ""
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        return !name.isEmpty
    }
    
    private func save() {
        let clientToSave = client ?? Client(context: viewContext)
        clientToSave.id = client?.id ?? UUID()
        clientToSave.name = name
        clientToSave.tag = tag.isEmpty ? nil : tag
        
        if let rateValue = Decimal(string: hourlyRate) {
            clientToSave.hourlyRate = NSDecimalNumber(decimal: rateValue)
        } else {
            clientToSave.hourlyRate = NSDecimalNumber.zero
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                dismiss()
            }
        } catch {
            print("Error saving client: \(error)")
        }
    }
}

#Preview {
    ClientFormView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 
