import SwiftUI
import CoreData
import Charts

struct ClientDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var client: Client
    @State private var showingAddEntry = false
    @State private var showingEditClient = false
    @State private var selectedFilter: EntryTypeFilter = .all
    @State private var animateFilter = false
    @State private var selectedFinancialCard = 0
    
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
    
    // Calculate payments for different time periods
    private var thisMonthPayments: Double {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        return entries.filter { entry in
            entry.type == LogEntryType.payment.rawValue &&
            (entry.date ?? Date.distantPast) >= startOfMonth
        }.reduce(0) { sum, entry in
            if let amount = entry.amount as NSDecimalNumber? {
                return sum + amount.doubleValue
            }
            return sum
        }
    }
    
    private var thisYearPayments: Double {
        let calendar = Calendar.current
        let now = Date()
        let startOfYear = calendar.dateInterval(of: .year, for: now)?.start ?? now
        
        return entries.filter { entry in
            entry.type == LogEntryType.payment.rawValue &&
            (entry.date ?? Date.distantPast) >= startOfYear
        }.reduce(0) { sum, entry in
            if let amount = entry.amount as NSDecimalNumber? {
                return sum + amount.doubleValue
            }
            return sum
        }
    }
    
    private var lastYearPayments: Double {
        let calendar = Calendar.current
        let now = Date()
        let startOfYear = calendar.dateInterval(of: .year, for: now)?.start ?? now
        let startOfLastYear = calendar.date(byAdding: .year, value: -1, to: startOfYear) ?? now
        
        return entries.filter { entry in
            entry.type == LogEntryType.payment.rawValue &&
            (entry.date ?? Date.distantPast) >= startOfLastYear &&
            (entry.date ?? Date.distantPast) < startOfYear
        }.reduce(0) { sum, entry in
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
    
    // Group entries by date for timeline view
    private var groupedEntries: [(String, [LogEntry])] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        let grouped = Dictionary(grouping: filteredEntries) { entry -> String in
            guard let date = entry.date else { return "Undated" }
            
            let entryDate = calendar.startOfDay(for: date)
            
            if calendar.isDate(entryDate, inSameDayAs: today) {
                return "Today"
            } else if calendar.isDate(entryDate, inSameDayAs: yesterday) {
                return "Yesterday"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM d, yyyy"
                return formatter.string(from: date)
            }
        }
        
        // Sort sections by date, with Today and Yesterday first
        return grouped.sorted { section1, section2 in
            if section1.key == "Today" { return true }
            if section2.key == "Today" { return false }
            if section1.key == "Yesterday" { return true }
            if section2.key == "Yesterday" { return false }
            if section1.key == "Undated" { return false }
            if section2.key == "Undated" { return true }
            
            // Parse dates for comparison
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d, yyyy"
            let date1 = formatter.date(from: section1.key) ?? Date.distantPast
            let date2 = formatter.date(from: section2.key) ?? Date.distantPast
            return date1 > date2
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
            VStack(spacing: 28) {
                // Client header with better spacing
                clientHeaderView
                    .padding(.top, 8)
                
                // Financial section with header
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Financial Overview")
                            .font(.appTitle3)
                            .foregroundColor(.themePrimary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    summaryCard
                }
                
                // Divider with proper spacing
                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 1)
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                
                // Entries section with header
                VStack(alignment: .leading, spacing: 16) {
                    filterSegments
                    
                    // Entries
                    if filteredEntries.isEmpty {
                        emptyEntriesView
                    } else {
                        entriesList
                    }
                }
                
                // Add entry button with more spacing
                addEntryButton
                    .padding(.top, 8)
                
                // Bottom padding for safety
                Color.clear.frame(height: 20)
            }
            .padding(.vertical, 12)
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
    
    // Helper function to format currency with smart abbreviations
    private func formatCurrency(_ value: Double, forceDecimals: Bool = false) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.currencySymbol = "$"
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        
        if value >= 1_000_000 {
            return String(format: "$%.1fM", value / 1_000_000)
        } else if value >= 10_000 {
            return String(format: "$%.1fK", value / 1_000)
        } else if value >= 1_000 {
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 0
            return formatter.string(from: NSNumber(value: value)) ?? "$0"
        } else {
            if forceDecimals || value.truncatingRemainder(dividingBy: 1) != 0 {
                formatter.minimumFractionDigits = 2
                formatter.maximumFractionDigits = 2
            }
            return formatter.string(from: NSNumber(value: value)) ?? "$0"
        }
    }
    
    // Calculate year-over-year growth
    private var yearOverYearGrowth: Double? {
        guard lastYearPayments > 0 else { return nil }
        return ((thisYearPayments - lastYearPayments) / lastYearPayments) * 100
    }
    
    // Get monthly payment data for charts - show full year
    private var monthlyPayments: [(month: String, amount: Double)] {
        let calendar = Calendar.current
        let now = Date()
        var monthlyData: [(String, Double)] = []
        
        // Get last 12 months of data for full year view
        for monthOffset in (0..<12).reversed() {
            guard let monthDate = calendar.date(byAdding: .month, value: -monthOffset, to: now) else { continue }
            let monthStart = calendar.dateInterval(of: .month, for: monthDate)?.start ?? monthDate
            let monthEnd = calendar.dateInterval(of: .month, for: monthDate)?.end ?? monthDate
            
            let monthPayments = entries.filter { entry in
                entry.type == LogEntryType.payment.rawValue &&
                (entry.date ?? Date.distantPast) >= monthStart &&
                (entry.date ?? Date.distantPast) < monthEnd
            }.reduce(0.0) { sum, entry in
                if let amount = entry.amount as NSDecimalNumber? {
                    return sum + amount.doubleValue
                }
                return sum
            }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            let monthName = formatter.string(from: monthDate)
            
            monthlyData.append((monthName, monthPayments))
        }
        
        return monthlyData
    }
    
    private var summaryCard: some View {
        VStack(spacing: 12) {
            // Swipeable cards - reduced to 3 for simplicity
            TabView(selection: $selectedFinancialCard) {
                // Card 1: Overview - combines key metrics
                QuickOverviewCard(
                    thisMonth: thisMonthPayments,
                    thisYear: thisYearPayments,
                    totalPayments: totalPayments,
                    paymentCount: paymentCount,
                    formatCurrency: formatCurrency
                )
                .tag(0)
                
                // Card 2: Payment History
                PaymentStatusCard(
                    client: client,
                    entries: entries,
                    formatCurrency: formatCurrency
                )
                .tag(1)
                
                // Card 3: Payment Patterns (12-month chart)
                PaymentPatternsCard(
                    monthlyData: monthlyPayments,
                    entries: entries,
                    formatCurrency: formatCurrency
                )
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 210)  // Slightly increased to prevent content cutoff
            
            // Custom page indicator dots - now outside and below the cards
            PageIndicator(currentPage: $selectedFinancialCard, totalPages: 3)
        }
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
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(groupedEntries.enumerated()), id: \.0) { index, group in
                    let section = group.0
                    let entries = group.1
                    let isLastSection = index == groupedEntries.count - 1
                    
                    ClientTimelineSectionView(
                        section: section,
                        entries: entries,
                        isLastSection: isLastSection
                    )
                }
                
                // Bottom padding to ensure last items are visible
                Color.clear.frame(height: 80)
            }
        }
        .background(Color.themeBackground)
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

