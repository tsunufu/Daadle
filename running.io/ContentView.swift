//
//  ContentView.swift
//  running.io
//
//  Created by ryo on 2024/02/14.
//

import SwiftUI
import MapKit

struct BottomCardView: View {
    var areaScore: Double?
    
    var body: some View {
        VStack {
            Capsule()
                .frame(width: 60, height: 8)
                .foregroundColor(.secondary)
                .padding(.vertical, 10)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("シーズン1")
                        .font(Font.custom("DelaGothicOne-Regular", size: 20))
                        .fontWeight(.bold)
                    Text("開催期間 2/1~3/31")
                        .font(Font.custom("DelaGothicOne-Regular", size: 12))
                        .foregroundColor(.gray)
                    Text("Score: \(areaScore != nil ? "\(Int(areaScore!))" : "null")")
                        .font(Font.custom("DelaGothicOne-Regular", size:12))
                    Text("次のバッジ獲得まであと4702")
                        .font(Font.custom("DelaGothicOne-Regular", size: 8))
                        .foregroundColor(.gray)
                        .padding(.bottom, 42)
                }
                .padding([.leading, .top, .bottom])
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("ランキング")
                        .font(Font.custom("DelaGothicOne-Regular", size: 16))
                    HStack {
                        Image(systemName: "rosette")
                        Text("1  あおいち  28384")
                            .font(Font.custom("DelaGothicOne-Regular", size: 12))
                    }
                    HStack {
                        Image(systemName: "rosette")
                            .padding(.bottom, 42)
                        Text("2  えふじ  22394")
                            .font(Font.custom("DelaGothicOne-Regular", size: 12))
                            .padding(.bottom, 42)
                    }
                }
                .padding([.trailing, .top, .bottom])
            }
            
            .padding(.horizontal, 32)
        }
        .background(Color(red: 253 / 255, green: 254 / 255, blue: 249 / 255))
        .cornerRadius(30)
        .shadow(radius: 12)
        .padding([.horizontal, .bottom], 0)
    }
}

struct FullScreenMapView: View {
    @ObservedObject private var locationManager = LocationManager()
    var userUID: String
    @State private var showProfileView = false
    @State private var areaScore: Double?
    @State private var locationsCount: Int = 0

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            MapView(locationManager: locationManager, userUID: userUID)
                .edgesIgnoringSafeArea(.all)
                .onChange(of: locationManager.locations.count) { newCount in
                    if newCount != locationsCount {
                        locationsCount = newCount // 位置情報の数を更新
                        updatePolygonScore() // 面積スコアを更新
                    }
                }

            VStack {
                HStack {
                    Spacer() // 右寄せにするためのSpacer
                    Image(systemName: "person.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .padding()
                        .onTapGesture {
                            self.showProfileView = true
                        }
                }
                Spacer()
            }

            BottomCardView(areaScore: areaScore)
                .offset(y: 50)
                .edgesIgnoringSafeArea(.bottom)
        }
        .sheet(isPresented: $showProfileView) {
            ProfileView(userID: userUID)
        }
    }

    func updatePolygonScore() {
        areaScore = locationManager.calculateAreaOfPolygon(coordinates: locationManager.locations)
    }
}
