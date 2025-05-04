import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct ExportView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var startDate: Date = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    @State private var endDate: Date = Date()
    @State private var selectedClient: Client?
    @State private var selectedType: LogEntryType?
    @State private var exportURL: URL?
    @State private var showingShareSheet = false
    @State private var isGenerating = false
    @State private var entriesFound = 0
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Client.name, ascending: true)],
        animation: .default)
    private var clients: FetchedResults<Client>
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 60))
                        .foregroundColor(.accentColor)
                        .padding(.bottom, 10)
                    
                    Text("Export Log Entries")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Generate a CSV file of your log entries filtered by date, client, and type.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 20)
                
                // Filters
                VStack(spacing: 16) {
                    filterSection
                    
                    generateButton
                    
                    if let url = exportURL {
                        shareSection(url: url)
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Export Data")
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
    }
    
    private var filterSection: some View {
        VStack(spacing: 20) {
            // Date Range
            GroupBox(label: Label("Date Range", systemImage: "calendar")) {
                VStack(spacing: 16) {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }
                .padding(.vertical, 10)
            }
            
            // Client Filter
            GroupBox(label: Label("Client", systemImage: "person")) {
                Picker("Select Client", selection: $selectedClient) {
                    Text("All Clients").tag(nil as Client?)
                    ForEach(clients) { client in
                        Text(client.name ?? "Unnamed Client").tag(client as Client?)
                    }
                }
                .pickerStyle(.menu)
                .padding(.vertical, 10)
            }
            
            // Type Filter
            GroupBox(label: Label("Entry Type", systemImage: "tag")) {
                Picker("Select Type", selection: $selectedType) {
                    Text("All Types").tag(nil as LogEntryType?)
                    ForEach(LogEntryType.allCases) { type in
                        Text(type.displayName).tag(type as LogEntryType?)
                    }
                }
                .pickerStyle(.menu)
                .padding(.vertical, 10)
            }
        }
    }
    
    private var generateButton: some View {
        Button(action: {
            isGenerating = true
            generateCSV()
        }) {
            HStack {
                if isGenerating {
                    ProgressView()
                        .padding(.trailing, 5)
                }
                
                Text(isGenerating ? "Generating..." : "Generate CSV")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .disabled(isGenerating)
        .frame(height: 55)
    }
    
    private func shareSection(url: URL) -> some View {
        VStack(spacing: 10) {
            Divider()
                .padding(.vertical, 10)
            
            Text("Found \(entriesFound) log \(entriesFound == 1 ? "entry" : "entries")")
                .font(.headline)
            
            Text("Your export file is ready")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: { showingShareSheet = true }) {
                Label("Share CSV File", systemImage: "square.and.arrow.up")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
            }
            .frame(height: 55)
        }
    }
    
    private func generateCSV() {
        let fetchRequest: NSFetchRequest<LogEntry> = LogEntry.fetchRequest()
        
        var predicates: [NSPredicate] = []
        predicates.append(NSPredicate(format: "date >= %@", startDate as NSDate))
        predicates.append(NSPredicate(format: "date <= %@", endDate as NSDate))
        
        if let client = selectedClient {
            predicates.append(NSPredicate(format: "client == %@", client))
        }
        
        if let type = selectedType {
            predicates.append(NSPredicate(format: "type == %d", type.rawValue))
        }
        
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \LogEntry.date, ascending: true)]
        
        do {
            let entries = try viewContext.fetch(fetchRequest)
            entriesFound = entries.count
            let csvString = generateCSVString(from: entries)
            
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = "logbook_export_\(Date().timeIntervalSince1970).csv"
            let fileURL = tempDir.appendingPathComponent(fileName)
            
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            exportURL = fileURL
            isGenerating = false
        } catch {
            print("Error generating CSV: \(error)")
            isGenerating = false
        }
    }
    
    private func generateCSVString(from entries: [LogEntry]) -> String {
        var csvString = "Date,Client,Type,Description,Amount,Tag\n"
        
        for entry in entries {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            
            let dateString: String
            if let date = entry.date {
                dateString = dateFormatter.string(from: date)
            } else {
                dateString = "No Date"
            }
            
            let client = entry.client?.name ?? "No Client"
            let type = LogEntryType(rawValue: entry.type)?.displayName ?? "Unknown"
            let description = entry.desc?.replacingOccurrences(of: ",", with: ";") ?? ""
            
            let amount: String
            if entry.type == LogEntryType.payment.rawValue, 
               let decimalAmount = entry.amount as NSDecimalNumber? {
                amount = String(format: "%.2f", decimalAmount.doubleValue)
            } else {
                amount = ""
            }
            
            let tag = entry.tag?.replacingOccurrences(of: ",", with: ";") ?? ""
            
            csvString += "\(dateString),\(client),\(type),\(description),\(amount),\(tag)\n"
        }
        
        return csvString
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        ExportView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
} 