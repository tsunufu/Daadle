//
//  ImageLoader.swift
//  running.io
//
//  Created by 中村蒼 on 2024/02/23.
//

import Foundation
import SwiftUI
import Combine

class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false
    var cancellables = Set<AnyCancellable>()

    func load(fromURL url: URL) {
        isLoading = true
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    print("Image download error: \(error.localizedDescription)")
                    return
                }

                if let data = data, let downloadedImage = UIImage(data: data) {
                    print("Image downloaded successfully")
                    self.image = downloadedImage
                } else {
                    print("Failed to create image from downloaded data")
                }
            }
        }
        task.resume()
    }
}
