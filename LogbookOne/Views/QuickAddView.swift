import SwiftUI
import CoreData

// Task Date Picker View
struct TaskDatePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDate: Date
    @State private var monthDisplay: Date
    @State private var showTimeSelection: Bool = false
    @State private var selectedTime: Date
    
    init(selectedDate: Binding<Date>) {
        self._selectedDate = selectedDate
        self._monthDisplay = State(initialValue: selectedDate.wrappedValue)
        self._selectedTime = State(initialValue: selectedDate.wrappedValue)
        
        // Check if the date has a non-default time
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedDate.wrappedValue)
        
        // If time is not midnight, show time selection by default
        let hasCustomTime = !(timeComponents.hour == 0 && timeComponents.minute == 0) && 
                            !(timeComponents.hour == 9 && timeComponents.minute == 0)
        self._showTimeSelection = State(initialValue: hasCustomTime)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Quick options
                HStack(spacing: 16) {
                    // Today button
                    dateOptionButton(
                        label: "Today",
                        icon: "sun.max",
                        isSelected: Calendar.current.isDateInToday(selectedDate),
                        action: {
                            selectedDate = preserveTimeOrDefault(Date())
                        }
                    )
                    
                    // Tomorrow button
                    dateOptionButton(
                        label: "Tomorrow",
                        icon: "arrow.right",
                        isSelected: Calendar.current.isDateInTomorrow(selectedDate),
                        action: {
                            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                            selectedDate = preserveTimeOrDefault(tomorrow)
                        }
                    )
                    
                    // Next Week button
                    dateOptionButton(
                        label: "Next Week",
                        icon: "calendar",
                        isSelected: isNextWeek(selectedDate),
                        action: {
                            // Find a day next week (Monday-Friday)
                            let randomDaysToAdd = Int.random(in: 3...7)
                            let nextWeek = Calendar.current.date(byAdding: .day, value: randomDaysToAdd, to: Date()) ?? Date()
                            selectedDate = preserveTimeOrDefault(nextWeek)
                        }
                    )
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                Divider()
                
                // Month and year header with arrows
                HStack {
                    Text(monthYearFormatter.string(from: monthDisplay))
                        .font(.title3.bold())
                    
                    Spacer()
                    
                    Button(action: previousMonth) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.green)
                            .padding(8)
                    }
                    
                    Button(action: nextMonth) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.green)
                            .padding(8)
                    }
                }
                .padding(.horizontal)
                
                // Calendar grid
                CalendarGridView(
                    selectedDate: Binding(
                        get: { selectedDate },
                        set: { newDate in
                            selectedDate = preserveTimeOrDefault(newDate)
                            // Update selectedTime to match the time part of selectedDate
                            if showTimeSelection {
                                selectedTime = selectedDate
                            }
                        }
                    ),
                    monthDisplay: $monthDisplay
                )
                .padding(.horizontal)
                
                // Time selection toggle
                Toggle(isOn: $showTimeSelection.animation()) {
                    Text("Set a specific time")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal)
                .toggleStyle(SwitchToggleStyle(tint: .green))
                .onChange(of: showTimeSelection) { oldValue, newValue in
                    if newValue {
                        // When enabling time selection, initialize with current time if at default
                        let calendar = Calendar.current
                        let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedDate)
                        
                        if (timeComponents.hour == 0 && timeComponents.minute == 0) ||
                           (timeComponents.hour == 9 && timeComponents.minute == 0) {
                            // If currently at a default time, use current time
                            let now = Date()
                            let nowTimeComponents = calendar.dateComponents([.hour, .minute], from: now)
                            
                            var dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
                            dateComponents.hour = nowTimeComponents.hour
                            dateComponents.minute = nowTimeComponents.minute
                            
                            if let dateWithCurrentTime = calendar.date(from: dateComponents) {
                                selectedTime = dateWithCurrentTime
                                selectedDate = dateWithCurrentTime
                            }
                        } else {
                            // If a custom time was already set, keep it
                            selectedTime = selectedDate
                        }
                    } else {
                        // When disabling time selection, set to default 9 AM
                        let calendar = Calendar.current
                        var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
                        components.hour = 9
                        components.minute = 0
                        
                        if let defaultTime = calendar.date(from: components) {
                            selectedDate = defaultTime
                            selectedTime = defaultTime
                        }
                    }
                }
                
                // Time picker (only shown if toggle is on)
                if showTimeSelection {
                    DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(WheelDatePickerStyle())
                        .labelsHidden()
                        .frame(maxHeight: 150)
                        .onChange(of: selectedTime) { oldValue, newValue in
                            // Keep the date part from selectedDate and time part from selectedTime
                            updateDateWithSelectedTime()
                        }
                }
                
                Spacer()
            }
            .padding(.top, 16)
            .navigationTitle("Task date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // If showing time selection, ensure we use the currently selected time
                        if showTimeSelection {
                            updateDateWithSelectedTime()
                        }
                        dismiss()
                    }
                    .foregroundColor(.green)
                }
            }
        }
    }
    
    // Helper to update the date with the selected time
    private func updateDateWithSelectedTime() {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)
        
        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        
        if let combinedDate = calendar.date(from: combinedComponents) {
            selectedDate = combinedDate
        }
    }
    
    // Helper to preserve time when changing dates if time was specifically set
    private func preserveTimeOrDefault(_ newDate: Date) -> Date {
        if showTimeSelection {
            // If time selection is enabled, preserve the selected time
            let calendar = Calendar.current
            let currentTimeComponents = calendar.dateComponents([.hour, .minute], from: selectedDate)
            var newComponents = calendar.dateComponents([.year, .month, .day], from: newDate)
            
            newComponents.hour = currentTimeComponents.hour
            newComponents.minute = currentTimeComponents.minute
            
            return calendar.date(from: newComponents) ?? newDate
        } else {
            // Default time (9 AM)
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: newDate)
            components.hour = 9
            components.minute = 0
            
            return calendar.date(from: components) ?? newDate
        }
    }
    
    // Date formatter for month and year
    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
    
    // Check if date is next week
    private func isNextWeek(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let nextWeekStart = calendar.date(byAdding: .day, value: 2, to: Date()) ?? Date()
        let nextWeekEnd = calendar.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        return date >= nextWeekStart && date <= nextWeekEnd
    }
    
    // Previous month action
    private func previousMonth() {
        withAnimation {
            monthDisplay = Calendar.current.date(byAdding: .month, value: -1, to: monthDisplay) ?? monthDisplay
        }
    }
    
    // Next month action
    private func nextMonth() {
        withAnimation {
            monthDisplay = Calendar.current.date(byAdding: .month, value: 1, to: monthDisplay) ?? monthDisplay
        }
    }
    
    // Quick date option button
    private func dateOptionButton(label: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                
                Text(label)
                    .font(.system(size: 16))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? Color.green.opacity(0.15) : Color(UIColor.secondarySystemBackground))
            .foregroundColor(isSelected ? .green : .primary)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
            )
        }
    }
}

