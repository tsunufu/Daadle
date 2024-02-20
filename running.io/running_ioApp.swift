//
//  running_ioApp.swift
//  running.io
//
//  Created by ryo on 2024/02/14.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

// 追加
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
    
    func application(_ application: UIApplication,
                     open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}


//@main
//struct running_ioApp: App {
//    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
//    var body: some Scene {
//        WindowGroup {
//            FullScreenMapView()
//        }
//    }
//}

@main
struct running_ioApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var userSession = UserSession()

    var body: some Scene {
        WindowGroup {
            if userSession.isSignedIn {
                FullScreenMapView(userUID: userSession.userUID ?? "")
                    .environmentObject(userSession)
            } else {
                TitleView() // タイトル画面を最初に表示
                    .environmentObject(userSession)
            }
        }
    }
}

struct LoginView: View {
    @EnvironmentObject var userSession: UserSession // UserSession オブジェクトへのアクセス

    var body: some View {
        Button(action: signInWithGoogle) {
            Text("Sign in with Google")
        }
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
                }
            }
        }
    }
}
