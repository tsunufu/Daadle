//
//  LocationManager.swift
//  running.io
//
//  Created by ryo on 2024/02/14.
//

import Foundation
import CoreLocation
import MapKit
import FirebaseDatabase

class LocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    @Published var location: CLLocation?
    var locationManager: CLLocationManager
    @Published  var region =  MKCoordinateRegion()
    @Published var locations = [CLLocationCoordinate2D]()
    @Published var allUserLocations: [String: [String: Any]] = [:]
        
    var ref: DatabaseReference = Database.database().reference()
    
    func fetchOtherUsersLocation() {
        let dbRef = Database.database().reference()
        let userId = ""

        dbRef.child("users").observe(.value, with: { snapshot in
            guard let usersDict = snapshot.value as? [String: AnyObject] else {
                DispatchQueue.main.async {
                    print("エラー: データをデコードできませんでした")
                }
                return
            }

            var newLocations: [String: [String: Any]] = [:]
            for (key, value) in usersDict where key != userId {
                if let locationDict = value["locations"] as? [String: AnyObject],
                   let latitude = locationDict["latitude"] as? Double,
                   let longitude = locationDict["longitude"] as? Double {
                    print("ユーザー: \(key) - 緯度: \(latitude), 経度: \(longitude)")
                    newLocations[key] = ["latitude": latitude, "longitude": longitude]
                }
            }
            DispatchQueue.main.async {
                self.allUserLocations = newLocations
            }
        }) { error in
            DispatchQueue.main.async {
                print(error.localizedDescription)
            }
        }
    }

    
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
        fetchOtherUsersLocation()
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
