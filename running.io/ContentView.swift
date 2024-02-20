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
    var userUID: String
    
    var body: some View {
        MapView(locationManager: locationManager, userUID: userUID)
            .edgesIgnoringSafeArea(.all)
    }
    
}

struct FullScreenMapView_Previews: PreviewProvider {
    static var previews: some View {
        // ダミーとしてtestUserを使用
        FullScreenMapView(userUID: "testUser")
    }
}
