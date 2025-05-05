import SwiftUI
import MessageUI
import StoreKit
import CoreData
import UIKit

// Feedback type enum used by SettingsView and FeedbackFormView
enum FeedbackType: String {
    case support = "Support Request"
    case feature = "Feature Request"
    case bug = "Bug Report"
}

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.openURL) private var openURL
    
    // Settings state
    @AppStorage("useDarkMode") private var useDarkMode = false
    @AppStorage("useSystemAppearance") private var useSystemAppearance = true
    @AppStorage("startDayOfWeek") private var startDayOfWeek = 1 // 1 = Sunday
    @AppStorage("autoHideCompletedTasks") private var autoHideCompletedTasks = true
    @AppStorage("defaultCurrency") private var defaultCurrency = "USD"
    
    // Account info
    @AppStorage("userName") private var userName: String = ""
    @State private var tempUserName: String = ""
    @State private var editingName: Bool = false
    
    // Sample data
    @State private var useSampleData: Bool = false
    
    // UI state
    @State private var showingMailView = false
    @State private var showingFeedbackForm = false
    @State private var feedbackType: FeedbackType = .support
    @State private var mailSubject = "Logbook One Support Request"
    @State private var mailResult: Result<MFMailComposeResult, Error>? = nil
    @State private var showingDeleteConfirmation = false
    @State private var feedbackMessage: String = ""
    
    // Force view refresh
    @State private var refreshToggle = false
    
    // App info
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    var body: some View {
        VStack(spacing: 0) {
            // Settings header view - consistent with other views
            HStack {
                Text("Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.themePrimary)
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 8)
            .background(Color.themeBackground)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Account section
                    accountSection
                    
                    // Settings sections
                    appearanceSection
                    preferencesSection
                    nagModeSection
                    dataSection
                    supportSection
                    legalSection
                    aboutSection
                    
                    // Footer note
                    Text("Logbook One v\(appVersion) (\(buildNumber))")
                        .font(.appCaption)
                        .foregroundColor(.themeSecondary)
                        .padding(.top, 8)
                }
                .padding(.vertical)
            }
        }
        .background(Color.themeBackground)
        // This invisible view forces a refresh when refreshToggle changes
        .overlay(Color.clear.opacity(refreshToggle ? 0.0001 : 0))
        .sheet(isPresented: $showingMailView) {
            MailView(subject: mailSubject, result: $mailResult)
        }
        .sheet(isPresented: $showingFeedbackForm) {
            FeedbackFormView(feedbackType: feedbackType)
                .presentationDetents([.height(450)])
        }
        .alert("Delete All Data", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAllData()
            }
        } message: {
            Text("This will permanently delete all your tasks, notes, payments, and clients. This action cannot be undone.")
        }
        .onAppear {
            tempUserName = userName
            
            // Check if sample data is active
            checkSampleDataStatus()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .toolbarBackground(Color.themeBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .preferredColorScheme(getPreferredColorScheme())
    }
    
    // Helper to get the current preferred color scheme based on settings
    private func getPreferredColorScheme() -> ColorScheme? {
        if useSystemAppearance {
            return nil // Use system setting
        } else {
            return useDarkMode ? .dark : .light
        }
    }
    
    // MARK: - Helper Methods
    
    /// Deletes all data from the app
    private func deleteAllData() {
        // Delete all LogEntry records
        let logEntryFetch = NSFetchRequest<LogEntry>(entityName: "LogEntry")
        
        // Delete all Client records
        let clientFetch = NSFetchRequest<Client>(entityName: "Client")
        
        do {
            // Delete all log entries
            let logEntries = try viewContext.fetch(logEntryFetch)
            for entry in logEntries {
                viewContext.delete(entry)
            }
            
            // Delete all clients
            let clients = try viewContext.fetch(clientFetch)
            for client in clients {
                viewContext.delete(client)
            }
            
            try viewContext.save()
            
            // Update sample data state
            useSampleData = false
            
            // Add haptic feedback for confirmation
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } catch {
            print("Failed to delete data: \(error)")
            
            // Error haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }
    
    /// Create sample data for demonstration
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
            
            // Update status
            useSampleData = true
            
            // Success feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } catch {
            print("Failed to create sample data: \(error)")
            
            // Error feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }
    
    /// Remove sample data from the app
    private func removeSampleData() {
        // This is the same as deleteAllData for now
        deleteAllData()
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
    
    /// Check sample data status to update UI
    private func checkSampleDataStatus() {
        useSampleData = hasSampleData()
    }
    
    // MARK: - Content Sections
    
    private var accountSection: some View {
        SettingsSectionView(title: "Account Info", icon: "person.crop.circle") {
            VStack(spacing: 16) {
                HStack(spacing: 20) {
                    // Name editor
                    VStack(alignment: .leading, spacing: 8) {
                        if editingName {
                            TextField("Your Name", text: $tempUserName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.appHeadline)
                                .submitLabel(.done)
                                .onSubmit {
                                    userName = tempUserName
                                    editingName = false
                                }
                                .padding(.trailing, 4)
                        } else {
                            Text(userName.isEmpty ? "Add Your Name" : userName)
                                .font(.appHeadline)
                                .foregroundColor(userName.isEmpty ? .themeSecondary : .themePrimary)
                        }
                        
                        Text("Set your name for personalized greetings")
                            .font(.appCaption)
                            .foregroundColor(.themeSecondary)
                    }
                    
                    Spacer()
                    
                    // Edit button
                    Button(action: {
                        if editingName {
                            userName = tempUserName
                            editingName = false
                        } else {
                            editingName = true
                        }
                    }) {
                        Image(systemName: editingName ? "checkmark" : "pencil")
                            .foregroundColor(.themeAccent)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.themeAccent.opacity(0.1))
                            )
                    }
                }
                .padding()
            }
        }
    }
    
    private var appearanceSection: some View {
        SettingsSectionView(title: "Appearance", icon: "paintbrush") {
            VStack(alignment: .leading, spacing: 16) {
                Toggle("Use System Appearance", isOn: $useSystemAppearance)
                    .onChange(of: useSystemAppearance) { _, newValue in
                        if newValue {
                            // Reset manual dark mode when using system appearance
                            useDarkMode = false
                        }
                        
                        // Apply the change directly to all windows
                        applyAppearanceChange()
                        
                        // Force a refresh of this view
                        withAnimation {
                            refreshToggle.toggle()
                        }
                        
                        // Post notification for app-wide changes
                        NotificationCenter.default.post(name: NSNotification.Name("RefreshAppearance"), object: nil)
                    }
                
                if !useSystemAppearance {
                    Toggle("Dark Mode", isOn: $useDarkMode)
                        .onChange(of: useDarkMode) { _, newValue in
                            // Apply the change directly to all windows
                            applyAppearanceChange()
                            
                            // Force a refresh of this view
                            withAnimation {
                                refreshToggle.toggle()
                            }
                            
                            // Post notification for app-wide changes
                            NotificationCenter.default.post(name: NSNotification.Name("RefreshAppearance"), object: nil)
                        }
                }
                
                NavigationLink(destination: ThemeColorDebugView()) {
                    HStack {
                        Text("View Theme Colors")
                        
                        Spacer()
                        
                        Image(systemName: "circle.hexagongrid.fill")
                            .foregroundColor(.themeAccent)
                    }
                }
            }
            .padding()
        }
    }
    
    private var preferencesSection: some View {
        SettingsSectionView(title: "Preferences", icon: "gear") {
            VStack(alignment: .leading, spacing: 16) {
                // Day of week picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Start Day of Week")
                        .font(.appSubheadline)
                        .foregroundColor(.themePrimary)
                    
                    Picker("Start Day of Week", selection: $startDayOfWeek) {
                        Text("Sunday").tag(1)
                        Text("Monday").tag(2)
                        Text("Saturday").tag(7)
                    }
                    .pickerStyle(.segmented)
                }
                
                Divider()
                
                // Currency picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Default Currency")
                        .font(.appSubheadline)
                        .foregroundColor(.themePrimary)
                    
                    Picker("Default Currency", selection: $defaultCurrency) {
                        Text("USD ($)").tag("USD")
                        Text("EUR (€)").tag("EUR")
                        Text("GBP (£)").tag("GBP")
                        Text("JPY (¥)").tag("JPY")
                        Text("CAD ($)").tag("CAD")
                        Text("AUD ($)").tag("AUD")
                    }
                    .pickerStyle(.menu)
                }
                
                Divider()
                
                // Task preferences
                Toggle("Automatically Hide Completed Tasks", isOn: $autoHideCompletedTasks)
            }
            .padding()
        }
    }
    
    // Nag Mode section
    private var nagModeSection: some View {
        SettingsSectionView(title: "Accountability", icon: "bell.badge.fill") {
            VStack(spacing: 16) {
                NavigationLink(destination: NagModeSettingsView()) {
                    HStack {
                        // NAG MODE text with simple Impact style
                        Text("NAG MODE")
                            .font(.system(size: 18, weight: .black, design: .default))
                            .foregroundColor(.red)
                            .kerning(1)
                            .tracking(0.5)
                        
                        Spacer()
                        
                        // Status & chevron
                        HStack {
                            if UserDefaults.standard.bool(forKey: "nagModeEnabled") {
                                Text("On")
                                    .font(.appSubheadline)
                                    .foregroundColor(.themeSuccess)
                            } else {
                                Text("Off")
                                    .font(.appSubheadline)
                                    .foregroundColor(.themeSecondary)
                            }
                            
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Color.themeSecondary.opacity(0.5))
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                if UserDefaults.standard.bool(forKey: "nagModeEnabled") && 
                   UserDefaults.standard.bool(forKey: "nagModeShowJournal") {
                    NavigationLink(destination: NagModeJournalView()) {
                        SettingsRowView(title: "View Nag Journal", icon: "calendar.badge.clock", iconColor: .themeAccent)
                    }
                }
            }
            .padding()
        }
    }
    
    private var dataSection: some View {
        SettingsSectionView(title: "Data Management", icon: "externaldrive") {
            VStack(spacing: 16) {
                NavigationLink(destination: ExportView()) {
                    SettingsRowView(title: "Export Data", icon: "square.and.arrow.up", iconColor: .themeAccent)
                }
                
                NavigationLink(destination: ImportView()) {
                    SettingsRowView(title: "Import Data", icon: "square.and.arrow.down", iconColor: .themeAccent)
                }
                
                Button(action: {
                    showingDeleteConfirmation = true
                }) {
                    SettingsRowView(title: "Clear All Data", icon: "trash", iconColor: .themeDanger)
                }
                
                HStack {
                    Image(systemName: "cube.box")
                        .font(.system(size: 18))
                        .foregroundColor(.themeAccent)
                        .frame(width: 24, height: 24)
                    
                    Text("Use Sample Data")
                        .font(.appBody)
                        .foregroundColor(.themePrimary)
                    
                    Spacer()
                    
                    Toggle("", isOn: $useSampleData)
                        .labelsHidden()
                }
                .onChange(of: useSampleData) { oldValue, newValue in
                    if newValue {
                        createSampleData()
                    } else {
                        removeSampleData()
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
            }
            .padding()
        }
    }
    
    private var supportSection: some View {
        SettingsSectionView(title: "Support", icon: "questionmark.circle") {
            VStack(spacing: 16) {
                Button(action: {
                    feedbackType = .support
                    showingFeedbackForm = true
                }) {
                    SettingsRowView(title: "Contact Support", icon: "envelope", iconColor: .themeAccent)
                }
                
                Button(action: {
                    feedbackType = .feature
                    showingFeedbackForm = true
                }) {
                    SettingsRowView(title: "Submit Feature Request", icon: "lightbulb", iconColor: .themeWarning)
                }
                
                Button(action: {
                    feedbackType = .bug
                    showingFeedbackForm = true
                }) {
                    SettingsRowView(title: "Report a Bug", icon: "ladybug", iconColor: .themeDanger)
                }
                
                Button(action: {
                    // Open App Store review
                    if #available(iOS 18.0, *) {
                        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                            AppStore.requestReview(in: scene)
                        }
                    } else {
                        // Fallback for iOS versions below 18.0
                        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                            SKStoreReviewController.requestReview(in: scene)
                        }
                    }
                }) {
                    SettingsRowView(title: "Rate the App", icon: "star", iconColor: .themeWarning)
                }
            }
            .padding()
        }
    }
    
    private var legalSection: some View {
        SettingsSectionView(title: "Legal & Info", icon: "doc.text") {
            VStack(spacing: 16) {
                Button(action: {
                    openURL(URL(string: "https://example.com/terms")!)
                }) {
                    SettingsRowView(title: "Terms of Use", icon: "doc.plaintext", iconColor: .themeAccent)
                }
                
                Button(action: {
                    openURL(URL(string: "https://example.com/privacy")!)
                }) {
                    SettingsRowView(title: "Privacy Policy", icon: "lock.shield", iconColor: .themeAccent)
                }
                
                NavigationLink(destination: ChangelogView()) {
                    SettingsRowView(title: "What's New", icon: "list.star", iconColor: .themeAccent)
                }
            }
            .padding()
        }
    }
    
    private var aboutSection: some View {
        SettingsSectionView(title: "About", icon: "info.circle") {
            VStack(alignment: .leading, spacing: 16) {
                Text("Logbook One is a simple, elegant freelance work tracker designed for independent professionals who want to keep track of their tasks, notes, and payments in one place.")
                    .font(.appBody)
                    .foregroundColor(.themeSecondary)
                    .padding()
                
                Divider()
                
                // Credits
                VStack(alignment: .leading, spacing: 8) {
                    Text("Created by")
                        .font(.appSubheadline)
                        .foregroundColor(.themePrimary)
                    
                    Text("Tony Shaw")
                        .font(.appBody)
                        .foregroundColor(.themeSecondary)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
    }
    
    // Apply appearance changes immediately to all app windows
    private func applyAppearanceChange() {
        for scene in UIApplication.shared.connectedScenes {
            if let windowScene = scene as? UIWindowScene {
                for window in windowScene.windows {
                    if useSystemAppearance {
                        window.overrideUserInterfaceStyle = .unspecified
                    } else {
                        window.overrideUserInterfaceStyle = useDarkMode ? .dark : .light
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

/// A section container for settings
struct SettingsSectionView<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.themeAccent)
                
                Text(title)
                    .font(.appHeadline)
                    .foregroundColor(.themePrimary)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            // Section content
            content
                .background(Color.themeCard)
                .cornerRadius(16)
                .padding(.horizontal)
        }
    }
}

/// A standard row for settings items
struct SettingsRowView: View {
    let title: String
    let icon: String
    var iconColor: Color = .themeAccent
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(iconColor)
                .frame(width: 24, height: 24)
            
            Text(title)
                .font(.appBody)
                .foregroundColor(.themePrimary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundColor(Color.themeSecondary.opacity(0.5))
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Mail View
struct MailView: UIViewControllerRepresentable {
    let subject: String
    @Binding var result: Result<MFMailComposeResult, Error>?
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let viewController = MFMailComposeViewController()
        viewController.mailComposeDelegate = context.coordinator
        viewController.setToRecipients(["support@example.com"])
        viewController.setSubject(subject)
        
        let message = """
            App Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
            
            Please describe your request or issue:
            
            """
        
        viewController.setMessageBody(message, isHTML: false)
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        var parent: MailView
        
        init(_ parent: MailView) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            if let error = error {
                parent.result = .failure(error)
            } else {
                parent.result = .success(result)
            }
            controller.dismiss(animated: true)
        }
    }
}

// MARK: - Changelog View
struct ChangelogView: View {
    // Sample changelog - would be populated from a real source
    private let versions = [
        ChangelogVersion(version: "1.0.1", date: "May 15, 2025", changes: [
            "Fixed dark mode not applying correctly",
            "Added sample data for demo purposes",
            "Improved performance of calendar view",
            "Fixed bug with payment calculations"
        ]),
        ChangelogVersion(version: "1.0", date: "May 3, 2025", changes: [
            "Initial release of Logbook One",
            "Task management with completion tracking",
            "Client management system",
            "Payment and invoice tracking",
            "Note-taking functionality",
            "Dark mode support"
        ])
    ]
    
    var body: some View {
        List {
            ForEach(versions) { version in
                Section(header: 
                    HStack {
                        Text("Version \(version.version)")
                            .font(.appHeadline)
                        Spacer()
                        Text(version.date)
                            .font(.appCaption)
                            .foregroundColor(.themeSecondary)
                    }
                ) {
                    ForEach(version.changes, id: \.self) { change in
                        HStack(alignment: .top) {
                            Text("•")
                                .font(.appBody)
                                .foregroundColor(.themeAccent)
                            
                            Text(change)
                                .font(.appBody)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .navigationTitle("What's New")
    }
    
    // Changelog data model
    struct ChangelogVersion: Identifiable {
        let id = UUID()
        let version: String
        let date: String
        let changes: [String]
    }
}

//MARK: - FeedbackFormView
struct FeedbackFormView: View {
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.openURL) private var openURL
    
    let feedbackType: FeedbackType
    @State private var email: String = ""
    @State private var message: String = ""
    @State private var isSending = false
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Contact Information")) {
                    TextField("Your Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                Section(header: Text(getMessageHeader())) {
                    TextEditor(text: $message)
                        .frame(minHeight: 150)
                }
                
                Section {
                    Button(action: sendFeedback) {
                        HStack {
                            Spacer()
                            if isSending {
                                ProgressView()
                                    .padding(.trailing, 10)
                            }
                            Text("Submit")
                                .font(.headline)
                            Spacer()
                        }
                    }
                    .disabled(email.isEmpty || message.isEmpty || isSending)
                }
            }
            .navigationTitle(feedbackType.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .alert("Thank You", isPresented: $showingSuccessAlert) {
                Button("OK") {
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("Your \(feedbackType.rawValue.lowercased()) has been submitted successfully.")
            }
            .alert("Error", isPresented: $showingErrorAlert) {
                Button("Try Again", role: .cancel) { }
                Button("Send Email Instead") {
                    sendViaEmail()
                }
            } message: {
                Text("There was a problem submitting your feedback. Please try again or use email instead.")
            }
        }
    }
    
    private func getMessageHeader() -> String {
        switch feedbackType {
        case .support:
            return "How can we help you?"
        case .feature:
            return "Describe the feature you'd like to see"
        case .bug:
            return "Describe the issue you're experiencing"
        }
    }
    
    private func sendFeedback() {
        isSending = true
        
        // Simulate network request
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isSending = false
            
            // In a real app, this would send data to your backend
            if Bool.random() { // Simulate success/failure for demo
                showingSuccessAlert = true
            } else {
                showingErrorAlert = true
            }
        }
    }
    
    private func sendViaEmail() {
        let subject = URLQueryItem(name: "subject", value: feedbackType.rawValue)
        let body = URLQueryItem(name: "body", value: message)
        
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = "support@example.com"
        components.queryItems = [subject, body]
        
        if let url = components.url {
            openURL(url)
        }
        
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
} 