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
import FirebaseAuth
import UIKit 

class LocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    @Published var location: CLLocation?
    var locationManager: CLLocationManager
    @Published  var region =  MKCoordinateRegion()
    @Published var locations = [CLLocationCoordinate2D]()
    @Published var allUserLocations: [String: [String: Any]] = [:]
    @Published var userLocationsHistory: [String: [CLLocationCoordinate2D]] = [:]
    @Published var isAlwaysAuthorized: Bool = false
    var currentUserID: String? = Auth.auth().currentUser?.uid
    var lastDatabaseUpdate: Date?
        
    var ref: DatabaseReference = Database.database().reference()
    
    func fetchFriendsLocations() {
            // フレンドリストを取得
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            print("Error: Current user ID is nil")
            return
        }

        print("Current user ID: \(currentUserID)")
        ref.child("users/\(currentUserID)/friends").observeSingleEvent(of: .value) { [weak self] snapshot in
            print("Snapshot value: \(snapshot.value)")
            guard let self = self, let friendsDict = snapshot.value as? [String: Bool] else {
                print("Error: Could not decode friends data")
                return
            }
                
                // フレンドリストのユーザーIDを配列に保存
                let friendUIDs = Array(friendsDict.keys)

                // フレンドの位置情報を取得
                self.fetchUserLocations(friendUIDs: friendUIDs)
            }
        }

    private func fetchUserLocations(friendUIDs: [String]) {
        ref.child("users").observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let self = self, let usersDict = snapshot.value as? [String: AnyObject] else {
                print("Error: Could not decode users data")
                return
            }
            
            var newLocations: [String: [String: Any]] = [:]
            for userId in friendUIDs {
                if let userValue = usersDict[userId],
                   let locationDict = userValue["locations"] as? [String: AnyObject],
                   let latitude = locationDict["latitude"] as? Double,
                   let longitude = locationDict["longitude"] as? Double {
                    newLocations[userId] = ["latitude": latitude, "longitude": longitude]
                    print("Updated location for user \(userId): \(latitude), \(longitude)")
                }
            }
            
            DispatchQueue.main.async {
                self.allUserLocations = newLocations
                print("All updated user locations: \(self.allUserLocations)")
            }
        }
    }
    
    func writeLocationToDatabase(location: CLLocation) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("Error: User ID is nil")
            return
        }

        let locationData = [
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude,
            "timestamp": Int(location.timestamp.timeIntervalSince1970)  // タイムスタンプも保存
        ] as [String : Any]

        ref.child("users/\(userID)/locations").setValue(locationData) { error, _ in
            if let error = error {
                print("Error writing location to Firebase: \(error.localizedDescription)")
            } else {
                print("Successfully wrote location to Firebase")
            }
        }
    }
    
    func updateLocation(for userId: String, with newCoordinate: CLLocationCoordinate2D) {
        var coordinates = userLocationsHistory[userId] ?? []
        coordinates.append(newCoordinate) // 新しい座標を追加
        userLocationsHistory[userId] = coordinates // 更新された配列を保存
//        print("User \(userId) has locations: \(coordinates)")
    }


    
    override init() {
        locationManager = CLLocationManager()
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 3.0
        locationManager.requestAlwaysAuthorization()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.startUpdatingLocation()
        fetchFriendsLocations()
        loadLocationsOnLocal()
        NotificationCenter.default.addObserver(self, selector: #selector(saveLocationsOnLocal), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    private func checkInitialAuthorizationStatus() {
        let status = CLLocationManager.authorizationStatus()
        isAlwaysAuthorized = (status == .authorizedAlways)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways:
            isAlwaysAuthorized = true
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.startUpdatingLocation()
        default:
            isAlwaysAuthorized = false
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }

        let locationAdded = filterAndAddLocation(newLocation)
        if locationAdded {
            let center = CLLocationCoordinate2D(latitude: newLocation.coordinate.latitude, longitude: newLocation.coordinate.longitude)
            self.location = newLocation
            self.locations.append(center)
            self.region = MKCoordinateRegion(center: center, latitudinalMeters: 1000.0, longitudinalMeters: 1000.0)
            
            // 30秒ごとにデータベースに書き込む
            let now = Date()
            if let lastUpdate = lastDatabaseUpdate, now.timeIntervalSince(lastUpdate) < 30 {
                return
            }
            
            writeLocationToDatabase(location: newLocation)
            lastDatabaseUpdate = now
        }
    }
    
    func filterAndAddLocation(_ location: CLLocation) -> Bool {
        let age = -location.timestamp.timeIntervalSinceNow
        if age > 10 { return false }
        if location.horizontalAccuracy < 0 { return false }
        if location.horizontalAccuracy > 100 { return false }

        return true
    }
    
    @objc func saveLocationsOnLocal() {
        let encodedData = try? JSONEncoder().encode(locations.map { [$0.latitude, $0.longitude] })
        UserDefaults.standard.set(encodedData, forKey: "savedPolygon")
    }

    func loadLocationsOnLocal() {
        if let data = UserDefaults.standard.data(forKey: "savedPolygon"),
           let decodedCoordinates = try? JSONDecoder().decode([[Double]].self, from: data) {
            locations = decodedCoordinates.map { CLLocationCoordinate2D(latitude: $0[0], longitude: $0[1]) }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}

extension LocationManager {
    func calculateAreaOfPolygon(coordinates: [CLLocationCoordinate2D]) -> Double {
        guard coordinates.count > 2 else { return 0 }

        var area: Double = 0
        let earthRadiusKm = 6371.0

        for i in 0..<coordinates.count {
            let p1 = coordinates[i]
            let p2 = coordinates[(i + 1) % coordinates.count] // Ensure the last point connects to the first

            let lat1 = p1.latitude * .pi / 180
            let lon1 = p1.longitude * .pi / 180
            let lat2 = p2.latitude * .pi / 180
            let lon2 = p2.longitude * .pi / 180

            // Convert lat/long from degrees to radians
            let dLon = lon2 - lon1

            // Use spherical excess formula
            let partialArea = atan2(sin(dLon) * cos(lat2), cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon))
            area += partialArea
        }

        area = abs(area * earthRadiusKm * earthRadiusKm)

        return area/1000000
    }
}
