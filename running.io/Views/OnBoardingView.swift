//
//  OnBoardingView.swift
//  running.io
//
//  Created by 中村蒼 on 2024/02/22.
//

import Foundation
import SwiftUI
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import FirebaseDatabase

struct OnBoardingView: View {
    @EnvironmentObject var userSession: UserSession

    var body: some View {
        ZStack {
            Color(red: 255 / 255, green: 209 / 255, blue: 163 / 255)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                TabView {
                    VStack(spacing: 20) {
                        
                        Text("Hello Daadle!")
                            .underline()
                            .font(Font.custom("DelaGothicOne-Regular", size: 36))
                            .foregroundColor(Color(red: 0.302, green: 0.302, blue: 0.302))
                            .padding()
                            .cornerRadius(10)
                        
                        Text("Daadle(ダードル)は\n現実世界をフィールドと見立てて\nユーザー同士で陣取り合戦をすることのできる\n全く新しいアソビの形を提供します")
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color(red: 0.302, green: 0.302, blue: 0.302))
                            .font(Font.custom("DelaGothicOne-Regular", size: 16))
                            .padding()
                        
                        Image("walkthrough1")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .padding()
                    }
                    
                    VStack(spacing: 20) {
                        
                        Text("楽しみ方は無限大")
                            .underline()
                            .font(Font.custom("DelaGothicOne-Regular", size: 36))
                            .foregroundColor(Color(red: 0.302, green: 0.302, blue: 0.302))
                            .padding()
                            .cornerRadius(10)
                        
                        Text("近くにいる人同士でルームを作成して\nゲームを開始することができます。\nもちろん友達同士でも、ソロプレイで一人で\n冒険して陣地を広げることも")
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color(red: 0.302, green: 0.302, blue: 0.302))
                            .font(Font.custom("DelaGothicOne-Regular", size: 16))
                            .padding()
                        
                        HStack(spacing: 10) {
                            
                            Image("walkthrough2-1")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                            
                            Image("walkthrough2-2")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
                        .padding()
                        
                    }
                    
                    VStack(spacing: 20) {
                        
                        Text("実績を積み重ねる")
                            .underline()
                            .font(Font.custom("DelaGothicOne-Regular", size: 36))
                            .foregroundColor(Color(red: 0.302, green: 0.302, blue: 0.302))
                            .padding()
                            .cornerRadius(10)
                        
                        Text("色を塗れば塗るほど実績を獲得できます\nバッジを獲得して自分だけの街にしましょう")
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color(red: 0.302, green: 0.302, blue: 0.302))
                            .font(Font.custom("DelaGothicOne-Regular", size: 16))
                            .padding()
                        
                        HStack(alignment: .center, spacing: 0) {
                                Image("badge1")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)

                                Image("badge2")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)

                                Image("badge3")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            }
                            .padding(.horizontal, 20)
                        
                    }
                    
                    VStack(spacing: 20) {
                        
                        Text("はじめよう!")
                            .underline()
                            .font(Font.custom("DelaGothicOne-Regular", size: 36))
                            .foregroundColor(Color(red: 0.302, green: 0.302, blue: 0.302))
                            .padding()
                            .cornerRadius(10)
                        
                        Text("アソビに行く準備はできた？")
                            .multilineTextAlignment(.center)
                            .font(Font.custom("DelaGothicOne-Regular", size: 16))
                            .foregroundColor(Color(red: 0.302, green: 0.302, blue: 0.302))
                            .padding()
                        
                    }
                    
                }
                .tabViewStyle(PageTabViewStyle())
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                
                Button(action: {
                    signInWithGoogle()
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
                .padding(.vertical, 20)
            }

        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        
    }
    
    
    private func signInWithGoogle() {
        
        guard let clientID:String = FirebaseApp.app()?.options.clientID else { return }
        let config:GIDConfiguration = GIDConfiguration(clientID: clientID)
        
        let windowScene:UIWindowScene? = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let rootViewController:UIViewController? = windowScene?.windows.first!.rootViewController!
        
        GIDSignIn.sharedInstance.configuration = config
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController!) { result, error in
            guard error == nil else {
                print("GIDSignInError: \(error!.localizedDescription)")
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString
            else {
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,accessToken: user.accessToken.tokenString)
            self.login(credential: credential)
        }
    }
    
    // ログイン処理内で userSession を更新
    private func login(credential: AuthCredential) {
        Auth.auth().signIn(with: credential) { (authResult, error) in
            // エラーチェックと UID の取得
            DispatchQueue.main.async {
                if let user = authResult?.user {
                    self.userSession.userUID = user.uid
                    self.userSession.isSignedIn = true
                    
                    // 新しいユーザーの場合はデフォルトのユーザー名を設定
                    let userRef = Database.database().reference(withPath: "users/\(user.uid)")
                    // ユーザーデータの確認と必要に応じて更新
                    userRef.observeSingleEvent(of: .value, with: { snapshot in
                        var updates = [String: Any]()
                        if let userData = snapshot.value as? [String: Any], let username = userData["username"] as? String, !username.isEmpty {
                            // usernameが存在する場合は何もしない
                        } else {
                            updates["username"] = "未設定ユーザー"
                        }
                        
                        // 新しいユーザーの場合、デフォルトバッジを追加
                        if snapshot.childSnapshot(forPath: "badges").childrenCount == 0 {
                            updates["badges/badgeStart"] = true
                            self.userSession.showBadgeView = true
                        }
                        
                        if updates.count > 0 {
                            userRef.updateChildValues(updates)
                        }
                    })
                }
            }
        }
    }
}

