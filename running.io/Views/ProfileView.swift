//
//  ProfileView.swift
//  running.io
//
//  Created by 中村蒼 on 2024/02/22.
//

import Foundation
import SwiftUI

//struct BezierTopView: View {
//    var body: some View {
//        GeometryReader { geometry in
//            Path { path in
//                let width = geometry.size.width
//                let height: CGFloat = 100  // Adjust height according to your design
//                
//                // Start point at top left
//                path.move(to: CGPoint(x: 0, y: 0))
//                
//                // Define the points for the Bezier curve
//                path.addLine(to: CGPoint(x: 0, y: height - 20))
//                path.addCurve(to: CGPoint(x: width, y: height - 40),
//                              control1: CGPoint(x: width * 0.3, y: height + 40),
//                              control2: CGPoint(x: width * 0.7, y: height - 80))
//                path.addLine(to: CGPoint(x: width, y: 0))
//                path.addLine(to: CGPoint(x: 0, y: 0))
//            }
//            .fill(
//                LinearGradient(gradient: Gradient(colors: [Color(hex: "#FFA24C"), Color(hex: "#FFD1A3")]),
//                               startPoint: .leading,
//                               endPoint: .trailing)
//            )
//        }
//        .frame(height: 100)  // Set frame height same as the maximum height used in the path
//    }
//}

struct ProfileView: View {
    @StateObject private var controller: ProfileController

    @State private var isEditing = false
    @State private var draftUsername = ""
    @State private var isImagePickerPresented = false
    @State private var selectedImage: UIImage? = nil
    @State private var selectedTab = "フレンド"
    @State private var searchText = ""
    @State private var showingSearchResults = false
    @State private var isUsernamePopupPresented = false

    var showUsernameEditUI: Bool = true
    var showFriendSearchUI: Bool = true
    var showCustomSegmentedPicker: Bool = true
    var showBlockButton: Bool = true

    init(userID: String, showUsernameEditUI: Bool, showFriendSearchUI: Bool, showCustomSegmentedPicker: Bool, showBlockButton: Bool) {
        _controller = StateObject(wrappedValue: ProfileController(userID: userID))
        self.showUsernameEditUI = showUsernameEditUI
        self.showFriendSearchUI = showFriendSearchUI
        self.showCustomSegmentedPicker = showCustomSegmentedPicker
        self.showBlockButton = showBlockButton
    }

    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                ScrollView {
                    VStack(alignment: .center) {
                        
                        ZStack {
                            // Bezier curve background
//                            BezierTopView()
//                                .frame(width: geometry.size.width, height: 100)
//                                .edgesIgnoringSafeArea(.top)
//                                .zIndex(0) // Lower zIndex means it will be in the background

                            // Profile image
                            ProfileImageView(selectedImage: $selectedImage, imageUrl: $controller.imageUrl, isImagePickerPresented: $isImagePickerPresented)
                                .zIndex(1) // Higher zIndex means it will be in the foreground
                        }
                        
                        // ユーザー名の変更UI（ポップアップのボタン）
                        if showUsernameEditUI {
                            Button(action: {
                                draftUsername = controller.profile.userName
                                isUsernamePopupPresented = true
                            }) {
                                HStack {
                                    Text(controller.profile.userName)
                                        .font(Font.custom("DelaGothicOne-Regular", size: 24))
                                        .fontWeight(.bold)
                                        .foregroundColor(controller.userNameLoadFailed ? .red : .black)
                                    
                                    Image(systemName: "pencil")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                        }
                        
                        // バッジ表示ビュー
                        BadgeView(userBadges: controller.profile.badges)
                        
                        // スコア表示ビュー
                        ScoreView(totalScore: controller.profile.totalScore, streaks: controller.profile.streaks, wins: controller.profile.wins)
                        
                        
                        // フレンドリスト
                        // タブに応じて表示するビューを切り替え
                        VStack {
                            if selectedTab == "リクエスト" {
                                FriendRequestsView(
                                    searchText: $searchText,
                                    searchResults: $controller.searchResults,
                                    showingSearchResults: $showingSearchResults,
                                    friends: $controller.friends,
                                    fetchUsers: controller.fetchUsers,
                                    sendFriendRequest: controller.sendFriendRequest,
                                    showFriendSearchUI: showFriendSearchUI,
                                    friendRequests: $controller.friendRequests,
                                    handleRequest: controller.handleFriendRequest
                                )
                            } else {
                                FriendListView(
                                    searchText: $searchText,
                                    searchResults: $controller.searchResults,
                                    showingSearchResults: $showingSearchResults,
                                    friends: $controller.friends,
                                    fetchUsers: controller.fetchUsers,
                                    sendFriendRequest: controller.sendFriendRequest,
                                    removeFriend: controller.removeFriend,
                                    showFriendSearchUI: showFriendSearchUI,
                                    showBlockButton: showBlockButton
                                )
                            }
                            
                            // カスタムセグメンテッドピッカーの表示
                            if showCustomSegmentedPicker {
                                CustomSegmentedPicker(selectedTab: $selectedTab, tabs: ["フレンド", "リクエスト"])
                                    .padding(.bottom, 10)
                            }
                        }
                        .background(Color(hex: "#FDFEF9"))  // 全体の背景を白に設定
                        .cornerRadius(10)
                        .padding(.horizontal, 0)  // 必要に応じてパディングを追加
                        
                    }
                    .onDisappear {
                        controller.dataTask?.cancel()
                    }
                    .sheet(isPresented: $isImagePickerPresented) {
                        ImagePicker(selectedImage: $selectedImage)
                    }
                    .onChange(of: selectedImage) { newImage in
                        if let image = newImage {
                            controller.uploadImageToFirebase(image)
                        }
                    }
                    .overlay(
                        UsernameEditPopup(
                            isPresented: $isUsernamePopupPresented,
                            userName: $controller.profile.userName,
                            draftUsername: $draftUsername,
                            updateUsername: { controller.updateUsername(draftUsername: draftUsername) }
                        )
                    )
                }
                .navigationBarHidden(true)
                .background(Color(hex: "#FFF8F0"))
            }
        }
        .edgesIgnoringSafeArea(.top)
    }
        
}

