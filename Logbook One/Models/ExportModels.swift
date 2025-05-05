import Foundation
import CoreData

// Data models for export and import
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
    
    // Custom initializer for ImportView to use when parsing imported data
    init(id: String, type: String, date: String, description: String, clientID: String?, 
         isComplete: Bool, amount: Decimal?, tag: String) {
        self.id = id
        self.type = type
        self.date = date
        self.description = description
        self.clientID = clientID
        self.isComplete = isComplete
        self.amount = amount
        self.tag = tag
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
    
    // Custom initializer for ImportView to use when parsing imported data
    init(id: String, name: String, tag: String, hourlyRate: Decimal) {
        self.id = id
        self.name = name
        self.tag = tag
        self.hourlyRate = hourlyRate
    }
} 