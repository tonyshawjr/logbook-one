//
//  LogEntry+CoreDataProperties.swift
//  
//
//  Created by Tony Shaw on 5/5/25.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension LogEntry {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LogEntry> {
        return NSFetchRequest<LogEntry>(entityName: "LogEntry")
    }

    @NSManaged public var amount: NSDecimalNumber?
    @NSManaged public var date: Date?
    @NSManaged public var desc: String?
    @NSManaged public var id: UUID?
    @NSManaged public var isComplete: Bool
    @NSManaged public var tag: String?
    @NSManaged public var type: Int16
    @NSManaged public var creationDate: Date?
    @NSManaged public var client: Client?

}

extension LogEntry : Identifiable {

}
