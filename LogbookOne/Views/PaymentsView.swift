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

struct PaymentsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedClient: Client? = nil
    @State private var selectedPeriod: TimePeriod = .month
    @State private var showingAddPayment = false
    @State private var showingClientPicker = false
    @State private var showingPeriodPicker = false
    
    // Custom fetch request that updates whenever filter changes
    var payments: [LogEntry] {
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
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
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
                                .foregroundColor(.primaryText)
                            
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondaryText)
                                .padding(.leading, 2)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.cardBackground)
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
                                .foregroundColor(.primaryText)
                            
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondaryText)
                                .padding(.leading, 2)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.cardBackground)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(Color.appBackground)
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
                
                // Payment history title
                HStack {
                    Text("Payment History")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primaryText)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 6)
                
                // Payments list
                if payments.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(payments.filter { $0.managedObjectContext != nil }) { payment in
                                PaymentRow(payment: payment)
                            }
                        }
                        .padding(.top, 6)
                    }
                    .background(Color.appBackground)
                }
            }
            .background(Color.appBackground)
            .navigationTitle("Payments")
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
                        .foregroundColor(.secondaryText)
                    
                    Text(formatCurrency(totalAmount))
                        .font(.system(size: 34, weight: .bold, design: .default))
                        .foregroundColor(.primaryText)
                }
                
                Spacer()
                
                if let client = selectedClient {
                    Text(client.name ?? "")
                        .font(.appSubheadline)
                        .foregroundColor(.appAccent)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.appAccent.opacity(0.1))
                        .cornerRadius(20)
                }
            }
            
            Divider()
                .padding(.vertical, 4)
            
            HStack {
                // Payment count
                Text("\(payments.count) payment\(payments.count == 1 ? "" : "s")")
                    .font(.appCaption)
                    .foregroundColor(.secondaryText)
                
                Spacer()
                
                // Avg payment
                if payments.count > 0 {
                    Text("Avg: \(formatCurrency(averageAmount))")
                        .font(.appCaption)
                        .foregroundColor(.secondaryText)
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
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
                .foregroundColor(Color.secondaryText.opacity(0.3))
                .padding(.bottom, 10)
                .padding(.top, 20)
            
            Text("No Payments Found")
                .font(.appTitle2)
                .foregroundColor(.primaryText)
            
            Text(emptyStateMessage)
                .font(.appBody)
                .foregroundColor(.secondaryText)
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
        payments.reduce(0) { total, payment in
            if let amount = payment.amount as NSDecimalNumber? {
                return total + amount.doubleValue
            }
            return total
        }
    }
    
    private var averageAmount: Double {
        payments.isEmpty ? 0 : totalAmount / Double(payments.count)
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
        
        for payment in payments {
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
                                    .foregroundColor(.primaryText)
                            }
                            
                            // Description
                            Text(payment.desc ?? "")
                                .font(.subheadline)
                                .foregroundColor(.secondaryText)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        if let date = payment.date {
                            Text(dateFormatter.string(from: date))
                                .font(.footnote)
                                .foregroundColor(.secondaryText)
                        }
                    }
                    
                    // Amount in green
                    if let amount = payment.amount as NSDecimalNumber? {
                        Text(formatCurrency(amount.doubleValue))
                            .font(.system(.title3, design: .rounded).weight(.bold))
                            .foregroundColor(.paymentColor)
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
                .background(Color.cardBackground)
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
                                .foregroundColor(.primaryText)
                            
                            Spacer()
                            
                            if selectedClient == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.appAccent)
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
                                    .foregroundColor(.primaryText)
                                
                                Spacer()
                                
                                if selectedClient == client {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.appAccent)
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
                                    .foregroundColor(.primaryText)
                                
                                Spacer()
                                
                                if selectedPeriod == period {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.appAccent)
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

#Preview {
    PaymentsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 