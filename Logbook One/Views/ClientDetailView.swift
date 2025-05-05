import SwiftUI
import CoreData

struct ClientDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var client: Client
    @State private var showingAddEntry = false
    @State private var showingEditClient = false
    @State private var selectedFilter: EntryTypeFilter = .all
    @State private var animateFilter = false
    
    @FetchRequest private var entries: FetchedResults<LogEntry>
    
    enum EntryTypeFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case task = "Tasks"
        case note = "Notes"
        case payment = "Payments"
        
        var id: String { self.rawValue }
        
        var predicate: NSPredicate? {
            switch self {
            case .all:
                return nil
            case .task:
                return NSPredicate(format: "type == %d", LogEntryType.task.rawValue)
            case .note:
                return NSPredicate(format: "type == %d", LogEntryType.note.rawValue)
            case .payment:
                return NSPredicate(format: "type == %d", LogEntryType.payment.rawValue)
            }
        }
        
        var systemImage: String {
            switch self {
            case .all:
                return "list.bullet"
            case .task:
                return "checkmark.circle"
            case .note:
                return "note.text"
            case .payment:
                return "dollarsign.circle"
            }
        }
    }
    
    init(client: Client) {
        self.client = client
        
        // Initialize the fetch request with the client predicate
        let clientPredicate = NSPredicate(format: "client == %@", client)
        _entries = FetchRequest<LogEntry>(
            sortDescriptors: [NSSortDescriptor(keyPath: \LogEntry.date, ascending: false)],
            predicate: clientPredicate
        )
    }
    
    private var totalPayments: Double {
        entries.filter { $0.type == LogEntryType.payment.rawValue }
            .reduce(0) { sum, entry in
                if let amount = entry.amount as NSDecimalNumber? {
                    return sum + amount.doubleValue
                }
                return sum
            }
    }
    
    private var filteredEntries: [LogEntry] {
        if selectedFilter == .all {
            return Array(entries)
        } else if let filterPredicate = selectedFilter.predicate {
            return entries.filter { entry in
                let evaluationContext: [String: Any] = ["type": entry.type]
                return filterPredicate.evaluate(with: entry, substitutionVariables: evaluationContext)
            }
        } else {
            return Array(entries)
        }
    }
    
    // Helper computed properties for counting entries by type
    private var taskCount: Int {
        entries.filter { $0.type == LogEntryType.task.rawValue }.count
    }
    
    private var noteCount: Int {
        entries.filter { $0.type == LogEntryType.note.rawValue }.count
    }
    
    private var paymentCount: Int {
        entries.filter { $0.type == LogEntryType.payment.rawValue }.count
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Client header
                clientHeaderView
                
                // Summary card
                summaryCard
                
                // Filters
                filterSegments
                
                // Entries
                if filteredEntries.isEmpty {
                    emptyEntriesView
                } else {
                    entriesList
                }
                
                // Add entry button
                addEntryButton
            }
            .padding(.vertical)
        }
        .background(Color.themeBackground)
        .navigationTitle(client.name ?? "Client")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingEditClient = true }) {
                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .medium))
                }
            }
        }
        .sheet(isPresented: $showingAddEntry) {
            LogEntryFormView(client: client)
        }
        .sheet(isPresented: $showingEditClient) {
            ClientFormView(client: client)
        }
    }
    
    private var clientHeaderView: some View {
        VStack(spacing: 20) {
            // Client avatar & info
            HStack(spacing: 16) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color.themeAccent.opacity(0.12))
                        .frame(width: 70, height: 70)
                    
                    Text(clientInitials)
                        .font(.system(.title2, design: .default).weight(.semibold))
                        .foregroundColor(Color.themeAccent)
                }
                
                // Client details
                VStack(alignment: .leading, spacing: 6) {
                    Text(client.name ?? "Unnamed Client")
                        .font(.appTitle2)
                        .foregroundColor(.themePrimary)
                    
                    if let tag = client.tag, !tag.isEmpty {
                        HStack(spacing: 6) {
                            Text(tag)
                                .font(.appSubheadline)
                                .foregroundColor(.themeSecondary)
                        }
                    }
                    
                    if let rate = client.hourlyRate as NSDecimalNumber?, rate.doubleValue > 0 {
                        let rateValue = rate.doubleValue
                        Text("$\(rateValue, specifier: "%.2f")/hour")
                            .font(.appHeadline)
                            .foregroundColor(.themePayment)
                            .padding(.top, 2)
                    }
                }
                
                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
    
    private var summaryCard: some View {
        VStack(spacing: 12) {
            // Header with icon
            HStack {
                Label("Financial Summary", systemImage: "chart.bar.fill")
                    .font(.appHeadline)
                    .foregroundColor(.themePrimary)
                Spacer()
            }
            
            Divider()
                .padding(.vertical, 4)
            
            HStack(alignment: .bottom, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Paid")
                        .font(.appCaption)
                        .foregroundColor(.themeSecondary)
                    
                    let totalValue = totalPayments
                    Text("$\(totalValue, specifier: "%.2f")")
                        .font(.system(size: 34, weight: .bold, design: .default))
                        .foregroundColor(.themePrimary)
                }
                
                Spacer()
                
                // Payment count badge
                Text("\(paymentCount) payment\(paymentCount == 1 ? "" : "s")")
                    .font(.appCaption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.themePayment.opacity(0.12))
                    .foregroundColor(Color.themePayment)
                    .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color.themeCard)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    private var filterSegments: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Log Entries")
                .font(.appHeadline)
                .foregroundColor(.themePrimary)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(EntryTypeFilter.allCases) { filter in
                        FilterButton(
                            filter: filter,
                            isSelected: selectedFilter == filter,
                            count: countForFilter(filter),
                            action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedFilter = filter
                                    animateFilter.toggle()
                                }
                                // Add haptic feedback for filter selection
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                            }
                        )
                        .scaleEffect(selectedFilter == filter && animateFilter ? 1.05 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedFilter)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func countForFilter(_ filter: EntryTypeFilter) -> Int {
        switch filter {
        case .all:
            return entries.count
        case .task:
            return taskCount
        case .note:
            return noteCount
        case .payment:
            return paymentCount
        }
    }
    
    private var emptyEntriesView: some View {
        VStack(spacing: 20) {
            Spacer()
                .frame(height: 20)
                
            Image(systemName: selectedFilter.systemImage)
                .font(.system(size: 60))
                .foregroundColor(Color.themeSecondary.opacity(0.3))
                .padding(.bottom, 10)
            
            Text("No \(selectedFilter.rawValue)")
                .font(.appTitle3)
                .foregroundColor(.themePrimary)
            
            Text("Add a \(selectedFilter == .all ? "log entry" : selectedFilter.rawValue.dropLast().lowercased()) to track your work with this client")
                .font(.appBody)
                .foregroundColor(.themeSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
            
            Spacer()
        }
        .frame(minHeight: 300)
    }
    
    private var entriesList: some View {
        VStack(spacing: 12) {
            ForEach(filteredEntries) { entry in
                NavigationLink(destination: EntryDetailView(entry: entry)) {
                    LogEntryCard(entry: entry)
                        .padding(.horizontal)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var addEntryButton: some View {
        Button(action: { showingAddEntry = true }) {
            HStack {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                Text("Add Log Entry")
                    .font(.appHeadline)
            }
            .frame(height: 24)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.top, 20)
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

struct FilterButton: View {
    let filter: ClientDetailView.EntryTypeFilter
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: filter.systemImage)
                    .font(.system(size: 12))
                
                Text(filter.rawValue)
                    .font(.appSubheadline)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.appCaption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.white.opacity(0.3) : Color.themeAccent.opacity(0.1))
                        )
                        .foregroundColor(isSelected ? .white : .themeAccent)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.themeAccent : Color.themeCard)
                    .shadow(color: isSelected ? Color.themeAccent.opacity(0.3) : Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
            )
            .foregroundColor(isSelected ? .white : .themePrimary)
        }
    }
}

#Preview {
    NavigationStack {
        ClientDetailView(client: Client())
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
} 

