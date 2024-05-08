import SwiftUI
import MapKit
import FirebaseDatabase
import FirebaseAuth

struct MapView: UIViewRepresentable {
    @ObservedObject var locationManager: LocationManager
    var userUID: String
    
    var ref: DatabaseReference! = Database.database().reference()
    
    var mapView: MKMapView = MKMapView()

       func makeUIView(context: Context) -> MKMapView {
           let mapView = MKMapView()
           mapView.delegate = context.coordinator
           mapView.showsUserLocation = true
           mapView.userTrackingMode = .follow
           return mapView
       }

       func updateUIView(_ uiView: MKMapView, context: Context) {
           print("updateUIView is called")
           updatePolyline(for: uiView)
           updateUserLocationsOnMap(uiView)
           updateUserPolygonsOnMap(uiView)
           updateUserAnnotationsOnMap(uiView)
       }

       func makeCoordinator() -> Coordinator {
           Coordinator(self, locationManager: locationManager)
       }

       class Coordinator: NSObject, CLLocationManagerDelegate, MKMapViewDelegate {
           var parent: MapView
           var locationManager: LocationManager
           var imageLoaders: [String: ImageLoader] = [:]

           init(_ parent: MapView, locationManager: LocationManager) {
               self.parent = parent
               self.locationManager = locationManager
               super.init()
               self.locationManager.locationManager.delegate = self
           }

           func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
               if let location = locations.last {
                   let speedKmH = location.speed * 3.6  // Convert speed from m/s to km/h
                   if speedKmH >= 30 {
                       // Speed is above 30 km/h, save and reset the polygon
                       if !parent.locationManager.locations.isEmpty {
                           saveAndResetPolygon()
                       }
                       parent.locationManager.locations.removeAll()  // Ensure locations are cleared
                   } else {
                       // Speed is below 30 km/h, update the location
                       let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                       parent.locationManager.location = location

                       // Start a new polyline if it was previously stopped due to high speed
                       if parent.locationManager.locations.isEmpty {
                           parent.locationManager.locations.append(center)
                           // Optionally start a new polygon if needed
                       } else {
                           parent.locationManager.locations.append(center)
                           parent.updatePolyline(for: parent.mapView)  // Update polyline with new location
                       }
                       parent.locationManager.region = MKCoordinateRegion(center: center, latitudinalMeters: 1000.0, longitudinalMeters: 1000.0)
                   }
               }
           }

           func saveAndResetPolygon() {
               if !parent.locationManager.locations.isEmpty {
                   let polygon = MKPolygon(coordinates: parent.locationManager.locations, count: parent.locationManager.locations.count)
                   parent.mapView.addOverlay(polygon)
                   parent.locationManager.locations.removeAll()  // リストをクリア
               }
           }
           
