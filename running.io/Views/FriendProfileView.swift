//
//  FriendProfileView.swift
//  running.io
//
//  Created by 中村蒼 on 2024/04/26.
//

import SwiftUI

struct FriendProfileView: View {
    let friend: ProfileView.Friend
    
    var body: some View {
        ProfileView(userID: friend.id, totalScore: .constant(friend.friendScore), showUsernameEditUI: false, showFriendSearchUI: false)
    }
}
