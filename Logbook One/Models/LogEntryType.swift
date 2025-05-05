import Foundation

enum LogEntryType: Int16, CaseIterable, Identifiable {
    case task = 0
    case note = 1
    case payment = 2
    
    var id: Int16 { self.rawValue }
    
    var displayName: String {
        switch self {
        case .task: return "Task"
        case .note: return "Note"
        case .payment: return "Payment"
        }
    }
} 