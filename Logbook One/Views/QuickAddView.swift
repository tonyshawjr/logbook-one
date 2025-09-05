import SwiftUI
import CoreData

// Import HashtagExtractor utility
import Foundation

// Task Date Picker View
struct TaskDatePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDate: Date
    @State private var monthDisplay: Date
    @State private var showTimeSelection: Bool = false
    @State private var selectedTime: Date
    @State private var selectedTimeOption: TimeOption = .morning
    
    // Predefined time options for quick selection
    enum TimeOption: String, CaseIterable, Identifiable {
        case morning = "Morning"
        case afternoon = "Afternoon"
        case evening = "Evening"
        case custom = "Custom"
        
        var id: String { self.rawValue }
        
        var hour: Int {
            switch self {
            case .morning: return 9
            case .afternoon: return 14
            case .evening: return 19
            case .custom: return 0 // Custom will use the actual time picker
            }
        }
        
        var minute: Int {
            return 0
        }
    }
    
    init(selectedDate: Binding<Date>) {
        self._selectedDate = selectedDate
        self._monthDisplay = State(initialValue: selectedDate.wrappedValue)
        self._selectedTime = State(initialValue: selectedDate.wrappedValue)
        
        // Check if the date has a time that matches one of our preset options
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: selectedDate.wrappedValue)
        
        // Find the matching time option or set to custom
        let timeOption: TimeOption
        if hour >= 7 && hour < 12 {
            timeOption = .morning
        } else if hour >= 12 && hour < 17 {
            timeOption = .afternoon
        } else if hour >= 17 {
            timeOption = .evening
        } else {
            timeOption = .custom
        }
        
        self._selectedTimeOption = State(initialValue: timeOption)
        
        // Check if time selection should be shown by default
        let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedDate.wrappedValue)
        let hasCustomTime = !(timeComponents.hour == 0 && timeComponents.minute == 0) && 
                           !(timeComponents.hour == 9 && timeComponents.minute == 0)
        self._showTimeSelection = State(initialValue: hasCustomTime)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Quick options
                HStack(spacing: 12) {
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
                            .foregroundColor(.themeAccent)
                            .padding(8)
                    }
                    
                    Button(action: nextMonth) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.themeAccent)
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
                VStack(spacing: 12) {
                    Toggle(isOn: $showTimeSelection.animation()) {
                        Text("Set a specific time")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .themeAccent))
                    .padding(.horizontal)
                    .onChange(of: showTimeSelection) { oldValue, newValue in
                        if !newValue {
                            // When disabling time selection, set to default 9 AM
                            setDefaultTime()
                        }
                    }
                    
                    // Time options (only shown if toggle is on)
                    if showTimeSelection {
                        // Quick time options
                        HStack(spacing: 8) {
                            ForEach(TimeOption.allCases) { option in
                                Button(action: {
                                    if option != .custom {
                                        withAnimation {
                                            selectedTimeOption = option
                                            setTimeFromOption(option)
                                        }
                                    } else {
                                        withAnimation {
                                            selectedTimeOption = .custom
                                        }
                                    }
                                }) {
                                    Text(option.rawValue)
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule()
                                                .fill(selectedTimeOption == option ? 
                                                     Color.themeAccent : Color(UIColor.secondarySystemBackground))
                                        )
                                        .foregroundColor(selectedTimeOption == option ? .white : .primary)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                        
                        // Custom time picker (only shown if Custom is selected)
                        if selectedTimeOption == .custom {
                            HStack {
                                Spacer()
                                
                                // Compact time picker
                                DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .frame(maxWidth: 150)
                                    .onChange(of: selectedTime) { oldValue, newValue in
                                        updateDateWithSelectedTime()
                                    }
                                
                                Spacer()
                            }
                            .padding(.top, 8)
                        }
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
                        // If showing time selection and custom time is selected, ensure we use it
                        if showTimeSelection && selectedTimeOption == .custom {
                            updateDateWithSelectedTime()
                        } else if showTimeSelection {
                            // Use the selected time option
                            setTimeFromOption(selectedTimeOption)
                        }
                        dismiss()
                    }
                    .foregroundColor(.themeAccent)
                }
            }
        }
    }
    
    // Helper to set time from the selected option
    private func setTimeFromOption(_ option: TimeOption) {
        let calendar = Calendar.current
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        dateComponents.hour = option.hour
        dateComponents.minute = option.minute
        
        if let newDate = calendar.date(from: dateComponents) {
            selectedDate = newDate
            selectedTime = newDate
        }
    }
    
    // Set default time (9 AM)
    private func setDefaultTime() {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        components.hour = 9
        components.minute = 0
        
        if let defaultTime = calendar.date(from: components) {
            selectedDate = defaultTime
            selectedTime = defaultTime
            selectedTimeOption = .morning
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
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                
                Text(label)
                    .font(.system(size: 14))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.themeAccent.opacity(0.15) : Color(UIColor.secondarySystemBackground))
            .foregroundColor(isSelected ? .themeAccent : .primary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.themeAccent : Color.clear, lineWidth: 1.5)
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
                                .foregroundColor(isSelected(day.date) ? .white : (isToday(day.date) ? .themeAccent : .primary))
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(isSelected(day.date) ? Color.themeAccent : Color.clear)
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
    @Environment(\.theme) private var theme
    
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
    @State private var currentPrompt: String = ""
    @State private var keyboardIsShown = false
    
    // For auto-focusing the text field
    @FocusState private var isDescriptionFocused: Bool
    
    // Flag to determine if we should show the type selector (hide it when opened from FAB menu)
    @State private var showTypeSelector: Bool = true
    
    // Type-specific conversational prompts
    private let taskPrompts = [
        "Need to knock this out?",
        "What do you need to get done?",
        "What's the thing you can't drop?",
        "Give this task a name",
        "What needs your attention?",
        "Put this task here and tackle it later",
        "What's your next move?",
        "Quick task? Capture it."
    ]
    
    private let notePrompts = [
        "What's on your mind?",
        "Brain won't shut up? Start here",
        "What just popped into your head?",
        "Drop it before it disappears",
        "Type it now, sort it later",
        "Throw it in here for now",
        "Don't trust your memory, trust this.",
        "Quick idea? Toss it in."
    ]
    
    private let paymentPrompts = [
        "What needs logged right now?",
        "What was this payment for?",
        "Record a payment quickly",
        "Client payment to track?",
        "What's the money for?",
        "Log your income",
        "Quick payment entry",
        "What service did you provide?"
    ]
    
    // Initialize with the last used type
    init() {
        let savedType = UserDefaults.standard.integer(forKey: "lastUsedEntryType")
        _selectedType = State(initialValue: LogEntryType(rawValue: Int16(savedType)) ?? .task)
        _showDueDate = State(initialValue: false) // Explicitly start with no due date
        _showTypeSelector = State(initialValue: true) // Show type selector in standard mode
    }
    
    // Initialize with a specific entry type (for context-aware quick add)
    init(initialEntryType: LogEntryType) {
        _selectedType = State(initialValue: initialEntryType)
        _showDueDate = State(initialValue: false) // Default to false for unscheduled tasks
        _showTypeSelector = State(initialValue: false) // Hide type selector when a specific type is provided
        // Still save this as the last used type
        UserDefaults.standard.set(Int(initialEntryType.rawValue), forKey: "lastUsedEntryType")
    }
    
    // Initialize with a specific entry type and initial date (for tasks)
    init(initialEntryType: LogEntryType, initialDate: Date) {
        _selectedType = State(initialValue: initialEntryType)
        _dueDate = State(initialValue: initialDate)
        _showDueDate = State(initialValue: true) // When initialized with a date, set showDueDate to true
        _showTypeSelector = State(initialValue: false) // Hide type selector when a specific type is provided
        
        // Save as last used type
        UserDefaults.standard.set(Int(initialEntryType.rawValue), forKey: "lastUsedEntryType")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Clean header like the menu
            if !showTypeSelector {
                // Show type title when opened from menu
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 10) {
                            Image(systemName: iconForType(selectedType))
                                .font(.system(size: 24))
                                .foregroundColor(colorForType(selectedType))
                            
                            Text("New \(selectedType.displayName)")
                                .font(.title3.bold())
                                .foregroundColor(.primary)
                        }
                        
                        Text(currentPrompt)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(.gray)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)  // More padding at top
                .padding(.bottom, 24)
            } else {
                // Original type selector for standalone mode
                HStack {
                    // Type selector - Simple row of options
                    if showTypeSelector {
                        HStack(spacing: 8) {
                            ForEach(LogEntryType.allCases) { type in
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedType = type
                                        lastUsedEntryType = Int(type.rawValue)
                                        showDueDate = type == .task
                                        // Update the prompt when changing type
                                        currentPrompt = getRandomPrompt(for: type)
                                    }
                                    // Don't auto-focus after animation completes
                                    // Let the user tap when they want to type
                                }) {
                                    VStack(spacing: 8) {
                                        Image(systemName: iconForType(type))
                                            .font(.system(size: 20))
                                            .foregroundColor(selectedType == type ? .white : .themeAccent)
                                        
                                        Text(type.displayName)
                                            .font(.subheadline)
                                            .fontWeight(selectedType == type ? .semibold : .regular)
                                            .foregroundColor(selectedType == type ? .white : .themeAccent)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedType == type ? Color.themeAccent : Color.themeAccent.opacity(0.05))
                                    )
                                }
                            }
                        }
                    } else {
                        // Show a title instead of type selector when specific type is provided
                        HStack {
                            Image(systemName: iconForType(selectedType))
                                .font(.system(size: 22))
                                .foregroundColor(.themeAccent)
                            
                            Text("New \(selectedType.displayName)")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.themePrimary)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gray.opacity(0.4))
                            .background(Circle().fill(Color(UIColor.tertiarySystemFill)))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 8)
            }
            
            // Main input area with native styling
            VStack(alignment: .leading, spacing: 0) {
                TextField("", text: $description)
                    .placeholder(when: description.isEmpty) {
                        Text(showTypeSelector ? currentPrompt : "Type here...")
                            .foregroundColor(.secondary)
                    }
                    .font(.body)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 24)
                    .focused($isDescriptionFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        // Just dismiss the keyboard, don't save
                        isDescriptionFocused = false
                    }
                    .frame(minHeight: showTypeSelector ? 90 : 85)
                
                Divider()
                    .padding(.horizontal, 24)
            }
                
                // Options area with clean native style
                VStack(spacing: 0) {
                    // Client selection
                    Button(action: {
                        showClientPicker = true
                    }) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                            
                            Text(selectedClient?.name ?? "Select Client")
                                .foregroundColor(selectedClient != nil ? .primary : .primary)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 18)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Divider()
                        .padding(.horizontal, 24)
                    
                    // Date selection for tasks
                    if selectedType == .task {
                        Button(action: {
                            if showDueDate {
                                showDatePicker = true
                            } else {
                                showDueDate = true
                                showDatePicker = true
                            }
                        }) {
                            HStack {
                                Image(systemName: showDueDate ? "calendar" : "calendar.badge.plus")
                                    .font(.system(size: 24))
                                    .foregroundColor(.themeAccent)
                                
                                if showDueDate {
                                    if Calendar.current.isDateInToday(dueDate) {
                                        Text("Today")
                                            .foregroundColor(.primary)
                                    } else if Calendar.current.isDateInTomorrow(dueDate) {
                                        Text("Tomorrow")
                                            .foregroundColor(.primary)
                                    } else {
                                        Text(formattedDate(dueDate))
                                            .foregroundColor(.primary)
                                    }
                                } else {
                                    Text("Add Due Date")
                                        .foregroundColor(.primary)
                                }
                                
                                Spacer()
                                
                                if showDueDate {
                                    Button(action: {
                                        showDueDate = false
                                        dueDate = Date().addingTimeInterval(86400)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(.gray)
                                    }
                                } else {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 18)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Divider()
                            .padding(.horizontal, 24)
                    }
                    
                    // Payment amount field
                    if selectedType == .payment {
                        HStack {
                            Image(systemName: "dollarsign.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.green)
                            
                            Text("Amount")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Text("$")
                                    .foregroundColor(.primary)
                                    .font(.system(size: 17, weight: .medium))
                                
                                TextField("0.00", text: $amount)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 100)
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 18)
                        
                        Divider()
                            .padding(.horizontal, 24)
                    }
                }
                
                Spacer()
                
                // Save button at bottom
                Button(action: saveEntry) {
                    Text("Save")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(isFormValid ? .white : .white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(isFormValid ? Color.themeAccent : Color.gray.opacity(0.15))
                        .cornerRadius(14)
                }
                .disabled(!isFormValid)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
        }
        .background(Color(uiColor: .systemBackground))
        .ignoresSafeArea(edges: .bottom)
        // Modals and pickers
        .sheet(isPresented: $showClientPicker) {
            QuickClientPickerView(selectedClient: $selectedClient)
                .presentationDetents([.height(420)])
                .presentationDragIndicator(.hidden)
                .presentationBackground(Color(uiColor: .systemBackground))
                .presentationCornerRadius(24)
                .interactiveDismissDisabled(false)
        }
        .sheet(isPresented: $showDatePicker) {
            TaskDatePickerView(selectedDate: $dueDate)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .presentationBackground(Color(uiColor: .systemBackground))
                .presentationCornerRadius(24)
                .interactiveDismissDisabled(false)
        }
        .overlay {
            if showingSavedAnimation {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                    .overlay {
                        VStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.themeAccent)
                            
                            Text("Saved!")
                                .font(.title3.weight(.medium))
                                .foregroundColor(.themeAccent)
                                .padding(.top, 4)
                        }
                    }
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.2), value: selectedType)
        .animation(.easeOut(duration: 0.2), value: showDueDate)
        .onAppear {
            // Select a random prompt when view appears
            currentPrompt = getRandomPrompt(for: selectedType)
            
            // Don't auto-focus the description field - wait for user to tap
            // This prevents the keyboard from appearing automatically
            
            // Don't automatically set showDueDate to true for tasks
            // Let it respect the initialized value
            
            // Add keyboard observers
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { _ in
                keyboardIsShown = true
            }
            
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                keyboardIsShown = false
            }
        }
        .onDisappear {
            // Remove keyboard observers
            NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        }
    }
    
    // Get a random conversational prompt for the selected entry type
    private func getRandomPrompt(for type: LogEntryType) -> String {
        switch type {
        case .task:
            return taskPrompts.randomElement() ?? "Need to knock this out?"
        case .note:
            return notePrompts.randomElement() ?? "What's on your mind?"
        case .payment:
            return paymentPrompts.randomElement() ?? "What was this payment for?"
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
            // For tasks, only set a due date if showDueDate is true
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
                // Don't set a date for unscheduled tasks
                entry.date = nil
            }
        case .note, .payment:
            // For notes and payments, use current date
            entry.date = now
        }
        
        entry.client = selectedClient
        
        // For notes, automatically extract hashtags from the description
        if selectedType == .note || selectedType == .payment {
            // Extract hashtags from the text
            let extractedTags = HashtagExtractor.extractHashtags(from: description)
            if !extractedTags.isEmpty {
                // Join tags with commas for storage
                entry.tag = HashtagExtractor.hashtags(toStorageFormat: extractedTags)
            } else if !selectedTag.isEmpty {
                // Fallback to manually selected tag if no hashtags in the text
                entry.tag = selectedTag
            }
        } else {
            // For task entry type, use the selected tag
            entry.tag = selectedTag.isEmpty ? nil : selectedTag
        }
        
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
        return .themeAccent
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
                                    .foregroundColor(.primary)
                                
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.themeAccent)
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
                                .background(selectedTag == tag ? Color.themeAccent.opacity(0.15) : Color(UIColor.secondarySystemFill))
                                .foregroundColor(selectedTag == tag ? .themeAccent : .themePrimary)
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