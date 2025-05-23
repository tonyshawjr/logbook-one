import SwiftUI
import CoreData

// Time periods for revenue filtering
enum RevenuePeriod {
    case month, year
}

struct RevenueTimePeriodSelector: View {
    @Binding var selectedPeriod: RevenuePeriod
    
    var body: some View {
        HStack(spacing: 8) {
            Button(action: { selectedPeriod = .month }) {
                Text("This Month")
                    .font(.appSubheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(selectedPeriod == .month ? Color.themeAccent : Color.themeCard)
                    .foregroundColor(selectedPeriod == .month ? .white : .themePrimary)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(selectedPeriod == .month ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
            
            Button(action: { selectedPeriod = .year }) {
                Text("This Year")
                    .font(.appSubheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(selectedPeriod == .year ? Color.themeAccent : Color.themeCard)
                    .foregroundColor(selectedPeriod == .year ? .white : .themePrimary)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(selectedPeriod == .year ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
            
            Spacer()
        }
    }
}

struct DashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingAddEntry = false
    @State private var showingAddClient = false
    
    // Time formatter for activity times
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \LogEntry.date, ascending: false)],
        predicate: NSPredicate(format: "date >= %@", 
                               Calendar.current.startOfDay(for: Date()) as NSDate),
        animation: .default)
    private var todayEntries: FetchedResults<LogEntry>
    
    // For monthly payment summary
    @FetchRequest(
        entity: LogEntry.entity(),
        sortDescriptors: [],
        predicate: NSPredicate(format: "type == %d AND date >= %@ AND date <= %@", 
                               LogEntryType.payment.rawValue,
                               Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date()))! as NSDate,
                               Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), 
                                                    to: Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date()))!)! as NSDate),
        animation: .default)
    private var monthlyPayments: FetchedResults<LogEntry>
    
    // For open tasks due today
    @FetchRequest(
        entity: LogEntry.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \LogEntry.date, ascending: true)],
        predicate: NSPredicate(format: "type == %d AND isComplete == NO AND date >= %@ AND date <= %@", 
                              LogEntryType.task.rawValue,
                              Calendar.current.startOfDay(for: Date()) as NSDate,
                              Calendar.current.date(byAdding: DateComponents(day: 1, second: -1), 
                                                  to: Calendar.current.startOfDay(for: Date()))! as NSDate),
        animation: .default)
    private var tasksForToday: FetchedResults<LogEntry>
    
    // For yearly payment summary
    @FetchRequest(
        entity: LogEntry.entity(),
        sortDescriptors: [],
        predicate: NSPredicate(format: "type == %d AND date >= %@", 
                               LogEntryType.payment.rawValue,
                               Calendar.current.date(from: Calendar.current.dateComponents([.year], from: Date()))! as NSDate),
        animation: .default)
    private var yearlyPayments: FetchedResults<LogEntry>
    
    @State private var selectedRevenuePeriod: RevenuePeriod = .month
    
    private var totalMonthlyRevenue: Double {
        monthlyPayments.reduce(0) { sum, entry in
            if let amount = entry.amount as NSDecimalNumber? {
                return sum + amount.doubleValue
            }
            return sum
        }
    }
    
    private var totalYearlyRevenue: Double {
        yearlyPayments.reduce(0) { sum, entry in
            if let amount = entry.amount as NSDecimalNumber? {
                return sum + amount.doubleValue
            }
            return sum
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Revenue summary
                revenueCard
                
                // Task overview - only show if there are tasks due today
                if !tasksForToday.isEmpty {
                    taskOverviewCard
                }
                
                // Today's entries section
                VStack(spacing: 16) {
                    sectionHeader
                    
                    if todayEntries.isEmpty {
                        emptyStateView
                    } else {
                        entriesList
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Color.themeBackground)
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingAddEntry) {
            LogEntryFormView()
        }
        .sheet(isPresented: $showingAddClient) {
            ClientFormView()
        }
    }
    
    private var revenueCard: some View {
        VStack(spacing: 16) {
            // Card header
            HStack {
                Label("Revenue Summary", systemImage: "chart.bar.fill")
                    .font(.appHeadline)
                    .foregroundColor(.themePrimary)
                
                Spacer()
                
                NavigationLink(destination: PaymentsView()) {
                    Text("View All")
                        .font(.appCaption.weight(.medium))
                        .foregroundColor(.themeAccent)
                }
            }
            
            Divider()
            
            // Time period selector
            RevenueTimePeriodSelector(selectedPeriod: $selectedRevenuePeriod)
            
            // Revenue display
            VStack(alignment: .leading, spacing: 8) {
                Text(selectedRevenuePeriod == .month ? "This Month" : "This Year")
                    .font(.appCaption)
                    .foregroundColor(.themeSecondary)
                
                if selectedRevenuePeriod == .month {
                    Text(formatCurrency(totalMonthlyRevenue))
                        .font(.system(size: 34, weight: .bold, design: .default))
                        .foregroundColor(.themePrimary)
                    
                    Text("\(monthlyPayments.count) payment\(monthlyPayments.count == 1 ? "" : "s")")
                        .font(.appCaption)
                        .foregroundColor(.themeSecondary)
                } else {
                    Text(formatCurrency(totalYearlyRevenue))
                        .font(.system(size: 34, weight: .bold, design: .default))
                        .foregroundColor(.themePrimary)
                    
                    Text("\(yearlyPayments.count) payment\(yearlyPayments.count == 1 ? "" : "s")")
                        .font(.appCaption)
                        .foregroundColor(.themeSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color.themeCard)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    private var taskOverviewCard: some View {
        VStack(spacing: 12) {
            // Card header
            HStack {
                Label("Task Overview", systemImage: "checkmark.circle")
                    .font(.appHeadline)
                    .foregroundColor(.themePrimary)
                
                Spacer()
                
                NavigationLink(destination: TasksView()) {
                    Text("View All")
                        .font(.appCaption.weight(.medium))
                        .foregroundColor(.themeAccent)
                }
            }
            
            Divider()
            
            // Task list display
            VStack(alignment: .leading, spacing: 10) {
                Text("Due Today")
                    .font(.appSubheadline)
                    .foregroundColor(.themeSecondary)
                    .padding(.top, 4)
                
                if tasksForToday.isEmpty {
                    HStack {
                        Text("No tasks due today")
                            .font(.appBody)
                            .foregroundColor(.themeSecondary)
                            .padding(.vertical, 8)
                        
                        Spacer()
                    }
                } else {
                    ForEach(tasksForToday) { task in
                        NavigationLink(destination: EntryDetailView(entry: task)) {
                            TaskRowView(task: task)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if task != tasksForToday.last {
                            Divider()
                                .padding(.vertical, 2)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.themeCard)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    // Task row component for the task overview
    private struct TaskRowView: View {
        let task: LogEntry
        @Environment(\.managedObjectContext) private var viewContext
        
        // Time formatter for consistent display
        private let timeFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter
        }()
        
        var body: some View {
            HStack(alignment: .center, spacing: 12) {
                // Checkbox
                Button {
                    toggleTaskCompletion()
                } label: {
                    Image(systemName: task.isComplete ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundColor(task.isComplete ? .themeTask : .themeSecondary)
                }
                .buttonStyle(BorderlessButtonStyle())
                
                // Task description
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.desc ?? "Untitled Task")
                        .font(.appSubheadline)
                        .foregroundColor(.themePrimary)
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        if let client = task.client?.name, !client.isEmpty {
                            Text(client)
                                .font(.appCaption)
                                .foregroundColor(.themeSecondary)
                        }
                        
                        if let tag = task.tag, !tag.isEmpty {
                            Text("•")
                                .font(.appCaption)
                                .foregroundColor(.themeSecondary)
                            
                            Text(tag)
                                .font(.appCaption)
                                .foregroundColor(.themeSecondary)
                        }
                        
                        // Show due time if it exists and is different from creation time
                        if let date = task.date, isCustomDueTime(date) {
                            Text("•")
                                .font(.appCaption)
                                .foregroundColor(.themeSecondary)
                            
                            Text("Due: \(timeFormatter.string(from: date))")
                                .font(.appCaption)
                                .foregroundColor(.themeSecondary)
                        }
                    }
                }
                
                Spacer()
                
                // Show when activity happened or task was created - NOT the scheduled time
                if let creationDate = task.value(forKey: "creationDate") as? Date {
                    Text(timeFormatter.string(from: creationDate))
                        .font(.appCaption)
                        .foregroundColor(.themeSecondary)
                } else if let date = task.date {
                    // Fallback to date only for legacy entries
                    Text(timeFormatter.string(from: date))
                        .font(.appCaption)
                        .foregroundColor(.themeSecondary)
                }
            }
            .contentShape(Rectangle())
        }
        
        private func toggleTaskCompletion() {
            withAnimation {
                let wasComplete = task.isComplete
                task.isComplete.toggle()
                
                // If task is being completed (not uncompleted), create a completion entry
                if !wasComplete && task.isComplete {
                    createCompletionEntry()
                }
                
                try? viewContext.save()
            }
        }
        
        // Helper to determine if a due time should be shown
        private func isCustomDueTime(_ date: Date) -> Bool {
            // Check if we have a specific time set (not midnight or 9 AM default)
            let calendar = Calendar.current
            let timeComponents = calendar.dateComponents([.hour, .minute], from: date)
            
            // Don't show due time for default times (midnight or 9 AM)
            let isDefaultTime = (timeComponents.hour == 0 && timeComponents.minute == 0) || 
                               (timeComponents.hour == 9 && timeComponents.minute == 0)
            
            // Only show if it's not a default time and is in the future
            return !isDefaultTime && date > Date()
        }
        
        private func createCompletionEntry() {
            // Create a new log entry for the completed task to show in Today's Activity
            let completionEntry = LogEntry(context: viewContext)
            completionEntry.id = UUID()
            completionEntry.type = LogEntryType.task.rawValue
            completionEntry.desc = "Completed: \(task.desc ?? "Task")"
            completionEntry.date = Date() // Current time
            completionEntry.setValue(Date(), forKey: "creationDate") // Set creation date to now
            completionEntry.isComplete = true
            completionEntry.client = task.client
            completionEntry.tag = task.tag
            
            // If the original task had an amount, copy it
            if let amount = task.amount {
                completionEntry.amount = amount
            }
        }
    }
    
    private var sectionHeader: some View {
        HStack {
            Text("Today's Activity")
                .font(.appTitle3)
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundColor(Color.themeSecondary.opacity(0.3))
                .padding(.top, 30)
            
            Text("No Entries Today")
                .font(.appTitle2)
                .foregroundColor(.themePrimary)
            
            Text("Use the + button to add a new entry")
                .font(.appBody)
                .foregroundColor(.themeSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            Spacer()
                .frame(height: 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private var entriesList: some View {
        LazyVStack(spacing: 12) {
            ForEach(todayEntries) { entry in
                NavigationLink(destination: EntryDetailView(entry: entry)) {
                    LogEntryCard(entry: entry)
                        .padding(.horizontal)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

struct LogEntryCard: View {
    let entry: LogEntry
    
    // Time formatter for consistent display
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    // For debugging
    init(entry: LogEntry) {
        self.entry = entry
        
        // Check if creation date exists for debug purposes
        if let creationDate = entry.value(forKey: "creationDate") as? Date {
            print("Entry \(entry.id?.uuidString ?? "unknown") has creationDate: \(creationDate)")
        } else {
            print("Entry \(entry.id?.uuidString ?? "unknown") has NO creationDate, falling back to date: \(entry.date ?? Date())")
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with type badge and time
            HStack {
                EntryTypeBadgeView(type: LogEntryType(rawValue: entry.type) ?? .task)
                
                Spacer()
                
                // Show when the activity was logged (creationDate) rather than when it's due (date)
                // This ensures the dashboard shows when activities actually happened
                if let creationDate = entry.value(forKey: "creationDate") as? Date {
                    Text(timeFormatter.string(from: creationDate))
                        .font(.appCaption)
                        .foregroundColor(.themeSecondary)
                } else if let date = entry.date {
                    Text(timeFormatter.string(from: date))
                        .font(.appCaption)
                        .foregroundColor(.themeSecondary)
                }
            }
            
            // Client name
            Text(entry.client?.name ?? "No Client")
                .font(.appHeadline)
                .foregroundColor(.themePrimary)
                .padding(.top, 4)
            
            // Description
            Text(entry.desc ?? "")
                .font(.appBody)
                .foregroundColor(.themeSecondary)
                .lineLimit(2)
            
            // Show amount for payment entries
            if entry.type == LogEntryType.payment.rawValue, 
               let amount = entry.amount as NSDecimalNumber? {
                HStack {
                    Spacer()
                    let amountValue = amount.doubleValue
                    Text("$\(amountValue, specifier: "%.2f")")
                        .font(.appTitle3)
                        .foregroundColor(.themePayment)
                }
                .padding(.top, 4)
            }
            
            // Optional tag
            if let tag = entry.tag, !tag.isEmpty {
                Text(tag)
                    .font(.appCaption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.themeCard)
        .cornerRadius(16)
    }
}

#Preview {
    NavigationStack {
        DashboardView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
} 