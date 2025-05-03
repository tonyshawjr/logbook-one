//
//  Persistence.swift
//  LogbookOne
//
//  Created by Tony Shaw on 5/3/25.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample clients
        let client1 = Client(context: viewContext)
        client1.id = UUID()
        client1.name = "Sample Client"
        
        // Create sample tasks
        let task1 = LogEntry(context: viewContext)
        task1.id = UUID()
        task1.type = LogEntryType.task.rawValue
        task1.desc = "Complete app design"
        task1.date = Date().addingTimeInterval(86400) // Due tomorrow
        
        // Set creation time (when the task was created, not when it's due)
        let creationTimeForTask1 = Date().addingTimeInterval(-3600) // Created 1 hour ago
        task1.setValue(creationTimeForTask1, forKey: "creationDate")
        task1.client = client1
        
        let task2 = LogEntry(context: viewContext)
        task2.id = UUID()
        task2.type = LogEntryType.task.rawValue
        task2.desc = "Send follow-up email"
        task2.date = Date().addingTimeInterval(3600) // Due in 1 hour
        
        // Set creation time (earlier today)
        let creationTimeForTask2 = Date().addingTimeInterval(-7200) // Created 2 hours ago
        task2.setValue(creationTimeForTask2, forKey: "creationDate")
        
        // Create sample note
        let note = LogEntry(context: viewContext)
        note.id = UUID()
        note.type = LogEntryType.note.rawValue
        note.desc = "Client meeting notes - discussed timeline and budget"
        note.date = Date()
        note.setValue(Date(), forKey: "creationDate")
        note.client = client1
        
        // Create sample payment
        let payment = LogEntry(context: viewContext)
        payment.id = UUID()
        payment.type = LogEntryType.payment.rawValue
        payment.desc = "Website design payment"
        payment.date = Date()
        payment.setValue(Date(), forKey: "creationDate")
        payment.amount = NSDecimalNumber(value: 500.00)
        payment.client = client1
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        
        return result
    }()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "LogbookOne")
        
        // Configure the persistent store options to enable migration
        let description = container.persistentStoreDescriptions.first
        description?.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        description?.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // This is a serious error - log it and handle appropriately
                print("Persistent store failed: \(error), \(error.userInfo)")
                print("Store description: \(storeDescription)")
                
                // This is not ideal in production, but will help us debug
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        print("Core Data store initialized successfully")
    }
}
