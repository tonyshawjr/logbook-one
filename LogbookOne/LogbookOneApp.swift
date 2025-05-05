//
//  LogbookOneApp.swift
//  LogbookOne
//
//  Created by Tony Shaw on 5/3/25.
//

import SwiftUI
import CoreData

@main
struct LogbookOneApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var nagManager = NagModeManager.shared
    
    // App appearance settings
    @AppStorage("useDarkMode") private var useDarkMode = false
    @AppStorage("useSystemAppearance") private var useSystemAppearance = true
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    
    // Create a shared ClientFormState instance
    @StateObject private var clientFormState = ClientFormState()
    
    init() {
        // Fix for existing entries that don't have a creation date
        updateExistingEntriesWithMissingCreationDate()
        
        // Set up appearance for UIKit components (like navigation bars, etc.)
        configureAppearance()
        
        // Listen for appearance refresh notifications
        setupAppearanceRefreshListener()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if hasCompletedOnboarding {
                    ContentView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                        .preferredColorScheme(colorScheme)
                        .environment(\.theme, colorScheme == .dark ? DarkTheme : LightTheme)
                        .environmentObject(clientFormState)
                        .withCurrentTheme()
                        .onAppear {
                            // Force UI update when app appears to apply any appearance changes
                            configureAppearance()
                            
                            // Check if Nag Mode should activate
                            nagManager.checkAndScheduleNags(in: persistenceController.container.viewContext)
                        }
                        .onChange(of: useSystemAppearance) { _, _ in
                            configureAppearance()
                        }
                        .onChange(of: useDarkMode) { _, _ in
                            configureAppearance()
                        }
                        .onChange(of: UITraitCollection.current.userInterfaceStyle) { _, newStyle in
                            if useSystemAppearance {
                                // Update CurrentTheme when system appearance changes
                                let _ = CurrentTheme.shared.getCurrentTheme(isDark: newStyle == .dark)
                            }
                        }
                        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                            // Check nag status whenever app becomes active
                            nagManager.checkAndScheduleNags(in: persistenceController.container.viewContext)
                        }
                        .overlay(alignment: .top) {
                            NagModeBanner()
                                .animation(.spring(), value: nagManager.showInAppNag)
                        }
                } else {
                    OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                        .preferredColorScheme(colorScheme)
                        .environment(\.theme, colorScheme == .dark ? DarkTheme : LightTheme)
                        .withCurrentTheme()
                }
            }
        }
    }
    
    // Setup notification listener for immediate appearance updates
    private func setupAppearanceRefreshListener() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name("RefreshAppearance"), object: nil, queue: .main) { _ in
            // Determine dark mode status
            let isDarkMode = self.useSystemAppearance ? 
                (UITraitCollection.current.userInterfaceStyle == .dark) : self.useDarkMode
            
            // Update the current theme singleton
            let _ = CurrentTheme.shared.getCurrentTheme(isDark: isDarkMode)
            
            // Force appearance update by reconfiguring
            self.configureAppearance()
            
            // Get the theme to update
            let theme = isDarkMode ? DarkTheme : LightTheme
            
            // Apply appearance change to all windows in the app to ensure the change is visible
            for scene in UIApplication.shared.connectedScenes {
                if let windowScene = scene as? UIWindowScene {
                    for window in windowScene.windows {
                        // Force window to refresh with animation
                        UIView.transition(with: window, duration: 0.01, options: .transitionCrossDissolve) {
                            if self.useSystemAppearance {
                                window.overrideUserInterfaceStyle = .unspecified
                            } else {
                                window.overrideUserInterfaceStyle = self.useDarkMode ? .dark : .light
                            }
                        }
                        
                        // Ensure views are redrawn
                        window.subviews.forEach { $0.setNeedsDisplay() }
                        window.setNeedsLayout()
                        window.layoutIfNeeded()
                    }
                }
            }
            
            // Directly update tab bars and other UI components
            self.updateExistingTabBars(theme: theme)
            
            // Perform additional immediate UI updates for tab bar and text
            DispatchQueue.main.async {
                // Force update tab bar appearance
                let accentColor = UIColor(theme.accent)
                UITabBar.appearance().tintColor = accentColor
                
                // Force another update after a short delay to make sure everything is caught
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    self.updateExistingTabBars(theme: theme)
                }
            }
            
            // Post a notification that the theme has changed for any views that need to respond
            NotificationCenter.default.post(name: NSNotification.Name("ThemeColorChange"), object: nil)
        }
    }
    
    // Helper method to find the active tab bar controller
    private func findActiveTabBarController() -> UITabBarController? {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first(where: { $0.isKeyWindow }),
           let rootViewController = window.rootViewController {
            
            // Try to find the tab bar controller recursively
            return findTabBarController(in: rootViewController)
        }
        return nil
    }
    
    // Recursively search for UITabBarController
    private func findTabBarController(in viewController: UIViewController) -> UITabBarController? {
        if let tabBarController = viewController as? UITabBarController {
            return tabBarController
        }
        
        if let navigationController = viewController as? UINavigationController {
            return findTabBarController(in: navigationController.visibleViewController ?? navigationController)
        }
        
        if let presentedViewController = viewController.presentedViewController {
            return findTabBarController(in: presentedViewController)
        }
        
        // Handle container view controllers
        for child in viewController.children {
            if let found = findTabBarController(in: child) {
                return found
            }
        }
        
        return nil
    }
    
    // Determine the color scheme based on settings
    private var colorScheme: ColorScheme? {
        if useSystemAppearance {
            return nil // Use system setting
        } else {
            return useDarkMode ? .dark : .light
        }
    }
    
    /// Configure the appearance for UIKit components to match SwiftUI theming
    private func configureAppearance() {
        // Determine dark mode setting
        let isDarkMode = useSystemAppearance ? 
            (UITraitCollection.current.userInterfaceStyle == .dark) : useDarkMode
        
        // Update the current theme singleton
        let _ = CurrentTheme.shared.getCurrentTheme(isDark: isDarkMode)
        
        // Get current theme based on appearance settings
        let theme = isDarkMode ? DarkTheme : LightTheme
        
        // Convert SwiftUI colors to UIColors
        let backgroundColor = UIColor(theme.background)
        let textColor = UIColor(theme.primaryText)
        let accentColor = UIColor(theme.accent)
        let cardColor = UIColor(theme.card)
        
        // Configure navigation bar appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = backgroundColor
        navBarAppearance.titleTextAttributes = [.foregroundColor: textColor]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: textColor]
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().tintColor = accentColor
        
        // Configure tab bar appearance for tabs
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        tabBarAppearance.backgroundColor = backgroundColor
        
        // Adjust the tab bar item appearance
        let itemAppearance = UITabBarItemAppearance()
        
        // Make the text a bit smaller for tabs
        itemAppearance.normal.titleTextAttributes = [.font: UIFont.systemFont(ofSize: 10, weight: .medium), .foregroundColor: UIColor.gray]
        itemAppearance.selected.titleTextAttributes = [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: accentColor]
        
        // Make sure to use theme accent color for selected tabs
        UITabBar.appearance().tintColor = accentColor
        
        // Apply the item appearance to the tab bar
        tabBarAppearance.stackedLayoutAppearance = itemAppearance
        tabBarAppearance.inlineLayoutAppearance = itemAppearance
        tabBarAppearance.compactInlineLayoutAppearance = itemAppearance
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // Configure other UI components as needed
        UITableView.appearance().backgroundColor = backgroundColor
        UITableViewCell.appearance().backgroundColor = cardColor
        
        // Immediately apply settings to any existing tab bars
        DispatchQueue.main.async {
            self.updateExistingTabBars(theme: theme)
        }
    }
    
    /// Directly update any existing tab bars in the app
    private func updateExistingTabBars(theme: AppTheme) {
        let accentColor = UIColor(theme.accent)
        let backgroundColor = UIColor(theme.background)
        let textColor = UIColor(theme.primaryText)
        
        for scene in UIApplication.shared.connectedScenes {
            if let windowScene = scene as? UIWindowScene {
                for window in windowScene.windows {
                    // Recursively find and update all tab bars
                    findAndUpdateTabBars(in: window.rootViewController, 
                                         accentColor: accentColor,
                                         backgroundColor: backgroundColor, 
                                         textColor: textColor)
                    
                    // Force redraw
                    window.setNeedsLayout()
                    window.layoutIfNeeded()
                }
            }
        }
    }
    
    /// Recursively find and update all tab bars in the view controller hierarchy
    private func findAndUpdateTabBars(in viewController: UIViewController?, 
                                     accentColor: UIColor,
                                     backgroundColor: UIColor,
                                     textColor: UIColor) {
        guard let viewController = viewController else { return }
        
        // Update tab bar controller
        if let tabBarController = viewController as? UITabBarController {
            tabBarController.tabBar.tintColor = accentColor
            tabBarController.tabBar.backgroundColor = backgroundColor
            
            // Update each item directly (this helps fix the stuck tab item issue)
            if let items = tabBarController.tabBar.items {
                for item in items {
                    item.setTitleTextAttributes([.foregroundColor: UIColor.gray], for: .normal)
                    item.setTitleTextAttributes([.foregroundColor: accentColor], for: .selected)
                }
            }
            
            // Force redraw
            tabBarController.tabBar.setNeedsDisplay()
        }
        
        // Check navigation controllers
        if let navigationController = viewController as? UINavigationController {
            navigationController.navigationBar.tintColor = accentColor
            navigationController.navigationBar.titleTextAttributes = [.foregroundColor: textColor]
            navigationController.navigationBar.largeTitleTextAttributes = [.foregroundColor: textColor]
            
            // Force redraw
            navigationController.navigationBar.setNeedsDisplay()
            
            // Continue searching in the visible view controller
            findAndUpdateTabBars(in: navigationController.visibleViewController,
                                accentColor: accentColor,
                                backgroundColor: backgroundColor,
                                textColor: textColor)
        }
        
        // Check presented view controller
        findAndUpdateTabBars(in: viewController.presentedViewController,
                            accentColor: accentColor,
                            backgroundColor: backgroundColor,
                            textColor: textColor)
        
        // Check child view controllers
        for childVC in viewController.children {
            findAndUpdateTabBars(in: childVC,
                                accentColor: accentColor,
                                backgroundColor: backgroundColor,
                                textColor: textColor)
        }
    }
    
    /// Updates existing log entries that don't have a creation date
    private func updateExistingEntriesWithMissingCreationDate() {
        let viewContext = persistenceController.container.viewContext
        
        // Fetch all LogEntry objects
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "LogEntry")
        
        do {
            let entries = try viewContext.fetch(fetchRequest)
            var updatedCount = 0
            
            for entry in entries {
                // Check if creationDate is nil
                if entry.value(forKey: "creationDate") == nil {
                    // Set the creation date to the entry's date or current date if date is nil
                    let entryDate = entry.value(forKey: "date") as? Date ?? Date()
                    entry.setValue(entryDate, forKey: "creationDate")
                    updatedCount += 1
                }
            }
            
            // Only save if we made changes
            if updatedCount > 0 {
                print("Updated \(updatedCount) entries with missing creation dates")
                try viewContext.save()
            }
        } catch {
            print("Error updating entries with missing creation dates: \(error)")
        }
    }
}

extension UIImage {
    static func shadowImage(color: UIColor, height: CGFloat) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: height)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}
