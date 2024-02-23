//
//  RemoteImageView.swift
//  running.io
//
//  Created by 中村蒼 on 2024/02/23.
//

import Foundation
import SwiftUI

struct RemoteImageView: View {
    @StateObject private var imageLoader = ImageLoader()
    let url: URL

    var body: some View {
        Group {
            if let image = imageLoader.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if imageLoader.isLoading {
                // ローディング中のインディケーターを表示する場合はここに追加
                ProgressView()
            } else {
                // ロードに失敗した場合のデフォルトアイコン
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            imageLoader.load(fromURL: url)
        }
    }
}
