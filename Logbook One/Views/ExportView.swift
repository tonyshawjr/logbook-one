import SwiftUI
import CoreData
import UniformTypeIdentifiers
// Import the shared models
import Foundation

struct ExportView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    // UI state
    @State private var isExporting = false
    @State private var showingShareSheet = false
    @State private var showingErrorAlert = false
    @State private var showingClientRequiredAlert = false
    @State private var errorMessage = ""
    @State private var exportFormat = ExportFormat.csv
    @State private var exportedData: Data?
    
    // Export data selection state
    @State private var exportTasks = true
    @State private var exportNotes = true
    @State private var exportPayments = true
    @State private var exportClients = true
    
    // Export format enum
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
        
        var contentType: UTType {
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
                Toggle("Tasks", isOn: $exportTasks)
                
                Toggle("Notes", isOn: $exportNotes)
                
                Toggle("Payments", isOn: $exportPayments)
                
                Toggle("Clients", isOn: $exportClients)
                    .onChange(of: exportClients) { _, newValue in
                        // If clients are needed for entries, prevent disabling
                        if !newValue && (exportTasks || exportNotes || exportPayments) {
                            exportClients = true
                            showingClientRequiredAlert = true
                        }
                    }
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
                .disabled(isExporting || !(exportTasks || exportNotes || exportPayments || exportClients))
                .buttonStyle(.borderedProminent)
                .tint(.themeAccent)
                .listRowInsets(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
            }
        }
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingShareSheet) {
            if let data = exportedData {
                ShareSheet(
                    items: [data],
                    fileName: "logbook_export.\(exportFormat.fileExtension)",
                    contentType: exportFormat.contentType
                )
            }
        }
        .alert("Export Failed", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert("Client Data Required", isPresented: $showingClientRequiredAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Client data must be included when exporting tasks, notes, or payments to maintain relationships between entries and clients.")
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
        // Get entries based on selection
        let entriesFetch = NSFetchRequest<LogEntry>(entityName: "LogEntry")
        
        // Filter by selected entry types if not all types are selected
        if !(exportTasks && exportNotes && exportPayments) {
            var typesToExport: [Int16] = []
            if exportTasks { typesToExport.append(LogEntryType.task.rawValue) }
            if exportNotes { typesToExport.append(LogEntryType.note.rawValue) }
            if exportPayments { typesToExport.append(LogEntryType.payment.rawValue) }
            
            entriesFetch.predicate = NSPredicate(format: "type IN %@", typesToExport)
        }
        
        let entries = try viewContext.fetch(entriesFetch)
        
        // Get clients if selected
        var clients: [Client] = []
        if exportClients {
            let clientsFetch = NSFetchRequest<Client>(entityName: "Client")
            clients = try viewContext.fetch(clientsFetch)
        }
        
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