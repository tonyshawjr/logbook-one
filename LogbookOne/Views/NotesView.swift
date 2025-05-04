import SwiftUI
import CoreData

struct NotesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingAddNote = false
    @State private var searchText = ""
    @State private var selectedClient: Client? = nil
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \LogEntry.creationDate, ascending: false)],
        predicate: NSPredicate(format: "type == %d", LogEntryType.note.rawValue),
        animation: .default
    ) private var notes: FetchedResults<LogEntry>
    
    // Filtered notes based on search text and client selection
    private var filteredNotes: [LogEntry] {
        if searchText.isEmpty && selectedClient == nil {
            return Array(notes)
        } else {
            return notes.filter { note in
                let matchesSearch = searchText.isEmpty || 
                    (note.desc ?? "").localizedCaseInsensitiveContains(searchText)
                let matchesClient = selectedClient == nil || note.client == selectedClient
                return matchesSearch && matchesClient
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Client filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        Button(action: { selectedClient = nil }) {
                            HStack {
                                Text("All Clients")
                                    .font(.appSubheadline)
                                
                                if selectedClient == nil {
                                    Image(systemName: "checkmark")
                                        .font(.caption)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedClient == nil ? Color.themeAccent.opacity(0.1) : Color.themeCard)
                            .foregroundColor(selectedClient == nil ? .themeAccent : .themePrimary)
                            .cornerRadius(8)
                        }
                        
                        ForEach(clientsWithNotes) { client in
                            Button(action: { selectedClient = client }) {
                                HStack {
                                    Text(client.name ?? "Client")
                                        .font(.appSubheadline)
                                    
                                    if selectedClient == client {
                                        Image(systemName: "checkmark")
                                            .font(.caption)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedClient == client ? Color.themeAccent.opacity(0.1) : Color.themeCard)
                                .foregroundColor(selectedClient == client ? .themeAccent : .themePrimary)
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color.themeBackground)
                
                if filteredNotes.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredNotes) { note in
                                NoteCard(note: note)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .background(Color.themeBackground)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .toolbarBackground(Color.themeBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .searchable(text: $searchText, prompt: "Search notes")
            .background(Color.themeBackground)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.text")
                .font(.system(size: 70))
                .foregroundColor(.themeSecondary.opacity(0.3))
                .padding(.bottom, 10)
                .padding(.top, 60)
            
            Text("No Notes Found")
                .font(.appTitle2)
                .foregroundColor(.themePrimary)
            
            Text(emptyStateMessage)
                .font(.appBody)
                .foregroundColor(.themeSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: { showingAddNote = true }) {
                Text("Add New Note")
                    .font(.appHeadline)
                    .frame(height: 24)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 40)
            .padding(.top, 12)
            
            Spacer()
        }
        .sheet(isPresented: $showingAddNote) {
            QuickAddView(initialEntryType: .note)
                .environment(\.managedObjectContext, viewContext)
        }
    }
    
    private var emptyStateMessage: String {
        if !searchText.isEmpty {
            return "No notes matching \"\(searchText)\" found."
        } else if let client = selectedClient {
            return "No notes for \(client.name ?? "this client") yet."
        } else {
            return "Capture your thoughts, ideas and information here."
        }
    }
    
    private var clientsWithNotes: [Client] {
        let fetchRequest: NSFetchRequest<Client> = Client.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "ANY logEntries.type == %d", LogEntryType.note.rawValue)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Client.name, ascending: true)]
        
        do {
            return try viewContext.fetch(fetchRequest)
        } catch {
            print("Error fetching clients with notes: \(error)")
            return []
        }
    }
}

struct NoteCard: View {
    @ObservedObject var note: LogEntry
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        NavigationLink(destination: EntryDetailView(entry: note)) {
            VStack(alignment: .leading, spacing: 12) {
                // Content and date
                VStack(alignment: .leading, spacing: 8) {
                    Text(note.desc ?? "")
                        .font(.appBody)
                        .foregroundColor(.themePrimary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    HStack {
                        if let client = note.client {
                            Text(client.name ?? "Client")
                                .font(.appCaption)
                                .foregroundColor(.themeNote)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.themeNote.opacity(0.1))
                                .cornerRadius(8)
                        }
                        
                        Spacer()
                        
                        // Date
                        if let date = note.creationDate ?? note.date {
                            Text(dateFormatter.string(from: date))
                                .font(.appCaption)
                                .foregroundColor(.themeSecondary)
                        }
                    }
                }
            }
            .padding()
            .background(Color.themeCard)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NotesView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 