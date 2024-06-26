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
import CoreData

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
                self.fetchFriendsLocationHistory(friendUIDs: friendUIDs)
            }
        }
    
    func fetchFriendsLocationHistory(friendUIDs: [String]) {
        for friendUID in friendUIDs {
            ref.child("users/\(friendUID)/locationHistory").observeSingleEvent(of: .value) { [weak self] snapshot in
                guard let self = self, let locationDataArray = snapshot.value as? [[String: Double]] else {
                    print("Error reading location history for friend ID \(friendUID)")
                    return
                }
                
                var friendLocations: [CLLocationCoordinate2D] = []
                for locationData in locationDataArray {
                    if let latitude = locationData["latitude"], let longitude = locationData["longitude"] {
                        friendLocations.append(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                    }
                }
                
                DispatchQueue.main.async {
                    self.userLocationsHistory[friendUID] = friendLocations
//                    print("Updated userLocationsHistory for \(friendUID): \(friendLocations.map { "\($0.latitude), \($0.longitude)" })")
                }
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
    
    func saveLocationHistoryToFirebase() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("Error: User ID is nil")
            return
        }
        
        // 位置情報の配列をlatitudeとlongitudeのペアの配列に変換
        let locationData = locations.map { ["latitude": $0.latitude, "longitude": $0.longitude] }

        // Firebaseに書き込み
        ref.child("users/\(userID)/locationHistory").setValue(locationData) { error, _ in
            if let error = error {
                print("Error writing location history to Firebase: \(error.localizedDescription)")
            } else {
                print("Successfully wrote location history to Firebase")
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
        loadLocationsFromCoreData()

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
            
            // 30秒ごとにデータベースに書き込みと読み込みを繰り返す
            let now = Date()
            if let lastUpdate = lastDatabaseUpdate, now.timeIntervalSince(lastUpdate) < 30 {
                return
            }
            
            writeLocationToDatabase(location: newLocation)
            saveLocationHistoryToFirebase()
            fetchFriendsLocations()
            saveLocationsToCoreData()
            loadLocationsFromCoreData()
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
    
    
    func saveLocationsToCoreData() {
        let context = PersistenceController.shared.container.viewContext

        // 既存のデータを削除する
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Location")
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        _ = try? context.execute(batchDeleteRequest)

        // 新しいデータを保存
        for coordinate in locations {
            let newLocation = Location(context: context)
            newLocation.latitude = coordinate.latitude
            newLocation.longitude = coordinate.longitude
        }

        do {
            try context.save()
        } catch {
            print("Failed to save locations: \(error)")
        }
    }
    
    @objc func loadLocationsFromCoreData() {
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest: NSFetchRequest<Location> = Location.fetchRequest()

        do {
            let locationsFromCoreData = try context.fetch(fetchRequest)
            locations = locationsFromCoreData.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
            
            if locationsFromCoreData.isEmpty {
                print("No locations were loaded from CoreData.")
            } else {
                print("Loaded \(locationsFromCoreData.count) locations from CoreData:")
                for location in locationsFromCoreData {
                    print("Latitude: \(location.latitude), Longitude: \(location.longitude)")
                }
            }
        } catch {
            print("Failed to fetch locations: \(error)")
        }
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
