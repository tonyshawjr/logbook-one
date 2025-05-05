import SwiftUI
import CoreData

struct TasksView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.theme) private var theme
    @State private var showingAddTask = false
    @State private var selectedDate = Date() // Currently selected date
    @State private var showMonthPicker = false
    @State private var forceUpdate: Bool = false // State variable to force refresh
    
    // Date calculations
    private var calendar: Calendar { Calendar.current }
    
    private var weekDates: [Date] {
        // Get dates for the whole week containing the selected date
        let today = calendar.startOfDay(for: selectedDate)
        let weekday = calendar.component(.weekday, from: today)
        
        // Calculate the start of the week (Sunday)
        let startOfWeek = calendar.date(byAdding: .day, value: 1-weekday, to: today) ?? today
        
        // Generate array of dates for the week
        return (0...6).map { day in
            calendar.date(byAdding: .day, value: day, to: startOfWeek) ?? today
        }
    }
    
    // Dynamic fetch request for tasks on the selected day
    @FetchRequest private var tasksForSelectedDay: FetchedResults<LogEntry>
    
    // Fetch request for all tasks to check which days have tasks
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \LogEntry.date, ascending: true)],
        predicate: NSPredicate(format: "type == %d", LogEntryType.task.rawValue),
        animation: .default
    ) private var allTasks: FetchedResults<LogEntry>
    
    // Separate fetch request for undated tasks
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \LogEntry.creationDate, ascending: false)],
        predicate: NSPredicate(format: "type == %d AND isComplete == NO AND date == nil", LogEntryType.task.rawValue),
        animation: .default
    ) private var undatedTasks: FetchedResults<LogEntry>
    
    // Separate fetch request for overdue tasks - tasks with due dates before today that aren't completed
    @FetchRequest private var overdueTasks: FetchedResults<LogEntry>
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }()
    
    private let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    init() {
        // Get the start and end of the selected day
        let today = Calendar.current.startOfDay(for: Date())
        let startOfDay = Calendar.current.startOfDay(for: today)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)?.addingTimeInterval(-1) ?? startOfDay
        
        // Create predicate for tasks on the selected day
        let predicate = NSPredicate(format: "type == %d AND date >= %@ AND date <= %@", 
                                   LogEntryType.task.rawValue,
                                   startOfDay as NSDate,
                                   endOfDay as NSDate)
        
        // Initialize fetch request for tasks on selected day
        self._tasksForSelectedDay = FetchRequest<LogEntry>(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \LogEntry.isComplete, ascending: true),
                NSSortDescriptor(keyPath: \LogEntry.date, ascending: true)
            ],
            predicate: predicate,
            animation: .default
        )
        
        // Initialize fetch request for overdue tasks
        let todayStart = Calendar.current.startOfDay(for: Date())
        let overduePredicate = NSPredicate(format: "type == %d AND isComplete == NO AND date < %@",
                                          LogEntryType.task.rawValue,
                                          todayStart as NSDate)
        
        self._overdueTasks = FetchRequest<LogEntry>(
            sortDescriptors: [NSSortDescriptor(keyPath: \LogEntry.date, ascending: true)],
            predicate: overduePredicate,
            animation: .default
        )
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Tasks header view
                        HStack {
                            // Title with large font matching NotesView
                            Text("Tasks")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.themePrimary)
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                        .background(Color.themeBackground)
                        
                        // Week view header
                        weekCalendarHeader
                        
                        Divider()
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        
                        // Scheduled tasks section
                        if tasksForSelectedDay.isEmpty && overdueTasks.isEmpty {
                            if undatedTasks.isEmpty {
                                // Only show empty day view if both scheduled and unscheduled tasks are empty
                                emptyDayView
                            } else {
                                // If there are unscheduled tasks, show a simpler message
                                VStack(spacing: 12) {
                                    Text("Nothing planned for this day yet.")
                                        .font(.body)
                                        .foregroundColor(.themeSecondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 40)
                                        .padding(.vertical, 20)
                                }
                            }
                        } else {
                            taskList
                        }
                        
                        // Only show unscheduled section if there are unscheduled tasks
                        if !undatedTasks.isEmpty {
                            // Unscheduled tasks header
                            HStack {
                                Text("Unscheduled")
                                    .font(.headline)
                                    .foregroundColor(.themePrimary)
                                    .padding(.leading)
                                    .padding(.top, 24)
                                    .padding(.bottom, 8)
                                Spacer()
                            }
                            
                            // Unscheduled tasks list
                            unscheduledTaskList
                        }
                        
                        // Add spacing at bottom for floating button
                        Spacer(minLength: 80)
                    }
                }
            }
            .onChange(of: selectedDate) { oldValue, newValue in
                updateFetchRequest()
                // Toggle the force update flag to trigger a view refresh
                forceUpdate.toggle()
            }
            .id(forceUpdate) // Force view to update when this changes
            .navigationBarTitleDisplayMode(.inline) // Hide the navigation bar title
            .toolbar(.hidden, for: .navigationBar) // Hide the navigation bar completely
            .toolbarBackground(Color.themeBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showingAddTask) {
                // Use the selectedDate as the initial date for the new task
                QuickAddView(initialEntryType: .task, initialDate: selectedDate)
                    .presentationDragIndicator(.hidden)
                    .presentationDetents([.height(420)])
                    .presentationBackground(Color(uiColor: .systemBackground))
                    .presentationCornerRadius(24)
                    .interactiveDismissDisabled(false)
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(isPresented: $showMonthPicker) {
                MonthPickerView(selectedDate: $selectedDate)
                    .presentationDetents([.medium])
                    .presentationBackground(Color(uiColor: .systemBackground))
            }
        }
    }
    
    // Week calendar header that shows a single week
    private var weekCalendarHeader: some View {
        VStack(spacing: 16) {
            // Month and year with calendar button
            HStack {
                Text(monthYearFormatter.string(from: selectedDate))
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.themePrimary)
                
                Spacer()
                
                Button(action: {
                    showMonthPicker = true
                }) {
                    Image(systemName: "calendar")
                        .font(.headline)
                        .foregroundColor(.themeAccent)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.themeAccent, lineWidth: 1.5)
                        )
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)
            
            // Week view
            HStack(spacing: 0) {
                ForEach(Array(zip(weekDates, ["S", "M", "T", "W", "T", "F", "S"])), id: \.0) { date, dayLabel in
                    let isToday = calendar.isDateInToday(date)
                    let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                    
                    Button(action: {
                        selectedDate = date
                    }) {
                        VStack(spacing: 4) {
                            // Day letter
                            Text(dayLabel)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.themeSecondary.opacity(0.6))
                            
                            // Day number
                            Text("\(calendar.component(.day, from: date))")
                                .font(.system(size: 18, weight: isSelected ? .bold : .regular))
                                .foregroundColor(isSelected ? .white : (isToday ? .themeAccent : .themePrimary))
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle()
                                        .fill(isSelected ? Color.themeAccent : (isToday ? Color.themeAccent.opacity(0.1) : Color.clear))
                                )
                            
                            // Task indicator dots
                            if hasTasksOnDay(date) {
                                Circle()
                                    .fill(isSelected ? Color.white.opacity(0.8) : Color.themeAccent)
                                    .frame(width: 5, height: 5)
                            } else {
                                Spacer()
                                    .frame(height: 5)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                }
            }
            .padding(.bottom, 16)
        }
        .background(Color.themeBackground)
    }
    
    // Scheduled tasks list
    private var taskList: some View {
        LazyVStack(spacing: 12, pinnedViews: []) {
            // Always show overdue tasks
            if !overdueTasks.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    // Overdue header
                    Text("Overdue")
                        .font(.appSubheadline)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // Overdue tasks
                    ForEach(overdueTasks) { task in
                        TaskCardView(task: task, isOverdue: true)
                            .padding(.horizontal)
                    }
                }
            }
            
            // Group tasks by time of day if not today, or use "Due Today" for today's tasks
            if !tasksForSelectedDay.isEmpty {
                // Check if selected date is today
                let isToday = calendar.isDateInToday(selectedDate)
                
                if isToday {
                    // Today's tasks get a special header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Due Today")
                            .font(.appSubheadline)
                            .foregroundColor(.themeAccent)
                            .padding(.horizontal)
                            .padding(.top, 8)
                        
                        // Today's tasks
                        ForEach(tasksForSelectedDay) { task in
                            TaskCardView(task: task)
                                .padding(.horizontal)
                        }
                    }
                } else {
                    // Group and sort tasks by morning/afternoon/evening for other days
                    let groupedTasks = groupTasksByTime(tasksForSelectedDay)
                    
                    // Define a custom sort order for time groups
                    let timeOrder = ["Morning", "Afternoon", "Evening"]
                    
                    // Use the custom order to sort the groups
                    ForEach(timeOrder.filter { groupedTasks[$0]?.isEmpty == false }, id: \.self) { timeGroup in
                        if let tasks = groupedTasks[timeGroup], !tasks.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                // Time group header (Morning, Afternoon, Evening)
                                Text(timeGroup)
                                    .font(.appSubheadline)
                                    .foregroundColor(.themeSecondary)
                                    .padding(.horizontal)
                                    .padding(.top, 8)
                                
                                // Tasks in this time group
                                ForEach(tasks) { task in
                                    TaskCardView(task: task)
                                        .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 12)
    }
    
    // Unscheduled tasks list
    private var unscheduledTaskList: some View {
        LazyVStack(spacing: 12) {
            ForEach(undatedTasks) { task in
                UnscheduledTaskCardView(
                    task: task, 
                    assignTaskToToday: assignTaskToToday
                )
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 12)
    }
    
    private var emptyDayView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 50))
                .foregroundColor(.themeSecondary.opacity(0.3))
                .padding(20)
            
            Text("No Tasks")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.themePrimary)
            
            Text("Nothing planned for this day yet.")
                .font(.body)
                .foregroundColor(.themeSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    // Function to check if a day has any tasks
    private func hasTasksOnDay(_ date: Date) -> Bool {
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)?.addingTimeInterval(-1) ?? startOfDay
        
        return allTasks.contains { task in
            guard let taskDate = task.date else { return false }
            return taskDate >= startOfDay && taskDate <= endOfDay
        }
    }
    
    // Function to count tasks on a specific day
    private func countTasksOnDay(_ date: Date) -> Int {
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)?.addingTimeInterval(-1) ?? startOfDay
        
        return allTasks.filter { task in
            guard let taskDate = task.date else { return false }
            return taskDate >= startOfDay && taskDate <= endOfDay
        }.count
    }
    
    // Function to group tasks by time of day
    private func groupTasksByTime(_ tasks: FetchedResults<LogEntry>) -> [String: [LogEntry]] {
        var groupedTasks: [String: [LogEntry]] = [
            "Morning": [],
            "Afternoon": [],
            "Evening": []
        ]
        
        for task in tasks {
            guard let date = task.date else { continue }
            
            let hour = calendar.component(.hour, from: date)
            
            if hour < 12 {
                groupedTasks["Morning"]?.append(task)
            } else if hour < 17 {
                groupedTasks["Afternoon"]?.append(task)
            } else {
                groupedTasks["Evening"]?.append(task)
            }
        }
        
        return groupedTasks
    }
    
    private func updateFetchRequest() {
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)?.addingTimeInterval(-1) ?? startOfDay
        
        // Create new predicate
        let predicate = NSPredicate(format: "type == %d AND date >= %@ AND date <= %@", 
                                   LogEntryType.task.rawValue,
                                   startOfDay as NSDate,
                                   endOfDay as NSDate)
        
        // Update fetch request for tasks on selected day
        tasksForSelectedDay.nsPredicate = predicate
        
        // Refresh overdue tasks fetch request
        let today = calendar.startOfDay(for: Date())
        let overduePredicate = NSPredicate(format: "type == %d AND isComplete == NO AND date < %@", 
                                          LogEntryType.task.rawValue, 
                                          today as NSDate)
        
        // Update the overdue tasks
        overdueTasks.nsPredicate = overduePredicate
    }
    
    private func assignTaskToToday(_ task: LogEntry) {
        let today = calendar.startOfDay(for: Date())
        let defaultTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: today) ?? today
        
        withAnimation {
            task.date = defaultTime
            do {
                try viewContext.save()
                // Update fetch requests after saving
                updateFetchRequest()
            } catch {
                print("Error saving task date: \(error)")
            }
        }
    }
}

