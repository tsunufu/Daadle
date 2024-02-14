//
//  LocationManager.swift
//  running.io
//
//  Created by ryo on 2024/02/14.
//

import Foundation
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    @Published var location: CLLocation?
    var locationManager: CLLocationManager 

    override init() {
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.requestWhenInUseAuthorization()
        
        super.init()
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]){
        
        if let newLocation = locations.last{
            self.location = newLocation
            print("(\(newLocation.coordinate.latitude), \(newLocation.coordinate.longitude))")
        }
        
    }

}
