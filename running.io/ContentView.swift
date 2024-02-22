//
//  ContentView.swift
//  running.io
//
//  Created by ryo on 2024/02/14.
//

import SwiftUI
import MapKit

struct BottomCardView: View {
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
                    Text("Score: 10298")
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
    @State private var showProfileView = false // プロフィールビュー表示用の状態変数

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            MapView(locationManager: locationManager, userUID: userUID)
                .edgesIgnoringSafeArea(.all) // MapViewが全方向のsafeAreaを無視

            // プロフィール画像
            VStack {
                HStack {
                    Spacer() // 右寄せにするためのSpacer
                    Image(systemName: "person.circle") // あとでGoogleの画像になるよう置き換える
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .padding()
                        .onTapGesture {
                            self.showProfileView = true // プロフィールビューを表示
                        }
                }
                Spacer() // 全体のレイアウトを整えるためのSpacer
            }

            BottomCardView()
                .offset(y: 50) // SafeAreaで無視できなかったからそもそもずらした、けどこれ実装方法としてはカスだよな
                .edgesIgnoringSafeArea(.bottom) // BottomCardViewが下部のsafeAreaを無視
        }
        .sheet(isPresented: $showProfileView) {
            // プロフィールビューのコンテンツ
            ProfileView(userID: userUID)
        }
    }
}
