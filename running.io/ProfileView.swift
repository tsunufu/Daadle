//
//  ProfileView.swift
//  running.io
//
//  Created by 中村蒼 on 2024/02/22.
//

import Foundation
import SwiftUI

struct ProfileView: View {
    let profileImageName = "defaultProfile" // デフォルトのプロフィール画像名
    let userName = "あなたの名前"
    let totalScore = 298489
    let streaks = 12
    let wins = 24
    let friendsList = [
            ("フレンド1", 13982, "B+"),
            ("フレンド2", 12500, "A"),
            ("フレンド3", 11800, "B"),
        ]

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

                // ユーザー名
                Text(userName)
                    .font(Font.custom("DelaGothicOne-Regular", size: 24))
                    .foregroundColor(Color(.black))
                    .fontWeight(.bold)
                    .padding(.top, 8)

                // バッジセクション
//                HStack {
//                    Image(systemName: "rosette")
//                    Image(systemName: "crown")
//                    Image(systemName: "star")
//                }
                .font(.title)
                .padding(.top, 16)

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
                .padding(.top, 16)

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
        .background(Color.orange.opacity(0.2)) // 背景色
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .previewDevice("iPhone 12") // 特定のデバイスでのプレビューを指定 (オプション)
    }
}