           func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
               if let polyline = overlay as? MKPolyline {
                   let renderer = MKPolylineRenderer(polyline: polyline)
                   renderer.alpha = 0.5
                   guard let currentUserId = Auth.auth().currentUser?.uid else {
                       renderer.strokeColor = UIColor.gray.withAlphaComponent(0.5)
                       renderer.lineWidth = 4.0
                       return renderer
                   }
                   if polyline.title == currentUserId {
                       renderer.strokeColor = UIColor.red.withAlphaComponent(0.5)
                   } else {
                       renderer.strokeColor = UIColor.purple.withAlphaComponent(0.5)
                   }
                   renderer.lineWidth = 4.0
                   return renderer
               } else if let polygon = overlay as? MKPolygon {
                   let renderer = MKPolygonRenderer(polygon: polygon)
                   renderer.alpha = 0.5
                   guard let currentUserId = Auth.auth().currentUser?.uid else {
                       renderer.fillColor = UIColor.gray.withAlphaComponent(0.5)
                       renderer.strokeColor = UIColor.gray.withAlphaComponent(0.5)
                       renderer.lineWidth = 1.0
                       return renderer
                   }
                   if polygon.title == currentUserId {
                       renderer.fillColor = UIColor.red.withAlphaComponent(0.5)
                       renderer.strokeColor = UIColor.red.withAlphaComponent(0.5)
                   } else {
                       renderer.fillColor = UIColor.purple.withAlphaComponent(0.5)
                       renderer.strokeColor = UIColor.purple.withAlphaComponent(0.5)
                   }
                   renderer.lineWidth = 1.0
                   return renderer
               }
               return MKOverlayRenderer()
           }
           
           func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
               // ユーザーの現在位置のアノテーションは無視する
               if annotation is MKUserLocation {
                   return nil
               }

               let annotationIdentifier = "UserLocationAnnotation"
               var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) as? MKAnnotationView

               if annotationView == nil {
                   annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
                   annotationView?.canShowCallout = true
               } else {
                   annotationView?.annotation = annotation
               }

               if let userId = (annotation as? UserLocationAnnotation)?.userId {
                   let imageLoader = imageLoaders[userId] ?? ImageLoader()
                   imageLoaders[userId] = imageLoader

                   let imageUrlRef = Database.database().reference(withPath: "users/\(userId)/profileImageUrl")
                   imageUrlRef.observeSingleEvent(of: .value) { snapshot in
                       if let imageUrlString = snapshot.value as? String, let url = URL(string: imageUrlString) {
                           imageLoader.load(fromURL: url)

                           imageLoader.$image.sink { [weak annotationView] downloadedImage in
                               guard let downloadedImage = downloadedImage else {
                                   DispatchQueue.main.async {
                                       annotationView?.image = UIImage(systemName: "person.circle.fill")
                                   }
                                   return
                               }
                               DispatchQueue.main.async {
                                   let size = CGSize(width: 30, height: 30)
                                   UIGraphicsBeginImageContextWithOptions(size, false, 0.0)

                                   // 丸いクリップパスの作成
                                   let path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: size.width, height: size.height))
                                   path.addClip()

                                   downloadedImage.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))

                                   // 白い枠線の追加
                                   UIColor.white.setStroke()
                                   path.lineWidth = 2
                                   path.stroke()

                                   let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
                                   UIGraphicsEndImageContext()
                                   annotationView?.image = resizedImage
                               }
                           }.store(in: &imageLoader.cancellables)
                       } else {
                           DispatchQueue.main.async {
                               annotationView?.image = UIImage(systemName: "person.circle.fill")
                           }
                       }
                   }
               }

               return annotationView
           }
           
           
       }
    }

extension MapView {
    func updatePolyline(for mapView: MKMapView, minimumDistance: CLLocationDistance = 20) { // 500メートルを距離の閾値とする
        guard let lastLocation = locationManager.location, lastLocation.speed * 3.6 < 30 else {
            print("Skipping polyline update due to high speed (> 30 km/h)")
            return  // 30 km/h 以上の速度であればポリラインの更新をスキップ
        }

        let currentUserId = Auth.auth().currentUser?.uid
        let existingPolylines = mapView.overlays.compactMap { $0 as? MKPolyline }
        let polylinesForCurrentUser = existingPolylines.filter { $0.title == currentUserId }

        let coordinates = locationManager.locations
        if coordinates.count > 1 {
            if let lastPolyline = polylinesForCurrentUser.last {
                var lastCoordinate = CLLocationCoordinate2D()
                // 最後の座標を取得
                lastPolyline.getCoordinates(&lastCoordinate, range: NSRange(location: lastPolyline.pointCount - 1, length: 1))

                let lastCLLocation = CLLocation(latitude: lastCoordinate.latitude, longitude: lastCoordinate.longitude)
                let newLocation = CLLocation(latitude: coordinates.first!.latitude, longitude: coordinates.first!.longitude)
                
                let distance = lastCLLocation.distance(from: newLocation)
                print("Distance to last polyline: \(distance) meters")
                
                if distance > minimumDistance {
                    locationManager.locations.removeAll()  // 座標リストをクリア
                    locationManager.locations.append(contentsOf: [lastLocation.coordinate, coordinates.first!])  // 新しいポリラインの開始点として追加
                    let newPolyline = MKPolyline(coordinates: locationManager.locations, count: locationManager.locations.count)
                    newPolyline.title = currentUserId
                    mapView.addOverlay(newPolyline)
                }

            } else {
                // 既存のポリラインがない場合、または最後の座標が取得できない場合、新しいポリラインを追加
                let newPolyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
                newPolyline.title = currentUserId
                mapView.addOverlay(newPolyline)
            }
        }
        
        print("Updating polyline with coordinates: \(coordinates.map { "\($0.latitude), \($0.longitude)" })")
        if let lastLocation = coordinates.last {
            uploadLocation(latitude: lastLocation.latitude, longitude: lastLocation.longitude)
        }
    }




    
    func uploadLocation(latitude: Double, longitude: Double) {
        // 位置情報のデータを準備
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let locationData: [String: Any] = ["latitude": latitude, "longitude": longitude, "timestamp": timestamp]
        
        // ユーザーIDに基づいて位置情報をFirebaseに保存
        ref.child("users").child(userUID).child("locations").setValue(locationData) { (error, reference) in
            if let error = error {
                print("Data could not be saved: \(error.localizedDescription)")
            } else {
                print("Data saved successfully!")
            }
        }
    }

    
    func updateUserLocationsOnMap(_ uiView: MKMapView) {
        let currentPolylines = Set(uiView.overlays.compactMap { $0 as? MKPolyline })
        let newPolylines = Set(locationManager.userLocationsHistory.compactMap { userId, coordinates -> MKPolyline? in
            guard coordinates.count > 1 else { return nil }
            let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
            polyline.title = userId
            return polyline
        })

        // 既存のポリラインと新しいポリラインの差分を取得
        let polylinesToAdd = Array(newPolylines.subtracting(currentPolylines))
        let polylinesToRemove = Array(currentPolylines.subtracting(newPolylines))

        // 地図上の更新を一括で行う
        DispatchQueue.main.async {
            uiView.addOverlays(polylinesToAdd)
            uiView.removeOverlays(polylinesToRemove)
        }
    }


