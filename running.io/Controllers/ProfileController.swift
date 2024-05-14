//
//  ProfileController.swift
//  running.io
//
//  Created by 中村蒼 on 2024/02/22.
//

import Foundation
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth
import UIKit

class ProfileController: ObservableObject {
    @Published var profile = Profile(userName: "ユーザー名を読み込み中...", totalScore: 0, streaks: 0, wins: 0, badges: [])
    @Published var friends: [Friend] = []
    @Published var searchResults: [Friend] = []
    @Published var imageUrl: String?
    @Published var isLoadingUserName = true
    @Published var userNameLoadFailed = false
    @Published var showMessage = false
    @Published var friendRequests: [FriendRequest] = []
    
    var userID: String
    var dataTask: URLSessionDataTask?

    init(userID: String) {
        self.userID = userID
        fetchUserData()
        fetchFriends()
        fetchFriendRequests()
    }

    func fetchUserData() {
        let usernameRef = Database.database().reference(withPath: "users/\(userID)/username")
        usernameRef.observeSingleEvent(of: .value) { snapshot in
            DispatchQueue.main.async {
                self.isLoadingUserName = false
                if let username = snapshot.value as? String {
                    self.profile.userName = username
                    self.userNameLoadFailed = false
                } else {
                    self.profile.userName = "読み込みに失敗！"
                    self.userNameLoadFailed = true
                    print("Error: Unable to load username for userID \(self.userID)")
                }
            }
        }
        
        let imageUrlRef = Database.database().reference(withPath: "users/\(userID)/profileImageUrl")
        imageUrlRef.observeSingleEvent(of: .value) { snapshot in
            if let imageUrlString = snapshot.value as? String {
                DispatchQueue.main.async {
                    self.imageUrl = imageUrlString
                }
            } else {
                print("Error: Unable to load profile image URL for userID \(self.userID)")
            }
        }
        
        let scoreRef = Database.database().reference(withPath: "users/\(userID)/score")
        scoreRef.observeSingleEvent(of: .value) { snapshot in
            if let score = snapshot.value as? Double {
                DispatchQueue.main.async {
                    self.profile.totalScore = score
                }
            } else {
                print("Error: Unable to load score for userID \(self.userID)")
            }
        }
    }

