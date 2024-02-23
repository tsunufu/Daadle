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
            ZStack {
                Color(red: 255 / 255, green: 209 / 255, blue: 163 / 255)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Image("appstore")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 300)
                    
                    Text("Daadle")
                        .font(Font.custom("DelaGothicOne-Regular", size: 36))
                        .foregroundColor(Color(red: 0.302, green: 0.302, blue: 0.302))
                        .padding(.vertical, 12)
                    
                    Text("塗ろう、自分の街になるまで")
                        .font(Font.custom("DelaGothicOne-Regular", size: 16))
                        .foregroundColor(Color(red: 0.302, green: 0.302, blue: 0.302))
                    
                    Button(action: {
                        userSession.isNavigatingToLogin = true
                    }) {
                        Text("はじめる")
                            .font(Font.custom("DelaGothicOne-Regular", size: 16))
                            .foregroundColor(Color(red: 0.302, green: 0.302, blue: 0.302))
                            .padding()
                            .frame(width: UIScreen.main.bounds.width / 2)
                            .background(RoundedRectangle(cornerRadius: 20)
                                .fill(Color(red: 255 / 255, green: 158 / 255, blue: 94 / 255))
                                .shadow(color: .gray, radius: 5, x: 0, y: 4))
                    }
                    .padding(.vertical)
                    .background(
                        NavigationLink(destination: LoginView().environmentObject(userSession), isActive: $userSession.isNavigatingToLogin) { EmptyView() }
                    )
                }
            }
        }
    }
}
