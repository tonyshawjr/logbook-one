import SwiftUI

/// A view modifier to restrict access to premium features
struct PaywallViewModifier: ViewModifier {
    let feature: ProFeature
    let message: String
    
    @StateObject private var purchaseManager = PurchaseManager.shared
    @State private var showingUpgradePrompt = false
    
    func body(content: Content) -> some View {
        ZStack {
            // Actual content with conditional interactivity
            content
                .allowsHitTesting(hasAccess)
                .overlay(
                    // Semi-transparent overlay if feature is locked
                    Group {
                        if !hasAccess {
                            Rectangle()
                                .fill(Color.black.opacity(0.1))
                                .onTapGesture {
                                    showingUpgradePrompt = true
                                }
                        }
                    }
                )
            
            // Upgrade prompt overlay
            if showingUpgradePrompt {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .overlay(
                        UpgradePromptView(
                            isPresented: $showingUpgradePrompt,
                            feature: feature,
                            message: message
                        )
                    )
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: showingUpgradePrompt)
    }
    
    // Helper computed property to check access
    private var hasAccess: Bool {
        purchaseManager.hasAccess(to: feature)
    }
}

// Extension on View for easier application
extension View {
    /// Restricts access to a premium feature
    /// - Parameters:
    ///   - feature: The premium feature to restrict
    ///   - message: The message to display when prompting for upgrade
    /// - Returns: A modified view that checks for premium access
    func requiresSubscription(for feature: ProFeature, message: String) -> some View {
        self.modifier(PaywallViewModifier(feature: feature, message: message))
    }
} 