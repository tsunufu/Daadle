//
//  ProfileModel.swift
//  running.io
//
//  Created by 中村蒼 on 2024/02/22.
//

import Foundation

struct Friend {
    let id: String
    let username: String
    let friendScore: Double
    let imageUrl: String?
}

struct Profile {
    var userName: String
    var totalScore: Double
    var streaks: Int
    var wins: Int
    var badges: [String]
}
