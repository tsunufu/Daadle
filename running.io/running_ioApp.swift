//
//  running_ioApp.swift
//  running.io
//
//  Created by ryo on 2024/02/14.
//

import SwiftUI

@main
struct running_ioApp: App {
    @StateObject private var locationManager = LocationManager()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(locationManager)
        }
    }
}
