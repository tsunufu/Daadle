import SwiftUI
import MapKit
import FirebaseDatabase
import FirebaseAuth

struct MapView: UIViewRepresentable {
    @ObservedObject var locationManager: LocationManager
    var userUID: String
    
    var ref: DatabaseReference! = Database.database().reference()

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
           updatePolygon(for: uiView)
           
           updateUserLocationsOnMap(uiView)
           updateUserPolygonsOnMap(uiView)
           updateUserAnotationsOnMap(uiView)
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
                   let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                   parent.locationManager.location = location
                   parent.locationManager.locations.append(center)
                   parent.locationManager.region = MKCoordinateRegion(center: center, latitudinalMeters: 1000.0, longitudinalMeters: 1000.0)
               }
           }
           
           func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
               guard let polygon = overlay as? MKPolygon else {
                   return MKOverlayRenderer(overlay: overlay)
               }

               let renderer = MKPolygonRenderer(polygon: polygon)

               // 現在のユーザーIDを取得
               guard let currentUserId = Auth.auth().currentUser?.uid else {
                   // 現在のユーザーIDがnilの場合、デフォルトの色を設定して処理を続行
                   renderer.fillColor = UIColor.gray.withAlphaComponent(0.5)
                   renderer.strokeColor = .gray
                   renderer.lineWidth = 4.0
                   return renderer
               }

               // ポリゴンのタイトルが現在のユーザーIDと一致するかどうかで色を変更
               if polygon.title == currentUserId {
                   renderer.fillColor = UIColor.red.withAlphaComponent(0.5)
                   renderer.strokeColor = .red
               } else {
                   renderer.fillColor = UIColor.purple.withAlphaComponent(0.5)
                   renderer.strokeColor = .purple
               }

               renderer.lineWidth = 4.0
               return renderer
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
    func updatePolyline(for mapView: MKMapView) {
        mapView.overlays.forEach { if $0 is MKPolyline { mapView.removeOverlay($0) } }

        let coordinates = locationManager.locations
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        
        
        print("Updating polyline with coordinates: \(coordinates.map { "\($0.latitude), \($0.longitude)" })")
        mapView.addOverlay(polyline)
        
        if let lastLocation = locationManager.locations.last {
            // Firebase Databaseを更新
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
    
    func updatePolygon(for mapView: MKMapView) {
        mapView.overlays.forEach { if $0 is MKPolygon { mapView.removeOverlay($0) } }

        for (userId, coordinates) in locationManager.userLocationsHistory {
            guard coordinates.count > 2 else { continue } // ポリゴンを形成するためには少なくとも3点が必要
            
            let polygon = MKPolygon(coordinates: coordinates, count: coordinates.count)
            polygon.title = userId // 実際のユーザーIDをタイトルに設定
            mapView.addOverlay(polygon)
        }
    }

    
    func updateUserLocationsOnMap(_ uiView: MKMapView) {
        var existingPolylinesIds: [String] = uiView.overlays.compactMap { overlay in
            if let polyline = overlay as? MKPolyline, let polylineId = polyline.title {
                return polylineId
            }
            return nil
        }

        for (userId, coordinates) in locationManager.userLocationsHistory {
            print("User ID: \(userId) has \(coordinates.count) coordinates.")

            guard coordinates.count > 1 else { continue }

            let polylineId = userId
            let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
            polyline.title = polylineId

            if existingPolylinesIds.contains(polylineId) {
                if let index = uiView.overlays.firstIndex(where: { ($0 as? MKPolyline)?.title == polylineId }) {
                    uiView.removeOverlay(uiView.overlays[index])
                    uiView.addOverlay(polyline)
                }
            } else {
                uiView.addOverlay(polyline)
            }

            existingPolylinesIds.removeAll { $0 == polylineId }
        }

        for polylineId in existingPolylinesIds {
            if let index = uiView.overlays.firstIndex(where: { ($0 as? MKPolyline)?.title == polylineId }) {
                uiView.removeOverlay(uiView.overlays[index])
            }
        }
    }
    
    func updateUserPolygonsOnMap(_ uiView: MKMapView) {
        let existingPolygons = uiView.overlays.compactMap { $0 as? MKPolygon }
        let existingPolygonIds = Set(existingPolygons.map { $0.title ?? "" })

        for (userId, coordinates) in locationManager.userLocationsHistory {
            guard coordinates.count > 2 else { continue }

            let newPolygon = MKPolygon(coordinates: coordinates, count: coordinates.count)
            newPolygon.title = userId

            // 既存のポリゴンを削除する前に新しいポリゴンを追加
            uiView.addOverlay(newPolygon)

            // 既存のポリゴンを更新するか新しいポリゴンを追加するか判断
            if existingPolygonIds.contains(userId) {
                // 既存のポリゴンを見つけて削除
                if let existingPolygon = existingPolygons.first(where: { $0.title == userId }) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        uiView.removeOverlay(existingPolygon)
                    }
                }
            }
        }
    }
    
    
    func updateUserAnotationsOnMap(_ uiView: MKMapView) {
        // 既存のアノテーションを取得し、ユーザーIDをキーとする辞書を作成
        let existingAnnotations = uiView.annotations.compactMap { $0 as? UserLocationAnnotation }
        let existingAnnotationsDict = Dictionary(uniqueKeysWithValues: existingAnnotations.map { ($0.userId, $0) })

        for (userId, locationData) in locationManager.allUserLocations {
            if let locationInfo = locationData as? [String: Any],
               let latitude = locationInfo["latitude"] as? CLLocationDegrees,
               let longitude = locationInfo["longitude"] as? CLLocationDegrees {
                let newCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                
                if let existingAnnotation = existingAnnotationsDict[userId] {
                    existingAnnotation.coordinate = newCoordinate
                    
                    let coordinates = [existingAnnotation.coordinate, newCoordinate].compactMap { $0 }
                } else {
                    let annotation = UserLocationAnnotation(userId: userId, coordinate: newCoordinate, title: "aaa")
                    uiView.addAnnotation(annotation)
                }
            }
        }
    }


}
