//
//  ContentView.swift
//  LogbookOne
//
//  Created by Tony Shaw on 5/3/25.
//

import SwiftUI
import CoreData

// Extension to check if the device has a home indicator (iPhone X and later)
extension UIDevice {
    var hasHomeIndicator: Bool {
        if #available(iOS 15.0, *) {
            // Use the recommended approach for iOS 15+
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) else {
                return false
            }
            return keyWindow.safeAreaInsets.bottom > 0
        } else {
            // Fallback for iOS versions before 15.0
            let windows = UIApplication.shared.windows
            let keyWindow = windows.first(where: { $0.isKeyWindow })
            return keyWindow?.safeAreaInsets.bottom ?? 0 > 0
        }
    }
}

// Notification name for refreshing views after quick add
extension Notification.Name {
    static let refreshAfterQuickAdd = Notification.Name("refreshAfterQuickAdd")
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        ZStack {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            }
        }
    }
}

struct MainTabView: View {
    @State private var showingQuickAdd = false
    @State private var selectedTab = 0
    @State private var refreshID = UUID() // For forcing view refresh
    
    // Environment to pass to the various views
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var clientFormState: ClientFormState
    
    // For showing upgrade prompts
    @State private var showingUpgradePrompt = false
    @State private var upgradeFeature: ProFeature = .tasks
    
    // References to view state
    @State private var tasksViewShowingAdd = false

