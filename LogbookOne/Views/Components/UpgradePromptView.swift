import SwiftUI
import SafariServices

struct UpgradePromptView: View {
    @Binding var isPresented: Bool
    let feature: ProFeature
    let message: String
    
    @State private var showingUpgradeView = false
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                // Pro badge
                Text("PRO FEATURE")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.themeAccent)
                    .cornerRadius(12)
                
                // Feature locked icon
                Image(systemName: getFeatureIcon())
                    .font(.system(size: 50))
                    .foregroundColor(.themeAccent)
                
                // Title and description
                Text(getFeatureTitle())
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.themePrimary)
                    .padding(.top, 4)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.themeSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 20)
            
            // Action buttons
            VStack(spacing: 12) {
                Button(action: {
                    showingUpgradeView = true
                }) {
                    Text("Upgrade Now")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.themeAccent)
                        .cornerRadius(12)
                }
                
                Button(action: {
                    isPresented = false
                }) {
                    Text("Not Now")
                        .font(.subheadline)
                        .foregroundColor(.themeSecondary)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .frame(width: 300)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.themeCard)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .sheet(isPresented: $showingUpgradeView) {
            UpgradeView()
        }
    }
    
    // Helper to get appropriate icon for feature
    private func getFeatureIcon() -> String {
        switch feature {
        case .tasks:
            return "checkmark.square.fill"
        case .payments:
            return "dollarsign.circle.fill"
        case .clients:
            return "person.crop.circle.fill"
        case .nagMode:
            return "bell.fill"
        case .export:
            return "arrow.up.circle.fill"
        case .dataImport:
            return "arrow.down.circle.fill"
        }
    }
    
    // Helper to get appropriate title for feature
    private func getFeatureTitle() -> String {
        switch feature {
        case .tasks:
            return "Tasks Management"
        case .payments:
            return "Payments Tracking"
        case .clients:
            return "Client Management"
        case .nagMode:
            return "Nag Mode"
        case .export:
            return "Data Export"
        case .dataImport:
            return "Data Import"
        }
    }
}

// Wrapper view that shows a premium feature lock overlay
struct PremiumFeatureWrapper<Content: View>: View {
    let feature: ProFeature
    let message: String
    let content: Content
    
    @StateObject private var purchaseManager = PurchaseManager.shared
    @State private var showingUpgradePrompt = false
    
    init(feature: ProFeature, message: String, @ViewBuilder content: () -> Content) {
        self.feature = feature
        self.message = message
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            // The actual feature content
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
            
            // Upgrade prompt
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

// TabView wrapper that allows disabling tabs for premium features
struct ProTabViewWrapper: View {
    @StateObject private var purchaseManager = PurchaseManager.shared
    @Binding var selection: Int
    
    let premiumTabs: [Int]
    let regularTabs: [Int]
    
    @State private var showingUpgradePrompt = false
    @State private var selectedPremiumTab: Int? = nil
    
    var body: some View {
        ZStack {
            // Your actual TabView would go here
            // This is just a placeholder for the concept
            Text("Tab content for tab \(selection)")
            
            // Upgrade prompt overlay
            if showingUpgradePrompt {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .overlay(
                        UpgradePromptView(
                            isPresented: $showingUpgradePrompt,
                            feature: getFeatureForTab(selectedPremiumTab ?? 0),
                            message: "Upgrade to Pro to access this feature and more!"
                        )
                    )
                    .transition(.opacity)
            }
        }
        .onChange(of: selection) { oldValue, newValue in
            // Check if the selected tab is premium and user doesn't have access
            if premiumTabs.contains(newValue) && 
               !purchaseManager.hasAccess(to: getFeatureForTab(newValue)) {
                // Revert to previous tab
                selection = oldValue
                selectedPremiumTab = newValue
                showingUpgradePrompt = true
            }
        }
        .animation(.easeInOut, value: showingUpgradePrompt)
    }
    
    // Helper to map tab index to feature
    private func getFeatureForTab(_ tab: Int) -> ProFeature {
        switch tab {
        case 1: // Tasks tab
            return .tasks
        case 3: // Payments tab
            return .payments
        case 4: // Clients tab
            return .clients
        default:
            return .tasks
        }
    }
}

// Preview for design purposes
#Preview {
    VStack {
        UpgradePromptView(
            isPresented: .constant(true),
            feature: .tasks,
            message: "Upgrade to Pro to access Tasks and all premium features!"
        )
        .padding()
        
        Divider()
        
        PremiumFeatureWrapper(
            feature: .nagMode,
            message: "Upgrade to Pro to access Nag Mode and other premium features!"
        ) {
            Text("This is premium content")
                .padding()
                .background(Color.themeCard)
                .cornerRadius(8)
        }
        .frame(height: 200)
    }
} 