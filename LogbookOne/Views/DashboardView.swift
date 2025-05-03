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
                    .background(selectedPeriod == .month ? Color.appAccent : Color.cardBackground)
                    .foregroundColor(selectedPeriod == .month ? .white : .primaryText)
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
                    .background(selectedPeriod == .year ? Color.appAccent : Color.cardBackground)
                    .foregroundColor(selectedPeriod == .year ? .white : .primaryText)
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
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \LogEntry.date, ascending: false)],
        predicate: NSPredicate(format: "date >= %@", Calendar.current.startOfDay(for: Date()) as NSDate),
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
    
    // For open tasks
    @FetchRequest(
        entity: LogEntry.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \LogEntry.date, ascending: false)],
        predicate: NSPredicate(format: "type == %d AND isComplete == NO", LogEntryType.task.rawValue),
        animation: .default)
    private var openTasks: FetchedResults<LogEntry>
    
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
                
                // Task overview
                taskOverviewCard
                
                // Today's entries section
                VStack(spacing: 16) {
                    sectionHeader
                    
                    if todayEntries.isEmpty {
                        emptyStateView
                    } else {
                        entriesList
                    }
                }
                
                // Add entry button
                addEntryButton
            }
            .padding(.vertical)
        }
        .background(Color.appBackground)
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
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                NavigationLink(destination: PaymentsView()) {
                    Text("View All")
                        .font(.appCaption.weight(.medium))
                        .foregroundColor(.appAccent)
                }
            }
            
            Divider()
            
            // Time period selector
            RevenueTimePeriodSelector(selectedPeriod: $selectedRevenuePeriod)
            
            // Revenue display
            VStack(alignment: .leading, spacing: 8) {
                Text(selectedRevenuePeriod == .month ? "This Month" : "This Year")
                    .font(.appCaption)
                    .foregroundColor(.secondaryText)
                
                if selectedRevenuePeriod == .month {
                    Text(formatCurrency(totalMonthlyRevenue))
                        .font(.system(size: 34, weight: .bold, design: .default))
                        .foregroundColor(.primaryText)
                    
                    Text("\(monthlyPayments.count) payment\(monthlyPayments.count == 1 ? "" : "s")")
                        .font(.appCaption)
                        .foregroundColor(.secondaryText)
                } else {
                    Text(formatCurrency(totalYearlyRevenue))
                        .font(.system(size: 34, weight: .bold, design: .default))
                        .foregroundColor(.primaryText)
                    
                    Text("\(yearlyPayments.count) payment\(yearlyPayments.count == 1 ? "" : "s")")
                        .font(.appCaption)
                        .foregroundColor(.secondaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
    
    private var taskOverviewCard: some View {
        VStack(spacing: 16) {
            // Card header
            HStack {
                Label("Task Overview", systemImage: "checkmark.circle")
                    .font(.appHeadline)
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                NavigationLink(destination: TasksView()) {
                    Text("View All")
                        .font(.appCaption.weight(.medium))
                        .foregroundColor(.appAccent)
                }
            }
            
            Divider()
            
            // Task count display
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(openTasks.count)")
                            .font(.system(size: 32, weight: .bold, design: .default))
                            .foregroundColor(.primaryText)
                        
                        Text("Open")
                            .font(.appCaption)
                            .foregroundColor(.secondaryText)
                            .padding(.leading, 4)
                    }
                    
                    if let nextDueTask = openTasks.first, openTasks.count > 0 {
                        Text(nextDueTask.desc ?? "")
                            .font(.appCaption)
                            .foregroundColor(.secondaryText)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Add task button
                NavigationLink(destination: LogEntryFormView(selectedType: .task)) {
                    Text("New Task")
                        .font(.appCaption.weight(.medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.taskColor)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    private var sectionHeader: some View {
        HStack {
            Text("Today's Activity")
                .font(.appTitle3)
            
            Spacer()
            
            Menu {
                Button(action: { showingAddEntry = true }) {
                    Label("New Entry", systemImage: "plus.circle")
                }
                
                Button(action: { showingAddClient = true }) {
                    Label("New Client", systemImage: "person.badge.plus")
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .frame(width: 44, height: 44)
                    .foregroundColor(.appAccent)
            }
        }
        .padding(.horizontal)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundColor(Color.secondaryText.opacity(0.3))
                .padding(.top, 30)
            
            Text("No Entries Today")
                .font(.appTitle2)
                .foregroundColor(.primaryText)
            
            Text("Add your first entry to start tracking your client work")
                .font(.appBody)
                .foregroundColor(.secondaryText)
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
    
    private var addEntryButton: some View {
        Button(action: { showingAddEntry = true }) {
            Text("Add New Entry")
                .font(.appHeadline)
                .frame(height: 24)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }
}

struct LogEntryCard: View {
    let entry: LogEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with type badge and time
            HStack {
                EntryTypeBadgeView(type: LogEntryType(rawValue: entry.type) ?? .task)
                
                Spacer()
                
                if let date = entry.date {
                    Text(date, style: .time)
                        .font(.appCaption)
                        .foregroundColor(.secondaryText)
                }
            }
            
            // Client name
            Text(entry.client?.name ?? "No Client")
                .font(.appHeadline)
                .foregroundColor(.primaryText)
                .padding(.top, 4)
            
            // Description
            Text(entry.desc ?? "")
                .font(.appBody)
                .foregroundColor(.secondaryText)
                .lineLimit(2)
            
            // Show amount for payment entries
            if entry.type == LogEntryType.payment.rawValue, 
               let amount = entry.amount as NSDecimalNumber? {
                HStack {
                    Spacer()
                    let amountValue = amount.doubleValue
                    Text("$\(amountValue, specifier: "%.2f")")
                        .font(.appTitle3)
                        .foregroundColor(.paymentColor)
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
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

#Preview {
    NavigationStack {
        DashboardView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
} 