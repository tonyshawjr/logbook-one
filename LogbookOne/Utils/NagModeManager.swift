import Foundation
import UserNotifications
import SwiftUI
import CoreData

class NagModeManager: ObservableObject {
    static let shared = NagModeManager()
    
    // Published properties to drive UI
    @Published var showInAppNag: Bool = false
    @Published var currentNagMessage: String = ""
    @Published var nagHistory: [NagHistoryItem] = []
    
    // Internal state
    private var hasLoggedTodayCache: Bool = false
    private var notificationIds: [String] = []
    private let maxHistory = 30 // Keep track of the last 30 nag events
    
    private init() {
        // Load existing history if available
        loadNagHistory()
        
        // Initial update
        updateHasLoggedToday()
        
        // Set up for notifications
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
    
    // MARK: - Public Methods
    
    /// Checks conditions and schedules nags if needed
    func checkAndScheduleNags(in context: NSManagedObjectContext) {
        // Only proceed if Nag Mode is enabled
        guard UserDefaults.standard.bool(forKey: "nagModeEnabled") else {
            cancelAllNags()
            return
        }
        
        // Update cache to check if user has logged today
        updateHasLoggedToday(with: context)
        
        // Don't nag if they've already logged something today
        guard !hasLoggedTodayCache else {
            cancelAllNags()
            return
        }
        
        // Check if we're past the cutoff time
        let cutoffHour = UserDefaults.standard.integer(forKey: "nagModeCutoffTime")
        let currentHour = Calendar.current.component(.hour, from: Date())
        
        if currentHour >= cutoffHour {
            scheduleNagNotifications()
            
            // Show in-app nag if enabled
            if UserDefaults.standard.bool(forKey: "nagModeInAppNags") {
                showInAppNag = true
                currentNagMessage = getRandomNagMessage()
                
                // Record this nag in history
                recordNagEvent(type: .nagShown, response: .none)
            }
        }
    }
    
    /// Call this method when user logs an entry
    func userLoggedEntry() {
        hasLoggedTodayCache = true
        cancelAllNags()
        showInAppNag = false
        
        // Record response in history
        recordNagEvent(type: .nagResponded, response: .loggedEntry)
    }
    
    /// Call this method when user dismisses a nag
    func userDismissedNag() {
        showInAppNag = false
        
        // Record response in history
        recordNagEvent(type: .nagDismissed, response: .dismissed)
    }
    
    /// Call this method when user snoozes a nag
    func userSnoozedNag(minutes: Int = 30) {
        showInAppNag = false
        
        // Schedule a single notification for later
        scheduleSnoozeNotification(minutes: minutes)
        
        // Record response in history
        recordNagEvent(type: .nagSnoozed, response: .snoozed)
    }
    
    // MARK: - Notification Handling
    
    /// Schedule notifications based on intensity setting
    private func scheduleNagNotifications() {
        // Clear any existing notifications first
        cancelAllNags()
        
        let intensity = UserDefaults.standard.string(forKey: "nagModeIntensity") ?? "Gentle"
        
        // Set up notification content
        let content = UNMutableNotificationContent()
        content.title = "Logbook One"
        content.body = getRandomNagMessage()
        content.sound = UNNotificationSound.default
        
        // Set up notification frequency
        var intervalMinutes = 0
        
        switch intensity {
        case "Gentle":
            // Just one notification
            scheduleNotification(content: content, identifier: "nag_gentle")
            return
            
        case "Persistent":
            // Hourly
            intervalMinutes = 60
            
        case "Beast Mode":
            // Every 30 minutes
            intervalMinutes = 30
            
        default:
            intervalMinutes = 60
        }
        
        // Schedule repeating notifications
        for i in 0..<5 { // Maximum 5 notifications in queue
            let identifier = "nag_\(intensity.lowercased())_\(i)"
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: TimeInterval(intervalMinutes * 60 * (i + 1)),
                repeats: false
            )
            
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request)
            notificationIds.append(identifier)
        }
    }
    
    /// Schedule a single notification
    private func scheduleNotification(content: UNMutableNotificationContent, identifier: String) {
        // Schedule in 1 minute
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
        notificationIds.append(identifier)
    }
    
    /// Schedule a snooze notification
    private func scheduleSnoozeNotification(minutes: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Logbook One"
        content.body = getRandomNagMessage()
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(minutes * 60),
            repeats: false
        )
        
        let identifier = "nag_snooze"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
        notificationIds.append(identifier)
    }
    
    /// Cancel all scheduled notifications
    private func cancelAllNags() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: notificationIds)
        notificationIds = []
        showInAppNag = false
    }
    
    // MARK: - Message Generation
    
    /// Get a random nag message based on the selected tone
    private func getRandomNagMessage() -> String {
        let tone = UserDefaults.standard.string(forKey: "nagModeTone") ?? "Encouraging"
        let buddyName = UserDefaults.standard.string(forKey: "nagModeBuddyName") ?? ""
        
        let messages: [String]
        
        switch tone {
        case "Encouraging":
            messages = [
                "Still time to log something today. You've got this.",
                "A little progress goes a long way. Drop in a note or task.",
                "One log = one less thing to forget later.",
                "Want to stay on top of it? Log something now.",
                "Momentum starts with one tap."
            ]
        case "Bossy":
            messages = [
                "No excuses. Add a log.",
                "Didn't log today yet. Fix that.",
                "You said you wanted to stay on track. Prove it.",
                "Don't let the day win. Log something.",
                "Tick-tock. The day's moving. So should you."
            ]
        case "Friendly":
            messages = [
                "Hey, got anything to jot down?",
                "Quick brain dump while it's still fresh?",
                "You've been quiet today. Want to log something?",
                "Tap in real quick and stay on top of things.",
                "Just checking in—any updates for today?"
            ]
        case "Sarcastic":
            messages = [
                "No logs yet? What are you even doing?",
                "Today's looking empty… just like your entries.",
                "Still waiting on that log. Just like your clients.",
                "If procrastinating was a task, you'd have logged it.",
                "Come on. It takes 3 seconds."
            ]
        default:
            messages = [
                "Don't forget to log your activity today.",
                "Time to add an entry to your logbook.",
                "Keep your records up to date by logging now."
            ]
        }
        
        let message = messages.randomElement() ?? "Time to log something!"
        
        // Add buddy name if set
        if !buddyName.isEmpty {
            return "\(buddyName) says: \(message)"
        }
        
        return message
    }
    
    // MARK: - Data Helpers
    
    /// Check if the user has logged anything today
    private func updateHasLoggedToday(with context: NSManagedObjectContext? = nil) {
        guard let context = context else {
            return // Skip check if no context provided
        }
        
        let fetchRequest: NSFetchRequest<LogEntry> = LogEntry.fetchRequest()
        
        // Get today's date range
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        // Create predicate for entries created today
        fetchRequest.predicate = NSPredicate(
            format: "date >= %@ AND date < %@",
            today as NSDate,
            tomorrow as NSDate
        )
        
        // Limit to one result since we only need to know if any exist
        fetchRequest.fetchLimit = 1
        
        do {
            let entriesCount = try context.count(for: fetchRequest)
            hasLoggedTodayCache = entriesCount > 0
        } catch {
            print("Error checking for today's entries: \(error)")
            hasLoggedTodayCache = false
        }
    }
    
    // MARK: - History Tracking
    
    /// Record a nag event in the history
    private func recordNagEvent(type: NagEventType, response: NagResponseType) {
        let newItem = NagHistoryItem(
            date: Date(),
            eventType: type,
            responseType: response
        )
        
        // Add to history
        nagHistory.insert(newItem, at: 0)
        
        // Trim history if needed
        if nagHistory.count > maxHistory {
            nagHistory = Array(nagHistory.prefix(maxHistory))
        }
        
        // Save history
        saveNagHistory()
    }
    
    /// Save nag history to UserDefaults
    private func saveNagHistory() {
        if let encoded = try? JSONEncoder().encode(nagHistory) {
            UserDefaults.standard.set(encoded, forKey: "nagModeHistory")
        }
    }
    
    /// Load nag history from UserDefaults
    private func loadNagHistory() {
        if let data = UserDefaults.standard.data(forKey: "nagModeHistory"),
           let decoded = try? JSONDecoder().decode([NagHistoryItem].self, from: data) {
            nagHistory = decoded
        }
    }
}

