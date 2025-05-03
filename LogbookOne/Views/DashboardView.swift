import SwiftUI
import CoreData

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
    
    private var totalMonthlyRevenue: Double {
        monthlyPayments.reduce(0) { sum, entry in
            if let amount = entry.amount as NSDecimalNumber? {
                return sum + amount.doubleValue
            }
            return sum
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Monthly summary card
                revenueCard
                
                // Today's entries
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("This Month")
                        .font(.appCaption)
                        .foregroundColor(.secondaryText)
                    
                    let revenueValue = totalMonthlyRevenue
                    Text("$\(revenueValue, specifier: "%.2f")")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.primaryText)
                }
                
                Spacer()
                
                Text(Date(), style: .date)
                    .font(.appCaption)
                    .foregroundColor(.secondaryText)
            }
            
            Divider()
                .padding(.vertical, 4)
            
            Text("\(monthlyPayments.count) payment\(monthlyPayments.count == 1 ? "" : "s")")
                .font(.appCaption)
                .foregroundColor(.secondaryText)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private var sectionHeader: some View {
        HStack {
            Text("Today's Entries")
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
                .foregroundColor(.secondary.opacity(0.5))
                .padding(.top, 30)
            
            Text("No Entries Today")
                .font(.appTitle2)
            
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
                LogEntryCard(entry: entry)
                    .padding(.horizontal)
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
                EntryTypeBadge(type: LogEntryType(rawValue: entry.type) ?? .task)
                
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

struct EntryTypeBadge: View {
    let type: LogEntryType
    
    var body: some View {
        Text(type.displayName)
            .font(.appCaption.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(badgeColor.opacity(0.2))
            .foregroundColor(badgeColor)
            .cornerRadius(8)
    }
    
    var badgeColor: Color {
        switch type {
        case .task:
            return .taskColor
        case .note:
            return .noteColor
        case .payment:
            return .paymentColor
        }
    }
}

#Preview {
    NavigationStack {
        DashboardView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
} 