struct CustomTextFieldBorder: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray, lineWidth: 1)
            )
    }
}

struct UsernameEditPopup: View {
    @Binding var isPresented: Bool
    @Binding var userName: String
    @Binding var draftUsername: String
    let updateUsername: () -> Void

    var body: some View {
        if isPresented {
            VStack {
                VStack(spacing: 16) {
                    Text("ユーザー名を編集")
                        .font(Font.custom("DelaGothicOne-Regular", size: 20))
                        .fontWeight(.bold)
                        .padding(.top, 20)

                    TextField("ユーザー名を入力", text: $draftUsername)
                        .font(Font.custom("DelaGothicOne-Regular", size: 16))
                        .padding(10)
                        .background(Color.white)
                        .cornerRadius(10)
                        .modifier(CustomTextFieldBorder())

                    HStack {
                        Button(action: {
                            isPresented = false
                        }) {
                            Text("キャンセル")
                                .foregroundColor(.red)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)
                                .font(Font.custom("DelaGothicOne-Regular", size: 16))
                        }

                        Spacer()

                        Button(action: {
                            updateUsername()
                            isPresented = false
                        }) {
                            Text("保存")
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(Color.blue)
                                .cornerRadius(10)
                                .font(Font.custom("DelaGothicOne-Regular", size: 16
                                                 ))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .padding()
                .frame(width: 300)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(radius: 10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.5))
            .ignoresSafeArea()
        }
    }
}

struct ProfileImageView: View {
    @Binding var selectedImage: UIImage?
    @Binding var imageUrl: String?
    @Binding var isImagePickerPresented: Bool

    var body: some View {
        if let selectedImage = selectedImage {
            Image(uiImage: selectedImage)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color(hex: "#E29E5E"), lineWidth: 2))
                .shadow(radius: 10)
                .padding(.top, 44)
                .onTapGesture {
                    self.isImagePickerPresented = true
                }
        } else if let imageUrl = self.imageUrl, let url = URL(string: imageUrl) {
            RemoteImageView(url: url)
                .scaledToFit()
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color(hex: "#E29E5E"), lineWidth: 2))
                .shadow(radius: 10)
                .padding(.top, 44)
                .onTapGesture {
                    self.isImagePickerPresented = true
                }
        } else {
            Image(systemName: "person.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color(hex: "#E29E5E"), lineWidth: 2))
                .shadow(radius: 10)
                .padding(.top, 44)
                .onTapGesture {
                    self.isImagePickerPresented = true
                }
        }
    }
}

