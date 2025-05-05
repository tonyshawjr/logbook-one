import SwiftUI
import CoreData
import Charts

// Time period for revenue filtering
enum TimePeriod: String, CaseIterable, Identifiable {
    case month = "This Month"
    case quarter = "This Quarter"
    case year = "This Year"
    case all = "All Time"
    
    var id: String { self.rawValue }
}

// MARK: - Payments Header View
struct PaymentsHeaderView: View {
    var body: some View {
        HStack {
            // Title - "Payments" with styling matching Notes header
            Text("Payments")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.themePrimary)
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .background(Color.themeBackground)
    }
}

struct PaymentsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedClient: Client? = nil
    @State private var selectedPeriod: TimePeriod = .month
    @State private var selectedTag: String? = "#all"
    @State private var showingAddPayment = false
    @State private var showingClientPicker = false
    @State private var showingPeriodPicker = false
    
    // Get all unique hashtags from the payments
    private var allHashtags: [String] {
        var tags = ["#all"]
        
        // Payments source for extracting hashtags - filter by client if one is selected
        let paymentSource: [LogEntry]
        if let selectedClient = selectedClient {
            // Only use payments from selected client
            paymentSource = payments(excluding: [])
        } else {
            // Use all payments if no client is selected
            paymentSource = payments(excluding: [])
        }
        
        // Extract hashtags from the payments descriptions
        tags.append(contentsOf: HashtagExtractor.uniqueHashtags(from: paymentSource))
        return tags
    }
    
    // Custom fetch request that updates whenever filter changes
    func payments(excluding: [NSPredicate] = []) -> [LogEntry] {
        // Build the predicate based on filters
        var predicates: [NSPredicate] = []
        
        // Always filter for payment type
        predicates.append(NSPredicate(format: "type == %d", LogEntryType.payment.rawValue))
        
        // Filter by time period
        if let datePredicate = getDatePredicate(for: selectedPeriod) {
            predicates.append(datePredicate)
        }
        
        // Filter by client if selected
        if let client = selectedClient {
            predicates.append(NSPredicate(format: "client == %@", client))
        }
        
        // Filter by hashtag if selected
        if let tag = selectedTag, tag != "#all" {
            // Either the tag field contains the hashtag, or the description contains the hashtag
            let tagPredicate = NSPredicate(format: "tag CONTAINS[c] %@ OR desc CONTAINS[c] %@", tag, tag)
            predicates.append(tagPredicate)
        }
        
        // Add any exclusion predicates
        for predicate in excluding {
            predicates.append(NSCompoundPredicate(notPredicateWithSubpredicate: predicate))
        }
        
        // Combine predicates with AND
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        // Fetch request
        let fetchRequest: NSFetchRequest<LogEntry> = LogEntry.fetchRequest()
        fetchRequest.predicate = compoundPredicate
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \LogEntry.date, ascending: false)]
        
        do {
            return try viewContext.fetch(fetchRequest)
        } catch {
            print("Error fetching payments: \(error)")
            return []
        }
    }
    
    // Group payments by date for timeline view - similar to NotesView
    private var groupedPayments: [(String, [LogEntry])] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        // Get payments with current filters
        let filteredPayments = payments()
        
        let grouped = Dictionary(grouping: filteredPayments) { payment -> String in
            guard let date = payment.date else { return "Undated" }
            
            let paymentDate = calendar.startOfDay(for: date)
            
            if calendar.isDate(paymentDate, inSameDayAs: today) {
                return "Today"
            } else if calendar.isDate(paymentDate, inSameDayAs: yesterday) {
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
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Add Payments header at the top
                PaymentsHeaderView()
                
                // Revenue card
                revenueCard
                
                // Combined filters section
                HStack(spacing: 12) {
                    // Period filter dropdown
                    Button(action: {
                        showingPeriodPicker = true
                    }) {
                        HStack {
                            Text(selectedPeriod.rawValue)
                                .font(.appSubheadline)
                                .foregroundColor(.themePrimary)
                            
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.themeSecondary)
                                .padding(.leading, 2)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.themeCard)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                    
                    // Client filter dropdown
                    Button(action: {
                        showingClientPicker = true
                    }) {
                        HStack {
                            Text(selectedClient?.name ?? "All Clients")
                                .font(.appSubheadline)
                                .foregroundColor(.themePrimary)
                            
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.themeSecondary)
                                .padding(.leading, 2)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.themeCard)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(Color.themeBackground)
                .sheet(isPresented: $showingClientPicker) {
                    ClientPickerView(
                        clients: clientsWithPayments,
                        selectedClient: $selectedClient
                    )
                }
                .sheet(isPresented: $showingPeriodPicker) {
                    PeriodPickerView(
                        selectedPeriod: $selectedPeriod
                    )
                }
                
                // Hashtag filter view (if we have any tags)
                if allHashtags.count > 1 { // More than just "#all"
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
                        .padding(.bottom, 10)
                    }
                    .background(Color.themeBackground)
                }
                
                // Payment history title
                HStack {
                    Text("Payment History")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.themePrimary)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 6)
                
                // Payments list with timeline
                if payments().isEmpty {
                    emptyStateView
                } else {
                    // Updated to use timeline style like Notes view
                    PaymentsTimelineView(groupedPayments: groupedPayments)
                }
            }
            .background(Color.themeBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .toolbarBackground(Color.themeBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showingAddPayment) {
                // Pre-select the payment type
                LogEntryFormView(selectedType: .payment, client: selectedClient)
            }
        }
    }
    
    private var revenueCard: some View {
        VStack(spacing: 16) {
            // Header with total
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedPeriod.rawValue)
                        .font(.appCaption)
                        .foregroundColor(.themeSecondary)
                    
                    Text(formatCurrency(totalAmount))
                        .font(.system(size: 34, weight: .bold, design: .default))
                        .foregroundColor(.themePrimary)
                }
                
                Spacer()
                
                if let client = selectedClient {
                    Text(client.name ?? "")
                        .font(.appSubheadline)
                        .foregroundColor(.themeAccent)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.themeAccent.opacity(0.1))
                        .cornerRadius(20)
                }
            }
            
            Divider()
                .padding(.vertical, 4)
            
            HStack {
                // Payment count
                Text("\(payments().count) payment\(payments().count == 1 ? "" : "s")")
                    .font(.appCaption)
                    .foregroundColor(.themeSecondary)
                
                Spacer()
                
                // Avg payment
                if payments().count > 0 {
                    Text("Avg: \(formatCurrency(averageAmount))")
                        .font(.appCaption)
                        .foregroundColor(.themeSecondary)
                }
            }
        }
        .padding()
        .background(Color.themeCard)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "dollarsign.circle")
                .font(.system(size: 70))
                .foregroundColor(Color.themeSecondary.opacity(0.3))
                .padding(.bottom, 10)
                .padding(.top, 20)
            
            Text("No Payments Found")
                .font(.appTitle2)
                .foregroundColor(.themePrimary)
            
            Text(emptyStateMessage)
                .font(.appBody)
                .foregroundColor(.themeSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: { showingAddPayment = true }) {
                Text("Add New Payment")
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
            return "You don't have any payments for \(client.name ?? "this client") \(selectedPeriod == .all ? "" : "in \(selectedPeriod.rawValue.lowercased())")."
        } else {
            return "You don't have any payments \(selectedPeriod == .all ? "" : "in \(selectedPeriod.rawValue.lowercased())")."
        }
    }
    
    private var clientsWithPayments: [Client] {
        let fetchRequest: NSFetchRequest<Client> = Client.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "ANY logEntries.type == %d", LogEntryType.payment.rawValue)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Client.name, ascending: true)]
        
        do {
            return try viewContext.fetch(fetchRequest)
        } catch {
            print("Error fetching clients with payments: \(error)")
            return []
        }
    }
    
    private var totalAmount: Double {
        payments().reduce(0) { total, payment in
            if let amount = payment.amount as NSDecimalNumber? {
                return total + amount.doubleValue
            }
            return total
        }
    }
    
    private var averageAmount: Double {
        payments().isEmpty ? 0 : totalAmount / Double(payments().count)
    }
    
    private func getDatePredicate(for period: TimePeriod) -> NSPredicate? {
        let calendar = Calendar.current
        let now = Date()
        var startDate: Date?
        
        switch period {
        case .month:
            // Get the first day of the current month
            startDate = calendar.date(from: calendar.dateComponents([.year, .month], from: now))
        case .quarter:
            // Calculate the first day of the current quarter
            let month = calendar.component(.month, from: now)
            let quarter = (month - 1) / 3
            let startMonth = quarter * 3 + 1
            var components = calendar.dateComponents([.year], from: now)
            components.month = startMonth
            components.day = 1
            startDate = calendar.date(from: components)
        case .year:
            // Get the first day of the current year
            startDate = calendar.date(from: calendar.dateComponents([.year], from: now))
        case .all:
            return nil
        }
        
        guard let start = startDate else { return nil }
        return NSPredicate(format: "date >= %@", start as NSDate)
    }
    
    private func getPaymentData() -> [PaymentDataPoint] {
        var result: [PaymentDataPoint] = []
        
        for payment in payments() {
            if let date = payment.date,
               let amount = payment.amount as NSDecimalNumber? {
                result.append(PaymentDataPoint(date: date, amount: amount.doubleValue))
            }
        }
        
        return result.sorted { $0.date < $1.date }
    }
}

