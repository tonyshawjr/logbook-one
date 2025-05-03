import SwiftUI
import CoreData

struct ClientFormView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var tag: String = ""
    @State private var hourlyRate: String = ""
    
    var client: Client?
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    TextField("Tag", text: $tag)
                    TextField("Hourly Rate", text: $hourlyRate)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle(client == nil ? "New Client" : "Edit Client")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        save()
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
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
            dismiss()
        } catch {
            print("Error saving client: \(error)")
        }
    }
}

#Preview {
    ClientFormView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 
