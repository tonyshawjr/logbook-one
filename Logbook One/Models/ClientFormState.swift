import SwiftUI

/// A global state object to coordinate client form presentation across the app
class ClientFormState: ObservableObject {
    @Published var showingAddClient: Bool = false
    
    func showClientForm() {
        showingAddClient = true
    }
    
    func hideClientForm() {
        showingAddClient = false
    }
} 