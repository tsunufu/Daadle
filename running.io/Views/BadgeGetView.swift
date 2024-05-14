//
//  BadgeGetView.swift
//  running.io
//
//  Created by ryo on 2024/04/29.
//

import SwiftUI

struct BadgeGetView: View {
    @Binding var showBadgeView: Bool
    var body: some View {
        ZStack {
            Color.white.opacity(0.6)  // 背景に透明度を設定
                .edgesIgnoringSafeArea(.all)
            VStack {
                Image("badgeStart")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
                Text("新米冒険者")
                    .font(Font.custom("DelaGothicOne-Regular", size: 28))
                
                Text("おめでとうございます！\n初めてのログインによりバッジを獲得しました")
                    .font(.system(size: 12))
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    self.showBadgeView = false
                }) {
                    Text("閉じる")
                        .font(Font.custom("DelaGothicOne-Regular", size: 16))
                        .foregroundColor(Color(red: 0.302, green: 0.302, blue: 0.302))
                        .padding()
                        .frame(width: UIScreen.main.bounds.width / 2)
                        .background(RoundedRectangle(cornerRadius: 20)
                            .fill(Color(red: 255 / 255, green: 158 / 255, blue: 94 / 255))
                            .shadow(color: .gray, radius: 5, x: 0, y: 4))
                }
                .padding(.top, 20)  // ボタンの上に余白を追加
            }
            .padding()  // VStack全体のパディング
        }
    }
}

