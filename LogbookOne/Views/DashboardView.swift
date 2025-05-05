import SwiftUI
import CoreData

// Time of day enum for greeting messages
enum TimeOfDay {
    case morning
    case midday
    case evening
    case night
    
    var message: String {
        switch self {
        case .morning:
            let messages = [
                "Jumpstart your morning and make it productive.",
                "A fresh start is a chance to move the needle.",
                "Set your tone before the day sets it for you."
            ]
            return messages.randomElement() ?? messages[0]
            
        case .midday:
            let messages = [
                "Keep the momentum going.",
                "Knock out the next right thing.",
                "Progress over perfection—keep building."
            ]
            return messages.randomElement() ?? messages[0]
            
        case .evening:
            let messages = [
                "End the day with clarity, not with clutter.",
                "Clean it up or plan it out—both are wins.",
                "A little progress now makes tomorrow easier."
            ]
            return messages.randomElement() ?? messages[0]
            
        case .night:
            let messages = [
                "Planning late? Just prep one step ahead.",
                "Organize your thoughts, then rest your mind.",
                "Even quiet hours can move the mission forward."
            ]
            return messages.randomElement() ?? messages[0]
        }
    }
}

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
    @State private var activitySortAscending = false
    
    // User name from settings
    @AppStorage("userName") private var userName: String = ""
    
    // Time formatter for activity times
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \LogEntry.creationDate, ascending: false),
            NSSortDescriptor(keyPath: \LogEntry.date, ascending: false)
        ],
        predicate: NSPredicate(format: "(type == %d AND isComplete == YES OR type == %d) AND (date >= %@ OR creationDate >= %@)", 
                              LogEntryType.task.rawValue,
                              LogEntryType.payment.rawValue,
                              Calendar.current.startOfDay(for: Date()) as NSDate,
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
    
    // For overdue tasks
    @FetchRequest(
        entity: LogEntry.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \LogEntry.date, ascending: true)],
        predicate: NSPredicate(format: "type == %d AND isComplete == NO AND date < %@",
                              LogEntryType.task.rawValue,
                              Calendar.current.startOfDay(for: Date()) as NSDate),
        animation: .default)
    private var overdueTasks: FetchedResults<LogEntry>
    
    // For undated tasks
    @FetchRequest(
        entity: LogEntry.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \LogEntry.creationDate, ascending: false)],
        predicate: NSPredicate(format: "type == %d AND isComplete == NO AND date == nil", 
                              LogEntryType.task.rawValue),
        animation: .default)
    private var undatedTasks: FetchedResults<LogEntry>
    
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
                // User greeting
                personalGreeting
                
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .toolbarBackground(Color.themeBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $showingAddEntry) {
            LogEntryFormView()
        }
        .sheet(isPresented: $showingAddClient) {
            ClientFormView()
        }
    }
    
    // Personal greeting based on time of day
    private var personalGreeting: some View {
        let timeOfDay = getCurrentTimeOfDay()
        
        return VStack(alignment: .leading, spacing: 16) {
            // Simple greeting with first name and wave emoji
            HStack {
                Text("Hello \(getFirstName())! 👋")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundColor(.themePrimary)
                
                Spacer()
                
                // Settings button
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 22))
                        .foregroundColor(.themeAccent)
                        .padding(10)
                        .background(
                            Circle()
                                .fill(Color.themeAccent.opacity(0.1))
                        )
                }
            }
            
            // Main tagline - make this the headline
            Text(timeOfDay.message)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.themePrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
    
    // Helper to extract first name from full name
    private func getFirstName() -> String {
        guard !userName.isEmpty else { return "there" }
        
        let components = userName.components(separatedBy: " ")
        return components.first ?? userName
    }
    
    // Function to get time of day for appropriate greeting
    private func getCurrentTimeOfDay() -> TimeOfDay {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 5..<12:
            // Morning (5:00 AM – 11:59 AM)
            return .morning
        case 12..<17:
            // Afternoon (12:00 PM – 4:59 PM)
            return .midday
        case 17..<22:
            // Evening (5:00 PM – 9:59 PM)
            return .evening
        default:
            // Night (10:00 PM – 4:59 AM)
            return .night
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
                Label("What to Tackle", systemImage: "checkmark.circle")
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
            
            // Minimal task list display
            VStack(alignment: .leading, spacing: 10) {
                if tasksForToday.isEmpty && overdueTasks.isEmpty {
                    HStack {
                        Text("No tasks for today")
                            .font(.appBody)
                            .foregroundColor(.themeSecondary)
                            .padding(.vertical, 8)
                        
                        Spacer()
                    }
                } else {
                    // Show overdue tasks first
                    ForEach(overdueTasks) { task in
                        NavigationLink(destination: EntryDetailView(entry: task)) {
                            MinimalTaskRowView(task: task, isOverdue: true)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Today's tasks
                    ForEach(tasksForToday) { task in
                        NavigationLink(destination: EntryDetailView(entry: task)) {
                            MinimalTaskRowView(task: task)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                // Show up to 3 unscheduled tasks
                if !undatedTasks.isEmpty {
                    Divider()
                        .padding(.vertical, 4)
                    
                    Text("Unscheduled")
                        .font(.appSubheadline)
                        .foregroundColor(.themeSecondary)
                        .padding(.top, 4)
                    
                    let tasksToShow = undatedTasks.prefix(3)
                    ForEach(Array(tasksToShow)) { task in
                        NavigationLink(destination: EntryDetailView(entry: task)) {
                            MinimalTaskRowView(task: task)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    if undatedTasks.count > 3 {
                        Text("+ \(undatedTasks.count - 3) more")
                            .font(.caption)
                            .foregroundColor(.themeSecondary)
                            .padding(.top, 4)
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
    
    // Minimal task row component for the task overview
    private struct MinimalTaskRowView: View {
        let task: LogEntry
        var isOverdue: Bool = false
        @Environment(\.managedObjectContext) private var viewContext
        
        var body: some View {
            HStack(alignment: .center, spacing: 12) {
                // Checkbox
                Button {
                    toggleTaskCompletion()
                } label: {
                    Image(systemName: task.isComplete ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundColor(task.isComplete ? .themeTask : (isOverdue ? .red : .themeSecondary))
                }
                .buttonStyle(BorderlessButtonStyle())
                
                // Just the task description
                Text(task.desc ?? "Untitled Task")
                    .font(.appSubheadline)
                    .foregroundColor(isOverdue ? .red : .themePrimary)
                    .lineLimit(1)
                    .strikethrough(task.isComplete)
                
                Spacer()
            }
            .contentShape(Rectangle())
            .padding(.vertical, 4)
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
        
        private func createCompletionEntry() {
            // Create a new log entry for the completed task to show in Today's Wins
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
            Text("Today's Wins")
                .font(.appTitle3)
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    activitySortAscending.toggle()
                }
            }) {
                HStack(spacing: 4) {
                    Text(activitySortAscending ? "Oldest first" : "Newest first")
                        .font(.caption)
                        .foregroundColor(.themeSecondary)
                    
                    Image(systemName: activitySortAscending ? "arrow.up" : "arrow.down")
                        .font(.caption)
                        .foregroundColor(.themeAccent)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color.themeCard)
                .cornerRadius(8)
            }
        }
        .padding(.horizontal)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "trophy")
                .font(.system(size: 60))
                .foregroundColor(Color.themeSecondary.opacity(0.3))
                .padding(.top, 30)
            
            Text("No Wins Yet Today")
                .font(.appTitle2)
                .foregroundColor(.themePrimary)
            
            Text("Complete tasks or log payments to see them here")
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
            let sortedEntries = activitySortAscending ? 
                            Array(todayEntries.sorted(by: { 
                                (getEntryTime($0) ?? Date.distantPast) < (getEntryTime($1) ?? Date.distantPast) 
                            })) :
                            Array(todayEntries)
            
            ForEach(sortedEntries, id: \.id) { entry in
                NavigationLink(destination: EntryDetailView(entry: entry)) {
                    LogEntryCard(entry: entry)
                        .padding(.horizontal)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // Helper to get an entry's time for sorting (creationDate or date)
    private func getEntryTime(_ entry: LogEntry) -> Date? {
        if let creationDate = entry.value(forKey: "creationDate") as? Date {
            return creationDate
        } else {
            return entry.date
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
            
            // Description - show with visual indicator if it's a completed task
            if entry.type == LogEntryType.task.rawValue && entry.isComplete {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.themeTask)
                        .font(.system(size: 16))
                    
                    Text(entry.desc ?? "")
                        .font(.appBody)
                        .foregroundColor(.themeSecondary)
                        .strikethrough(true)
                        .lineLimit(2)
                }
            } else {
                Text(entry.desc ?? "")
                    .font(.appBody)
                    .foregroundColor(.themeSecondary)
                    .lineLimit(2)
            }
            
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