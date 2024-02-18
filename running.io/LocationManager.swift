//
//  LocationManager.swift
//  running.io
//
//  Created by ryo on 2024/02/14.
//

import Foundation
import CoreLocation
import MapKit

class LocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    @Published var location: CLLocation?
    var locationManager: CLLocationManager
    @Published  var region =  MKCoordinateRegion()
    @Published var locations = [CLLocationCoordinate2D]()
    
    override init() {
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 3.0
        
        locationManager.requestAlwaysAuthorization()
        
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        
        super.init()
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
    }
    
    
    
    
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation], didChangeAuthorization status: CLAuthorizationStatus){
        
        if status == .authorizedAlways {
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.startUpdatingLocation()
        }
        
        
        guard let newLocation = locations.last else { return }

        let locationAdded = filterAndAddLocation(newLocation)
        if locationAdded {
            let center = CLLocationCoordinate2D(latitude: newLocation.coordinate.latitude, longitude: newLocation.coordinate.longitude)
            self.location = newLocation
            self.locations.append(center)
            self.region = MKCoordinateRegion(center: center, latitudinalMeters: 1000.0, longitudinalMeters: 1000.0)
            print("New location added: (\(newLocation.coordinate.latitude), \(newLocation.coordinate.longitude))")
        }
        
    }
    
    func filterAndAddLocation(_ location: CLLocation) -> Bool {
        let age = -location.timestamp.timeIntervalSinceNow
        if age > 10 { return false }
        if location.horizontalAccuracy < 0 { return false }
        if location.horizontalAccuracy > 100 { return false }

        return true
    }
}