// MARK: - Supporting Types

/// Type of nag events
enum NagEventType: String, Codable {
    case nagShown
    case nagSnoozed
    case nagDismissed
    case nagResponded
}

/// Type of user responses to nags
enum NagResponseType: String, Codable {
    case none
    case snoozed
    case dismissed
    case loggedEntry
}

/// History item for tracking nag events
struct NagHistoryItem: Identifiable, Codable {
    var id = UUID()
    let date: Date
    let eventType: NagEventType
    let responseType: NagResponseType
    
    // For Codable
    enum CodingKeys: String, CodingKey {
        case id, date, eventType, responseType
    }
}

// MARK: - SwiftUI Components

/// Banner view shown at the top of the screen when nag is active
struct NagModeBanner: View {
    @ObservedObject private var nagManager = NagModeManager.shared
    
    var body: some View {
        if nagManager.showInAppNag {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "bell.fill")
                        .foregroundColor(.white)
                        .padding(.trailing, 4)
                    
                    Text(nagManager.currentNagMessage)
                        .font(.appSubheadline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        nagManager.userDismissedNag()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .padding(8)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(Color.themeAccent)
                .onTapGesture {
                    // Take user to add entry view
                    // This would be implemented by your app's navigation system
                }
                
                Divider()
                    .opacity(0)
            }
            .transition(.move(edge: .top))
        }
    }
}

/// Pulsing button effect for when nag mode is active
struct NagModePulseEffect: ViewModifier {
    @ObservedObject private var nagManager = NagModeManager.shared
    
    @State private var pulsing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(pulsing && nagManager.showInAppNag ? 1.1 : 1.0)
            .animation(
                nagManager.showInAppNag ? 
                    Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true) : 
                    .default,
                value: pulsing
            )
            .onAppear {
                if nagManager.showInAppNag {
                    pulsing = true
                }
            }
            .onChange(of: nagManager.showInAppNag) { _, isShowing in
                pulsing = isShowing
            }
    }
}

extension View {
    func nagModePulse() -> some View {
        self.modifier(NagModePulseEffect())
    }
} 