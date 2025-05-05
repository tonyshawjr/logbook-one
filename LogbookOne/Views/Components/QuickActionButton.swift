import SwiftUI

struct QuickActionButton: View {
    // The tabs where this button should be shown (0=Today, 1=Tasks, 2=Notes, 3=Payments)
    // Clients is now tab 4, and there's no tab 5 or 6 anymore
    private let allowedTabs = [0, 1, 2, 3]
    
    @Binding var showingSheet: Bool
    var currentTab: Int
    @ObservedObject private var nagManager = NagModeManager.shared
    @ObservedObject private var purchaseManager = PurchaseManager.shared
    
    // Check if the current tab is premium and accessible
    private var isPremiumTab: Bool {
        switch currentTab {
        case 1: // Tasks
            return purchaseManager.hasAccess(to: .tasks) == false
        case 3: // Payments
            return purchaseManager.hasAccess(to: .payments) == false
        case 4: // Clients
            return purchaseManager.hasAccess(to: .clients) == false
        default:
            return false
        }
    }
    
    var body: some View {
        // Only render actual content if we're on an allowed tab
        if allowedTabs.contains(currentTab) {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        // Use haptic feedback when pressing button
                        let impactMed = UIImpactFeedbackGenerator(style: .medium)
                        impactMed.impactOccurred()
                        
                        // If it's a premium tab and we don't have access, still show the sheet
                        // The sheet will handle showing the upgrade prompt
                        showingSheet = true
                        
                        // Tell NagMode that the user is logging an entry
                        // Only if we're not on a premium tab or we have access
                        if nagManager.showInAppNag && !isPremiumTab {
                            nagManager.userLoggedEntry()
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(
                                Circle()
                                    .fill(Color.themeAccent)
                                    .shadow(color: Color.themeAccent.opacity(0.3), radius: 5, x: 0, y: 3)
                            )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .nagModePulse() // Apply the pulsing effect when Nag Mode is active
                    .padding(.trailing, 20)
                }
            }
            .background(Color.clear)
        } else {
            // Return an empty view for tabs where the button shouldn't appear
            EmptyView()
        }
    }
}

// Custom button style for smoother press animation
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

#Preview {
    QuickActionButton(showingSheet: .constant(false), currentTab: 0)
} 