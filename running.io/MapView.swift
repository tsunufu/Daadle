import SwiftUI
import MapKit
import FirebaseDatabase

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
       }

       func makeCoordinator() -> Coordinator {
           Coordinator(self, locationManager: locationManager)
       }

       class Coordinator: NSObject, CLLocationManagerDelegate, MKMapViewDelegate {
           var parent: MapView
           var locationManager: LocationManager

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
               if let polyline = overlay as? MKPolyline {
                   let renderer = MKPolylineRenderer(polyline: polyline)
                   renderer.strokeColor = .blue
                   renderer.lineWidth = 4.0
                   return renderer
               } else if let polygon = overlay as? MKPolygon {
                   let renderer = MKPolygonRenderer(polygon: polygon)
                   renderer.strokeColor = .purple
                   renderer.lineWidth = 4.0
                   renderer.fillColor = UIColor.purple.withAlphaComponent(0.5)
                   return renderer
               }
               return MKOverlayRenderer(overlay: overlay)
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

        let coordinates = locationManager.locations
        let polygon = MKPolygon(coordinates: coordinates, count: coordinates.count)

        mapView.addOverlay(polygon)
    }

    
    func updateUserLocationsOnMap(_ uiView: MKMapView) {
        // すでに追加されているポリラインの識別子を格納する配列
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
        uiView.overlays.forEach { if $0 is MKPolygon { uiView.removeOverlay($0) } }

        for (userId, coordinates) in locationManager.userLocationsHistory {
            guard coordinates.count > 2 else { continue }

            let polygon = MKPolygon(coordinates: coordinates, count: coordinates.count)
            polygon.title = userId

            // ポリゴンをマップビューに追加
            uiView.addOverlay(polygon)
        }
    }




    }



