//
//  Location+CoreDataProperties.swift
//  running.io
//
//  Created by ryo on 2024/06/26.
//
//

import Foundation
import CoreData


extension Location {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Location> {
        return NSFetchRequest<Location>(entityName: "Location")
    }

    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double

}

extension Location : Identifiable {

}
