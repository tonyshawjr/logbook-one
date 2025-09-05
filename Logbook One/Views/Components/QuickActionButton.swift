import SwiftUI

struct QuickActionButton: View {
    // The tabs where this button should be shown (0=Today, 1=Tasks, 2=Notes, 3=Payments)
    // Clients is now tab 4, and there's no tab 5 or 6 anymore
    private let allowedTabs = [0, 1, 2, 3]
    
    @Binding var showingSheet: Bool
    var currentTab: Int
    @ObservedObject private var nagManager = NagModeManager.shared
    @Environment(\.theme) private var theme
    
    // State for FAB menu
    @State private var isMenuExpanded = false
    @State private var selectedType: LogEntryType?
    @State private var pulseAmount: CGFloat = 1.0
    
    // Define the FAB menu items
    private let menuItems: [(type: LogEntryType, icon: String, label: String)] = [
        (.task, "checkmark.circle", "Task"),
        (.note, "doc.text", "Note"),
        (.payment, "dollarsign.circle", "Payment")
    ]
    
    var body: some View {
        // Only render actual content if we're on an allowed tab
        if allowedTabs.contains(currentTab) {
            ZStack {
                // Background overlay for closing the menu when tapping elsewhere
                if isMenuExpanded {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()  // This should cover the entire screen
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onTapGesture {
                            closeMenu()
                        }
                        .transition(.opacity)
                }
                
                VStack {
                    Spacer()
                    
                    // Position FAB in bottom-right with better integration
                    HStack {
                        Spacer()
                        
                        // FAB container with background blur for better visual separation
                        ZStack {
                            // Subtle background blur to separate FAB from content
                            if isMenuExpanded {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 180, height: 180)
                                    .blur(radius: 10)
                                    .opacity(0.8)
                            }
                            
                            // Display the menu items in an arc
                            ForEach(Array(menuItems.enumerated()), id: \.offset) { index, item in
                                if isMenuExpanded {
                                    fabMenuItem(
                                        icon: item.icon, 
                                        label: item.label, 
                                        color: theme.accent,
                                        index: index, 
                                        total: menuItems.count,
                                        isHighlighted: shouldHighlight(item.type)
                                    )
                                    .onTapGesture {
                                        handleMenuItemTap(item.type)
                                    }
                                }
                            }
                            
                            // Main FAB Button - slightly larger for easier tapping
                            Button(action: {
                                // Use haptic feedback when pressing button
                                let impactMed = UIImpactFeedbackGenerator(style: .medium)
                                impactMed.impactOccurred()
                                
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    isMenuExpanded.toggle()
                                    
                                    // Start pulsing animation for highlighted buttons when menu expands
                                    if isMenuExpanded {
                                        withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                            pulseAmount = 1.2
                                        }
                                    } else {
                                        pulseAmount = 1.0
                                    }
                                }
                                
                                // Tell NagMode that the user might log an entry
                                if nagManager.showInAppNag && !isMenuExpanded {
                                    nagManager.userLoggedEntry()
                                }
                            }) {
                                Image(systemName: isMenuExpanded ? "xmark" : "plus")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 56, height: 56) // Slightly smaller, more integrated size
                                    .background(
                                        Circle()
                                            .fill(theme.accent)
                                            .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 3)
                                    )
                            }
                            .rotationEffect(Angle(degrees: isMenuExpanded ? 90 : 0))
                            .buttonStyle(ScaleButtonStyle())
                            .nagModePulse() // Apply the pulsing effect when Nag Mode is active
                        }
                        .padding(.trailing, 20) // Add right padding
                    }
                    .padding(.bottom, 20) // Add spacing from content
                    
                    // Adjusted spacing to prevent overlap with tab bar
                    // Extra padding to ensure it doesn't feel "lost"
                    .padding(.bottom, UIDevice.current.hasHomeIndicator ? 85 : 70)
                }
                .background(Color.clear)
            }
            // Add high z-index to ensure FAB stays on top
            .zIndex(1000)
            .sheet(item: $selectedType) { type in
                QuickAddView(initialEntryType: type)
                    .presentationDragIndicator(.hidden)
                    .presentationDetents([.height(type == .task ? 360 : 340)]) // Use dynamic height based on entry type
                    .presentationBackground(Color(uiColor: .systemBackground))
                    .presentationCornerRadius(24)
                    .interactiveDismissDisabled(false)
                    .onDisappear {
                        NotificationCenter.default.post(name: .refreshAfterQuickAdd, object: nil)
                    }
            }
        } else {
            // Return an empty view for tabs where the button shouldn't appear
            EmptyView()
        }
    }
    
    // Helper to handle menu item taps
    private func handleMenuItemTap(_ type: LogEntryType) {
        // Provide haptic feedback
        let impactMed = UIImpactFeedbackGenerator(style: .medium)
        impactMed.impactOccurred()
        
        // Close the menu
        closeMenu()
        
        // Show the appropriate quick add sheet
        selectedType = type
        
        // Tell NagMode that the user is logging an entry
        if nagManager.showInAppNag {
            nagManager.userLoggedEntry()
        }
    }
    
    // Helper to close the menu
    private func closeMenu() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isMenuExpanded = false
            pulseAmount = 1.0
        }
    }
    
    // Helper to create a FAB menu item with position based on index
    private func fabMenuItem(icon: String, label: String, color: Color, index: Int, total: Int, isHighlighted: Bool) -> some View {
        // Define angles for each action type - optimized for center positioning
        let angleForType: Double
        if label == "Task" {
            angleForType = 60.0      // Upper-right for easier reach
        } else if label == "Note" {
            angleForType = 90.0      // Straight up (12 o'clock)
        } else { // Payment
            angleForType = 120.0     // Upper-left for balance
        }
        
        // Convert degrees to radians
        let radians = angleForType * .pi / 180
     
        // Radius from FAB center - increased to prevent overlap
        let radius: CGFloat = 100
     
        // Calculate offsets
        let xOffset = cos(radians) * radius
        let yOffset = -sin(radians) * radius
        
        // Return only the icon button without text label
        return ZStack {
            // Pulsing outline for highlighted items
            if isHighlighted {
                Circle()
                    .stroke(color.opacity(0.6), lineWidth: 3)
                    .scaleEffect(pulseAmount)
            }
            
            // Button background with subtle shadow
            Circle()
                .fill(color)
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
            
            // Button icon - larger for better visibility
            Image(systemName: icon)
                .font(.system(size: isHighlighted ? 22 : 20, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(width: 52, height: 52) // Increased from 48 to 52 for better touch targets
        .offset(x: xOffset, y: yOffset)
        .transition(.scale.combined(with: .opacity))
    }
    
    // Determine if a menu item should be highlighted based on the current tab
    private func shouldHighlight(_ type: LogEntryType) -> Bool {
        switch (currentTab, type) {
        case (0, _):
            // Today tab - highlight all items
            return true
        case (1, .task): 
            // Tasks tab - highlight Task
            return true
        case (2, .note): 
            // Notes tab - highlight Note
            return true
        case (3, .payment): 
            // Payments tab - highlight Payment
            return true
        default:
            return false
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