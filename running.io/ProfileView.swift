//
//  ProfileView.swift
//  running.io
//
//  Created by 中村蒼 on 2024/02/22.
//

import Foundation
import SwiftUI
import FirebaseDatabase

struct ProfileView: View {
    let profileImageName = "defaultProfile" // あとで変更する必要あり
    @State private var userName = "ユーザー名を読み込み中..."
    let totalScore = 298489 //  あとで変更する必要あり
    let streaks = 12 // 変更必要
    let wins = 24 // 変更必要
    let userID: String
    @State private var isEditing = false
    @State private var draftUsername = "" // 編集中のユーザー名を一時保存

    let friendsList = [
            ("フレンド1", 13982, "B+"),
            ("フレンド2", 12500, "A"),
            ("フレンド3", 11800, "B"),
        ]
    
    func fetchUsername() {
        let ref = Database.database().reference(withPath: "users/\(userID)/username")
        ref.observeSingleEvent(of: .value) { snapshot in
            if let username = snapshot.value as? String {
                self.userName = username
                self.draftUsername = username // 初期状態は現在のユーザー名
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

    var body: some View {
        ScrollView {
            VStack(alignment: .center) {
                // プロフィール画像
                Image(profileImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                    .shadow(radius: 10)
                    .padding(.top, 44)

                
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
                            .foregroundColor(Color(.black))
                            .fontWeight(.bold)
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
        }
        .background(Color.orange.opacity(0.2))
        .onAppear(perform: fetchUsername)
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(userID: "testUser")
            .previewDevice("iPhone 12") // 特定のデバイスでのプレビューを指定 (オプション)
    }
}
