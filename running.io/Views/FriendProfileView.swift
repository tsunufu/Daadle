//
//  FriendProfileView.swift
//  running.io
//
//  Created by 中村蒼 on 2024/04/26.
//

import SwiftUI

struct FriendProfileView: View {
    let friend: Friend
    
    var body: some View {
        NavigationStack {
            ProfileView(
                userID: friend.id,
                showUsernameEditUI: false,
                showFriendSearchUI: false,
                showCustomSegmentedPicker: false,
                showBlockButton: false
            )
        }
    }
}

struct FriendProfileView_Previews: PreviewProvider {
    static var previews: some View {
        FriendProfileView(
            friend: Friend(id: "testID", username: "Test Friend", friendScore: 100, imageUrl: nil)
        )
    }
}