    var body: some View {
        ZStack {
            // Tab view as base layer
            TabView(selection: $selectedTab) {
                NavigationStack {
                    DashboardView()
                        .environment(\.managedObjectContext, viewContext)
                        .id(refreshID) // Force refresh when ID changes
                }
                .tabItem {
                    Label("Today", systemImage: "house")
                }
                .tag(0)
                
                NavigationStack {
                    TasksView()
                        .environment(\.managedObjectContext, viewContext)
                        .id(refreshID) // Force refresh when ID changes
                        .requiresSubscription(
                            for: .tasks,
                            message: "Upgrade to Pro to access Tasks and all premium features!"
                        )
                }
                .tabItem {
                    Label("Tasks", systemImage: "checkmark.circle")
                }
                .tag(1)
                
                NavigationStack {
                    NotesView()
                        .environment(\.managedObjectContext, viewContext)
                        .id(refreshID) // Force refresh when ID changes
                }
                .tabItem {
                    Label("Notes", systemImage: "doc.text")
                    }
                .tag(2)
                
                NavigationStack {
                    PaymentsView()
                        .environment(\.managedObjectContext, viewContext)
                        .id(refreshID) // Force refresh when ID changes
                        .requiresSubscription(
                            for: .payments,
                            message: "Upgrade to Pro to access Payments and all premium features!"
                        )
                }
                .tabItem {
                    Label("Payments", systemImage: "dollarsign.circle")
                }
                .tag(3)
                
                NavigationStack {
                    ClientListView()
                        .environment(\.managedObjectContext, viewContext)
                        .environmentObject(clientFormState)
                        .id(refreshID) // Force refresh when ID changes
                        .requiresSubscription(
                            for: .clients,
                            message: "Upgrade to Pro to access Client Management and all premium features!"
                        )
                }
                .tabItem {
                    Label("Clients", systemImage: "person.3")
                }
                .tag(4)
            }
            .tint(Color.themeAccent)
            .environment(\.managedObjectContext, viewContext)
            .environmentObject(clientFormState)
            .onChange(of: selectedTab) { oldValue, newValue in
                // Request layout update with a simple approach
                DispatchQueue.main.async {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
            .onAppear {
                // Let the specialized UITabBarAppearance from LogbookOneApp take precedence
                // Only adjust generic settings here
                UITabBar.appearance().backgroundColor = nil
                UITabBar.appearance().isTranslucent = true
                
                // Set up notification observer for refresh after quick add
                NotificationCenter.default.addObserver(forName: .refreshAfterQuickAdd, object: nil, queue: .main) { _ in
                    // Generate a new ID to force view refresh
                    refreshID = UUID()
                }
                
                // Set up notification observer for showing upgrade prompt
                NotificationCenter.default.addObserver(forName: NSNotification.Name("ShowUpgradePrompt"), object: nil, queue: .main) { notification in
                    if let feature = notification.object as? ProFeature {
                        upgradeFeature = feature
                        showingUpgradePrompt = true
                    } else if let typeRawValue = notification.object as? Int16 {
                        // Convert the type raw value to the proper feature
                        let entryType = LogEntryType(rawValue: typeRawValue) ?? .task
                        switch entryType {
                        case .task:
                            upgradeFeature = .tasks
                        case .payment:
                            upgradeFeature = .payments
                        case .note:
                            return // Notes don't require premium
                        }
                        showingUpgradePrompt = true
                    }
                }
            }
            .onDisappear {
                // Remove notification observers
                NotificationCenter.default.removeObserver(self, name: .refreshAfterQuickAdd, object: nil)
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name("ShowUpgradePrompt"), object: nil)
            }
            
            // Floating action button that only appears on certain tabs
            ZStack {
                // Only show on tabs 0-3 (Today, Tasks, Notes, Payments)
                if [0, 1, 2, 3].contains(selectedTab) {
                    VStack {
                        Spacer() // Push to bottom
                        HStack {
                            Spacer() // Push to right
                            QuickActionButton(showingSheet: $showingQuickAdd, currentTab: selectedTab)
                                .id(selectedTab) // Force recreation when tab changes
                        }
                        // Use more bottom padding and add extra for devices with home indicator
                        .padding(.bottom, UIDevice.current.hasHomeIndicator ? 100 : 85)
            }
        }
    }
            .ignoresSafeArea(.all)
        }
        .sheet(isPresented: $showingQuickAdd) {
            Group {
                switch selectedTab {
                case 0: // Dashboard
                    // For Dashboard, only allow Notes in free mode, other types require Pro
                    QuickAddView(initialEntryType: .note)
                        .onDisappear {
                            // Post notification to refresh views when sheet dismisses
                            NotificationCenter.default.post(name: .refreshAfterQuickAdd, object: nil)
                        }
                case 1: // Tasks
                    if PurchaseManager.shared.hasAccess(to: .tasks) {
                        QuickAddView(initialEntryType: .task)
                            .onDisappear {
                                // Post notification to refresh views when sheet dismisses
                                NotificationCenter.default.post(name: .refreshAfterQuickAdd, object: nil)
                            }
                    } else {
                        // Show upgrade prompt
                        UpgradePromptView(
                            isPresented: $showingQuickAdd,
                            feature: .tasks,
                            message: "Upgrade to Pro to access Tasks and all premium features!"
                        )
                    }
                case 2: // Notes
                    QuickAddView(initialEntryType: .note)
                        .onDisappear {
                            // Post notification to refresh views when sheet dismisses
                            NotificationCenter.default.post(name: .refreshAfterQuickAdd, object: nil)
                        }
                case 3: // Payments
                    if PurchaseManager.shared.hasAccess(to: .payments) {
                        QuickAddView(initialEntryType: .payment)
                            .onDisappear {
                                // Post notification to refresh views when sheet dismisses
                                NotificationCenter.default.post(name: .refreshAfterQuickAdd, object: nil)
                            }
                    } else {
                        // Show upgrade prompt
                        UpgradePromptView(
                            isPresented: $showingQuickAdd,
                            feature: .payments,
                            message: "Upgrade to Pro to access Payments and all premium features!"
                        )
                    }
                default:
                    // Fallback for any other tab (though this shouldn't happen)
                    QuickAddView(initialEntryType: .note)
                        .onDisappear {
                            // Post notification to refresh views when sheet dismisses
                            NotificationCenter.default.post(name: .refreshAfterQuickAdd, object: nil)
                        }
                }
            }
            .presentationDragIndicator(.hidden)
            .presentationDetents([.height(420)])
            .presentationBackground(Color(uiColor: .systemBackground))
            .presentationCornerRadius(24)
            .interactiveDismissDisabled(false)
            .environment(\.managedObjectContext, viewContext)
            }
        // Global client form presentation
        .sheet(isPresented: $clientFormState.showingAddClient) {
            ClientFormView()
                .environment(\.managedObjectContext, viewContext)
                .presentationDragIndicator(.hidden)
                .presentationDetents([.height(420)])
                .presentationBackground(Color(uiColor: .systemBackground))
                .presentationCornerRadius(24)
                .interactiveDismissDisabled(false)
                .onDisappear {
                    // Post notification to refresh views when sheet dismisses
                    NotificationCenter.default.post(name: .refreshAfterQuickAdd, object: nil)
                }
        }
        // Upgrade prompt sheet
        .sheet(isPresented: $showingUpgradePrompt) {
            UpgradePromptView(
                isPresented: $showingUpgradePrompt,
                feature: upgradeFeature,
                message: "Upgrade to Pro to access \(getFeatureTitle(upgradeFeature)) and all premium features!"
            )
        }
    }

    // Helper method to get the feature title based on ProFeature
    private func getFeatureTitle(_ feature: ProFeature) -> String {
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

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