// Helper view for task cards
struct TaskCardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.theme) private var theme
    @ObservedObject var task: LogEntry
    @State private var isComplete: Bool = false
    var isOverdue: Bool = false
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
    
    var body: some View {
        NavigationLink(destination: EntryDetailView(entry: task)) {
            HStack(spacing: 12) {
                // Checkbox
                Button(action: toggleCompletion) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(isComplete ? Color.themeAccent : (isOverdue ? theme.danger : Color.gray.opacity(0.4)), lineWidth: 2)
                            .frame(width: 24, height: 24)
                        
                        if isComplete {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.themeAccent)
                        }
                    }
                }
                .buttonStyle(.plain)
                
                VStack(alignment: .leading, spacing: 4) {
                    // Task description and time in a single row
                    HStack {
                        Text(task.desc ?? "")
                            .font(.appHeadline)
                            .foregroundColor(isComplete ? .themeSecondary : (isOverdue ? .red : .themePrimary))
                            .strikethrough(isComplete)
                        
                        Spacer(minLength: 8)
                        
                        if let date = task.date {
                            Text(isOverdue ? dateFormatter.string(from: date) : timeFormatter.string(from: date))
                                .font(.appCaption)
                                .foregroundColor(isOverdue ? .red : .themeSecondary)
                        }
                    }
                    
                    // Client info
                    if let client = task.client {
                        HStack {
                            Text(client.name ?? "Client")
                                .font(.appCaption)
                                .foregroundColor(.themeSecondary)
                            
                            if let tag = task.tag, !tag.isEmpty {
                                Text("•")
                                    .font(.appCaption)
                                    .foregroundColor(.themeSecondary.opacity(0.5))
                                
                                Text(tag)
                                    .font(.appCaption)
                                    .foregroundColor(.themeSecondary)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color.themeCard)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isOverdue ? theme.danger.opacity(0.2) : Color.gray.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            isComplete = task.isComplete
        }
    }
    
    private func toggleCompletion() {
        let wasComplete = isComplete
        isComplete.toggle()
        task.isComplete = isComplete
        
        do {
            try viewContext.save()
            
            // Add haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        } catch {
            print("Error saving task completion: \(error)")
        }
    }
}