// MARK: - Timeline Section View (matches Notes and Payments style)
struct ClientTimelineSectionView: View {
    let section: String
    let entries: [LogEntry]
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
            
            // Entries with vertical line beside them
            ForEach(entries) { entry in
                HStack(alignment: .top, spacing: 0) {
                    // Vertical line
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2)
                        .padding(.leading, 24)
                    
                    // Entry card
                    NavigationLink(destination: EntryDetailView(entry: entry)) {
                        ClientTimelineEntryCard(entry: entry)
                            .padding(.leading, 10)
                            .padding(.trailing, 16)
                            .padding(.bottom, 16)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Extra space at end of section (except for last one)
            if !isLastSection {
                Color.clear.frame(height: 8)
            }
        }
    }
}

// MARK: - Timeline Entry Card
struct ClientTimelineEntryCard: View {
    let entry: LogEntry
    
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
                
                // Show time
                if let date = entry.date {
                    Text(timeFormatter.string(from: date))
                        .font(.appCaption)
                        .foregroundColor(.themeSecondary)
                }
            }
            
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
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                Text(entry.desc ?? "")
                    .font(.appBody)
                    .foregroundColor(.themePrimary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
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
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
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

// MARK: - Page Indicator
struct PageIndicator: View {
    @Binding var currentPage: Int
    let totalPages: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? Color.themeAccent : Color.gray.opacity(0.3))
                    .frame(
                        width: index == currentPage ? 24 : 8,
                        height: 8
                    )
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - Financial Summary Cards

// Base card view for consistent styling
struct FinancialCardBase<Content: View>: View {
    let headerTitle: String
    let headerSubtitle: String
    let headerColor: Color
    let content: Content
    
    init(
        headerTitle: String,
        headerSubtitle: String,
        headerColor: Color = .themeAccent,
        @ViewBuilder content: () -> Content
    ) {
        self.headerTitle = headerTitle
        self.headerSubtitle = headerSubtitle
        self.headerColor = headerColor
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Fixed height header to ensure consistency across all cards
            VStack(alignment: .leading, spacing: 2) {
                Text(headerTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.themePrimary)
                    .lineLimit(1)
                
                Text(headerSubtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.themeSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: 42, maxHeight: 42, alignment: .leading)
            .padding(.horizontal, 16)
            
            Divider()
                .background(Color.gray.opacity(0.2))
            
            // Content area with consistent frame
            content
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(height: 190)  // Adjusted to prevent content cutoff
        .background(Color.themeCard)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}

// Quick Overview Card - Simplified combined metrics
struct QuickOverviewCard: View {
    let thisMonth: Double
    let thisYear: Double
    let totalPayments: Double
    let paymentCount: Int
    let formatCurrency: (Double, Bool) -> String
    
    var body: some View {
        FinancialCardBase(
            headerTitle: "Overview",
            headerSubtitle: "Key metrics at a glance",
            headerColor: .themeAccent
        ) {
            VStack(spacing: 16) {
                // Top row - main metrics
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("This Month")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.themeSecondary)
                        
                        Text(formatCurrency(thisMonth, false))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.themePrimary)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("This Year")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.themeSecondary)
                        
                        Text(formatCurrency(thisYear, false))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.themeAccent)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                    }
                }
                
                Divider()
                
                // Bottom row - secondary metrics
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("All Time")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.themeSecondary)
                        
                        Text(formatCurrency(totalPayments, false))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.themePrimary)
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Payments")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.themeSecondary)
                        
                        Text("\(paymentCount)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.themePrimary)
                    }
                }
                
                Spacer()
            }
        }
    }
}

