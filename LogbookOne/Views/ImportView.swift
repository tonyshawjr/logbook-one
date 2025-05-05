import SwiftUI
import CoreData
import UniformTypeIdentifiers
// Import the shared models
import Foundation

struct ImportView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var isImporting = false
    @State private var showingFileImporter = false
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var importFormat = ImportFormat.csv
    @State private var importSummary: ImportSummary?
    
    enum ImportFormat: String, CaseIterable, Identifiable {
        case csv = "CSV"
        case json = "JSON"
        
        var id: String { self.rawValue }
        
        var fileExtension: String {
            switch self {
            case .csv: return "csv"
            case .json: return "json"
            }
        }
        
        var utTypes: [UTType] {
            switch self {
            case .csv: return [UTType.commaSeparatedText]
            case .json: return [UTType.json]
            }
        }
    }
    
    struct ImportSummary {
        let totalEntries: Int
        let importedEntries: Int
        let skippedEntries: Int
        let totalClients: Int
        let importedClients: Int
        let skippedClients: Int
    }
    
    var body: some View {
        List {
            Section(header: Text("Import Format")) {
                Picker("Format", selection: $importFormat) {
                    ForEach(ImportFormat.allCases) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 8)
            }
            
            Section(header: Text("Import Method")) {
                Text("Select a \(importFormat.rawValue) file containing Logbook One data. Only properly formatted files exported from Logbook One can be imported.")
                    .font(.appBody)
                    .foregroundColor(.themeSecondary)
                    .padding(.vertical, 8)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Note:")
                        .font(.appHeadline)
                        .foregroundColor(.themeAccent)
                    
                    Text("• Entries and clients with the same ID will be skipped to prevent duplicates")
                        .font(.appCaption)
                        .foregroundColor(.themeSecondary)
                    
                    Text("• You cannot import entries for clients that don't exist")
                        .font(.appCaption)
                        .foregroundColor(.themeSecondary)
                }
                .padding(.vertical, 8)
            }
            
            Section {
                Button(action: { showingFileImporter = true }) {
                    HStack {
                        Spacer()
                        if isImporting {
                            ProgressView()
                                .padding(.trailing, 10)
                        }
                        Text("Select \(importFormat.rawValue) File")
                            .font(.appHeadline)
                        Spacer()
                    }
                    .frame(height: 44)
                }
                .disabled(isImporting)
                .buttonStyle(.borderedProminent)
                .tint(.themeAccent)
                .listRowInsets(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
            }
            
            if let summary = importSummary {
                Section(header: Text("Import Summary")) {
                    VStack(alignment: .leading, spacing: 16) {
                        Group {
                            Text("Entries:")
                                .font(.appSubheadline.bold())
                                .foregroundColor(.themePrimary)
                            
                            HStack {
                                Text("• Imported:")
                                    .foregroundColor(.themeSecondary)
                                Spacer()
                                Text("\(summary.importedEntries) of \(summary.totalEntries)")
                                    .foregroundColor(.themeAccent)
                            }
                            
                            HStack {
                                Text("• Skipped (duplicates):")
                                    .foregroundColor(.themeSecondary)
                                Spacer()
                                Text("\(summary.skippedEntries)")
                                    .foregroundColor(.themeSecondary)
                            }
                        }
                        
                        Divider()
                        
                        Group {
                            Text("Clients:")
                                .font(.appSubheadline.bold())
                                .foregroundColor(.themePrimary)
                            
                            HStack {
                                Text("• Imported:")
                                    .foregroundColor(.themeSecondary)
                                Spacer()
                                Text("\(summary.importedClients) of \(summary.totalClients)")
                                    .foregroundColor(.themeAccent)
                            }
                            
                            HStack {
                                Text("• Skipped (duplicates):")
                                    .foregroundColor(.themeSecondary)
                                Spacer()
                                Text("\(summary.skippedClients)")
                                    .foregroundColor(.themeSecondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Import Data")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: importFormat.utTypes,
            allowsMultipleSelection: false
        ) { result in
            importFile(result)
        }
        .alert("Import Successful", isPresented: $showingSuccessAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your data has been imported successfully.")
        }
        .alert("Import Failed", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // Handle importing a file
    private func importFile(_ result: Result<[URL], Error>) {
        do {
            // Get the file URL from the result
            guard let selectedFile = try result.get().first else {
                throw ImportError.noFileSelected
            }
            
            // Start the import process
            isImporting = true
            
            // Verify the file can be accessed and get security-scoped access
            guard selectedFile.startAccessingSecurityScopedResource() else {
                throw ImportError.accessDenied
            }
            
            defer {
                selectedFile.stopAccessingSecurityScopedResource()
            }
            
            // Perform import on background thread to avoid UI freezes
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    // Read the file data
                    let data = try Data(contentsOf: selectedFile)
                    
                    // Parse and import data based on the file format
                    let summary = try processImportData(data, format: importFormat)
                    
                    // Return to main thread to update UI
                    DispatchQueue.main.async {
                        self.isImporting = false
                        self.importSummary = summary
                        self.showingSuccessAlert = true
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.isImporting = false
                        self.errorMessage = error.localizedDescription
                        self.showingErrorAlert = true
                    }
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            showingErrorAlert = true
        }
    }
    
    // Process the import data
    private func processImportData(_ data: Data, format: ImportFormat) throws -> ImportSummary {
        // Parse the data into our import structure
        let importData: ExportData
        
        switch format {
        case .json:
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            importData = try decoder.decode(ExportData.self, from: data)
            
        case .csv:
            importData = try parseCSV(data)
        }
        
        // Import the data into Core Data
        return try importIntoDatabase(importData)
    }
    
    // Parse CSV data
    private func parseCSV(_ data: Data) throws -> ExportData {
        // Convert data to string
        guard let csvString = String(data: data, encoding: .utf8) else {
            throw ImportError.invalidCSVFormat
        }
        
        // Split into lines
        let lines = csvString.components(separatedBy: .newlines)
        
        // Validate that this is a Logbook One export
        guard lines.count > 0, lines[0].trimmingCharacters(in: .whitespacesAndNewlines) == "Logbook One Export" else {
            throw ImportError.notLogbookExport
        }
        
        var exportDate = Date()
        if lines.count > 1, lines[1].starts(with: "Export Date,") {
            let dateString = lines[1].replacingOccurrences(of: "Export Date,", with: "")
            if let date = ISO8601DateFormatter().date(from: dateString) {
                exportDate = date
            }
        }
        
        // Find client and entry sections
        var clientStartIndex: Int?
        var clientHeaderIndex: Int?
        var entryStartIndex: Int?
        var entryHeaderIndex: Int?
        
        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine == "CLIENTS" {
                clientStartIndex = index
            } else if clientStartIndex != nil && clientHeaderIndex == nil && trimmedLine.starts(with: "ID,") {
                clientHeaderIndex = index
            } else if trimmedLine == "ENTRIES" {
                entryStartIndex = index
            } else if entryStartIndex != nil && entryHeaderIndex == nil && trimmedLine.starts(with: "ID,") {
                entryHeaderIndex = index
            }
        }
        
        // Validate that we found all the required sections
        guard let _ = clientStartIndex, let clientHeaderIndex = clientHeaderIndex,
              let entryStartIndex = entryStartIndex, let entryHeaderIndex = entryHeaderIndex else {
            throw ImportError.invalidCSVFormat
        }
        
        // Parse clients
        var clients = [ExportClient]()
        for i in (clientHeaderIndex + 1)..<entryStartIndex {
            if i >= lines.count {
                break
            }
            
            let line = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty {
                continue
            }
            
            let fields = parseCSVLine(line)
            if fields.count >= 4 {
                let client = ExportClient(
                    id: fields[0],
                    name: fields[1],
                    tag: fields[2],
                    hourlyRate: Decimal(string: fields[3]) ?? 0
                )
                clients.append(client)
            }
        }
        
        // Parse entries
        var entries = [ExportEntry]()
        for i in (entryHeaderIndex + 1)..<lines.count {
            if i >= lines.count {
                break
            }
            
            let line = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty {
                continue
            }
            
            let fields = parseCSVLine(line)
            if fields.count >= 8 {
                let entry = ExportEntry(
                    id: fields[0],
                    type: fields[1],
                    date: fields[2],
                    description: fields[3],
                    clientID: fields[4].isEmpty ? nil : fields[4],
                    isComplete: fields[5].lowercased() == "true",
                    amount: Decimal(string: fields[6]),
                    tag: fields[7]
                )
                entries.append(entry)
            }
        }
        
        return ExportData(
            exportDate: exportDate,
            entries: entries,
            clients: clients
        )
    }
    
    // Parse a CSV line taking into account quoted fields
    private func parseCSVLine(_ line: String) -> [String] {
        var fields = [String]()
        var currentField = ""
        var insideQuotes = false
        
        for character in line {
            if character == "\"" {
                if insideQuotes && line.hasPrefix("\"\"", after: line.distance(from: line.startIndex, to: line.firstIndex(of: character)!)) {
                    // Double quote inside quoted field - add a single quote
                    currentField.append("\"")
                } else {
                    // Toggle quote state
                    insideQuotes.toggle()
                }
            } else if character == "," && !insideQuotes {
                // End of field
                fields.append(currentField)
                currentField = ""
            } else {
                // Regular character
                currentField.append(character)
            }
        }
        
        // Add the last field
        fields.append(currentField)
        
        return fields
    }
    
    // Import the parsed data into Core Data
    private func importIntoDatabase(_ importData: ExportData) throws -> ImportSummary {
        // Get existing clients and entries by ID for duplicate checking
        let existingClientsFetch = NSFetchRequest<Client>(entityName: "Client")
        let existingClients = try viewContext.fetch(existingClientsFetch)
        var existingClientIDs = Set<String>()
        
        for client in existingClients {
            if let id = client.id?.uuidString {
                existingClientIDs.insert(id)
            }
        }
        
        let existingEntriesFetch = NSFetchRequest<LogEntry>(entityName: "LogEntry")
        let existingEntries = try viewContext.fetch(existingEntriesFetch)
        var existingEntryIDs = Set<String>()
        
        for entry in existingEntries {
            if let id = entry.id?.uuidString {
                existingEntryIDs.insert(id)
            }
        }
        
        // Import clients first
        var importedClientsCount = 0
        var importedClientsByID = [String: Client]()
        
        for importClient in importData.clients {
            // Skip if this client already exists
            if existingClientIDs.contains(importClient.id) {
                continue
            }
            
            // Create new client
            let client = Client(context: viewContext)
            client.id = UUID(uuidString: importClient.id)
            client.name = importClient.name
            client.tag = importClient.tag
            client.hourlyRate = NSDecimalNumber(decimal: importClient.hourlyRate)
            
            // Save reference for linking entries
            importedClientsByID[importClient.id] = client
            importedClientsCount += 1
        }
        
        // Now combine existing and newly imported clients for entry association
        for client in existingClients {
            if let id = client.id?.uuidString {
                importedClientsByID[id] = client
            }
        }
        
        // Import entries
        var importedEntriesCount = 0
        let dateFormatter = ISO8601DateFormatter()
        
        for importEntry in importData.entries {
            // Skip if this entry already exists
            if existingEntryIDs.contains(importEntry.id) {
                continue
            }
            
            // Create new entry
            let entry = LogEntry(context: viewContext)
            entry.id = UUID(uuidString: importEntry.id)
            
            // Convert type string back to type ID
            var typeID: Int16 = 0 // Default to task
            if importEntry.type == LogEntryType.task.displayName {
                typeID = LogEntryType.task.rawValue
            } else if importEntry.type == LogEntryType.note.displayName {
                typeID = LogEntryType.note.rawValue
            } else if importEntry.type == LogEntryType.payment.displayName {
                typeID = LogEntryType.payment.rawValue
            }
            entry.type = typeID
            
            // Parse date
            if !importEntry.date.isEmpty {
                entry.date = dateFormatter.date(from: importEntry.date)
            }
            
            // Set actual creation date
            entry.setValue(Date(), forKey: "creationDate")
            
            entry.desc = importEntry.description
            entry.isComplete = importEntry.isComplete
            
            if let amount = importEntry.amount {
                entry.amount = NSDecimalNumber(decimal: amount)
            }
            
            entry.tag = importEntry.tag
            
            // Link to client if possible
            if let clientID = importEntry.clientID, let client = importedClientsByID[clientID] {
                entry.client = client
            }
            
            importedEntriesCount += 1
        }
        
        // Save the context if changes were made
        if importedClientsCount > 0 || importedEntriesCount > 0 {
            try viewContext.save()
        }
        
        // Return import summary
        return ImportSummary(
            totalEntries: importData.entries.count,
            importedEntries: importedEntriesCount,
            skippedEntries: importData.entries.count - importedEntriesCount,
            totalClients: importData.clients.count,
            importedClients: importedClientsCount,
            skippedClients: importData.clients.count - importedClientsCount
        )
    }
}

// Custom error types for import operations
enum ImportError: Error, LocalizedError {
    case noFileSelected
    case accessDenied
    case invalidCSVFormat
    case invalidJSONFormat
    case notLogbookExport
    
    var errorDescription: String? {
        switch self {
        case .noFileSelected:
            return "No file was selected for import."
        case .accessDenied:
            return "Unable to access the selected file."
        case .invalidCSVFormat:
            return "The CSV file is not in the correct format."
        case .invalidJSONFormat:
            return "The JSON file is not in the correct format."
        case .notLogbookExport:
            return "The file does not appear to be a Logbook One export."
        }
    }
}

// Extension for String to check if it has a prefix after a certain point
extension String {
    func hasPrefix(_ prefix: String, after index: Int) -> Bool {
        guard index < count, prefix.count <= count - index else {
            return false
        }
        
        let startIndex = self.index(self.startIndex, offsetBy: index)
        let endIndex = self.index(startIndex, offsetBy: prefix.count)
        return String(self[startIndex..<endIndex]) == prefix
    }
}

#Preview {
    NavigationStack {
        ImportView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
} 