struct BadgeView: View {
    var userBadges: [String]

    var body: some View {
        VStack(alignment: .leading) {  // VStackのalignmentを.centerから.leadingに変更
            Text("取得したバッジ")
                .font(Font.custom("DelaGothicOne-Regular", size: 16))
                .frame(maxWidth: .infinity, alignment: .leading)  // 左寄せに設定
                .multilineTextAlignment(.leading)  // テキスト自体の整列も左寄せにする
                .padding(.horizontal, 8)

            if !userBadges.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .center, spacing: 10) {
                        ForEach(userBadges, id: \.self) { badgeName in
                            Image(badgeName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 36, height: 36)
                        }
                    }
                    .padding(.leading, 6)  // ここでHStackにも左寄せの余白を追加
                }
            } else {
                Text("バッジはまだありません")
                    .font(Font.custom("DelaGothicOne-Regular", size: 16))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)  // このテキストは中央揃え
                    .padding(.vertical, 10)
            }
        }
        .padding(.leading, 30)
    }
}


struct ScoreView: View {
    let totalScore: Double
    let streaks: Int
    let wins: Int

    var body: some View {
        HStack(spacing: 50) {
            VStack {
                Text(String(format: "%.0f", totalScore))
                    .font(Font.custom("DelaGothicOne-Regular", size: 16))
                    .fontWeight(.bold)
                Text("total score💪")
                    .font(Font.custom("DelaGothicOne-Regular", size: 12))
                    .foregroundColor(.gray)
            }
            VStack {
                Text("\(streaks)")
                    .font(Font.custom("DelaGothicOne-Regular", size: 16))
                    .fontWeight(.bold)
                Text("streaks🔥")
                    .font(Font.custom("DelaGothicOne-Regular", size: 12))
                    .foregroundColor(.gray)
            }
            VStack {
                Text("\(wins)")
                    .font(Font.custom("DelaGothicOne-Regular", size: 16))
                    .fontWeight(.bold)
                Text("wins🏆")
                    .font(Font.custom("DelaGothicOne-Regular", size: 12))
                    .foregroundColor(.gray)
            }
            
        }
        .padding(.bottom, 28)
    }
        
}

//struct CustomSegmentedPicker: View {
//    @Binding var selectedTab: String
//    let tabs: [String]
//
//    var body: some View {
//        Picker("", selection: $selectedTab) {
//            ForEach(tabs, id: \.self) { tab in
//                Text(tab)
//                    .padding(.vertical, 10)
//                    .padding(.horizontal, 20)
//                    .background(Color(hex: self.selectedTab == tab ? "#DFD3C5" : "#FDFEF9"))
//                    .foregroundColor(Color.black)
//                    .cornerRadius(10)
//            }
//        }
//        .pickerStyle(SegmentedPickerStyle())
//        .modifier(CustomSegmentedControlStyle())
//        .padding(.horizontal, 60)
//        .background(Color(hex: "#FDFEF9"))
//        .padding(.bottom, 30)
//    }
//}

struct CustomSegmentedPicker: View {
    @Binding var selectedTab: String
    let tabs: [String]

    var body: some View {
        HStack {
            ForEach(tabs, id: \.self) { tab in
                Text(tab)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .background(self.selectedTab == tab ? Color(hex: "#DFD3C5") : Color(hex: "#FDFEF9"))
                    .foregroundColor(.black)
                    .font(Font.custom("DelaGothicOne-Regular", size: 12))
                    .cornerRadius(20)
                    .onTapGesture {
                        self.selectedTab = tab
                    }
                    .padding(.horizontal, 5) // タブ間の水平方向の余白を追加
                    .padding(.vertical, 4)
            }
        }
        .background(Color(hex: "#FDFEF9"))
        .cornerRadius(20)
        .shadow(color: .gray.opacity(0.5), radius: 3, x: 0, y: 2)
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

struct CustomSegmentedControlStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(8)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 4)
    }
}

