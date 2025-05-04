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
    
    // App appearance settings
    @AppStorage("useDarkMode") private var useDarkMode = false
    @AppStorage("useSystemAppearance") private var useSystemAppearance = true
    
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
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .preferredColorScheme(colorScheme)
                .onAppear {
                    // Force UI update when app appears to apply any appearance changes
                    configureAppearance()
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
        
        // We're handling tab bar appearance directly in ContentView.swift
        // Removing all tab bar appearance code from here to avoid conflicts
        
        // Configure other UI components as needed
        UITableView.appearance().backgroundColor = UIColor(named: "themeBackground")
        UITableViewCell.appearance().backgroundColor = UIColor(named: "themeCard")
        
        // Apply tab bar customizations at runtime
        // Disabling custom tab bar spacing adjustments as they're causing layout issues
        /*
        NotificationCenter.default.addObserver(forName: UIApplication.didFinishLaunchingNotification, 
                                              object: nil, queue: .main) { _ in
            self.adjustTabBarItemSpacing()
        }
        */
    }
    
    /// Adjust tab bar item spacing after the app has launched
    /* 
    private func adjustTabBarItemSpacing() {
        DispatchQueue.main.async {
            // Find all tab bars in the app using scenes API
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) {
                self.findAndAdjustTabBars(in: keyWindow)
            }
        }
    }
    
    private func findAndAdjustTabBars(in view: UIView) {
        // Check if this view is a tab bar
        if let tabBar = view as? UITabBar {
            // Add top inset to tab bar items
            tabBar.items?.forEach { item in
                // Reduce the excessive top padding while keeping improved touch targets
                item.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 2)
                item.imageInsets = UIEdgeInsets(top: 4, left: 0, bottom: 0, right: 0)
            }
        }
        
        // Recursive search through view hierarchy
        for subview in view.subviews {
            findAndAdjustTabBars(in: subview)
        }
    }
    
    private func findTabBar(in view: UIView) -> UITabBar? {
        if let tabBar = view as? UITabBar {
            return tabBar
        }
        
        for subview in view.subviews {
            if let tabBar = findTabBar(in: subview) {
                return tabBar
            }
        }
        
        return nil
    }
    */
    
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
