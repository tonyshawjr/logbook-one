//
//  Client+CoreDataProperties.swift
//  
//
//  Created by Tony Shaw on 5/5/25.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Client {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Client> {
        return NSFetchRequest<Client>(entityName: "Client")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var tag: String?
    @NSManaged public var hourlyRate: NSDecimalNumber?
    @NSManaged public var logEntries: NSSet?

}

// MARK: Generated accessors for logEntries
extension Client {

    @objc(addLogEntriesObject:)
    @NSManaged public func addToLogEntries(_ value: LogEntry)

    @objc(removeLogEntriesObject:)
    @NSManaged public func removeFromLogEntries(_ value: LogEntry)

    @objc(addLogEntries:)
    @NSManaged public func addToLogEntries(_ values: NSSet)

    @objc(removeLogEntries:)
    @NSManaged public func removeFromLogEntries(_ values: NSSet)

}

extension Client : Identifiable {

}