    func updateUserPolygonsOnMap(_ uiView: MKMapView) {
           let existingPolygons = uiView.overlays.compactMap { $0 as? MKPolygon }
           let existingPolygonIds = Set(existingPolygons.map { $0.title ?? "" })

           var newPolygonsToAdd: [MKPolygon] = []

           for (userId, coordinates) in locationManager.userLocationsHistory {
               guard coordinates.count > 2 else { continue }

               let newPolygon = MKPolygon(coordinates: coordinates, count: coordinates.count)
               newPolygon.title = userId

               // 既存のポリゴンを削除する前に新しいポリゴンを追加
               uiView.addOverlay(newPolygon)
               newPolygonsToAdd.append(newPolygon)

               // 既存のポリゴンを更新するか新しいポリゴンを追加するか判断
               if existingPolygonIds.contains(userId) {
                   // 既存のポリゴンを見つけて削除
                   if let existingPolygon = existingPolygons.first(where: { $0.title == userId }) {
                       uiView.removeOverlay(existingPolygon)
                   }
               }
           }

           // 不要になった既存のポリゴンを削除
           let polygonsToRemove = existingPolygons.filter { !newPolygonsToAdd.contains($0) }
           uiView.removeOverlays(polygonsToRemove)
       }
    
    
    func updateUserAnnotationsOnMap(_ uiView: MKMapView) {
        var updatedAnnotations = Set<String>()
        
        for (userId, locationData) in locationManager.allUserLocations {
            if let locationInfo = locationData as? [String: Any],
               let latitude = locationInfo["latitude"] as? CLLocationDegrees,
               let longitude = locationInfo["longitude"] as? CLLocationDegrees {
                let newCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

                let existingAnnotation = uiView.annotations.first {
                    ($0 as? UserLocationAnnotation)?.userId == userId
                } as? UserLocationAnnotation

                let username = locationInfo["username"] as? String ?? "Unknown User"  // ユーザー名を取得、もしくはデフォルト値の設定

                if let annotation = existingAnnotation {
                    annotation.coordinate = newCoordinate
                    annotation.title = username  // 更新されたユーザー名を設定
                    uiView.addAnnotation(annotation)
                } else {
                    let annotation = UserLocationAnnotation(userId: userId, coordinate: newCoordinate, title: username)
                    uiView.addAnnotation(annotation)
                }
                updatedAnnotations.insert(userId)
            }
        }

        // Remove annotations that are no longer present in the data source
        let annotationsToRemove = uiView.annotations.filter {
            guard let annotation = $0 as? UserLocationAnnotation else { return false }
            return !updatedAnnotations.contains(annotation.userId)
        }
        
        uiView.removeAnnotations(annotationsToRemove)
    }


}
