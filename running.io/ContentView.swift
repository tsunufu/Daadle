//
//  ContentView.swift
//  running.io
//
//  Created by ryo on 2024/02/14.
//

import SwiftUI
import MapKit

struct BottomCardView: View {
    var body: some View {
        VStack {
            Capsule()
                .frame(width: 60, height: 6)
                .foregroundColor(.secondary)
                .padding(10)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("シーズン1")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("開催期間 2/1~3/31")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("Score: 10298")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("次のバッジ獲得まであと4702")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding([.leading, .top, .bottom])
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("ランキング")
                        .font(.headline)
                    HStack {
                        Image(systemName: "rosette")
                        Text("1  あおいち  28384")
                            .font(.system(size: 8))
                    }
                    HStack {
                        Image(systemName: "rosette")
                        Text("2  あおいち  22384")
                            .font(.system(size: 8))
                    }
                    // ... more items
                }
                .padding([.trailing, .top, .bottom])
            }
            
//            HStack {
//                ForEach(["hand.thumbsup", "hand.thumbsdown", "star"], id: \.self) { imageName in
//                    Image(systemName: imageName)
//                        .padding(4)
//                }
//                Spacer()
//                Text("24  回答")
//                    .font(.caption)
//                    .foregroundColor(.gray)
//            }
            .padding(.horizontal)
        }
        .background(Color(red: 253 / 255, green: 254 / 255, blue: 249 / 255))
        .cornerRadius(25)
        .shadow(radius: 10)
        .padding([.horizontal, .bottom], 0)
    }
}

struct FullScreenMapView: View {
    @ObservedObject private var locationManager = LocationManager()
    var userUID: String
    
    var body: some View {
        ZStack(alignment: .bottom) {
            MapView(locationManager: locationManager, userUID: userUID)
            BottomCardView() // Use the custom bottom card view
        }
        .edgesIgnoringSafeArea(.all)
    }
    
}

struct FullScreenMapView_Previews: PreviewProvider {
    static var previews: some View {
        // ダミーとしてtestUserを使用
        FullScreenMapView(userUID: "testUser")
    }
}
