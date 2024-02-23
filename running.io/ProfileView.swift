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
    let totalScore = 298489 //  あとで変更する必要あり
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

    let friendsList = [
            ("フレンド1", 13982, "B+"),
            ("フレンド2", 12500, "A"),
            ("フレンド3", 11800, "B"),
        ]
    
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

    
    func fetchUserData() {
        // ユーザーネームの取得
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
                        Text("\(totalScore)")
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
                    ForEach(friendsList, id: \.0) { friend in
                        VStack {
                            HStack {
                                Image(systemName: "person.circle") // Googleで引っ張ってきた画像を表示させる
                                    .resizable()
                                    .frame(width: 36, height: 36)
                                    .clipShape(Circle())
                                    .padding(.trailing, 8)
                                
                                VStack(alignment: .leading) {
                                    Text(friend.0)
                                        .font(Font.custom("DelaGothicOne-Regular", size: 16))
                                        .foregroundColor(.black)
                                    Text("\(friend.1) points")
                                        .font(Font.custom("DelaGothicOne-Regular", size: 10))
                                        .foregroundColor(.gray)
                                }
                                Spacer() // 中央のスペースを作成する
                                Text(friend.2)
                                    .font(Font.custom("DelaGothicOne-Regular", size: 16))
                                    .foregroundColor(.black)
                            }
                            .padding(.vertical, 10) // 上下に余白を追加して隙間を作る
                        }
                        Divider() // 各フレンドごとに線を引く
//                        .padding(.leading, 24) // Dividerの左側に余白を追加する（アイコンの幅に合わせる）
                    }
                    .padding(.horizontal)
                }
                .background(Color.white)
                .cornerRadius(10)
                .padding()
                .padding(.bottom, 50) // 下部の余白
            }
            .onAppear(perform: fetchUserData)
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

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(userID: "testUser")
            .previewDevice("iPhone 12") // 特定のデバイスでのプレビューを指定 (オプション)
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