// Helper view for unscheduled task cards
struct UnscheduledTaskCardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.theme) private var theme
    @ObservedObject var task: LogEntry
    @State private var isComplete: Bool = false
    var assignTaskToToday: (LogEntry) -> Void
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        NavigationLink(destination: EntryDetailView(entry: task)) {
            HStack(spacing: 12) {
                // Checkbox
                Button(action: toggleCompletion) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(isComplete ? Color.themeAccent : Color.gray.opacity(0.4), lineWidth: 2)
                            .frame(width: 24, height: 24)
                        
                        if isComplete {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.themeAccent)
                        }
                    }
                }
                .buttonStyle(.plain)
                
                // Task info - main row has task description and creation time
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(task.desc ?? "")
                            .font(.appHeadline)
                            .foregroundColor(isComplete ? .themeSecondary : .themePrimary)
                            .strikethrough(isComplete)
                            .lineLimit(1)
                        
                        Spacer(minLength: 8)
                        
                        if let creationDate = task.value(forKey: "creationDate") as? Date {
                            Text(timeFormatter.string(from: creationDate))
                                .font(.appCaption)
                                .foregroundColor(.themeSecondary)
                        }
                    }
                    
                    // Client info
                    if let client = task.client {
                        HStack {
                            Text(client.name ?? "Client")
                                .font(.appCaption)
                                .foregroundColor(.themeSecondary)
                            
                            if let tag = task.tag, !tag.isEmpty {
                                Text("•")
                                    .font(.appCaption)
                                    .foregroundColor(.themeSecondary.opacity(0.5))
                                
                                Text(tag)
                                    .font(.appCaption)
                                    .foregroundColor(.themeSecondary)
                            }
                        }
                    }
                }
                
                // "Today" button for quick scheduling
                Button(action: {
                    assignTaskToToday(task)
                }) {
                    Text("Today")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.themeAccent)
                        .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
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
        .onAppear {
            isComplete = task.isComplete
        }
    }
    
    private func toggleCompletion() {
        let wasComplete = isComplete
        isComplete.toggle()
        task.isComplete = isComplete
        
        do {
            try viewContext.save()
            
            // Add haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        } catch {
            print("Error saving task completion: \(error)")
        }
    }
}