// Calendar Grid View
struct CalendarGridView: View {
    @Binding var selectedDate: Date
    @Binding var monthDisplay: Date
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
    
    var body: some View {
        VStack(spacing: 20) {
            // Day headers
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar days
            let days = daysInMonth()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 16) {
                ForEach(days, id: \.self) { day in
                    if day.day != 0 {
                        Button(action: {
                            // Preserve time when selecting a new date
                            let selectedTimeComponents = calendar.dateComponents([.hour, .minute], from: selectedDate)
                            var newDateComponents = calendar.dateComponents([.year, .month, .day], from: day.date)
                            
                            // Keep the existing time components if they exist
                            newDateComponents.hour = selectedTimeComponents.hour
                            newDateComponents.minute = selectedTimeComponents.minute
                            
                            if let newDateWithTime = calendar.date(from: newDateComponents) {
                                selectedDate = newDateWithTime
                            } else {
                                selectedDate = day.date
                            }
                        }) {
                            Text("\(day.day)")
                                .font(.system(size: 18))
                                .foregroundColor(isSelected(day.date) ? .white : (isToday(day.date) ? .green : .primary))
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(isSelected(day.date) ? Color.green : Color.clear)
                                )
                        }
                    } else {
                        Text("")
                            .frame(width: 40, height: 40)
                    }
                }
            }
        }
    }
    
    // Check if a date is today
    private func isToday(_ date: Date) -> Bool {
        return calendar.isDateInToday(date)
    }
    
    // Check if a date is selected
    private func isSelected(_ date: Date) -> Bool {
        return calendar.isDate(date, inSameDayAs: selectedDate)
    }
    
    // Generate days in the month
    private func daysInMonth() -> [CalendarDay] {
        var days = [CalendarDay]()
        
        let range = calendar.range(of: .day, in: .month, for: monthDisplay)!
        let numDays = range.count
        
        // Get the first day of the month
        let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDisplay))!
        
        // Get the weekday of the first day (0 = Sunday, 1 = Monday, etc.)
        let firstWeekday = calendar.component(.weekday, from: firstDay) - 1
        
        // Add empty days for the beginning of the month
        for _ in 0..<firstWeekday {
            days.append(CalendarDay(day: 0, date: Date()))
        }
        
        // Add the days of the month
        for day in 1...numDays {
            let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay)!
            days.append(CalendarDay(day: day, date: date))
        }
        
        return days
    }
    
    // Helper struct for calendar days
    struct CalendarDay: Hashable {
        let day: Int
        let date: Date
    }
}

