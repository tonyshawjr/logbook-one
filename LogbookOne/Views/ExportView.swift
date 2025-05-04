import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct ExportView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var exportFormat = ExportFormat.csv
    @State private var isExporting = false
    @State private var exportedData: Data?
    @State private var showingShareSheet = false
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    enum ExportFormat: String, CaseIterable, Identifiable {
        case csv = "CSV"
        case json = "JSON"
        
        var id: String { self.rawValue }
        
        var fileExtension: String {
            switch self {
            case .csv: return "csv"
            case .json: return "json"
            }
        }
        
        var mimeType: String {
            switch self {
            case .csv: return "text/csv"
            case .json: return "application/json"
            }
        }
        
        var utType: UTType {
            switch self {
            case .csv: return UTType.commaSeparatedText
            case .json: return UTType.json
            }
        }
    }
    
    var body: some View {
        List {
            Section(header: Text("Export Format")) {
                Picker("Format", selection: $exportFormat) {
                    ForEach(ExportFormat.allCases) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 8)
            }
            
            Section(header: Text("Data to Export")) {
                Toggle("Tasks", isOn: .constant(true))
                    .disabled(true) // Always export tasks
                
                Toggle("Notes", isOn: .constant(true))
                    .disabled(true) // Always export notes
                
                Toggle("Payments", isOn: .constant(true))
                    .disabled(true) // Always export payments
                
                Toggle("Clients", isOn: .constant(true))
                    .disabled(true) // Always export clients
            }
            
            Section {
                Button(action: exportData) {
                    HStack {
                        Spacer()
                        if isExporting {
                            ProgressView()
                                .padding(.trailing, 10)
                        }
                        Text("Export Data")
                            .font(.appHeadline)
                        Spacer()
                    }
                    .frame(height: 44)
                }
                .disabled(isExporting)
                .buttonStyle(.borderedProminent)
                .tint(.themeAccent)
                .listRowInsets(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
            }
        }
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingShareSheet) {
            if let data = exportedData {
                ShareSheet(items: [data], 
                          fileName: "logbook_export.\(exportFormat.fileExtension)",
                          contentType: exportFormat.utType)
            }
        }
        .alert("Export Successful", isPresented: $showingSuccessAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your data has been exported successfully.")
        }
        .alert("Export Failed", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func exportData() {
        isExporting = true
        
        // Perform export on background thread to avoid UI freezes
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let data = try generateExportData()
                
                // Return to main thread to update UI
                DispatchQueue.main.async {
                    self.exportedData = data
                    self.isExporting = false
                    self.showingShareSheet = true
                }
            } catch {
                DispatchQueue.main.async {
                    self.isExporting = false
                    self.errorMessage = error.localizedDescription
                    self.showingErrorAlert = true
                }
            }
        }
    }
    
    private func generateExportData() throws -> Data {
        // Get all entries
        let entriesFetch = NSFetchRequest<LogEntry>(entityName: "LogEntry")
        let entries = try viewContext.fetch(entriesFetch)
        
        // Get all clients
        let clientsFetch = NSFetchRequest<Client>(entityName: "Client")
        let clients = try viewContext.fetch(clientsFetch)
        
        // Create export structure
        let exportData = ExportData(
            exportDate: Date(),
            entries: entries.map { ExportEntry(from: $0) },
            clients: clients.map { ExportClient(from: $0) }
        )
        
        // Format based on selected format
        switch exportFormat {
        case .json:
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            return try encoder.encode(exportData)
            
        case .csv:
            return try generateCSV(exportData)
        }
    }
    
    private func generateCSV(_ data: ExportData) throws -> Data {
        var csvString = ""
        
        // Add metadata
        csvString += "Logbook One Export\n"
        csvString += "Export Date,\(ISO8601DateFormatter().string(from: data.exportDate))\n\n"
        
        // Add clients section
        csvString += "CLIENTS\n"
        csvString += "ID,Name,Tag,Hourly Rate\n"
        
        for client in data.clients {
            csvString += "\(client.id),\(escapeCSV(client.name)),\(escapeCSV(client.tag)),\(client.hourlyRate)\n"
        }
        
        csvString += "\n"
        
        // Add entries section
        csvString += "ENTRIES\n"
        csvString += "ID,Type,Date,Description,Client ID,Is Complete,Amount,Tag\n"
        
        for entry in data.entries {
            csvString += "\(entry.id),\(entry.type),\(entry.date),"
            csvString += "\(escapeCSV(entry.description)),\(entry.clientID ?? ""),"
            csvString += "\(entry.isComplete),\(entry.amount ?? 0),"
            csvString += "\(escapeCSV(entry.tag))\n"
        }
        
        return csvString.data(using: .utf8) ?? Data()
    }
    
    private func escapeCSV(_ string: String?) -> String {
        guard let string = string else { return "" }
        let containsComma = string.contains(",")
        let containsQuote = string.contains("\"")
        let containsNewline = string.contains("\n")
        
        if containsComma || containsQuote || containsNewline {
            // Replace quotes with double quotes and wrap in quotes
            return "\"" + string.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        
        return string
    }
}

// Data models for export

struct ExportData: Codable {
    let exportDate: Date
    let entries: [ExportEntry]
    let clients: [ExportClient]
}

struct ExportEntry: Codable {
    let id: String
    let type: String
    let date: String
    let description: String
    let clientID: String?
    let isComplete: Bool
    let amount: Decimal?
    let tag: String
    
    init(from entry: LogEntry) {
        self.id = entry.id?.uuidString ?? ""
        
        // Convert Int16 type to a readable string using LogEntryType's displayName
        let typeValue = entry.type
        if let entryType = LogEntryType(rawValue: typeValue) {
            self.type = entryType.displayName
        } else {
            self.type = "Unknown"
        }
        
        let dateFormatter = ISO8601DateFormatter()
        self.date = entry.date != nil ? dateFormatter.string(from: entry.date!) : ""
        
        self.description = entry.desc ?? ""
        self.clientID = entry.client?.id?.uuidString
        self.isComplete = entry.isComplete
        self.amount = entry.amount as Decimal?
        self.tag = entry.tag ?? ""
    }
}

struct ExportClient: Codable {
    let id: String
    let name: String
    let tag: String
    let hourlyRate: Decimal
    
    init(from client: Client) {
        self.id = client.id?.uuidString ?? ""
        self.name = client.name ?? ""
        self.tag = client.tag ?? ""
        self.hourlyRate = client.hourlyRate as Decimal? ?? 0
    }
}

// Share sheet to present platform share UI
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    let fileName: String
    let contentType: UTType
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        // Create a temporary URL for the file
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        // Write the data to the file
        if let data = items.first as? Data {
            try? data.write(to: fileURL)
            
            // Create an activity view controller with the file URL
            let activityVC = UIActivityViewController(
                activityItems: [fileURL],
                applicationActivities: nil
            )
            
            // Configure excluded activity types if needed
            activityVC.excludedActivityTypes = [
                .assignToContact,
                .addToReadingList
            ]
            
            return activityVC
        } else {
            // Fallback to just sharing the items directly
            let activityVC = UIActivityViewController(
                activityItems: items,
                applicationActivities: nil
            )
            return activityVC
        }
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // Nothing to update
    }
}

#Preview {
    NavigationStack {
        ExportView()
    }
} 