import SwiftUI
import CoreData

struct TasksView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var filterStatus: TaskStatus = .all
    @State private var selectedClient: Client? = nil
    @State private var showingAddTask = false
    
    @FetchRequest private var tasks: FetchedResults<LogEntry>
    
    enum TaskStatus: String, CaseIterable, Identifiable {
        case all = "All"
        case open = "Open"
        case completed = "Completed"
        
        var id: String { self.rawValue }
    }
    
    init(filterStatus: TaskStatus = .all, selectedClient: Client? = nil) {
        self._filterStatus = State(initialValue: filterStatus)
        self._selectedClient = State(initialValue: selectedClient)
        
        // Build the predicate based on filters
        var predicates: [NSPredicate] = []
        
        // Always filter for task type
        predicates.append(NSPredicate(format: "type == %d", LogEntryType.task.rawValue))
        
        // Filter by completion status
        switch filterStatus {
        case .open:
            predicates.append(NSPredicate(format: "isComplete == NO"))
        case .completed:
            predicates.append(NSPredicate(format: "isComplete == YES"))
        case .all:
            break
        }
        
        // Filter by client if selected
        if let client = selectedClient {
            predicates.append(NSPredicate(format: "client == %@", client))
        }
        
        // Combine predicates with AND
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        // Initialize fetch request with sort descriptors and predicate
        self._tasks = FetchRequest<LogEntry>(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \LogEntry.isComplete, ascending: true),
                NSSortDescriptor(keyPath: \LogEntry.date, ascending: false)
            ],
            predicate: compoundPredicate,
            animation: .default
        )
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Status filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(TaskStatus.allCases) { status in
                            FilterChip(
                                title: status.rawValue,
                                count: countForStatus(status),
                                isSelected: filterStatus == status,
                                action: { filterStatus = status }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                
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
                            .background(selectedClient == nil ? Color.appAccent.opacity(0.1) : Color.cardBackground)
                            .foregroundColor(selectedClient == nil ? .appAccent : .primaryText)
                            .cornerRadius(8)
                        }
                        
                        ForEach(clientsWithTasks) { client in
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
                                .background(selectedClient == client ? Color.appAccent.opacity(0.1) : Color.cardBackground)
                                .foregroundColor(selectedClient == client ? .appAccent : .primaryText)
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                .background(Color.appBackground)
                
                // Tasks list
                if tasks.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(tasks) { task in
                                TaskRow(task: task)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                    .background(Color.appBackground)
                }
            }
            .background(Color.appBackground)
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTask = true }) {
                        Image(systemName: "plus")
                            .font(.headline)
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                // Pre-select the task type
                LogEntryFormView(selectedType: .task, client: selectedClient)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 70))
                .foregroundColor(Color.secondaryText.opacity(0.3))
                .padding(.bottom, 10)
                .padding(.top, 60)
            
            Text("No Tasks Found")
                .font(.appTitle2)
                .foregroundColor(.primaryText)
            
            Text(emptyStateMessage)
                .font(.appBody)
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: { showingAddTask = true }) {
                Text("Add New Task")
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
        if let client = selectedClient {
            return "You don't have any \(filterStatus == .completed ? "completed" : filterStatus == .open ? "open" : "") tasks for \(client.name ?? "this client")."
        } else {
            return "You don't have any \(filterStatus == .completed ? "completed" : filterStatus == .open ? "open" : "") tasks yet."
        }
    }
    
    private var clientsWithTasks: [Client] {
        let fetchRequest: NSFetchRequest<Client> = Client.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "ANY logEntries.type == %d", LogEntryType.task.rawValue)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Client.name, ascending: true)]
        
        do {
            return try viewContext.fetch(fetchRequest)
        } catch {
            print("Error fetching clients with tasks: \(error)")
            return []
        }
    }
    
    private func countForStatus(_ status: TaskStatus) -> Int {
        let fetchRequest: NSFetchRequest<LogEntry> = LogEntry.fetchRequest()
        var predicates: [NSPredicate] = []
        
        // Always filter for task type
        predicates.append(NSPredicate(format: "type == %d", LogEntryType.task.rawValue))
        
        // Filter by completion status
        switch status {
        case .open:
            predicates.append(NSPredicate(format: "isComplete == NO"))
        case .completed:
            predicates.append(NSPredicate(format: "isComplete == YES"))
        case .all:
            break
        }
        
        // Filter by client if selected
        if let client = selectedClient {
            predicates.append(NSPredicate(format: "client == %@", client))
        }
        
        // Combine predicates
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        do {
            return try viewContext.count(for: fetchRequest)
        } catch {
            print("Error counting tasks: \(error)")
            return 0
        }
    }
}

struct TaskRow: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var task: LogEntry
    @State private var isComplete: Bool = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    var body: some View {
        NavigationLink(destination: EntryDetailView(entry: task)) {
            HStack(spacing: 12) {
                // Checkbox
                Button(action: toggleCompletion) {
                    ZStack {
                        Circle()
                            .stroke(isComplete ? Color.appAccent : Color.gray.opacity(0.4), lineWidth: 2)
                            .frame(width: 24, height: 24)
                        
                        if isComplete {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.appAccent)
                        }
                    }
                }
                .buttonStyle(.plain)
                
                VStack(alignment: .leading, spacing: 4) {
                    // Task description
                    Text(task.desc ?? "")
                        .font(.appHeadline)
                        .foregroundColor(isComplete ? .secondaryText : .primaryText)
                        .strikethrough(isComplete)
                    
                    // Client and date
                    HStack {
                        if let client = task.client {
                            Text(client.name ?? "Client")
                                .font(.appCaption)
                                .foregroundColor(.secondaryText)
                        }
                        
                        if let date = task.date {
                            Text("•")
                                .font(.appCaption)
                                .foregroundColor(.secondaryText.opacity(0.5))
                            
                            Text(dateFormatter.string(from: date))
                                .font(.appCaption)
                                .foregroundColor(.secondaryText)
                        }
                    }
                }
                
                Spacer()
                
                // Tag if exists
                if let tag = task.tag, !tag.isEmpty {
                    Text(tag)
                        .font(.appCaption)
                        .foregroundColor(.secondaryText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
            }
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            isComplete = task.isComplete
        }
    }
    
    private func toggleCompletion() {
        isComplete.toggle()
        task.isComplete = isComplete
        
        do {
            try viewContext.save()
            
            // Add haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        } catch {
            print("Error saving task completion: \(error)")
        }
    }
}

struct FilterChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.appSubheadline)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.appCaption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.white.opacity(0.3) : Color.appAccent.opacity(0.1))
                        )
                        .foregroundColor(isSelected ? .white : .appAccent)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.appAccent : Color.cardBackground)
                    .shadow(color: isSelected ? Color.appAccent.opacity(0.3) : Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
            )
            .foregroundColor(isSelected ? .white : .primaryText)
        }
    }
}

#Preview {
    TasksView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 