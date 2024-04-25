//
//  UserSession.swift
//  running.io
//
//  Created by 中村蒼 on 2024/02/21.
//

import Foundation

class UserSession: ObservableObject {
    static let shared = UserSession()
    
    @Published var isSignedIn: Bool = false {
        didSet {
            print("isSignedIn updated to: \(isSignedIn)")
        }
    }
    @Published var userUID: String? = nil
    @Published var isNavigatingToLogin: Bool = false
    @Published var isOnBoardingCompleted: Bool = false
    
    private init() {}
}
