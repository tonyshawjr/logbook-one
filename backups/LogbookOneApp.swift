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
    
    init() {
        // Fix for existing entries that don't have a creation date
        updateExistingEntriesWithMissingCreationDate()
        
        // Set up appearance for UIKit components (like navigation bars, etc.)
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
    
    /// Configure the appearance for UIKit components to match SwiftUI theming
    private func configureAppearance() {
        // Configure navigation bar appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor(named: "appBackground")
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor(named: "primaryText") ?? .label]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(named: "primaryText") ?? .label]
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().tintColor = UIColor(named: "appAccent")
        
        // Configure other UI components as needed
        UITableView.appearance().backgroundColor = UIColor(named: "appBackground")
        UITableViewCell.appearance().backgroundColor = UIColor(named: "cardBackground")
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
