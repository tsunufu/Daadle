//
//  ProfileView.swift
//  running.io
//
//  Created by 中村蒼 on 2024/02/22.
//

import Foundation
import SwiftUI

struct ProfileView: View {
    @StateObject private var controller: ProfileController

    @State private var isEditing = false
    @State private var draftUsername = ""
    @State private var isImagePickerPresented = false
    @State private var selectedImage: UIImage? = nil
    @State private var selectedTab = "フレンド"
    @State private var searchText = ""
    @State private var showingSearchResults = false

    var showUsernameEditUI: Bool = true
    var showFriendSearchUI: Bool = true
    var showCustomSegmentedPicker: Bool = true

    init(userID: String, showUsernameEditUI: Bool, showFriendSearchUI: Bool, showCustomSegmentedPicker: Bool) {
        _controller = StateObject(wrappedValue: ProfileController(userID: userID))
        self.showUsernameEditUI = showUsernameEditUI
        self.showFriendSearchUI = showFriendSearchUI
        self.showCustomSegmentedPicker = showCustomSegmentedPicker
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .center) {
                    // プロフィール画像
                    ProfileImageView(selectedImage: $selectedImage, imageUrl: $controller.imageUrl, isImagePickerPresented: $isImagePickerPresented)

                    // ユーザー名の変更UI
                    UsernameEditView(
                        userName: $controller.profile.userName,
                        draftUsername: $draftUsername,
                        isEditing: $isEditing,
                        userNameLoadFailed: $controller.userNameLoadFailed,
                        showUsernameEditUI: showUsernameEditUI,
                        updateUsername: { controller.updateUsername(draftUsername: draftUsername) }
                    )

                    // バッジ表示ビュー
                    BadgeView(userBadges: controller.profile.badges)

                    // スコア表示ビュー
                    ScoreView(totalScore: controller.profile.totalScore, streaks: controller.profile.streaks, wins: controller.profile.wins)

                    // フレンドリスト
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
                            showFriendSearchUI: showFriendSearchUI
                        )
                    }

                    if showCustomSegmentedPicker {
                        CustomSegmentedPicker(selectedTab: $selectedTab, tabs: ["フレンド", "リクエスト"])
                    }
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
            }
            .background(Color.orange.opacity(0.2))
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
                .overlay(Circle().stroke(Color.white, lineWidth: 4))
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
                .overlay(Circle().stroke(Color.white, lineWidth: 4))
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
                .overlay(Circle().stroke(Color.white, lineWidth: 4))
                .shadow(radius: 10)
                .padding(.top, 44)
                .onTapGesture {
                    self.isImagePickerPresented = true
                }
        }
    }
}

struct UsernameEditView: View {
    @Binding var userName: String
    @Binding var draftUsername: String
    @Binding var isEditing: Bool
    @Binding var userNameLoadFailed: Bool
    let showUsernameEditUI: Bool
    let updateUsername: () -> Void

    var body: some View {
        HStack {
            if isEditing {
                TextField("ユーザー名を入力", text: $draftUsername)
                    .font(Font.custom("DelaGothicOne-Regular", size: 16))
                    .padding(10)
                    .background(Color.white)
                    .cornerRadius(10)
                    .padding(.trailing, 10)
            } else {
                Text(userName)
                    .font(Font.custom("DelaGothicOne-Regular", size: 24))
                    .fontWeight(.bold)
                    .foregroundColor(userNameLoadFailed ? .red : .black)
            }

            if showUsernameEditUI {
                Button(action: {
                    if self.isEditing {
                        self.updateUsername()
                    } else {
                        self.draftUsername = self.userName
                        self.isEditing = true
                    }
                }) {
                    if isEditing {
                        Image(systemName: "checkmark.square.fill")
                            .foregroundColor(.green)
                    } else {
                        Image("edit")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
}

struct BadgeView: View {
    var userBadges: [String]

    var body: some View {
        VStack(alignment: .leading) {
            Text("取得したバッジ")
                .font(Font.custom("DelaGothicOne-Regular", size: 16))
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)

            if !userBadges.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .center, spacing: 10) {
                        ForEach(userBadges, id: \.self) { badgeName in
                            Image(badgeName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                Text("バッジはまだありません")
                    .font(Font.custom("DelaGothicOne-Regular", size: 16))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
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
        HStack(spacing: 20) {
            VStack {
                Text(String(format: "%.0f", totalScore))
                    .font(Font.custom("DelaGothicOne-Regular", size: 20))
                    .fontWeight(.bold)
                Text("total score💪")
                    .font(Font.custom("DelaGothicOne-Regular", size: 12))
                    .foregroundColor(.gray)
            }
            VStack {
                Text("\(streaks)")
                    .font(Font.custom("DelaGothicOne-Regular", size: 20))
                    .fontWeight(.bold)
                Text("streaks🔥")
                    .font(Font.custom("DelaGothicOne-Regular", size: 12))
                    .foregroundColor(.gray)
            }
            VStack {
                Text("\(wins)")
                    .font(Font.custom("DelaGothicOne-Regular", size: 20))
                    .fontWeight(.bold)
                Text("wins🏆")
                    .font(Font.custom("DelaGothicOne-Regular", size: 12))
                    .foregroundColor(.gray)
            }
        }
    }
}

struct CustomSegmentedPicker: View {
    @Binding var selectedTab: String
    let tabs: [String]

    var body: some View {
        Picker("", selection: $selectedTab) {
            ForEach(tabs, id: \.self) { tab in
                Text(tab)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(self.selectedTab == tab ? Color.gray.opacity(0.2) : Color.white)
                    .cornerRadius(10)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .modifier(CustomSegmentedControlStyle())
        .padding(.horizontal, 60)
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
    var fetchUsers: (String) -> Void
    var sendFriendRequest: (String) -> Void
    var showFriendSearchUI: Bool

    var body: some View {
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
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(filteredFriends[index].username)
                                    .font(Font.custom("DelaGothicOne-Regular", size: 16))
                                    .foregroundColor(.black)
                                Text("スコア：\(filteredFriends[index].friendScore, specifier: "%.0f")")
                                    .font(Font.custom("DelaGothicOne-Regular", size: 14))
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 5)
                        Divider()
                    }
                }
            }
        }
        .background(Color.white)
        .cornerRadius(10)
        .padding()
        .padding(.bottom, 50)
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
    var fetchUsers: (String) -> Void
    var sendFriendRequest: (String) -> Void
    var showFriendSearchUI: Bool
    
    @Binding var friendRequests: [FriendRequest]
    var handleRequest: (String, Bool) -> Void

    var body: some View {
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
                                    handleRequest(filteredFriendRequests[index].id, false)
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
                            Divider()
                    }
                }
            }
        }
        .background(Color.white)
        .cornerRadius(10)
        .padding()
        .padding(.bottom, 50)
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
                    .font(Font.custom("DelaGothicOne-Regular", size: 16))
                    .padding(12)
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
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
                
                Button(action: {
                    fetchUsers(searchText)
                    showingSearchResults = true
                }) {
                    Image(systemName: "magnifyingglass")
                }
                
                .padding(.trailing, 10)
            }
        }
        .padding(.vertical, 10)
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