// Card 1: Recent Payments Overview
struct PaymentStatusCard: View {
    let client: Client
    let entries: FetchedResults<LogEntry>
    let formatCurrency: (Double, Bool) -> String
    
    // Get last payment info
    private var lastPayment: (amount: Double, date: Date)? {
        let payments = entries.filter { $0.type == LogEntryType.payment.rawValue }
            .compactMap { entry -> (Double, Date)? in
                guard let amount = entry.amount as NSDecimalNumber?,
                      let date = entry.date else { return nil }
                return (amount.doubleValue, date)
            }
            .sorted { $0.1 > $1.1 }
        
        return payments.first
    }
    
    // Get payment frequency
    private var paymentFrequency: String {
        let payments = entries.filter { $0.type == LogEntryType.payment.rawValue }
            .compactMap { $0.date }
            .sorted()
        
        guard payments.count >= 2 else { return "New Client" }
        
        // Calculate average days between payments
        var totalDays = 0
        for i in 1..<payments.count {
            let days = Calendar.current.dateComponents([.day], from: payments[i-1], to: payments[i]).day ?? 0
            totalDays += abs(days)
        }
        
        let avgDays = totalDays / (payments.count - 1)
        
        if avgDays <= 7 { return "Weekly" }
        if avgDays <= 14 { return "Bi-weekly" }
        if avgDays <= 35 { return "Monthly" }
        if avgDays <= 95 { return "Quarterly" }
        return "Irregular"
    }
    