    func fetchFriends() {
        let friendsRef = Database.database().reference(withPath: "users/\(userID)/friends")
        friendsRef.observeSingleEvent(of: .value) { snapshot in
            if !snapshot.exists() {
                print("フレンドリストが存在しません。")
                return
            }

            guard let friendIdsDict = snapshot.value as? [String: Bool] else {
                print("フレンドのデータ形式が不正です。")
                return
            }

            let friendIds = Array(friendIdsDict.keys)

            if friendIds.isEmpty {
                print("フレンドがいません🥺")
                return
            }

            self.friends.removeAll()
            let group = DispatchGroup()

            for friendId in friendIds {
                group.enter()
                let userRef = Database.database().reference(withPath: "users/\(friendId)")
                userRef.observeSingleEvent(of: .value) { userSnapshot in
                    defer { group.leave() }
                    if let userDict = userSnapshot.value as? [String: Any],
                       let username = userDict["username"] as? String,
                       let friendScore = userDict["score"] as? Double,
                       let imageUrl = userDict["profileImageUrl"] as? String {
                        let friend = Friend(id: friendId, username: username, friendScore: friendScore, imageUrl: imageUrl)
                        DispatchQueue.main.async {
                            self.friends.append(friend)
                        }
                    }
                }
            }

            group.notify(queue: .main) {
                print("フレンドデータの取得が完了しました。フレンド数: \(self.friends.count)")
            }
        }

        let badgesRef = Database.database().reference(withPath: "users/\(userID)/badges")
        badgesRef.observeSingleEvent(of: .value) { snapshot in
            var badges: [String] = []
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot, childSnapshot.value as? Bool ?? false {
                    badges.append(childSnapshot.key)
                }
            }
            DispatchQueue.main.async {
                self.profile.badges = badges
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
        usersRef.queryOrdered(byChild: "username").queryStarting(atValue: searchQuery).queryEnding(atValue: searchQuery + "\u{f8ff}").observeSingleEvent(of: .value) { snapshot in
            var results = [Friend]()
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                   let dict = childSnapshot.value as? [String: Any],
                   let username = dict["username"] as? String {
                    let id = childSnapshot.key
                    let friendScore = dict["score"] as? Double ?? 0
                    let imageUrl = dict["profileImageUrl"] as? String

                    let user = Friend(id: id, username: username, friendScore: friendScore, imageUrl: imageUrl)
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
                self.fetchFriends()
            }
        }
    }
    
    func sendFriendRequest(_ friendId: String) {
        let friendRequestsRef = Database.database().reference(withPath: "users/\(friendId)/friendRequests/\(userID)")
        friendRequestsRef.setValue(["status": "pending"]) { error, _ in
            if let error = error {
                print("フレンドリクエストの送信に失敗しました: \(error.localizedDescription)")
            } else {
                print("フレンドリクエストが正常に送信されました")
            }
        }
    }
    
    func fetchFriendRequests() {
        print("----------------------------------------")
        let friendRequestsRef = Database.database().reference(withPath: "users/\(userID)/friendRequests")
        friendRequestsRef.observe(.value, with: { snapshot in
            var newRequests: [FriendRequest] = []
            for child in snapshot.children {
                guard let childSnapshot = child as? DataSnapshot,
                      let value = childSnapshot.value as? [String: Any] else {
                    continue
                }

                // `status` キーのチェックを柔軟に
                let status = value["status"] as? String
                if status != "pending" {
                    print("Status is not 'pending', but processing continues. Current status: \(String(describing: status))")
                }

                // ユーザー情報を取得してリクエストを作成
                let requesterId = childSnapshot.key
                self.fetchUserInfo(userId: requesterId) { username, imageUrl in
                    let friendRequest = FriendRequest(id: requesterId, username: username, imageUrl: imageUrl)
                    DispatchQueue.main.async {
                        newRequests.append(friendRequest)
                        print("!!!!!!!!!!!!!!!!!!!")
                        print("Fetched friend requests: \(newRequests)")
                        self.friendRequests = newRequests
                    }
                }
            }
        })
    }


    // ユーザー情報を取得するヘルパーメソッド
    func fetchUserInfo(userId: String, completion: @escaping (String, String?) -> Void) {
        let userRef = Database.database().reference(withPath: "users/\(userId)")
        userRef.observeSingleEvent(of: .value) { snapshot in
            guard let dict = snapshot.value as? [String: Any],
                  let username = dict["username"] as? String else {
                completion("不明なユーザー", nil)
                return
            }
            let imageUrl = dict["profileImageUrl"] as? String
            completion(username, imageUrl)
        }
    }

    
    func handleFriendRequest(_ friendId: String, accept: Bool) {
        let friendRequestRef = Database.database().reference(withPath: "users/\(userID)/friendRequests/\(friendId)")
        if accept {
            // 承認の場合、両者のフレンドリストに追加
            let friendListRefUser = Database.database().reference(withPath: "users/\(userID)/friends/\(friendId)")
            let friendListRefFriend = Database.database().reference(withPath: "users/\(friendId)/friends/\(userID)")
            friendListRefUser.setValue(true)
            friendListRefFriend.setValue(true) { error, _ in
                if let error = error {
                    print("フレンドの追加に失敗しました: \(error.localizedDescription)")
                } else {
                    print("フレンドをリストに追加しました")
                    // リクエストを削除
                    friendRequestRef.removeValue()
                    
                    self.fetchFriends()
                    self.fetchFriendRequests()
                }
            }
        } else {
            // 拒否の場合、リクエストを削除
            print("申請を拒否しました")
            friendRequestRef.removeValue()
            self.fetchFriendRequests()
        }
    }

    func updateUsername(draftUsername: String) {
        let ref = Database.database().reference(withPath: "users/\(userID)/username")
        ref.setValue(draftUsername) { error, _ in
            if let error = error {
                print("Error updating username: \(error.localizedDescription)")
            } else {
                print("Username updated successfully.")
                self.profile.userName = draftUsername
            }
        }
    }

    func uploadImageToFirebase(_ image: UIImage) {
        if Auth.auth().currentUser == nil {
            print("ユーザーはログインしていません。")
            return
        }

        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        let storage = Storage.storage(url: "gs://hacku-hamayoko.appspot.com")
        let storageRef = storage.reference(withPath: "UserImages/\(userID).jpg")
        let uploadTask = storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("アップロードエラー: \(error.localizedDescription)")
                return
            }

            storageRef.downloadURL { url, error in
                guard let downloadURL = url else {
                    print(error?.localizedDescription ?? "URL取得エラー")
                    return
                }
                self.saveImageUrlToDatabase(downloadURL.absoluteString)
            }
        }

        _ = uploadTask.observe(.progress) { snapshot in
            let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount) / Double(snapshot.progress!.totalUnitCount)
            print("アップロード進捗: \(percentComplete)%")
        }
    }

    func saveImageUrlToDatabase(_ url: String) {
        let ref = Database.database().reference(withPath: "users/\(userID)/profileImageUrl")
        ref.setValue(url) { error, _ in
            if let error = error {
                print("プロフィール画像のURL保存エラー: \(error.localizedDescription)")
            } else {
                print("プロフィール画像のURLが成功的に保存されました。")
                self.imageUrl = url
            }
        }
    }
    
    func removeFriend(_ friendId: String) {
        // 現在のユーザーから友達を削除
        let currentUserFriendRef = Database.database().reference(withPath: "users/\(userID)/friends/\(friendId)")
        currentUserFriendRef.removeValue { error, _ in
            if let error = error {
                print("友達の削除に失敗しました: \(error.localizedDescription)")
            } else {
                print("現在のユーザーの友達リストから削除されました。")
                self.fetchFriends() // フレンドリストを再フェッチして更新
            }
        }
        
        // 友達のユーザーから現在のユーザーを削除
        let friendUserFriendRef = Database.database().reference(withPath: "users/\(friendId)/friends/\(userID)")
        friendUserFriendRef.removeValue { error, _ in
            if let error = error {
                print("友達の友達リストからの削除に失敗しました: \(error.localizedDescription)")
            } else {
                print("友達のユーザーの友達リストから削除されました。")
            }
        }
    }

}
