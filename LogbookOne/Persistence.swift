//
//  Persistence.swift
//  LogbookOne
//
//  Created by Tony Shaw on 5/3/25.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample clients
        let client1 = Client(context: viewContext)
        client1.id = UUID()
        client1.name = "Acme Corp"
        client1.tag = "Web Development"
        client1.hourlyRate = 150
        
        let client2 = Client(context: viewContext)
        client2.id = UUID()
        client2.name = "Smith & Co"
        client2.tag = "Consulting"
        client2.hourlyRate = 200
        
        // Create sample log entries
        let entry1 = LogEntry(context: viewContext)
        entry1.id = UUID()
        entry1.type = LogEntryType.task.rawValue
        entry1.desc = "Initial project setup and requirements gathering"
        entry1.date = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        entry1.client = client1
        
        let entry2 = LogEntry(context: viewContext)
        entry2.id = UUID()
        entry2.type = LogEntryType.payment.rawValue
        entry2.desc = "Project milestone payment"
        entry2.amount = 1500
        entry2.date = Date()
        entry2.client = client1
        
        let entry3 = LogEntry(context: viewContext)
        entry3.id = UUID()
        entry3.type = LogEntryType.note.rawValue
        entry3.desc = "Client requested additional features for next sprint"
        entry3.date = Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()
        entry3.client = client2
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "LogbookOne")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
