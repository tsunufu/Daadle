//
//  ContentView.swift
//  running.io
//
//  Created by ryo on 2024/02/14.
//

import SwiftUI
import MapKit
import FirebaseDatabase

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
    @State private var profileImageUrl: String?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            MapView(locationManager: locationManager, userUID: userUID)
                .edgesIgnoringSafeArea(.all)
                .onChange(of: locationManager.locations.count) { newCount in
                    if newCount != locationsCount {
                        locationsCount = newCount
                        updatePolygonScore()
                    }
                }

            VStack {
                HStack {
                    if let imageUrl = profileImageUrl, let url = URL(string: imageUrl) {
                        RemoteImageView(url: url)
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 4))
                            .shadow(radius: 3)
                            .padding()
                            .onTapGesture {
                                self.showProfileView = true
                            }
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .background(Color.white)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 4))
                            .shadow(radius: 3)
                            .padding()
                            .onTapGesture {
                                self.showProfileView = true
                            }
                    }
                    Spacer()
                }
                Spacer()
            }

            BottomCardView(areaScore: areaScore)
                .offset(y: 50)
                .edgesIgnoringSafeArea(.bottom)
        }
        .sheet(isPresented: $showProfileView) {
            ProfileView(userID: userUID, totalScore: Binding.constant(areaScore ?? 0.0))
        }
        .onAppear {
            fetchUserProfileImage()
        }
    }

    func updatePolygonScore() {
        areaScore = locationManager.calculateAreaOfPolygon(coordinates: locationManager.locations)
        // areaScoreをDatabaseに保存
        let scoreRef = Database.database().reference(withPath: "users/\(userUID)/score")
        scoreRef.setValue(areaScore) { error, _ in
            if let error = error {
                print("Error saving score: \(error.localizedDescription)")
            } else {
                print("Score saved successfully.")
            }
        }
    }
    
    func fetchUserProfileImage() {
        let imageUrlRef = Database.database().reference(withPath: "users/\(userUID)/profileImageUrl")
        imageUrlRef.observeSingleEvent(of: .value) { snapshot in
            if let imageUrlString = snapshot.value as? String {
                DispatchQueue.main.async {
                    self.profileImageUrl = imageUrlString
                }
            }
        }
    }
}
