import SwiftUI
import CoreData

struct NotesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingAddNote = false
    @State private var searchText = ""
    @State private var selectedTag: String? = "#all"
    @State private var selectedClient: Client?
    @State private var showingClientPicker = false
    
    // Base fetch request for all notes
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \LogEntry.creationDate, ascending: false)],
        predicate: NSPredicate(format: "type == %d", LogEntryType.note.rawValue),
        animation: .default
    ) private var notes: FetchedResults<LogEntry>
    
    // Clients that have notes
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
    
    // Filtered notes based on search text, tag selection, and client selection
    private var filteredNotes: [LogEntry] {
        // Start with all notes and apply filters
        return notes.filter { note in
            // Search text filter
            let matchesSearch = searchText.isEmpty || 
                (note.desc ?? "").localizedCaseInsensitiveContains(searchText)
            
            // Tag filter
            let matchesTag = selectedTag == "#all" || selectedTag == nil || 
                (note.desc?.localizedCaseInsensitiveContains(selectedTag ?? "") ?? false)
            
            // Client filter
            let matchesClient = selectedClient == nil || note.client == selectedClient
            
            // Return true only if all filters match
            return matchesSearch && matchesTag && matchesClient
        }
    }
    
    // Group notes by date for timeline view
    private var groupedNotes: [(String, [LogEntry])] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        let grouped = Dictionary(grouping: filteredNotes) { note -> String in
            guard let date = note.date else { return "Undated" }
            
            let noteDate = calendar.startOfDay(for: date)
            
            if calendar.isDate(noteDate, inSameDayAs: today) {
                return "Today"
            } else if calendar.isDate(noteDate, inSameDayAs: yesterday) {
                return "Yesterday"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM d"
                return formatter.string(from: date)
            }
        }
        
        // Sort sections by date, with Today and Yesterday first
        return grouped.sorted { section1, section2 in
            if section1.key == "Today" { return true }
            if section2.key == "Today" { return false }
            if section1.key == "Yesterday" { return true }
            if section2.key == "Yesterday" { return false }
            return section1.key > section2.key
        }
    }
    
    // Get all unique hashtags from the currently visible notes (filtered by client if applicable)
    private var allHashtags: [String] {
        var tags = ["#all"]
        
        // Notes source for extracting hashtags - filter by client if one is selected
        let noteSource: [LogEntry]
        if let selectedClient = selectedClient {
            // Only use notes from selected client
            noteSource = Array(notes.filter { note in
                note.client == selectedClient
            })
        } else {
            // Use all notes if no client is selected
            noteSource = Array(notes)
        }
        
        // Extract hashtags only from the filtered notes
        tags.append(contentsOf: HashtagExtractor.uniqueHashtags(from: noteSource))
        return tags
    }
    
    var body: some View {
        ZStack {
            NavigationStack {
                VStack(spacing: 0) {
                    // Header with title and client filter
                    NotesHeaderView(
                        selectedClient: $selectedClient,
                        clientsWithNotes: clientsWithNotes,
                        showingClientPicker: $showingClientPicker
                    )
                    
                    // Hashtag filter
                    HashtagFilterView(allHashtags: allHashtags, selectedTag: $selectedTag)
                    
                    if filteredNotes.isEmpty {
                        emptyStateView
                    } else {
                        // Timeline notes view
                        TimelineNotesView(
                            groupedNotes: groupedNotes
                        )
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(.hidden, for: .navigationBar)
                .toolbarBackground(Color.themeBackground, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .searchable(text: $searchText, prompt: "Search notes")
                .background(Color.themeBackground)
            } // Notes tab
        }
        // Use fullScreenCover for client picker
        .fullScreenCover(isPresented: $showingClientPicker) {
            NotesClientPickerView(selectedClient: $selectedClient)
                .presentationDetents([.medium, .large])
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
    }
    
    private var emptyStateMessage: String {
        if !searchText.isEmpty {
            return "No notes matching \"\(searchText)\" found."
        } else if selectedTag != "#all" && selectedTag != nil {
            return "No notes with \(selectedTag ?? "") tag yet."
        } else if selectedClient != nil {
            return "No notes for \(selectedClient?.name ?? "selected client") yet."
        } else {
            return "Capture your thoughts, ideas and information here."
        }
    }
}

// MARK: - Notes Header View
struct NotesHeaderView: View {
    @Binding var selectedClient: Client?
    let clientsWithNotes: [Client]
    @Binding var showingClientPicker: Bool
    
    var body: some View {
        HStack {
            // Title - simple "Notes" with styling matching Settings
            Text("Notes")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.themePrimary)
            
            Spacer()
            
            // Client filter button
            Button(action: { 
                // Explicitly set to true and print for debugging
                showingClientPicker = true
                print("Client picker button tapped, showingClientPicker: \(showingClientPicker)")
            }) {
                HStack {
                    Text(selectedClient?.name ?? "All Clients")
                        .foregroundColor(.themePrimary)
                        .font(.subheadline)
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(UIColor.secondarySystemBackground))
                )
            }
        }
        .padding(.horizontal)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .background(Color.themeBackground)
    }
}

// MARK: - Client Picker View for Notes
struct NotesClientPickerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedClient: Client?
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Client.name, ascending: true)],
        animation: .default)
    private var clients: FetchedResults<Client>
    
    var body: some View {
        NavigationStack {
            List {
                Button(action: {
                    selectedClient = nil
                    dismiss()
                }) {
                    HStack {
                        Text("All Clients")
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if selectedClient == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.themeAccent)
                        }
                    }
                }
                
                ForEach(clients) { client in
                    Button(action: {
                        selectedClient = client
                        dismiss()
                    }) {
                        HStack {
                            Text(client.name ?? "Unnamed Client")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if selectedClient == client {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.themeAccent)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.themeAccent)
                }
            }
        }
    }
}

