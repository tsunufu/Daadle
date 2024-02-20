//
//  TitleView.swift
//  running.io
//
//  Created by 中村蒼 on 2024/02/21.
//

import Foundation
import SwiftUI

struct TitleView: View {
    @EnvironmentObject var userSession: UserSession

    var body: some View {
        NavigationView {
            VStack {
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                
                Text("Daadle")
                    .font(.system(size: 36, weight: .bold, design: .default))
                    .foregroundColor(Color(.gray))
                    .fontWeight(.bold)
//                    .padding()

                Text("塗ろう、自分の街になるまで")
                    .font(.system(size: 16, weight: .bold, design: .default))
                    .foregroundColor(Color(.gray))
                    .padding(.vertical, 12)
                    .padding(.horizontal, 12)

                Button(action: {
                    userSession.isNavigatingToLogin = true
                }) {
                    Text("はじめる")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.gray) // 背景色を指定
                        .padding()
                        .frame(width: UIScreen.main.bounds.width / 2)
                        .background(RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.orange))
                }
                .padding(.horizontal)
                .background(
                    NavigationLink(destination: LoginView().environmentObject(userSession), isActive: $userSession.isNavigatingToLogin) { EmptyView() }
                )
            }
        }
    }
}
