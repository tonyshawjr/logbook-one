import SwiftUI
import CoreData

struct OnboardingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var hasCompletedOnboarding: Bool
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("useSampleData") private var useSampleData: Bool = false
    @AppStorage("useSystemAppearance") private var useSystemAppearance: Bool = true
    @AppStorage("useDarkMode") private var useDarkMode: Bool = false
    
    // Added a separate state to track setup vs feature tour
    @State private var setupStep = 0
    @State private var showingFeatureTour = false
    @State private var featureSlideIndex = 0
    @State private var tempUserName: String = ""
    
    // Use FocusState for the text field instead of regular State
    @FocusState private var isNameFieldFocused: Bool
    
    // The number of feature tour slides
    private let featureSlidesCount = 8
    
    var body: some View {
        ZStack {
            Color.themeBackground.ignoresSafeArea()
            
            if showingFeatureTour {
                // Feature tour view with swipeable slides
                featureTourView
            } else {
                // Setup flow
                setupFlowView
            }
        }
    }
    
    // Setup flow with progress indicators and different steps
    private var setupFlowView: some View {
        VStack {
            // Progress indicator
            HStack(spacing: 8) {
                ForEach(0..<4) { step in
                    Capsule()
                        .fill(step <= setupStep ? Color.themeAccent : Color.themeAccent.opacity(0.2))
                        .frame(height: 4)
                        .frame(width: step == setupStep ? 24 : 16)
                }
            }
            .padding(.top, 20)
            .padding(.bottom, 40)
            
            Spacer()
            
            // Content for each step
            switch setupStep {
            case 0:
                welcomeStep
            case 1:
                nameStep
            case 2:
                sampleDataStep
            case 3:
                styleStep
            default:
                EmptyView()
            }
            
            Spacer()
            
            // Navigation buttons
            VStack(spacing: 16) {
                Button(action: {
                    if setupStep < 3 {
                        advanceToNextStep()
                    } else {
                        // Show feature tour after setup
                        showingFeatureTour = true
                    }
                }) {
                    HStack {
                        Text(getButtonText(for: setupStep))
                            .font(.appHeadline)
                        
                        if setupStep != 1 || !tempUserName.isEmpty {
                            Image(systemName: "arrow.right")
                                .font(.appHeadline)
                        }
                    }
                    .frame(height: 24)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.themeAccent)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                    .shadow(color: Color.themeAccent.opacity(0.3), radius: 5, x: 0, y: 2)
                }
                .disabled(setupStep == 1 && tempUserName.isEmpty)
                .opacity(setupStep == 1 && tempUserName.isEmpty ? 0.6 : 1.0)
                
                // Only show skip for the feature tour, not for the setup screens
                if showingFeatureTour && featureSlideIndex < 8 {
                    Button("Skip to End") {
                        featureSlideIndex = 8 // Skip to the final slide
                    }
                    .font(.appSubheadline)
                    .foregroundColor(.themeSecondary)
                    .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
    
    // Feature tour with swipeable slides
    private var featureTourView: some View {
        VStack(spacing: 0) {
            // Swipe gesture area
            TabView(selection: $featureSlideIndex) {
                todayTabSlide
                    .tag(0)
                
                addingLogsSlide
                    .tag(1)
                
                tasksTabSlide
                    .tag(2)
                
                notesTabSlide
                    .tag(3)
                
                paymentsTabSlide
                    .tag(4)
                
                clientsTabSlide
                    .tag(5)
                
                nagModeSlide
                    .tag(6)
                
                powerFeaturesSlide
                    .tag(7)
                
                readyToGoSlide
                    .tag(8)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: featureSlideIndex)
            
            // Page indicator dots - only show if not on final screen
            if featureSlideIndex < 8 {
                HStack(spacing: 6) {
                    ForEach(0...8, id: \.self) { index in
                        Circle()
                            .fill(featureSlideIndex == index ? Color.themeAccent : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(featureSlideIndex == index ? 1.2 : 1.0)
                            .animation(.spring(), value: featureSlideIndex)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 5)
            }
            
            // Navigation buttons
            HStack {
                // Only show back button if not on final screen
                if featureSlideIndex < 8 {
                    Button(action: {
                        if featureSlideIndex > 0 {
                            featureSlideIndex -= 1
                        }
                    }) {
                        Text("Back")
                            .font(.subheadline)
                            .foregroundColor(.themeSecondary)
                            .padding(.vertical, 12)
                    }
                } else {
                    // Empty spacer when on final screen to maintain layout
                    Spacer().frame(width: 1)
                }
                
                Spacer()
                
                if featureSlideIndex < 8 {
                    Button(action: {
                        featureSlideIndex += 1
                    }) {
                        Text("Next")
                            .font(.subheadline)
                            .foregroundColor(.themeAccent)
                            .padding(.vertical, 12)
                    }
                } else {
                    Spacer()
                    Button(action: completeOnboarding) {
                        Text("Jump in. Let's go!")
                            .font(.appHeadline)
                            .frame(height: 24)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.themeAccent)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 40)
                    Spacer()
                }
            }
            .padding(.horizontal, featureSlideIndex < 8 ? 40 : 0)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Setup Flow Steps
    
    // Step 1: Welcome
    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.text")
                .font(.system(size: 70))
                .foregroundColor(.themeAccent)
            
            Text("Keep track of your day.\nNo clutter. No logins.")
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(.themePrimary)
            
            Text("Whether you fix things, build things, clean things, or design things—this is your place to track it.")
                .font(.appBody)
                .multilineTextAlignment(.center)
                .foregroundColor(.themeSecondary)
                .padding(.horizontal, 24)
                .padding(.top, 8)
        }
        .padding(.horizontal)
    }
    
    // Step 2: Name Input
    private var nameStep: some View {
        VStack(spacing: 32) {
            Text("What should we call you?")
                .font(.system(size: 24, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(.themePrimary)
            
            // Clean, minimal text field with just a blue line
            VStack(spacing: 16) {
                ZStack(alignment: .center) {
                    // Empty for initial state - just the line will show
                    if tempUserName.isEmpty {
                        Text("")
                            .font(.appTitle3)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 8)
                    } else {
                        // Show entered name
                        Text(tempUserName)
                            .font(.appTitle3)
                            .foregroundColor(.themePrimary)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 8)
                    }
                    
                    // Invisible text field on top that captures input
                    TextField("", text: $tempUserName)
                        .font(.appTitle3)
                        .multilineTextAlignment(.center)
                        .autocapitalization(.words)
                        .disableAutocorrection(true)
                        .submitLabel(.next)
                        .opacity(0.01) // Almost invisible but functional
                        .frame(height: 44)
                        .onSubmit {
                            if !tempUserName.isEmpty {
                                advanceToNextStep()
                            }
                        }
                        .focused($isNameFieldFocused)
                        .onAppear {
                            // Auto-focus the field when view appears
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                isNameFieldFocused = true
                            }
                        }
                }
                
                // Blue line beneath
                Rectangle()
                    .fill(Color.blue)
                    .frame(height: 1)
                    .padding(.horizontal, 40)
            }
            .padding(.horizontal, 40)
            .contentShape(Rectangle())
            .onTapGesture {
                isNameFieldFocused = true
            }
            
            Spacer().frame(height: 40)
            
            Text("This personalizes your greeting. You can change it later in Settings.")
                .font(.appCaption)
                .multilineTextAlignment(.center)
                .foregroundColor(.themeSecondary)
                .padding(.horizontal, 40)
        }
        .padding()
    }
    
    // Step 3: Sample Data Option
    private var sampleDataStep: some View {
        VStack(spacing: 24) {
            Text("Want a head start?")
                .font(.system(size: 24, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(.themePrimary)
            
            Text("We can load in some sample tasks, notes, and payments so you can explore the app.")
                .font(.appBody)
                .multilineTextAlignment(.center)
                .foregroundColor(.themeSecondary)
                .padding(.horizontal, 24)
            
            Toggle("Load Sample Data", isOn: $useSampleData)
                .padding(.horizontal, 40)
                .padding(.top, 16)
                .toggleStyle(SwitchToggleStyle(tint: .themeAccent))
        }
        .padding()
    }
    
    // Step 4: Style Settings
    private var styleStep: some View {
        VStack(spacing: 24) {
            Text("Light or Dark?")
                .font(.system(size: 24, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(.themePrimary)
            
            Text("Pick the theme that feels best for your flow.")
                .font(.appBody)
                .multilineTextAlignment(.center)
                .foregroundColor(.themeSecondary)
                .padding(.horizontal, 24)
            
            VStack(alignment: .leading, spacing: 16) {
                Toggle("Use System Appearance", isOn: $useSystemAppearance)
                    .onChange(of: useSystemAppearance) { _, newValue in
                        if newValue {
                            // Reset manual dark mode when using system appearance
                            useDarkMode = false
                        }
                    }
                
                if !useSystemAppearance {
                    Toggle("Dark Mode", isOn: $useDarkMode)
                }
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 16)
        }
        .padding()
    }
    
    // MARK: - Feature Tour Slides
    
    private var todayTabSlide: some View {
        featureSlide(
            icon: "sun.max",
            title: "Start your day with today",
            description: "See your monthly revenue, what needs tackling now, and what you've already knocked out. Every payment you log and task you complete updates this screen in real-time."
        )
    }
    
    private var addingLogsSlide: some View {
        featureSlide(
            icon: "plus.circle",
            title: "Tap the + button to log anything",
            description: "Quickly add a task, note, or payment. You can do this from anywhere in the app using the + button in the bottom right corner."
        )
    }
    
    private var tasksTabSlide: some View {
        featureSlide(
            icon: "checkmark.circle",
            title: "Plan one week at a time",
            description: "Stay on top of your week. Tap any day to view or edit tasks. Days will show overdue, scheduled, or unscheduled tasks."
        )
    }
    
    private var notesTabSlide: some View {
        featureSlide(
            icon: "doc.text",
            title: "Write it down and find it fast",
            description: "Your notes are auto-sorted by date and time. Add hashtags to organize and search easily. Filter by client if needed."
        )
    }
    
    private var paymentsTabSlide: some View {
        featureSlide(
            icon: "dollarsign.circle",
            title: "Track your income your way",
            description: "Log any payment, apply hashtags, and filter by client or timeframe—month, quarter, year, or all time."
        )
    }
    
    private var clientsTabSlide: some View {
        featureSlide(
            icon: "person.crop.circle",
            title: "Everything tied to a client, \nin one spot",
            description: "View client-specific notes, tasks, payments, and totals. Click any client to see a full dashboard just for them."
        )
    }
    
    private var nagModeSlide: some View {
        featureSlide(
            icon: "bell",
            title: "Stay accountable, your way",
            description: "Nag mode reminds you to log your day. Pick your tone: friendly, sarcastic, bossy, or beast mode. It's accountability with personality."
        )
    }
    
    private var powerFeaturesSlide: some View {
        featureSlide(
            icon: "arrow.up.arrow.down",
            title: "Import, export, reset. You're in control",
            description: "Export or import your data.\nClear all entries anytime.\nUse sample data for testing."
        )
    }
    
    private var readyToGoSlide: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 24) {
                // Header - updated to be enthusiastic with emoji
                Text("Ready for Today! 🎉")
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.themePrimary)
                    .padding(.horizontal, 24)
                
                // Subtext
                Text("Your workspace is ready.\nCapture thoughts. Track what's next.\nLog your payments as they come in.\nEverything you need—on one screen.")
                    .font(.appBody)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.themeSecondary)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
                
                // Centered bullet points without icons
                VStack(spacing: 16) {
                    Text("Quick notes and reminders.")
                        .font(.appBody)
                        .foregroundColor(.themePrimary)
                    
                    Text("Daily task tracking.")
                        .font(.appBody)
                        .foregroundColor(.themePrimary)
                    
                    Text("Payment logging and totals.")
                        .font(.appBody)
                        .foregroundColor(.themePrimary)
                }
                .padding(.top, 16)
                .padding(.horizontal, 32)
                .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.themeBackground)
    }
    
    // MARK: - Reusable Views
    
    // Reusable feature slide template
    private func featureSlide(icon: String, title: String, description: String) -> some View {
        VStack(spacing: 32) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundColor(.themeAccent)
                .padding(.bottom, 8)
            
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(.themePrimary)
                .padding(.horizontal, 24)
            
            Text(description)
                .font(.appBody)
                .multilineTextAlignment(.center)
                .foregroundColor(.themeSecondary)
                .padding(.horizontal, 32)
                .padding(.bottom, 16)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Helper Methods
    
    private func getButtonText(for step: Int) -> String {
        switch step {
        case 0:
            return "Get Started"
        case 1:
            return "Next"
        case 2:
            return "Continue"
        case 3:
            return "Continue to Features"
        default:
            return "Next"
        }
    }
    
    private func advanceToNextStep() {
        if setupStep == 1 && !tempUserName.isEmpty {
            // Save name if provided
            userName = tempUserName
        }
        
        withAnimation {
            setupStep += 1
        }
    }
    
    private func completeOnboarding() {
        // Create sample data if option was selected
        if useSampleData {
            createSampleData()
        }
        
        // Apply final settings and complete onboarding
        hasCompletedOnboarding = true
    }
    
    // Create sample data
    private func createSampleData() {
        // First check if we already have data
        if hasSampleData() {
            return
        }
        
        // Sample clients
        let clientNames = ["Acme Corp", "Design Studio", "Pixel Perfect", "Web Wizards"]
        let clientTags = ["Tech", "Design", "Marketing", "Development"]
        let hourlyRates: [Decimal] = [85.00, 95.00, 75.00, 120.00]
        
        var sampleClients = [Client]()
        
        // Create clients
        for i in 0..<clientNames.count {
            let client = Client(context: viewContext)
            client.id = UUID()
            client.name = clientNames[i]
            client.tag = clientTags[i]
            client.hourlyRate = NSDecimalNumber(decimal: hourlyRates[i])
            sampleClients.append(client)
        }
        
        // Sample tasks
        let taskDescriptions = [
            "Create logo design",
            "Update website homepage",
            "Implement dark mode",
            "Review content strategy",
            "Fix navigation menu",
            "Prepare client presentation",
            "Draft marketing email",
            "Research competitors"
        ]
        
        // Create tasks spread over past week and coming week
        for i in 0..<taskDescriptions.count {
            let entry = LogEntry(context: viewContext)
            entry.id = UUID()
            entry.type = LogEntryType.task.rawValue
            entry.desc = taskDescriptions[i]
            
            // Assign dates - some past, some future
            let daysOffset = i - (taskDescriptions.count / 2)
            entry.date = Calendar.current.date(byAdding: .day, value: daysOffset, to: Date())
            entry.setValue(Date(), forKey: "creationDate")
            
            // Mark some as complete
            entry.isComplete = (i % 3 == 0)
            
            // Assign to a client
            entry.client = sampleClients[i % sampleClients.count]
            
            // Add some tags
            if i % 2 == 0 {
                entry.tag = ["Urgent", "Important", "Later", "Easy"][i % 4]
            }
        }
        
        // Sample payments
        let paymentAmounts: [Decimal] = [750.00, 1200.00, 450.00, 2800.00]
        let paymentDesc = [
            "Website redesign", 
            "Brand identity package",
            "Logo design",
            "Monthly retainer"
        ]
        
        // Create payments in past months
        for i in 0..<paymentAmounts.count {
            let entry = LogEntry(context: viewContext)
            entry.id = UUID()
            entry.type = LogEntryType.payment.rawValue
            entry.desc = paymentDesc[i]
            entry.client = sampleClients[i]
            entry.amount = NSDecimalNumber(decimal: paymentAmounts[i])
            
            // Spread payments over recent months
            entry.date = Calendar.current.date(byAdding: .day, value: -(i * 12), to: Date())
            entry.setValue(entry.date, forKey: "creationDate")
        }
        
        // Sample notes
        let noteContents = [
            "Client mentioned they want to add a blog section to the website #website #feedback",
            "Remember to follow up on the invoice sent last week #invoice #follow-up",
            "Ideas for the new project: focus on accessibility and responsive design #ideas #accessibility",
            "Meeting notes: discussed timeline and budget constraints #meeting #budget"
        ]
        
        // Create notes
        for i in 0..<noteContents.count {
            let entry = LogEntry(context: viewContext)
            entry.id = UUID()
            entry.type = LogEntryType.note.rawValue
            entry.desc = noteContents[i]
            
            // Give some notes clients, others no client
            if i % 2 == 0 {
                entry.client = sampleClients[i % sampleClients.count]
            }
            
            // Spread notes over recent days
            entry.date = Calendar.current.date(byAdding: .day, value: -(i * 2), to: Date())
            entry.setValue(entry.date, forKey: "creationDate")
        }
        
        // Save changes
        do {
            try viewContext.save()
        } catch {
            print("Failed to create sample data: \(error)")
        }
    }
    
    /// Check if there's sample data present
    private func hasSampleData() -> Bool {
        let clientFetch = NSFetchRequest<Client>(entityName: "Client")
        clientFetch.predicate = NSPredicate(format: "name == %@", "Acme Corp")
        
        do {
            let count = try viewContext.count(for: clientFetch)
            return count > 0
        } catch {
            print("Error checking for sample data: \(error)")
            return false
        }
    }
}

// MARK: - Preview Provider
#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 