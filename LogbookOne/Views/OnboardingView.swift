import SwiftUI
import CoreData

struct OnboardingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var hasCompletedOnboarding: Bool
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("useSampleData") private var useSampleData: Bool = false
    @AppStorage("useSystemAppearance") private var useSystemAppearance: Bool = true
    @AppStorage("useDarkMode") private var useDarkMode: Bool = false
    
    @State private var currentStep = 0
    @State private var tempUserName: String = ""
    
    var body: some View {
        ZStack {
            Color.themeBackground.ignoresSafeArea()
            
            VStack {
                // Progress indicator
                if currentStep < 5 {
                    HStack(spacing: 8) {
                        ForEach(0..<5) { step in
                            Capsule()
                                .fill(step <= currentStep ? Color.themeAccent : Color.themeAccent.opacity(0.2))
                                .frame(height: 4)
                                .frame(width: step == currentStep ? 24 : 16)
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
                
                Spacer()
                
                // Content for each step
                switch currentStep {
                case 0:
                    welcomeStep
                case 1:
                    nameStep
                case 2:
                    sampleDataStep
                case 3:
                    styleStep
                case 4:
                    successStep
                default:
                    EmptyView()
                }
                
                Spacer()
                
                // Navigation buttons
                if currentStep < 4 {
                    VStack(spacing: 16) {
                        Button(action: advanceToNextStep) {
                            HStack {
                                Text(getButtonText(for: currentStep))
                                    .font(.appHeadline)
                                
                                if currentStep != 1 || !tempUserName.isEmpty {
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
                        .disabled(currentStep == 1 && tempUserName.isEmpty)
                        .opacity(currentStep == 1 && tempUserName.isEmpty ? 0.6 : 1.0)
                        
                        if currentStep > 0 && currentStep < 4 {
                            Button("Skip") {
                                if currentStep == 1 {
                                    // Skip name entry but continue to next step
                                    currentStep += 1
                                } else if currentStep < 3 {
                                    // Skip to last step
                                    currentStep = 4
                                }
                            }
                            .font(.appSubheadline)
                            .foregroundColor(.themeSecondary)
                            .padding(.vertical, 8)
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                } else if currentStep == 4 {
                    Button(action: completeOnboarding) {
                        HStack {
                            Text("Go to Today")
                                .font(.appHeadline)
                            
                            Image(systemName: "arrow.right")
                                .font(.appHeadline)
                        }
                        .frame(height: 24)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.themeAccent)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                        .shadow(color: Color.themeAccent.opacity(0.3), radius: 5, x: 0, y: 2)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
            }
        }
    }
    
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
            Text("What should we call you in the app?")
                .font(.system(size: 24, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(.themePrimary)
            
            TextField("Your Name", text: $tempUserName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.appTitle3)
                .padding(.horizontal, 40)
                .autocapitalization(.words)
                .disableAutocorrection(true)
                .submitLabel(.next)
                .onSubmit {
                    if !tempUserName.isEmpty {
                        advanceToNextStep()
                    }
                }
        }
        .padding()
    }
    
    // Step 3: Sample Data Option
    private var sampleDataStep: some View {
        VStack(spacing: 24) {
            Text("Want to Start with Some Sample Logs?")
                .font(.system(size: 24, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(.themePrimary)
            
            Text("Helpful for first-time users to see real examples.")
                .font(.appBody)
                .multilineTextAlignment(.center)
                .foregroundColor(.themeSecondary)
                .padding(.horizontal, 24)
            
            Toggle("Add sample data", isOn: $useSampleData)
                .padding(.horizontal, 40)
                .padding(.top, 16)
                .toggleStyle(SwitchToggleStyle(tint: .themeAccent))
        }
        .padding()
    }
    
    // Step 4: Style Settings
    private var styleStep: some View {
        VStack(spacing: 24) {
            Text("Set Your Style")
                .font(.system(size: 24, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(.themePrimary)
            
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
    
    // Step 5: Success Message
    private var successStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 70))
                .foregroundColor(.themeAccent)
            
            Text("You're in.")
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(.themePrimary)
            
            VStack(spacing: 16) {
                Text("Next Steps:")
                    .font(.appHeadline)
                    .foregroundColor(.themePrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(alignment: .top, spacing: 12) {
                    Text("1.")
                        .font(.appBody)
                        .foregroundColor(.themeSecondary)
                    
                    Text("Click \"Go to Today\" below to see your daily log")
                        .font(.appBody)
                        .foregroundColor(.themeSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                HStack(alignment: .top, spacing: 12) {
                    Text("2.")
                        .font(.appBody)
                        .foregroundColor(.themeSecondary)
                    
                    Text("Tap the + button in the bottom right corner to create your first entry")
                        .font(.appBody)
                        .foregroundColor(.themeSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                HStack(alignment: .top, spacing: 12) {
                    Text("3.")
                        .font(.appBody)
                        .foregroundColor(.themeSecondary)
                    
                    Text("Choose to add a task, note, or payment")
                        .font(.appBody)
                        .foregroundColor(.themeSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
        }
        .padding(.horizontal)
    }
    
    // Helper functions
    private func getButtonText(for step: Int) -> String {
        switch step {
        case 0: return "Get Started"
        case 1: return "Next"
        case 2: return "Continue"
        case 3: return "Finish Setup"
        default: return "Continue"
        }
    }
    
    private func advanceToNextStep() {
        if currentStep == 1 {
            // Save username from temp value
            userName = tempUserName
        }
        
        withAnimation {
            currentStep += 1
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
            "Client mentioned they want to add a blog section to the website",
            "Remember to follow up on the invoice sent last week",
            "Ideas for the new project: focus on accessibility and responsive design",
            "Meeting notes: discussed timeline and budget constraints"
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

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 