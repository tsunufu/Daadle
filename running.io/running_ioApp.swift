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
    var authStateDidChangeListenerHandle: AuthStateDidChangeListenerHandle?
    
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        authStateDidChangeListenerHandle = Auth.auth().addStateDidChangeListener { (auth, user) in
            let userSession = UserSession.shared
            if let user = user {
                userSession.userUID = user.uid
                userSession.isSignedIn = true
            } else {
                userSession.isSignedIn = false
            }
        }
        
        return true
    }
    
    func application(_ application: UIApplication,
                     open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}


@main
struct running_ioApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var userSession = UserSession.shared

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
        OnBoardingView()
    }
}
