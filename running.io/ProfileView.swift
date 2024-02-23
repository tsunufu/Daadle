//
//  ProfileView.swift
//  running.io
//
//  Created by 中村蒼 on 2024/02/22.
//

import Foundation
import SwiftUI
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth

struct ProfileView: View {
    let profileImageName = "defaultProfile" // あとで変更する必要あり
    @State private var userName = "ユーザー名を読み込み中..."
    let streaks = 12 // 変更必要
    let wins = 24 // 変更必要
    let userID: String
    @State private var isEditing = false
    @State private var draftUsername = "" // 編集中のユーザー名を一時保存
    @State private var isImagePickerPresented = false
    @State private var selectedImage: UIImage? = nil
    var dataTask: URLSessionDataTask?
    @State private var imageUrl: String? = nil
    @State private var isLoadingUserName = true
    @State private var userNameLoadFailed = false
    @Binding var totalScore: Double
    @State private var friends = [Friend]()
    @State private var searchText = ""
    @State private var searchResults = [Friend]()
    @State private var showMessage = false
    @State private var showingSearchResults = false
    
    init(userID: String, totalScore: Binding<Double>) {
        self.userID = userID
        _totalScore = totalScore
    }
    
    struct Friend {
        let id: String
        let username: String
    }
    
    struct RemoteImageView: View {
        @StateObject private var imageLoader = ImageLoader()
        let url: URL

        var body: some View {
            Group {
                if let image = imageLoader.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    // プレースホルダー画像やローディングインディケーターを表示
                    Image(systemName: "people.circle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.gray)
                }
            }
            .onAppear {
                imageLoader.load(fromURL: url)
            }
        }
    }

    func fetchUsers(searchQuery: String) {
        if searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.showMessage = true
            self.searchResults = []
            return
        }
        self.showMessage = false
        
