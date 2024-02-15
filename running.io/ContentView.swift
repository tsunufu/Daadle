//
//  ContentView.swift
//  running.io
//
//  Created by ryo on 2024/02/14.
//

import SwiftUI
import MapKit

struct FullScreenMapView: View {
    @ObservedObject private var locationManager = LocationManager()
    
    @State  var trackingMode = MapUserTrackingMode.follow

    var body: some View {
        
        Map(coordinateRegion: $locationManager.region,
            showsUserLocation: true,
            userTrackingMode: $trackingMode)
            .edgesIgnoringSafeArea(.all)
    }
}

struct FullScreenMapView_Previews: PreviewProvider {
    static var previews: some View {
        FullScreenMapView()
    }
}

