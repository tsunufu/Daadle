//
//  UserLocationAnnotation.swift
//  running.io
//
//  Created by ryo on 2024/02/23.
//

import Foundation
import MapKit

class UserLocationAnnotation: NSObject, MKAnnotation {
    dynamic var coordinate: CLLocationCoordinate2D
    var userId: String
    
    init(userId: String, coordinate: CLLocationCoordinate2D) {
        self.userId = userId
        self.coordinate = coordinate
        super.init()
    }
}