// MARK: - Hashtag Filter View
struct HashtagFilterView: View {
    let allHashtags: [String]
    @Binding var selectedTag: String?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(allHashtags, id: \.self) { tag in
                    Button(action: { selectedTag = tag }) {
                        Text(tag)
                            .font(.appSubheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedTag == tag ? Color.themeAccent : Color.themeCard)
                            .foregroundColor(selectedTag == tag ? .white : .themePrimary)
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color.themeBackground)
    }
}

// MARK: - Timeline Notes View
struct TimelineNotesView: View {
    let groupedNotes: [(String, [LogEntry])]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Break up the complex expression by using indices directly
                ForEach(0..<groupedNotes.count, id: \.self) { index in
                    let section = groupedNotes[index].0
                    let notes = groupedNotes[index].1
                    let isLastSection = index == groupedNotes.count - 1
                    
                    TimelineSectionView(
                        section: section,
                        notes: notes,
                        isLastSection: isLastSection
                    )
                }
                
                // Bottom padding to ensure last items are visible above FAB
                Color.clear.frame(height: 80)
            }
        }
        .background(Color.themeBackground)
    }
}

// MARK: - Timeline Section View
struct TimelineSectionView: View {
    let section: String
    let notes: [LogEntry]
    let isLastSection: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Date header at the top
            Text(section)
                .font(.headline)
                .foregroundColor(.themeSecondary)
                .padding(.top, 16)
                .padding(.bottom, 12)
                .padding(.leading, 16)
            
            // Notes with vertical line beside them
            ForEach(notes) { note in
                HStack(alignment: .top, spacing: 0) {
                    // Vertical line
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2)
                        .padding(.leading, 24)
                    
                    // Note card
                    NoteCard(note: note)
                        .padding(.leading, 10)
                        .padding(.trailing, 16)
                        .padding(.bottom, 16)
                }
            }
            
            // Extra space at end of section (except for last one)
            if !isLastSection {
                Color.clear.frame(height: 8)
            }
        }
    }
}

// MARK: - Note Card
struct NoteCard: View {
    @ObservedObject var note: LogEntry
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        NavigationLink(destination: EntryDetailView(entry: note)) {
            VStack(alignment: .leading, spacing: 12) {
                // Extract and render hashtags with special formatting
                if let noteText = note.desc {
                    FormattedNoteText(text: noteText)
                }
                
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

// MARK: - Formatted Note Text
struct FormattedNoteText: View {
    let text: String
    
    var body: some View {
        let attributedText = processText(text)
        Text(attributedText)
            .font(.appBody)
            .foregroundColor(.themePrimary)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    private func processText(_ text: String) -> AttributedString {
        var attributedString = AttributedString(text)
        
        // Find all hashtags using our extractor
        let hashtags = HashtagExtractor.extractHashtags(from: text)
        
        // Mark each hashtag with special formatting
        for hashtag in hashtags {
            if let range = attributedString.range(of: hashtag) {
                attributedString[range].foregroundColor = .themeAccent
                attributedString[range].font = .system(.body, design: .default).bold()
            }
        }
        
        return attributedString
    }
}

#Preview {
    NotesView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 