struct FriendListView: View {
    @Binding var searchText: String
    @Binding var searchResults: [Friend]
    @Binding var showingSearchResults: Bool
    @Binding var friends: [Friend]
    @State private var isShowAlert = false
    @State private var selectedFriendId: String?
    
    var fetchUsers: (String) -> Void
    var sendFriendRequest: (String) -> Void
    var removeFriend: (String) -> Void
    var showFriendSearchUI: Bool
    var showBlockButton: Bool

    var body: some View {
        ScrollView {
        VStack(alignment: .leading) {
            SearchBar(searchText: $searchText, fetchUsers: fetchUsers, showingSearchResults: $showingSearchResults, showFriendSearchUI: showFriendSearchUI)

            let filteredFriends = friends.filter { friend in searchText.isEmpty || friend.username.localizedCaseInsensitiveContains(searchText) }

            if showingSearchResults {
                if searchResults.isEmpty {
                    Text("該当するユーザーが見つかりませんでした")
                        .font(Font.custom("DelaGothicOne-Regular", size: 16))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 10)
                } else {
                    ForEach(searchResults, id: \.id) { user in
                        HStack {
                            Text(user.username)
                                .font(Font.custom("DelaGothicOne-Regular", size: 16))
                                .foregroundColor(.black)
                                .padding(.vertical, 2)
                                .padding(.leading, 20)

                            Spacer()

                            Button("申請") {
                                print("申請ボタンが押されました")
                                sendFriendRequest(user.id)
                            }
                            .font(Font.custom("DelaGothicOne-Regular", size: 14))
                            .padding(.trailing, 20)
                        }
                        .padding(.leading, 20)

                        Divider()
                    }
                }
            } else {
                ForEach(0..<filteredFriends.count, id: \.self) { index in
                    NavigationLink(destination: FriendProfileView(friend: filteredFriends[index])) {
                        HStack {
                            if let imageUrl = filteredFriends[index].imageUrl, let url = URL(string: imageUrl) {
                                RemoteImageView(url: url)
                                    .frame(width: 42, height: 42)
                                    .clipShape(Circle())
                                    .padding(.horizontal, 10)
                            } else {
                                Image(systemName: "person.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)
                                    .background(Color.gray.opacity(0.3))
                                    .clipShape(Circle())
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(filteredFriends[index].username)
                                    .font(Font.custom("DelaGothicOne-Regular", size: 14))
                                    .foregroundColor(.black)
                                Text("スコア：\(filteredFriends[index].friendScore, specifier: "%.0f")")
                                    .font(Font.custom("DelaGothicOne-Regular", size: 12))
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            if showBlockButton{
                                Button(action: {
                                    self.selectedFriendId = friends[index].id
                                    self.isShowAlert = true
                                }) {
                                    Image("Close_round")  // ここをカスタムアセット名に置き換え
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 24, height: 24)  // サイズ調整が必要な場合
                                        .padding(.trailing, 10)
                                        .foregroundColor(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.vertical, 5)
                        .padding(.horizontal, 40)
                        Divider()
                    }
                }
            }
        }
        .background(Color(hex: "#FDFEF9"))
        .cornerRadius(10)
        .padding(.horizontal, 0)
        .alert("友達を削除", isPresented: $isShowAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("OK", role: .destructive) {
                if let id = selectedFriendId {
                    removeFriend(id)
                }
            }
        } message: {
            Text("この友達をリストから削除してもよろしいですか？")
        }
        }
//        .padding(.bottom, 170)
    }
}

struct FriendRequest: Identifiable {
    var id: String
    var username: String
    var imageUrl: String?
}

struct FriendRequestsView: View {
    @Binding var searchText: String
    @Binding var searchResults: [Friend]
    @Binding var showingSearchResults: Bool
    @Binding var friends: [Friend]
    
    @State private var isShowAlert = false
    @State private var selectedFriendId: String?
    
    var fetchUsers: (String) -> Void
    var sendFriendRequest: (String) -> Void
    var showFriendSearchUI: Bool
    
    @Binding var friendRequests: [FriendRequest]
    var handleRequest: (String, Bool) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                SearchBar(searchText: $searchText, fetchUsers: fetchUsers, showingSearchResults: $showingSearchResults, showFriendSearchUI: showFriendSearchUI)
                
                let filteredFriendRequests = friendRequests.filter { request in
                    searchText.isEmpty || request.username.localizedCaseInsensitiveContains(searchText)
                }
                
                
                if showingSearchResults {
                    if searchResults.isEmpty {
                        Text("該当するユーザーが見つかりませんでした")
                            .font(Font.custom("DelaGothicOne-Regular", size: 16))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 10)
                    } else {
                        ForEach(searchResults, id: \.id) { user in
                            HStack {
                                Text(user.username)
                                    .font(Font.custom("DelaGothicOne-Regular", size: 16))
                                    .foregroundColor(.black)
                                    .padding(.vertical, 2)
                                    .padding(.leading, 20)
                                
                                Spacer()
                                
                                Button("申請") {
                                    sendFriendRequest(user.id)
                                }
                                .font(Font.custom("DelaGothicOne-Regular", size: 14))
                                .padding(.trailing, 20)
                            }
                            .padding(.leading, 20)
                            
                            Divider()
                        }
                    }
                } else {
                    if filteredFriendRequests.isEmpty {
                        Text("受信したフレンドリクエストはありません")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        ForEach(0..<filteredFriendRequests.count, id: \.self) { index in
                            HStack {
                                if let imageUrl = filteredFriendRequests[index].imageUrl, let url = URL(string: imageUrl) {
                                    RemoteImageView(url: url)
                                        .frame(width: 50, height: 50)
                                        .clipShape(Circle())
                                        .padding(.horizontal, 10)
                                } else {
                                    Image(systemName: "person.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 50, height: 50)
                                        .background(Color.gray.opacity(0.3))
                                        .clipShape(Circle())
                                        .padding(.horizontal, 10)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(filteredFriendRequests[index].username)
                                        .font(Font.custom("DelaGothicOne-Regular", size: 16))
                                        .foregroundColor(.black)
                                }
                                Spacer()
                                Button(action: {
                                    handleRequest(filteredFriendRequests[index].id, true)
                                }) {
                                    Image("User_add_alt_fill")  // ここをカスタムアセット名に置き換え
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 24, height: 24)  // サイズ調整が必要な場合
                                        .foregroundColor(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: {
                                    self.selectedFriendId = filteredFriendRequests[index].id
                                    self.isShowAlert = true
                                }) {
                                    Image("Close_round")  // ここをカスタムアセット名に置き換え
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 24, height: 24)  // サイズ調整が必要な場合
                                        .padding(.trailing, 10)
                                        .foregroundColor(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.vertical, 5)
                            .padding(.horizontal, 20)
                            Divider()
                        }
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(10)
            .padding(.horizontal, 0)
            .alert("招待を拒否", isPresented: $isShowAlert) {
                Button("いいえ", role: .cancel) { }
                Button("はい", role: .destructive) {
                    if let id = selectedFriendId {
                        handleRequest(id, false)
                    }
                }
            } message: {
                Text("友達リクエストを拒否しますか？")
            }
        }
//        .padding(.bottom, 170)
    }
}


struct SearchBar: View {
    @Binding var searchText: String
    var fetchUsers: (String) -> Void
    @Binding var showingSearchResults: Bool
    var showFriendSearchUI: Bool

    var body: some View {
        HStack {
            if showFriendSearchUI {
                TextField("フレンドを検索", text: $searchText)
                    .onChange(of: searchText) { newValue in
                        if newValue.isEmpty {
                            showingSearchResults = false
                        }
                    }
                    .font(Font.custom("DelaGothicOne-Regular", size: 14))
                    .padding(6)
                    .padding(.horizontal, 25)
                    .background(Color(.systemGray6))
                    .cornerRadius(25)
                    .overlay(
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 8)
                            
                            if !searchText.isEmpty {
                                Button(action: {
                                    self.searchText = ""
                                }) {
                                    Image(systemName: "multiply.circle.fill")
                                        .foregroundColor(.gray)
                                        .padding(.trailing, 8)
                                }
                            }
                        }
                    )
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                
                Button(action: {
                    fetchUsers(searchText)
                    showingSearchResults = true
                }) {
                    Image(systemName: "magnifyingglass")
                }
                
                .padding(.trailing, 10)
            }
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 12)
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = context.coordinator
        return imagePicker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