struct QuickAddView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("lastUsedEntryType") private var lastUsedEntryType = 0
    @State private var selectedType: LogEntryType
    @State private var description: String = ""
    @State private var amount: String = ""
    @State private var selectedTag: String = ""
    @State private var dueDate: Date = Date().addingTimeInterval(86400) // Tomorrow
    @State private var showDueDate: Bool = false
    @State private var isComplete: Bool = false
    @State private var selectedClient: Client?
    @State private var showClientPicker: Bool = false
    @State private var showDatePicker: Bool = false
    @State private var showingSavedAnimation = false
    
    // For auto-focusing the text field
    @FocusState private var isDescriptionFocused: Bool
    
    // Common tags
    private let quickTags = ["Work", "Personal", "Urgent", "Design", "Meeting", "Follow-up", "Website", "Admin", "Invoice"]
    
    // Initialize with the last used type
    init() {
        let savedType = UserDefaults.standard.integer(forKey: "lastUsedEntryType")
        _selectedType = State(initialValue: LogEntryType(rawValue: Int16(savedType)) ?? .task)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with title and cancel button
            HStack {
                Text("Drop it here.")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    ZStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 24)
            .padding(.bottom, 32)
            
            // Type selector - Simple row of options
            HStack(spacing: 8) {
                ForEach(LogEntryType.allCases) { type in
                    Button(action: {
                        withAnimation {
                            selectedType = type
                            lastUsedEntryType = Int(type.rawValue)
                            showDueDate = type == .task
                            isDescriptionFocused = true
                        }
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: iconForType(type))
                                .font(.system(size: 20))
                                .foregroundColor(selectedType == type ? .white : .green)
                            
                            Text(type.displayName)
                                .font(.subheadline)
                                .fontWeight(selectedType == type ? .semibold : .regular)
                                .foregroundColor(selectedType == type ? .white : .green)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedType == type ? Color.green : Color.green.opacity(0.05))
                        )
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
            
            // Main input form
            VStack(spacing: 0) {
                // Description field - clean without border
                TextField("", text: $description, axis: .vertical)
                    .placeholder(when: description.isEmpty) {
                        Text(placeholderForType)
                            .foregroundColor(.secondary)
                    }
                    .font(.title3)
                    .padding(.horizontal, 4)
                    .focused($isDescriptionFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        if !description.isEmpty {
                            saveEntry()
                        }
                    }
                    .frame(minHeight: 100)
                
                Spacer()
                
                // Bottom fields area
                VStack(spacing: 16) {
                    // Payment fields & client/date selection
                    HStack(spacing: 16) {
                        // Client selection for all types
                        Button(action: {
                            showClientPicker = true
                        }) {
                            HStack {
                                Text(selectedClient?.name ?? "Select Client")
                                    .foregroundColor(selectedClient != nil ? .primary : .secondary)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                        }
                        
                        Spacer(minLength: 0)
                        
                        // Date picker for tasks
                        if selectedType == .task {
                            if showDueDate {
                                Button(action: {
                                    showDatePicker = true
                                }) {
                                    HStack(spacing: 4) {
                                        if Calendar.current.isDateInToday(dueDate) {
                                            Text("Today")
                                                .foregroundColor(.green)
                                        } else if Calendar.current.isDateInTomorrow(dueDate) {
                                            Text("Tomorrow")
                                                .foregroundColor(.green)
                                        } else {
                                            Text(formattedDate(dueDate))
                                                .foregroundColor(.green)
                                                .lineLimit(1)
                                        }
                                        
                                        Image(systemName: "calendar")
                                            .foregroundColor(.green)
                                            .font(.system(size: 14))
                                            .padding(.leading, 2)
                                    }
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 12)
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .cornerRadius(8)
                                    .frame(maxWidth: 150)
                                }
                                
                                // Delete date button
                                Button(action: {
                                    // Reset date to tomorrow
                                    dueDate = Date().addingTimeInterval(86400)
                                    // Toggle due date flag
                                    showDueDate = false
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 18))
                                }
                                .padding(.leading, -8)
                            } else {
                                // Add due date button
                                Button(action: {
                                    showDueDate = true
                                    showDatePicker = true
                                }) {
                                    HStack {
                                        Image(systemName: "calendar.badge.plus")
                                            .foregroundColor(.green)
                                        Text("Add Due Date")
                                            .foregroundColor(.green)
                                            .font(.subheadline)
                                    }
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 12)
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .cornerRadius(8)
                                    .frame(maxWidth: 150)
                                }
                            }
                        }
                        
                        // Payment amount field
                        if selectedType == .payment {
                            HStack {
                                Text("$")
                                    .foregroundColor(.secondary)
                                    .font(.headline)
                                
                                TextField("0.00", text: $amount)
                                    .keyboardType(.decimalPad)
                                    .font(.headline)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                        }
                    }
                    
                    // Save button
                    Button(action: saveEntry) {
                        Text("Save")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(isFormValid ? Color.green : Color.green.opacity(0.5))
                            .cornerRadius(12)
                    }
                    .disabled(!isFormValid)
                }
                .padding(.bottom, 16)
            }
            .padding(.horizontal)
        }
        .background(Color(UIColor.systemBackground))
        // Modals and pickers
        .sheet(isPresented: $showClientPicker) {
            QuickClientPickerView(selectedClient: $selectedClient)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showDatePicker) {
            TaskDatePickerView(selectedDate: $dueDate)
                .presentationDetents([.large])
        }
        .overlay {
            if showingSavedAnimation {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                    .overlay {
                        VStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                            
                            Text("Saved!")
                                .font(.title3.weight(.medium))
                                .foregroundColor(.green)
                                .padding(.top, 4)
                        }
                    }
            }
        }
        .onAppear {
            // Auto-focus the description field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isDescriptionFocused = true
            }
            
            // Set due date visibility for tasks
            showDueDate = selectedType == .task
        }
    }
    
    // Dynamic conversational placeholders based on type
    private var placeholderForType: String {
        switch selectedType {
        case .task: return "What do you need to knock out?"
        case .note: return "Jot down your thoughts..."
        case .payment: return "What's this payment for?"
        }
    }
    
    private func saveEntry() {
        let entry = LogEntry(context: viewContext)
        entry.id = UUID()
        entry.type = selectedType.rawValue
        entry.desc = description
        
        // Set creation date for all entries - ensure we have the current time
        let now = Date()
        print("Setting creationDate to: \(now)") // Debug
        entry.setValue(now, forKey: "creationDate")
        
        // Double check the creation date was set
        if let creationDate = entry.value(forKey: "creationDate") as? Date {
            print("Verified creationDate is set to: \(creationDate)")
        } else {
            print("WARNING: creationDate was not set properly")
        }
        
        // Set the date field appropriately based on type
        switch selectedType {
        case .task:
            // For tasks, if due date is enabled, use that, otherwise use current date
            if showDueDate {
                // If the time wasn't specifically set, set to 9:00 AM (or beginning of day)
                let calendar = Calendar.current
                let timeComponents = calendar.dateComponents([.hour, .minute], from: dueDate)
                
                if timeComponents.hour == 0 && timeComponents.minute == 0 {
                    // Set to 9:00 AM of the selected day if no specific time
                    var components = calendar.dateComponents([.year, .month, .day], from: dueDate)
                    components.hour = 9
                    components.minute = 0
                    
                    if let nineAM = calendar.date(from: components) {
                        entry.date = nineAM
                    } else {
                        entry.date = dueDate
                    }
                } else {
                    // Keep existing time if it was specifically set
                    entry.date = dueDate
                }
            } else {
                entry.date = now
            }
        case .note, .payment:
            // For notes and payments, use current date
            entry.date = now
        }
        
        entry.client = selectedClient
        entry.tag = selectedTag.isEmpty ? nil : selectedTag
        
        // Handle task-specific properties
        if selectedType == .task {
            entry.isComplete = isComplete
            // The date is already set in the switch statement above
        }
        
        // Handle payment-specific properties
        if selectedType == .payment, let amountValue = Decimal(string: amount) {
            entry.amount = NSDecimalNumber(decimal: amountValue)
        }
        
        do {
            try viewContext.save()
            
            // Show success animation
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showingSavedAnimation = true
            }
            
            // Add success haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            // Dismiss after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                dismiss()
            }
        } catch {
            print("Error saving quick entry: \(error)")
        }
    }
    
    private func iconForType(_ type: LogEntryType) -> String {
        switch type {
        case .task: return "checkmark.square"
        case .note: return "doc.text"
        case .payment: return "dollarsign.circle"
        }
    }
    
    private func colorForType(_ type: LogEntryType) -> Color {
        // Use green for all types to maintain consistency with app theme
        return .green
    }
    
    // Date formatting helper to check if a date has a non-default time
    private func formattedDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: date)
        
        // Check if time is at midnight (default time)
        let isDefaultTime = timeComponents.hour == 0 && timeComponents.minute == 0
        
        // Use date-only formatter if default time, otherwise include time
        if isDefaultTime {
            return dateFormatter.string(from: date)
        } else {
            return dateTimeFormatter.string(from: date)
        }
    }
    
    // Date formatter for showing selected date without time
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }
    
    // Date formatter that includes time
    private var dateTimeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter
    }
    
    // Check if the form is valid for submission
    private var isFormValid: Bool {
        // Basic validation: description should not be empty
        if description.isEmpty {
            return false
        }
        
        // For payments, amount should be valid
        if selectedType == .payment {
            guard let amountValue = Decimal(string: amount), amountValue > 0 else {
                return false
            }
        }
        
        return true
    }
}

// Quick Client Picker View
struct QuickClientPickerView: View {
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
                Section {
                    Button(action: {
                        selectedClient = nil
                        dismiss()
                    }) {
                        HStack {
                            Text("No Client")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if selectedClient == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
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
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if selectedClient == client {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Client")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.green)
                }
            }
        }
    }
}

// Quick Tag Picker View
struct QuickTagPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTag: String
    
    // Common tags
    private let tags = ["Work", "Personal", "Urgent", "Design", "Meeting", "Follow-up", "Website", "Admin", "Invoice"]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                    ForEach(tags, id: \.self) { tag in
                        Button(action: {
                            selectedTag = tag
                            dismiss()
                        }) {
                            Text(tag)
                                .font(.system(size: 15))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .background(selectedTag == tag ? Color.appAccent.opacity(0.15) : Color(UIColor.secondarySystemFill))
                                .foregroundColor(selectedTag == tag ? .appAccent : .primaryText)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Choose a Tag")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Extension for placeholder text
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

struct QuickAddView_Previews: PreviewProvider {
    static var previews: some View {
        QuickAddView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
} 