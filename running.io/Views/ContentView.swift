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
                    if value.translation.height > 50 { // 下にドラッグした距離が50を超えた場合、ビューを閉じる
                        self.offset = CGSize(width: 0, height: 120) // モーダルを下に隠す
                    } else {
                        self.offset = .zero // 元の位置に戻す
                    }
                })
            
            HStack {
                VStack(alignment: .leading) {
                    Text("新緑の祝典")
                        .font(Font.custom("DelaGothicOne-Regular", size: 20))
                        .fontWeight(.bold)
                    Text("開催期間 4/30~5/31")
                        .font(Font.custom("DelaGothicOne-Regular", size: 12))
                        .foregroundColor(.gray)
                    Text("Score: \(areaScore != nil ? "\(Int(areaScore!))" : "null")")
                        .font(Font.custom("DelaGothicOne-Regular", size: 12))
                        .animation(nil)
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
                                .animation(nil)
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
    @State private var showWarningView = false
    @State private var areaScore: Double?
    @State private var locationsCount: Int = 0
    @State private var profileImageUrl: String?
    @State private var isImageTapped = false
    
    var showUsernameEditUI: Bool = true
    var showFriendSearchUI: Bool = true
    var showCustomSegmentedPicker: Bool = true
    var showBlockButton: Bool = true
    
    @State private var position: MapCameraPosition = .automatic
    @State private var isUserInteracting = false
    
    @State private var isPressed = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Map(position: $position, interactionModes: .all) {
                MapPolygon(coordinates: locationManager.locations)
                    .foregroundStyle(.orange.opacity(0.6))
                ForEach(Array(locationManager.userLocationsHistory.keys), id: \.self) { userId in
                    if let locations = locationManager.userLocationsHistory[userId], !locations.isEmpty {
                        MapPolygon(coordinates: locations)
                            .foregroundStyle(Color.blue.opacity(0.5))
                    }
                }

                UserAnnotation(anchor: .center) { userLocation in
                    VStack {
                        if let imageUrl = profileImageUrl, let url = URL(string: imageUrl) {
                            RemoteImageView(url: url) // カスタムリモート画像ビューを使用
                                .scaledToFit()
                                .frame(width: 40, height: 40) // サイズは適宜調整
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                .shadow(radius: 3)
                        } else {
                            Image(systemName: "person.circle.fill") // プロフィール画像がない場合のデフォルト
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .background(Color.white)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                .shadow(radius: 3)
                        }
                    }
                }
            }
                .mapStyle(.standard(elevation: .realistic))
                .onAppear {
                    if let userLocation = locationManager.location {
                        print("---------------------")
                        let camera = MapCamera(centerCoordinate: userLocation.coordinate, distance: 200, heading: 242, pitch: 40)
                        position = .camera(camera)
                    }
//                    fetchFriendsLocations()
                }
                .onChange(of: locationManager.location) { newLocation in
                    if let location = newLocation, !isPressed {
                        withAnimation(.linear(duration: 0.5)) { // アニメーションを追加
                            let camera = MapCamera(centerCoordinate: location.coordinate, distance: 400, heading: 242, pitch: 40)
                            position = .camera(camera)
                        }
                    }
                    self.updatePolygonScore()
                }
                .gesture(
                    DragGesture().onChanged { _ in isPressed = true }
                                .onEnded { _ in isPressed = false }
                )
                .onDisappear {
                    locationManager.saveLocationsToCoreData()
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
                            .scaleEffect(isImageTapped ? 1.5 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isImageTapped)
                            .onTapGesture {
                                self.isImageTapped = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    self.showProfileView = true
                                    self.isImageTapped = false
                                }
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
                            .scaleEffect(isImageTapped ? 1.5 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isImageTapped)
                            .onTapGesture {
                                self.isImageTapped = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    self.showProfileView = true
                                    self.isImageTapped = false
                                }
                            }
                    }
                    Spacer()
                }
                Spacer()
            }

            VStack { // VStackでボタンとカードビューをまとめて配置
                Spacer() // 画面の下部に要素を押し下げる
                HStack {
                    Button(action: {
                        isPressed = false
                        if let location = locationManager.location {
                            withAnimation(.linear(duration: 0.5)) {
                                let camera = MapCamera(centerCoordinate: location.coordinate, distance: 400, heading: 242, pitch: 40)
                                position = .camera(camera)
                            }
                        }
                    }) {
                        Image("currentButton")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                    }
                    .padding(.leading, 20) // 左端からのパディング
                    .padding(.bottom, -80)
                    Spacer() // 残りのスペースを埋める
                }
                BottomCardView(areaScore: areaScore, userUID: userUID)
                    .offset(y: 50)
                    .edgesIgnoringSafeArea(.bottom)
            }
            
            if userSession.showBadgeView {
                BadgeGetView(showBadgeView: $userSession.showBadgeView)
                    .background(Color.black.opacity(0.5)) // 背景を暗くするオプション
                    .edgesIgnoringSafeArea(.all) // 画面全体に広げる
                    .zIndex(1)
            }
            if showWarningView {
                WarningView {
                    self.showWarningView = false  // WarningViewを閉じる
                }
                .edgesIgnoringSafeArea(.all)
                .zIndex(1)
            }
        }
        .sheet(isPresented: $showProfileView) {
            ProfileView(userID: userUID, showUsernameEditUI: showUsernameEditUI, showFriendSearchUI: showFriendSearchUI, showCustomSegmentedPicker: showCustomSegmentedPicker, showBlockButton: showBlockButton)
        }
        .onAppear {
            fetchUserProfileImage()
            updateWarningViewState()
        }
        .onChange(of: locationManager.isAlwaysAuthorized) { isAuthorized in
            showWarningView = !isAuthorized
            
        }
    }
    
    private func updateWarningViewState() {
        showWarningView = !locationManager.isAlwaysAuthorized
    }

    func updatePolygonScore() {
        areaScore = locationManager.calculateAreaOfPolygon(coordinates: locationManager.locations)
        // areaScoreをDatabaseに保存
        let scoreRef = Database.database().reference(withPath: "users/\(userUID)/score")
        scoreRef.setValue(areaScore) { error, _ in
            if let error = error {
                print("Error saving score: \(error.localizedDescription)")
            } else {
//                print("Score saved successfully.")
            }
        }
    }
    
//    private func fetchFriendsLocations() {
//        let friendsRef = Database.database().reference(withPath: "users/\(userUID)/friends")
//        friendsRef.observeSingleEvent(of: .value) { snapshot in
//            var friendsUIDs = [String]()
//            for child in snapshot.children {
//                if let childSnapshot = child as? DataSnapshot {
//                    friendsUIDs.append(childSnapshot.key)
//                }
//            }
//            friendsUIDs.append(self.userUID)  // 自分自身を追加
//            self.observeLocationsForFriends(friendsUIDs)
//        }
//    }
//
//    private func observeLocationsForFriends(_ friendUIDs: [String]) {
//        let usersRef = Database.database().reference(withPath: "users")
//        for uid in friendUIDs {
//            usersRef.child(uid).child("locations").observe(.value) { snapshot in
//                var locations = [CLLocationCoordinate2D]()
//                for locationSnapshot in snapshot.children {
//                    if let locationDict = locationSnapshot as? DataSnapshot,
//                       let lat = locationDict.childSnapshot(forPath: "latitude").value as? Double,
//                       let lon = locationDict.childSnapshot(forPath: "longitude").value as? Double {
//                        locations.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
//                    }
//                }
//                DispatchQueue.main.async {
//                    locationManager.userLocationsHistory[uid] = locations
//                }
//            }
//        }
//    }

    
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