    // Get this month's total
    private var thisMonthTotal: Double {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        
        return entries.filter { entry in
            entry.type == LogEntryType.payment.rawValue &&
            (entry.date ?? Date.distantPast) >= startOfMonth
        }.compactMap { entry in
            (entry.amount as NSDecimalNumber?)?.doubleValue
        }.reduce(0, +)
    }
    
    var body: some View {
        FinancialCardBase(
            headerTitle: "Recent Payments",
            headerSubtitle: "Payment activity",
            headerColor: .themePayment
        ) {
            VStack(alignment: .leading, spacing: 12) {
                // This month's total
                VStack(alignment: .leading, spacing: 4) {
                    Text("This Month")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.themeSecondary)
                    
                    Text(formatCurrency(thisMonthTotal, false))
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.themePrimary)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                }
                
                // Last payment info
                if let last = lastPayment {
                    HStack(spacing: 30) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Last Payment")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.themeSecondary)
                            
                            Text(formatCurrency(last.amount, false))
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.themePayment)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Days Ago")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.themeSecondary)
                            
                            let daysAgo = Calendar.current.dateComponents([.day], from: last.date, to: Date()).day ?? 0
                            Text("\(daysAgo)")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(daysAgo < 30 ? .themePrimary : .orange)
                        }
                    }
                }
                
                Spacer()
                
                // Payment frequency indicator
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 11))
                    Text("\(paymentFrequency) payments")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.themeSecondary)
            }
        }
    }
}

// Card 2: Year Performance
struct YearPerformanceCard: View {
    let thisYear: Double
    let lastYear: Double
    let paymentCount: Int
    let averagePayment: Double
    let formatCurrency: (Double, Bool) -> String
    
    private var yearGrowth: Double? {
        guard lastYear > 0 else { return nil }
        return ((thisYear - lastYear) / lastYear) * 100
    }
    
    var body: some View {
        FinancialCardBase(
            headerTitle: "This Year",
            headerSubtitle: lastYear > 0 ? "Year over year" : "Current performance",
            headerColor: .themeAccent
        ) {
            VStack(alignment: .leading, spacing: 10) {
                // Main amount with growth indicator
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(formatCurrency(thisYear, false))
                            .font(.system(size: 28, weight: .bold, design: .default))
                            .foregroundColor(.themePrimary)
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                        
                        // Comparison to last year
                        if lastYear > 0 {
                            Text("vs \(formatCurrency(lastYear, false)) last year")
                                .font(.system(size: 11))
                                .foregroundColor(.themeSecondary)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    if let growth = yearGrowth {
                        VStack(alignment: .trailing, spacing: 0) {
                            Image(systemName: growth >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.system(size: 10, weight: .bold))
                            Text("\(abs(growth), specifier: "%.0f")%")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(growth >= 0 ? .green : .orange)
                    }
                }
                
                Spacer()
                
                // Stats row
                HStack(spacing: 30) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Payments")
                            .font(.system(size: 11))
                            .foregroundColor(.themeSecondary)
                        Text("\(paymentCount)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.themePrimary)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Average")
                            .font(.system(size: 11))
                            .foregroundColor(.themeSecondary)
                        Text(formatCurrency(averagePayment, false))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.themePrimary)
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)
                    }
                }
            }
        }
    }
}

