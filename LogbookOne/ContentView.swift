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
                }
                .tabItem {
                    Label("Clients", systemImage: "person.3")
                }
                .tag(4)
            }
            .tint(Color.themeAccent)
            .environment(\.managedObjectContext, viewContext)
            .environmentObject(clientFormState)
            .onChange(of: colorScheme) { oldValue, newValue in
                // Update CurrentTheme when the color scheme changes
                let _ = CurrentTheme.shared.getCurrentTheme(isDark: newValue == .dark)
                
                // Force refresh the entire view
                refreshID = UUID()
                
                // Use the force reset method to completely refresh the tab bar
                self.forceTabBarReset()
                
                // Also update tab bars recursively as a backup
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first(where: { $0.isKeyWindow }),
                   let rootViewController = window.rootViewController {
                    self.updateTabBarsRecursively(in: rootViewController)
                }
                
                // Schedule an additional update after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    self.forceTabBarReset()
                    refreshID = UUID() // Force another refresh
                }
            }
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
                
                // Force an initial tab bar reset to ensure correct appearance
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    self.forceTabBarReset()
                }
                
                // Set up notification observer for refresh after quick add
                NotificationCenter.default.addObserver(forName: .refreshAfterQuickAdd, object: nil, queue: .main) { _ in
                    // Generate a new ID to force view refresh
                    refreshID = UUID()
                }
                
                // Listen for theme changes
                NotificationCenter.default.addObserver(forName: NSNotification.Name("ThemeColorChange"), object: nil, queue: .main) { _ in
                    // Use the force reset method to completely refresh the tab bar
                    self.forceTabBarReset()
                    
                    // Also use the recursive method as a backup
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first(where: { $0.isKeyWindow }),
                       let rootViewController = window.rootViewController {
                        
                        // Find the main tab bar controller
                        self.updateTabBarsRecursively(in: rootViewController)
                    }
                    
                    // Force refresh the entire view by updating the refresh ID
                    // This will cause the entire view hierarchy to redraw with new theme colors
                    self.refreshID = UUID()
                    
                    // Schedule an additional refresh with a slight delay to handle edge cases
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                        self.forceTabBarReset()
                        self.refreshID = UUID() // Force another refresh
                    }
                }
            }
            .onDisappear {
                // Remove notification observers
                NotificationCenter.default.removeObserver(self, name: .refreshAfterQuickAdd, object: nil)
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name("ThemeColorChange"), object: nil)
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
                        // Remove padding here since it's now in the QuickActionButton itself
                    }
                }
            }
            .ignoresSafeArea(.all)
        }
        .sheet(isPresented: $showingQuickAdd) {
            Group {
                switch selectedTab {
                case 0: // Dashboard
                    QuickAddView()
                        .onDisappear {
                            // Post notification to refresh views when sheet dismisses
                            NotificationCenter.default.post(name: .refreshAfterQuickAdd, object: nil)
                        }
                case 1: // Tasks
                    QuickAddView(initialEntryType: .task)
                        .onDisappear {
                            // Post notification to refresh views when sheet dismisses
                            NotificationCenter.default.post(name: .refreshAfterQuickAdd, object: nil)
                        }
                case 2: // Notes
                    QuickAddView(initialEntryType: .note)
                        .onDisappear {
                            // Post notification to refresh views when sheet dismisses
                            NotificationCenter.default.post(name: .refreshAfterQuickAdd, object: nil)
                        }
                case 3: // Payments
                    QuickAddView(initialEntryType: .payment)
                        .onDisappear {
                            // Post notification to refresh views when sheet dismisses
                            NotificationCenter.default.post(name: .refreshAfterQuickAdd, object: nil)
                        }
                default:
                    // Fallback for any other tab (though this shouldn't happen)
                    QuickAddView()
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
    }
    
    // Recursive function to find and update tab bars
    private func updateTabBarsRecursively(in viewController: UIViewController) {
        // If this is a tab bar controller, update it
        if let tabBarController = viewController as? UITabBarController {
            // Get the current theme
            let theme = CurrentTheme.shared.activeTheme
            let accentColor = UIColor(theme.accent)
            let backgroundColor = UIColor(theme.background)
            
            // More aggressively update the tab bar
            DispatchQueue.main.async {
                // Direct updates to tab bar properties
                tabBarController.tabBar.tintColor = accentColor
                tabBarController.tabBar.backgroundColor = backgroundColor
                tabBarController.tabBar.unselectedItemTintColor = UIColor.gray
                
                // Update each item explicitly, with more properties
                if let items = tabBarController.tabBar.items {
                    for (index, item) in items.enumerated() {
                        // Clear any existing attributes first
                        item.setTitleTextAttributes(nil, for: .normal)
                        item.setTitleTextAttributes(nil, for: .selected)
                        
                        // Set new attributes with improved font settings
                        item.setTitleTextAttributes([
                            .foregroundColor: UIColor.gray,
                            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
                        ], for: .normal)
                        
                        item.setTitleTextAttributes([
                            .foregroundColor: accentColor,
                            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
                        ], for: .selected)
                        
                        // If this is the selected item, explicitly set its properties
                        if index == tabBarController.selectedIndex {
                            item.badgeColor = accentColor
                            // Force update selected item
                            if let imageView = item.value(forKey: "view") as? UIView {
                                imageView.tintColor = accentColor
                                imageView.setNeedsDisplay()
                            }
                        }
                    }
                }
                
                // Apply immediate appearance with these properties
                let tabAppearance = UITabBarAppearance()
                tabAppearance.configureWithDefaultBackground()
                tabAppearance.backgroundColor = backgroundColor
                
                let itemAppearance = UITabBarItemAppearance()
                itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.gray]
                itemAppearance.selected.titleTextAttributes = [.foregroundColor: accentColor]
                
                tabAppearance.stackedLayoutAppearance = itemAppearance
                tabAppearance.inlineLayoutAppearance = itemAppearance
                tabAppearance.compactInlineLayoutAppearance = itemAppearance
                
                tabBarController.tabBar.standardAppearance = tabAppearance
                tabBarController.tabBar.scrollEdgeAppearance = tabAppearance
                
                // Force redraw
                tabBarController.tabBar.setNeedsDisplay()
                tabBarController.tabBar.layoutIfNeeded()
                
                // Extra step: try to force tab bar item views to update
                tabBarController.viewWillLayoutSubviews()
                tabBarController.viewDidLayoutSubviews()
            }
        }
        
        // Check child view controllers
        for child in viewController.children {
            updateTabBarsRecursively(in: child)
        }
        
        // Check presented controller
        if let presented = viewController.presentedViewController {
            updateTabBarsRecursively(in: presented)
        }
        
        // Check navigation controller's visible controller
        if let navController = viewController as? UINavigationController,
           let visibleController = navController.visibleViewController {
            updateTabBarsRecursively(in: visibleController)
        }
    }
    
    // Add this helper method to MainTabView
    private func forceTabBarReset() {
        // This function uses a trick to force the tab bar to completely redraw
        // by temporarily hiding it and showing it again
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first(where: { $0.isKeyWindow }),
           let rootViewController = window.rootViewController,
           let tabBarController = findTabBarController(in: rootViewController) {
            
            // Get the current theme
            let theme = CurrentTheme.shared.activeTheme
            let accentColor = UIColor(theme.accent)
            let backgroundColor = UIColor(theme.background)
            
            // Step 1: Store the current state
            let selectedIndex = tabBarController.selectedIndex
            let isHidden = tabBarController.tabBar.isHidden
            
            // Step 2: Hide the tab bar momentarily (forces a redraw cycle)
            DispatchQueue.main.async {
                // Hide
                tabBarController.tabBar.isHidden = true
                
                // Update appearance while hidden
                tabBarController.tabBar.tintColor = accentColor
                tabBarController.tabBar.backgroundColor = backgroundColor
                tabBarController.tabBar.unselectedItemTintColor = UIColor.gray
                
                // Update appearance settings
                let appearance = UITabBarAppearance()
                appearance.configureWithDefaultBackground()
                appearance.backgroundColor = backgroundColor
                
                let itemAppearance = UITabBarItemAppearance()
                itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.gray]
                itemAppearance.selected.titleTextAttributes = [.foregroundColor: accentColor]
                
                appearance.stackedLayoutAppearance = itemAppearance
                appearance.inlineLayoutAppearance = itemAppearance
                appearance.compactInlineLayoutAppearance = itemAppearance
                
                tabBarController.tabBar.standardAppearance = appearance
                tabBarController.tabBar.scrollEdgeAppearance = appearance
                
                // Show the tab bar again (completes the redraw cycle)
                tabBarController.tabBar.isHidden = isHidden
                
                // Force layout update
                tabBarController.tabBar.setNeedsLayout()
                tabBarController.tabBar.layoutIfNeeded()
                
                // Select index again (forces selection refresh)
                tabBarController.selectedIndex = selectedIndex
                
                // Update tab item properties directly
                if let items = tabBarController.tabBar.items {
                    for (_, item) in items.enumerated() {
                        // Set properties for all items
                        item.setTitleTextAttributes([
                            .foregroundColor: UIColor.gray,
                            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
                        ], for: .normal)
                        
                        item.setTitleTextAttributes([
                            .foregroundColor: accentColor,
                            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
                        ], for: .selected)
                    }
                }
            }
        }
    }
    
    // Helper method to find the tab bar controller
    private func findTabBarController(in viewController: UIViewController?) -> UITabBarController? {
        guard let viewController = viewController else { return nil }
        
        if let tabBarController = viewController as? UITabBarController {
            return tabBarController
        }
        
        if let navigationController = viewController as? UINavigationController {
            return findTabBarController(in: navigationController.visibleViewController)
        }
        
        if let presentedViewController = viewController.presentedViewController {
            return findTabBarController(in: presentedViewController)
        }
        
        for child in viewController.children {
            if let tabBar = findTabBarController(in: child) {
                return tabBar
            }
        }
        
        return nil
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