#Preview {
    TasksView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

// Month picker view for selecting a specific date
struct MonthPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDate: Date
    
    @State private var displayedMonth: Date
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
    
    init(selectedDate: Binding<Date>) {
        self._selectedDate = selectedDate
        self._displayedMonth = State(initialValue: Calendar.current.startOfDay(for: selectedDate.wrappedValue))
    }
    
    private let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Month navigation
                HStack {
                    Button(action: previousMonth) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.themeAccent)
                    }
                    
                    Spacer()
                    
                    Text(monthYearFormatter.string(from: displayedMonth))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.themePrimary)
                    
                    Spacer()
                    
                    Button(action: nextMonth) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.themeAccent)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Day of week headers
                HStack(spacing: 0) {
                    ForEach(daysOfWeek, id: \.self) { day in
                        Text(day)
                            .font(.callout)
                            .fontWeight(.medium)
                            .foregroundColor(.themeSecondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
                
                // Calendar grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                    ForEach(daysInMonth(), id: \.self) { day in
                        if day.day != 0 {
                            Button(action: {
                                selectedDate = day.date
                                dismiss()
                            }) {
                                Text("\(day.day)")
                                    .font(.system(size: 18))
                                    .fontWeight(isSelected(day.date) ? .bold : .regular)
                                    .foregroundColor(isSelected(day.date) ? .white : (isToday(day.date) ? .themeAccent : .themePrimary))
                                    .frame(width: 40, height: 40)
                                    .background(
                                        Circle()
                                            .fill(isSelected(day.date) ? Color.themeAccent : (isToday(day.date) ? Color.themeAccent.opacity(0.1) : Color.clear))
                                    )
                            }
                        } else {
                            Text("")
                                .frame(width: 40, height: 40)
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
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
    
    // Check if a date is today
    private func isToday(_ date: Date) -> Bool {
        return calendar.isDateInToday(date)
    }
    
    // Check if a date is selected
    private func isSelected(_ date: Date) -> Bool {
        return calendar.isDate(date, inSameDayAs: selectedDate)
    }
    
    // Go to previous month
    private func previousMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }
    
    // Go to next month
    private func nextMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }
    
    // Generate days in the month
    private func daysInMonth() -> [CalendarDay] {
        var days = [CalendarDay]()
        
        let range = calendar.range(of: .day, in: .month, for: displayedMonth)!
        let numDays = range.count
        
        // Get the first day of the month
        let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))!
        
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