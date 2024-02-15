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

        
        if let newLocation = locations.last{
            self.location = newLocation
            locations.last.map {
                let center = CLLocationCoordinate2D(
                    latitude: $0.coordinate.latitude,
                    longitude: $0.coordinate.longitude)
                self.locations.append(center)
                    // 地図を表示するための領域を再構築
                    region = MKCoordinateRegion(
                        center: center,
                        latitudinalMeters: 1000.0,
                        longitudinalMeters: 1000.0
                )
            }
            print("(\(newLocation.coordinate.latitude), \(newLocation.coordinate.longitude))")
        }
        
        
    }

}