struct MonthlyTrendCard: View {
    let thisMonth: Double
    let monthlyData: [(month: String, amount: Double)]
    let formatCurrency: (Double, Bool) -> String
    
    private var maxAmount: Double {
        monthlyData.map { $0.amount }.max() ?? 1
    }
    
    private var trend: String {
        guard monthlyData.count >= 2 else { return "→" }
        let recent = monthlyData.suffix(3).map { $0.amount }
        let average = recent.reduce(0, +) / Double(recent.count)
        let previousAverage = monthlyData.prefix(3).map { $0.amount }.reduce(0, +) / 3
        
        if average > previousAverage * 1.1 { return "↗" }
        if average < previousAverage * 0.9 { return "↘" }
        return "→"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Monthly Trend")
                    .font(.headline)
                    .foregroundColor(.themeSecondary)
                
                Spacer()
                
                Text(trend)
                    .font(.system(size: 24))
                    .foregroundColor(trend == "↗" ? .green : trend == "↘" ? .orange : .themeSecondary)
            }
            
            // This month
            VStack(alignment: .leading, spacing: 4) {
                Text("This Month")
                    .font(.caption)
                    .foregroundColor(.themeSecondary)
                Text(formatCurrency(thisMonth, false))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.themePrimary)
            }
            
            Spacer()
            
            // Chart
            if !monthlyData.isEmpty {
                Chart(monthlyData, id: \.month) { data in
                    BarMark(
                        x: .value("Month", data.month),
                        y: .value("Amount", data.amount)
                    )
                    .foregroundStyle(Color.themeAccent.gradient)
                    .cornerRadius(4)
                }
                .frame(height: 80)
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let month = value.as(String.self) {
                                Text(month)
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartYAxis(.hidden)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.themeCard)
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// Card 3: Payment Patterns
struct PaymentPatternsCard: View {
    let monthlyData: [(month: String, amount: Double)]
    let entries: FetchedResults<LogEntry>
    let formatCurrency: (Double, Bool) -> String
    
    private var monthlyAverage: Double {
        let nonZeroMonths = monthlyData.filter { $0.amount > 0 }
        guard !nonZeroMonths.isEmpty else { return 0 }
        return nonZeroMonths.map { $0.amount }.reduce(0, +) / Double(nonZeroMonths.count)
    }
    
    private var bestMonth: (String, Double)? {
        monthlyData.max { $0.amount < $1.amount }
    }
    
    private var lastPaymentDays: Int {
        let payments = entries.filter { $0.type == LogEntryType.payment.rawValue }
            .compactMap { $0.date }
            .sorted()
        
        guard let lastDate = payments.last else { return 999 }
        return Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 999
    }
    
    var body: some View {
        FinancialCardBase(
            headerTitle: "Payment Patterns",
            headerSubtitle: "12-month trends",
            headerColor: .themeAccent
        ) {
            VStack(alignment: .leading, spacing: 8) {
                // Monthly average and best month
                HStack(spacing: 35) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Monthly Avg")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.themeSecondary)
                        
                        Text(formatCurrency(monthlyAverage, false))
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.themePrimary)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                    }
                    
                    if let best = bestMonth {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Best Month")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.themeSecondary)
                            
                            VStack(alignment: .leading, spacing: 0) {
                                Text(formatCurrency(best.1, false))
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.themePayment)
                                    .minimumScaleFactor(0.7)
                                    .lineLimit(1)
                                Text(best.0)
                                    .font(.system(size: 9))
                                    .foregroundColor(.themeSecondary)
                            }
                        }
                    }
                }
                
                // Full year chart - show all 12 months
                if !monthlyData.isEmpty {
                    HStack(alignment: .bottom, spacing: 2) {
                        ForEach(monthlyData, id: \.month) { data in
                            VStack(spacing: 1) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.themeAccent)
                                    .frame(
                                        width: 20,
                                        height: max(4, 40 * (data.amount / max(1, monthlyData.map { $0.amount }.max() ?? 1)))
                                    )
                                
                                // Show month abbreviation - first letter only for space
                                Text(String(data.month.prefix(1)))
                                    .font(.system(size: 7))
                                    .foregroundColor(.themeSecondary)
                            }
                        }
                    }
                    .frame(height: 45)
                    .padding(.vertical, 2)
                }
                
                Spacer(minLength: 2)
                
                // Last payment indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(lastPaymentDays < 30 ? Color.green : lastPaymentDays < 60 ? Color.orange : Color.red)
                        .frame(width: 6, height: 6)
                    Text("Last payment \(lastPaymentDays < 999 ? "\(lastPaymentDays) days ago" : "never")")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.themeSecondary)
                }
            }
        }
    }
}

