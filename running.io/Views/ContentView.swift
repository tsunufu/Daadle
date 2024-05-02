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
    var userUID: String
    @State private var friendRankings: [(username: String, score: Double, uid: String)] = []
    @State private var offset = CGSize.zero  // ビューのオフセット管理

    var body: some View {
        VStack {
            Capsule()
                .frame(width: 60, height: 8)
                .foregroundColor(.secondary)
                .padding(.vertical, 10)
                .gesture(DragGesture().onChanged { value in
                    self.offset = value.translation
                }.onEnded { value in
                    if value.translation.height > 50 { // 下にドラッグした距離が100を超えた場合、ビューを閉じる
                        self.offset = CGSize(width: 0, height: 120) // モーダルを下に隠す
                    } else {
                        self.offset = .zero // 元の位置に戻す
                    }
                })
            
            HStack {
                VStack(alignment: .leading) {
                    Text("シーズン1")
                        .font(Font.custom("DelaGothicOne-Regular", size: 20))
                        .fontWeight(.bold)
                    Text("開催期間 2/1~3/31")
                        .font(Font.custom("DelaGothicOne-Regular", size: 12))
                        .foregroundColor(.gray)
                    Text("Score: \(areaScore != nil ? "\(Int(areaScore!))" : "null")")
                        .font(Font.custom("DelaGothicOne-Regular", size: 12))
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
                        .padding(.bottom, 4)

                    ForEach(friendRankings.indices, id: \.self) { index in
                        HStack {
                            Image(systemName: "rosette")
                            Text("\(index + 1)  \(friendRankings[index].username)  \(Int(friendRankings[index].score))")
                                .font(Font.custom("DelaGothicOne-Regular", size: 12))
                        }
                        .padding(.bottom, index < friendRankings.count - 1 ? 4 : 0)
                    }
                }
                .offset(y: -10)
            }
            .padding(.horizontal, 32)
        }
        .background(Color(red: 253 / 255, green: 254 / 255, blue: 249 / 255))
        .cornerRadius(30)
        .shadow(radius: 12)
        .padding([.horizontal, .bottom], 0)
        .offset(y: self.offset.height)
        .animation(.spring())
        .onAppear {
            fetchFriendsAndTheirScores()
        }
    }

    private func fetchFriendsAndTheirScores() {
            let friendsRef = Database.database().reference(withPath: "users/\(userUID)/friends")
            friendsRef.observeSingleEvent(of: .value) { snapshot in
                var friendsUIDs = [String]()
                for child in snapshot.children {
                    if let childSnapshot = child as? DataSnapshot {
                        friendsUIDs.append(childSnapshot.key)
                    }
                }
                friendsUIDs.append(self.userUID)
                observeScoresForFriends(friendsUIDs)
            }
        }

        private func observeScoresForFriends(_ friendUIDs: [String]) {
            let usersRef = Database.database().reference(withPath: "users")
            for uid in friendUIDs {
                usersRef.child(uid).child("score").observe(.value) { snapshot in
                    guard let score = snapshot.value as? Double else { return }
                    usersRef.child(uid).child("username").observeSingleEvent(of: .value) { usernameSnapshot in
                        guard let username = usernameSnapshot.value as? String else { return }

                        if let index = self.friendRankings.firstIndex(where: { $0.uid == uid }) {
                            self.friendRankings[index].score = score
                        } else {
                            self.friendRankings.append((username, score, uid))
                        }

                        self.friendRankings.sort { $0.score > $1.score }
                    }
                }
            }
        }
}


struct FullScreenMapView: View {
    @EnvironmentObject var userSession: UserSession
    @ObservedObject private var locationManager = LocationManager()
    var userUID: String
    @State private var showProfileView = false
    @State private var showBadgeView = false
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

            BottomCardView(areaScore: areaScore, userUID: userUID)
                .offset(y: 50)
                .edgesIgnoringSafeArea(.bottom)
            if userSession.showBadgeView {
                BadgeGetView(showBadgeView: $userSession.showBadgeView)
                    .background(Color.black.opacity(0.5)) // 背景を暗くするオプション
                    .edgesIgnoringSafeArea(.all) // 画面全体に広げる
                    .zIndex(1)
            }
        }
        .sheet(isPresented: $showProfileView) {
            ProfileView(userID: userUID, totalScore: Binding.constant(areaScore ?? 0.0))
        }
        .onAppear {
            fetchUserProfileImage()
        }
//        .onChange(of: areaScore) { newValue in
//            if let score = newValue, score > 1000 {
//                showBadgeView = true // areaScoreが1000を超えたらBadgeGetViewを表示
//            }
//        }
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
