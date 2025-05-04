import SwiftUI
import CoreData

struct ClientListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingAddClient = false
    @State private var searchText = ""
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Client.name, ascending: true)],
        animation: .default)
    private var clients: FetchedResults<Client>
    
    var filteredClients: [Client] {
        if searchText.isEmpty {
            return Array(clients)
        } else {
            return clients.filter { client in
                (client.name ?? "").localizedCaseInsensitiveContains(searchText) ||
                (client.tag ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        ScrollView {
            if clients.isEmpty {
                emptyStateView
            } else {
                clientsList
            }
        }
        .background(Color.themeBackground)
        .searchable(text: $searchText, prompt: "Search clients")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .toolbarBackground(Color.themeBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $showingAddClient) {
            ClientFormView()
        }
    }
    
    private var emptyStateView: some View {
        EmptyStateView(
            systemImage: "person.3",
            title: "No Clients Yet",
            message: "Add your first client to start tracking your work",
            buttonText: "Add Your First Client",
            action: { showingAddClient = true }
        )
    }
    
    private var clientsList: some View {
        VStack(spacing: 16) {
            ForEach(filteredClients) { client in
                NavigationLink(destination: ClientDetailView(client: client)) {
                    ClientCardView(client: client)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            Spacer()
                .frame(height: 20)
        }
    }
}

struct ClientCardView: View {
    let client: Client
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Client avatar
            ZStack {
                Circle()
                    .fill(Color.themeAccent.opacity(0.12))
                    .frame(width: 50, height: 50)
                
                Text(clientInitials)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundColor(Color.themeAccent)
            }
            
            // Client info
            VStack(alignment: .leading, spacing: 4) {
                Text(client.name ?? "Unnamed Client")
                    .font(.appHeadline)
                    .foregroundColor(.themePrimary)
                
                if let tag = client.tag, !tag.isEmpty {
                    Text(tag)
                        .font(.appSubheadline)
                        .foregroundColor(.themeSecondary)
                }
                
                if let rate = client.hourlyRate as NSDecimalNumber?, rate.doubleValue > 0 {
                    let rateValue = rate.doubleValue
                    Text("$\(rateValue, specifier: "%.2f")/hour")
                        .font(.appSubheadline)
                        .foregroundColor(.themePayment)
                        .padding(.top, 2)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding()
        .background(Color.themeCard)
        .cornerRadius(16)
    }
    
    private var clientInitials: String {
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
}

#Preview {
    NavigationStack {
        ClientListView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
} 