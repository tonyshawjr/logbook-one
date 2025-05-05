import SwiftUI

struct NagModeJournalView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var nagManager = NagModeManager.shared
    
    // Computed properties for stats
    private var totalNags: Int {
        nagManager.nagHistory.filter { $0.eventType == .nagShown }.count
    }
    
    private var ignoredNags: Int {
        nagManager.nagHistory.filter { $0.responseType == .dismissed }.count
    }
    
    private var snoozedNags: Int {
        nagManager.nagHistory.filter { $0.responseType == .snoozed }.count
    }
    
    private var respondedNags: Int {
        nagManager.nagHistory.filter { $0.responseType == .loggedEntry }.count
    }
    
    private var responseRate: Double {
        guard totalNags > 0 else { return 0 }
        return Double(respondedNags) / Double(totalNags) * 100
    }
    
    private var streaksSaved: Int {
        // Count sequences of .nagShown followed by .nagResponded
        var count = 0
        var previousWasNag = false
        
        for item in nagManager.nagHistory {
            if previousWasNag && item.responseType == .loggedEntry {
                count += 1
                previousWasNag = false
            } else if item.eventType == .nagShown {
                previousWasNag = true
            } else {
                previousWasNag = false
            }
        }
        
        return count
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Logo section
                        nagModeLogo
                            .padding(.top, 20)
                        
                        // Stats card
                        statsCard
                        
                        // History list
                        if !nagManager.nagHistory.isEmpty {
                            historyList
                        } else {
                            emptyState
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Nag Journal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.themeBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - UI Components
    
    private var nagModeLogo: some View {
        VStack(spacing: 6) {
            // Simple Impact-style font
            Text("NAG MODE")
                .font(.system(size: 42, weight: .black, design: .default))
                .foregroundColor(.red)
                .kerning(2)
                .tracking(1)
            
            Text("YOUR ACCOUNTABILITY JOURNAL")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.themeSecondary)
        }
        .padding(.vertical, 16)
    }
    
    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Accountability Stats")
                .font(.appTitle3)
                .foregroundColor(.themePrimary)
            
            Divider()
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Total Reminders")
                        .font(.appSubheadline)
                        .foregroundColor(.themeSecondary)
                    
                    Text("\(totalNags)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.themePrimary)
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("Streaks Saved")
                        .font(.appSubheadline)
                        .foregroundColor(.themeSecondary)
                    
                    Text("\(streaksSaved)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.themeAccent)
                }
            }
            
            Divider()
            
            HStack {
                // Response pie chart
                ZStack {
                    Circle()
                        .trim(from: 0, to: CGFloat(responseRate) / 100)
                        .stroke(Color.themeAccent, lineWidth: 8)
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                    
                    Circle()
                        .trim(from: CGFloat(responseRate) / 100, to: 1)
                        .stroke(Color.themeSecondary.opacity(0.3), lineWidth: 8)
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(responseRate))%")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.themePrimary)
                }
                
                VStack(alignment: .leading) {
                    Text("Response Rate")
                        .font(.appSubheadline)
                        .foregroundColor(.themePrimary)
                    
                    Text("You respond to \(Int(responseRate))% of reminders")
                        .font(.appCaption)
                        .foregroundColor(.themeSecondary)
                }
                
                Spacer()
            }
            
            if ignoredNags > 0 || snoozedNags > 0 {
                Divider()
                
                VStack(alignment: .leading, spacing: 4) {
                    if ignoredNags > 0 {
                        Text("You've ignored me \(ignoredNags) time\(ignoredNags == 1 ? "" : "s")")
                            .font(.appCaption)
                            .foregroundColor(.themeSecondary)
                    }
                    
                    if snoozedNags > 0 {
                        Text("You've snoozed me \(snoozedNags) time\(snoozedNags == 1 ? "" : "s")")
                            .font(.appCaption)
                            .foregroundColor(.themeSecondary)
                    }
                }
            }
        }
        .padding()
    }
    
    private var historyList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.appTitle3)
                .foregroundColor(.themePrimary)
            
            ForEach(nagManager.nagHistory.prefix(10)) { item in
                HStack(spacing: 12) {
                    // Icon
                    Image(systemName: getIconForItem(item))
                        .font(.system(size: 18))
                        .foregroundColor(getColorForItem(item))
                        .frame(width: 24, height: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        // Event description
                        Text(getDescriptionForItem(item))
                            .font(.appSubheadline)
                            .foregroundColor(.themePrimary)
                        
                        // Date
                        Text(formatDate(item.date))
                            .font(.appCaption)
                            .foregroundColor(.themeSecondary)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 8)
                
                if item.id != nagManager.nagHistory.prefix(10).last?.id {
                    Divider()
                }
            }
            
            if nagManager.nagHistory.count > 10 {
                Text("And \(nagManager.nagHistory.count - 10) more...")
                    .font(.appCaption)
                    .foregroundColor(.themeSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
            }
        }
        .padding()
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("No Nag Activity Yet")
                .font(.appTitle3)
                .foregroundColor(.themePrimary)
            
            Text("Your nag activity history will appear here once Nag Mode starts reminding you.")
                .font(.appBody)
                .multilineTextAlignment(.center)
                .foregroundColor(.themeSecondary)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    // MARK: - Helper Functions
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func getIconForItem(_ item: NagHistoryItem) -> String {
        switch (item.eventType, item.responseType) {
        case (.nagShown, _):
            return "bell.fill"
        case (.nagSnoozed, _):
            return "alarm"
        case (.nagDismissed, _):
            return "xmark.circle"
        case (.nagResponded, _):
            return "checkmark.circle.fill"
        }
    }
    
    private func getColorForItem(_ item: NagHistoryItem) -> Color {
        switch (item.eventType, item.responseType) {
        case (.nagShown, _):
            return .themeAccent
        case (.nagSnoozed, _):
            return .themeWarning
        case (.nagDismissed, _):
            return .themeDanger
        case (.nagResponded, _):
            return .themeSuccess
        }
    }
    
    private func getDescriptionForItem(_ item: NagHistoryItem) -> String {
        switch (item.eventType, item.responseType) {
        case (.nagShown, _):
            return "Reminder sent"
        case (.nagSnoozed, _):
            return "You snoozed a reminder"
        case (.nagDismissed, _):
            return "You dismissed a reminder"
        case (.nagResponded, .loggedEntry):
            return "You responded by logging an entry"
        default:
            return "Unknown activity"
        }
    }
}

#Preview {
    NagModeJournalView()
} 