        let usersRef = Database.database().reference(withPath: "users")
        usersRef.queryOrdered(byChild: "username").queryStarting(atValue: searchQuery).queryEnding(atValue: searchQuery+"\u{f8ff}").observeSingleEvent(of: .value) { snapshot in
            var results = [Friend]()
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                   let dict = childSnapshot.value as? [String: Any],
                   let username = dict["username"] as? String {
                    let id = childSnapshot.key
                    let user = Friend(id: id, username: username)
                    results.append(user)
                }
            }
            DispatchQueue.main.async {
                self.searchResults = results
            }
        }
    }
    
    func addFriend(_ friendId: String) {
        let currentUserRef = Database.database().reference(withPath: "users/\(userID)/friends/\(friendId)")
        currentUserRef.setValue(true) { error, _ in
            if let error = error {
                print("フレンドの追加に失敗しました: \(error.localizedDescription)")
            } else {
                print("フレンドが正常に追加されました")
                fetchFriends()
            }
        }
    }
    
    func fetchUserData() {
        let usernameRef = Database.database().reference(withPath: "users/\(userID)/username")
        usernameRef.observeSingleEvent(of: .value) { snapshot in
            DispatchQueue.main.async {
                self.isLoadingUserName = false
                if let username = snapshot.value as? String {
                    self.userName = username
                    self.userNameLoadFailed = false
                } else {
                    self.userName = "読み込みに失敗！"
                    self.userNameLoadFailed = true
                }
            }
        }

        // プロフィール画像のURLの取得
        let imageUrlRef = Database.database().reference(withPath: "users/\(userID)/profileImageUrl")
        imageUrlRef.observeSingleEvent(of: .value) { snapshot in
            if let imageUrlString = snapshot.value as? String {
                DispatchQueue.main.async {
                    self.imageUrl = imageUrlString // Firebaseから取得した画像のURLを更新
                }
            }
        }
    }
    
    func fetchFriends() {
        let friendsRef = Database.database().reference(withPath: "users/\(userID)/friends")
        friendsRef.observeSingleEvent(of: .value) { snapshot in
            guard let friendIds = snapshot.value as? [String: Bool] else {
                print("フレンドがいません🥺")
                return
            }
            
            for friendId in friendIds.keys {
                let userRef = Database.database().reference(withPath: "users/\(friendId)/username")
                userRef.observeSingleEvent(of: .value) { userSnapshot in
                    if let username = userSnapshot.value as? String {
                        DispatchQueue.main.async {
                            self.friends.append(Friend(id: friendId, username: username))
                        }
                    }
                }
            }
        }
    }
    
    // ユーザー名の更新処理
    func updateUsername() {
        let ref = Database.database().reference(withPath: "users/\(userID)/username")
        ref.setValue(draftUsername) { error, _ in
            if let error = error {
                print("Error updating username: \(error.localizedDescription)")
            } else {
                print("Username updated successfully.")
                self.userName = self.draftUsername // ローカルの状態を保存
                self.isEditing = false // 編集モードをオフにする
            }
        }
    }
    
    func uploadImageToFirebase(_ image: UIImage) {
        if Auth.auth().currentUser == nil {
            print("ユーザーはログインしていません。")
            // UIを後々追加
            return
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        let storage = Storage.storage(url: "gs://hacku-hamayoko.appspot.com")
        let storageRef = storage.reference(withPath: "UserImages/\(userID).jpg")
        let uploadTask = storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
              print("アップロードエラー: \(error.localizedDescription)")
              // アップロード失敗のUI作成を後々やる
              return
            }

            storageRef.downloadURL { url, error in
                guard let downloadURL = url else {
                    // URL取得エラー
                    print(error?.localizedDescription ?? "URL取得エラー")
                    return
                }
                // ダウンロードURLをDatabaseに保存
                saveImageUrlToDatabase(downloadURL.absoluteString)
            }
        }
        let observer = uploadTask.observe(.progress) { snapshot in
            let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount)
              / Double(snapshot.progress!.totalUnitCount)
            print("アップロード進捗: \(percentComplete)%")
            // 必要に応じてUIを更新するコードをここに追加します。
        }
    }
    
    func saveImageUrlToDatabase(_ url: String) {
        let ref = Database.database().reference(withPath: "users/\(userID)/profileImageUrl")
        ref.setValue(url) { error, _ in
            if let error = error {
                print("プロフィール画像のURL保存エラー: \(error.localizedDescription)")
            } else {
                print("プロフィール画像のURLが成功的に保存されました。")
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .center) {
                // プロフィール画像
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
                    
                    Button(action: {
                        if self.isEditing {
                            self.updateUsername()
                        } else {
                            self.draftUsername = self.userName // 編集を開始する前に現在のユーザー名を保存
                            self.isEditing = true
                        }
                    }) {
                        if isEditing {
                            Image(systemName: "checkmark.square.fill")
                                .foregroundColor(.green)
                        } else {
                            Image("edit") // 'edit' という名前のカスタム画像を使用
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 32) // HStack全体に水平方向の余白を適用
                .padding(.top, 16)

                // バッジセクション
//                HStack {
//                    Image(systemName: "rosette")
//                    Image(systemName: "crown")
//                    Image(systemName: "star")
//                }


                // スコアセクション
                HStack(spacing: 20) {
                    VStack {
                        Text(String(format: "%.0f", totalScore))
                            .font(Font.custom("DelaGothicOne-Regular", size: 20))
                            .fontWeight(.bold)
                        Text("total score💪")
                            .font(Font.custom("DelaGothicOne-Regular", size: 12))
                            .foregroundColor(.gray)
                    }
//                    VStack {
//                        Text("\(streaks)")
//                            .font(Font.custom("DelaGothicOne-Regular", size: 20))
//                            .fontWeight(.bold)
//                        Text("streaks🔥")
//                            .font(Font.custom("DelaGothicOne-Regular", size: 12))
//                            .foregroundColor(.gray)
//                    }
//                    VStack {
//                        Text("\(wins)")
//                            .font(Font.custom("DelaGothicOne-Regular", size: 20))
//                            .fontWeight(.bold)
//                        Text("wins🏆")
//                            .font(Font.custom("DelaGothicOne-Regular", size: 12))
//                            .foregroundColor(.gray)
//                    }
                }
                .padding(.top, 12)

                // フレンドリスト
                VStack(alignment: .leading) {
                    HStack {
                        TextField("フレンドを検索", text: $searchText)
                            .onChange(of: searchText) { newValue in
                                if newValue.isEmpty {
                                    showingSearchResults = false
                                }
                            }
                            .font(Font.custom("DelaGothicOne-Regular", size: 16))
                            .padding(7)
                            .padding(.horizontal, 25)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
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
                            fetchUsers(searchQuery: searchText)
                            showingSearchResults = true // 検索ボタンが押されたことを示す
                        }) {
                            Image(systemName: "magnifyingglass")
                        }
                        .padding(.trailing, 10)
                    }
                    .padding(.vertical, 10)
                    
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
                                        .padding(.leading, 20) // 左側からの距離を調整
                                    
                                    Spacer() // テキストとボタンの間にスペースを作る
                                    
                                    Button("追加") {
                                        addFriend(user.id)
                                    }
                                    .font(Font.custom("DelaGothicOne-Regular", size: 14))
                                    .padding(.trailing, 20)
                                }
                                .padding(.leading, 20)
                                
                                Divider()
                            }
                        }
                    } else {
                        if friends.isEmpty {
                            Text("フレンドがいません🥺")
                                .font(Font.custom("DelaGothicOne-Regular", size: 16))
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity)
                                .multilineTextAlignment(.center)
                                .padding(.vertical, 10)

                            Spacer()
                        } else {
                            ForEach(friends.filter { friend in
                                searchText.isEmpty || friend.username.localizedCaseInsensitiveContains(searchText)
                            }, id: \.id) { friend in
                                Text(friend.username)
                                    .font(Font.custom("DelaGothicOne-Regular", size: 16))
                                    .foregroundColor(.black)
                                    .padding(.leading, 20)
                                
                                Divider()
                                
                            }
//                            .padding(.vertical, 10)
                        }
                    }
                }
                .background(Color.white)
                .cornerRadius(10)
                .padding()
                .padding(.bottom, 50)
            }
            .onAppear(perform: {
                fetchUserData()
                fetchFriends()
            })
            .onDisappear {
                self.dataTask?.cancel()
            }
            .sheet(isPresented: $isImagePickerPresented) {
                ImagePicker(selectedImage: $selectedImage)
            }
            .onChange(of: selectedImage) { newImage in
                if let image = newImage {
                    self.uploadImageToFirebase(image)
                }
            }

        }
        .background(Color.orange.opacity(0.2))
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
                parent.selectedImage = image // 選択された画像を更新
            }
            parent.presentationMode.wrappedValue.dismiss() // 画像ピッカーを閉じる
        }
    }
}