struct PaymentDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Double
}

struct PaymentRow: View {
    @ObservedObject var payment: LogEntry
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    var body: some View {
        // Ensure we only show rows for valid managed objects
        if payment.managedObjectContext != nil {
            NavigationLink(destination: EntryDetailView(entry: payment)) {
                VStack(alignment: .leading, spacing: 12) {
                    // Client name and date
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            if let client = payment.client {
                                Text(client.name ?? "Client")
                                    .font(.system(.headline))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.themePrimary)
                            }
                            
                            // Description
                            Text(payment.desc ?? "")
                                .font(.subheadline)
                                .foregroundColor(.themeSecondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        if let date = payment.date {
                            Text(dateFormatter.string(from: date))
                                .font(.footnote)
                                .foregroundColor(.themeSecondary)
                        }
                    }
                    
                    // Amount in green
                    if let amount = payment.amount as NSDecimalNumber? {
                        Text(formatCurrency(amount.doubleValue))
                            .font(.system(.title3, design: .rounded).weight(.bold))
                            .foregroundColor(.themePayment)
                    }
                    
                    // Show tag if it exists
                    if let tag = payment.tag, !tag.isEmpty {
                        Text(tag)
                            .font(.footnote)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.themeCard)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal)
            .padding(.bottom, 8)
        } else {
            EmptyView()
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

struct ClientPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let clients: [Client]
    @Binding var selectedClient: Client?
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button(action: {
                        selectedClient = nil
                        dismiss()
                    }) {
                        HStack {
                            Text("All Clients")
                                .font(.body)
                                .foregroundColor(.themePrimary)
                            
                            Spacer()
                            
                            if selectedClient == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.themeAccent)
                            }
                        }
                    }
                }
                
                Section {
                    ForEach(clients) { client in
                        Button(action: {
                            selectedClient = client
                            dismiss()
                        }) {
                            HStack {
                                Text(client.name ?? "Unnamed Client")
                                    .font(.body)
                                    .foregroundColor(.themePrimary)
                                
                                Spacer()
                                
                                if selectedClient == client {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.themeAccent)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PeriodPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedPeriod: TimePeriod
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(TimePeriod.allCases) { period in
                        Button(action: {
                            selectedPeriod = period
                            dismiss()
                        }) {
                            HStack {
                                Text(period.rawValue)
                                    .font(.body)
                                    .foregroundColor(.themePrimary)
                                
                                Spacer()
                                
                                if selectedPeriod == period {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.themeAccent)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Time Period")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Payments Timeline View
struct PaymentsTimelineView: View {
    let groupedPayments: [(String, [LogEntry])]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Break up the complex expression by using indices directly
                ForEach(0..<groupedPayments.count, id: \.self) { index in
                    let section = groupedPayments[index].0
                    let paymentsInSection = groupedPayments[index].1
                    let isLastSection = index == groupedPayments.count - 1
                    
                    PaymentsTimelineSectionView(
                        section: section,
                        payments: paymentsInSection,
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

// MARK: - Payments Timeline Section View
struct PaymentsTimelineSectionView: View {
    let section: String
    let payments: [LogEntry]
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
            
            // Payments with vertical line beside them
            ForEach(payments) { payment in
                HStack(alignment: .top, spacing: 0) {
                    // Vertical line
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2)
                        .padding(.leading, 24)
                    
                    // Payment card - use the existing PaymentRow styling but adjusted for timeline
                    PaymentTimelineCard(payment: payment)
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

// MARK: - Payment Timeline Card
struct PaymentTimelineCard: View {
    @ObservedObject var payment: LogEntry
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
    
    var body: some View {
        NavigationLink(destination: EntryDetailView(entry: payment)) {
            VStack(alignment: .leading, spacing: 12) {
                // Client name and description
                VStack(alignment: .leading, spacing: 6) {
                    if let client = payment.client {
                        Text(client.name ?? "Client")
                            .font(.system(.headline))
                            .fontWeight(.semibold)
                            .foregroundColor(.themePrimary)
                    }
                    
                    // Use FormattedNoteText to display hashtags with formatting
                    if let desc = payment.desc {
                        FormattedNoteText(text: desc)
                            .lineLimit(2)
                    }
                }
                
                // Amount with trailing time
                HStack {
                    if let amount = payment.amount as NSDecimalNumber? {
                        Text(formatCurrency(amount.doubleValue))
                            .font(.system(.title3, design: .rounded).weight(.bold))
                            .foregroundColor(.themePayment)
                    }
                    
                    Spacer()
                    
                    // Time only (date is in the section header)
                    if let date = payment.date {
                        Text(dateFormatter.string(from: date))
                            .font(.appCaption)
                            .foregroundColor(.themeSecondary)
                    }
                }
                
                // Show tag if it exists (not as a hashtag in description)
                // Only show if it's not already in the description as a hashtag
                if let tag = payment.tag, !tag.isEmpty, 
                   let desc = payment.desc, !desc.localizedCaseInsensitiveContains(tag) {
                    Text(tag)
                        .font(.footnote)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
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
    PaymentsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 