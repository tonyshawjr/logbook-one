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
                        .environmentObject(clientFormState)
                        .onAppear {
                            // Force UI update when app appears to apply any appearance changes
                            configureAppearance()
                            
                            // Check if Nag Mode should activate
                            nagManager.checkAndScheduleNags(in: persistenceController.container.viewContext)
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
                }
            }
        }
    }
    
    // Setup notification listener for immediate appearance updates
    private func setupAppearanceRefreshListener() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name("RefreshAppearance"), object: nil, queue: .main) { _ in
            // Force appearance update by reconfiguring
            self.configureAppearance()
            
            // Apply appearance change to all windows in the app to ensure the change is visible
            for scene in UIApplication.shared.connectedScenes {
                if let windowScene = scene as? UIWindowScene {
                    for window in windowScene.windows {
                        // Force window to refresh with animation
                        UIView.transition(with: window, duration: 0.1, options: .transitionCrossDissolve) {
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
        }
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
        // Configure navigation bar appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor(named: "themeBackground")
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor(named: "themePrimary") ?? .label]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(named: "themePrimary") ?? .label]
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().tintColor = UIColor(named: "themeAccent")
        
        // Configure tab bar appearance for 6 tabs
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        
        // Adjust the tab bar item appearance
        let itemAppearance = UITabBarItemAppearance()
        
        // Make the text a bit smaller for 6 tabs
        itemAppearance.normal.titleTextAttributes = [.font: UIFont.systemFont(ofSize: 10, weight: .medium)]
        itemAppearance.selected.titleTextAttributes = [.font: UIFont.systemFont(ofSize: 10, weight: .semibold)]
        
        // Make sure to use theme accent color for selected tabs
        UITabBar.appearance().tintColor = UIColor(named: "themeAccent")
        
        // Apply the item appearance to the tab bar
        tabBarAppearance.stackedLayoutAppearance = itemAppearance
        tabBarAppearance.inlineLayoutAppearance = itemAppearance
        tabBarAppearance.compactInlineLayoutAppearance = itemAppearance
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // Configure other UI components as needed
        UITableView.appearance().backgroundColor = UIColor(named: "themeBackground")
        UITableViewCell.appearance().backgroundColor = UIColor(named: "themeCard")
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
