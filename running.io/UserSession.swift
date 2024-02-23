//
//  UserSession.swift
//  running.io
//
//  Created by 中村蒼 on 2024/02/21.
//

import Foundation

class UserSession: ObservableObject {
    @Published var isSignedIn: Bool = false
    @Published var userUID: String? = nil
    @Published var isNavigatingToLogin: Bool = false
    @Published var isOnBoardingCompleted: Bool = false
}