// Card 4: Client Value
struct ClientValueCard: View {
    let client: Client
    let allTime: Double
    let thisYear: Double
    let paymentCount: Int
    let formatCurrency: (Double, Bool) -> String
    
    private var clientDuration: String {
        // Get the earliest log entry date for this client
        let entries = client.logEntries?.allObjects as? [LogEntry] ?? []
        let earliestDate = entries.compactMap { $0.date }.min()
        
        guard let created = earliestDate else { return "New Client" }
        let days = Calendar.current.dateComponents([.day], from: created, to: Date()).day ?? 0
        
        if days < 30 {
            return "\(days) days"
        } else if days < 365 {
            let months = days / 30
            return "\(months) month\(months == 1 ? "" : "s")"
        } else {
            let years = days / 365
            return "\(years) year\(years == 1 ? "" : "s")"
        }
    }
    
    private var averageProject: Double {
        guard paymentCount > 0 else { return 0 }
        return allTime / Double(paymentCount)
    }
    
    private var clientRank: String {
        // In a real app, this would compare against other clients
        if allTime > 50000 { return "🏆 Top Client" }
        if allTime > 20000 { return "⭐ Key Client" }
        if allTime > 5000 { return "💎 Valued Client" }
        return "🌱 Growing"
    }
    
    var body: some View {
        FinancialCardBase(
            headerTitle: "Client Value",
            headerSubtitle: "Lifetime metrics",
            headerColor: .themePrimary
        ) {
            VStack(alignment: .leading, spacing: 10) {
                // Total lifetime value
                VStack(alignment: .leading, spacing: 2) {
                    Text("Lifetime Value")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.themeSecondary)
                    
                    Text(formatCurrency(allTime, false))
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.themePrimary)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
                
                // Stats row
                HStack(spacing: 35) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Avg Project")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.themeSecondary)
                        
                        Text(formatCurrency(averageProject, false))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.themePrimary)
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Client Since")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.themeSecondary)
                        
                        Text(clientDuration)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.themePrimary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Client rank badge with better sizing
                HStack {
                    Text(clientRank)
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.themeAccent.opacity(0.15))
                        )
                }
            }
        }
    }
}

struct AllTimeStatsCard: View {
    let allTime: Double
    let paymentCount: Int
    let averagePayment: Double
    let hourlyRate: NSDecimalNumber?
    let formatCurrency: (Double, Bool) -> String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text("All-Time Stats")
                .font(.headline)
                .foregroundColor(.themeSecondary)
            
            // Total earned
            VStack(alignment: .leading, spacing: 4) {
                Text("Total Earned")
                    .font(.caption)
                    .foregroundColor(.themeSecondary)
                Text(formatCurrency(allTime, false))
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.themePrimary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Stats grid
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Payments")
                        .font(.caption)
                        .foregroundColor(.themeSecondary)
                    Text("\(paymentCount)")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.themePrimary)
                }
                
                if let rate = hourlyRate, rate.doubleValue > 0 {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hourly Rate")
                            .font(.caption)
                            .foregroundColor(.themeSecondary)
                        Text("$\(rate.doubleValue, specifier: "%.0f")/hr")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.themeAccent)
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.themeCard)
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

#Preview {
    NavigationStack {
        ClientDetailView(client: Client())
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
} 

