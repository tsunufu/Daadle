//
//  WarningView.swift
//  running.io
//
//  Created by ryo on 2024/05/04.
//

import SwiftUI

struct WarningView: View {
    @Environment(\.openURL) var openURL
    var dismissAction: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 255 / 255, green: 209 / 255, blue: 163 / 255)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    
                    Text("アソビに行くための準備")
                        .font(Font.custom("DelaGothicOne-Regular", size: 28))
                        .foregroundColor(Color(red: 0.302, green: 0.302, blue: 0.302))
                        .padding(.vertical, 12)
                    
                    Text("Daadleの機能、領土を常に塗りつぶせる\nようにするために、位置情報を「常に許可」\nに変更してください")
                        .font(.system(size: 16))
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 4)
                    
                    Text("1. デバイスの設定画面で、｢位置情報｣を選択\n2. 次に、｢常に許可｣を選択")
                        .padding(.vertical, 18)
                    
                    Image("setting")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 300)
                    
                    HStack(spacing: 10) { // ボタンを横並びにするためのHStack
                        
                        Button(action: dismissAction) {
                            Text("閉じる")
                                .font(Font.custom("DelaGothicOne-Regular", size: 16))
                                .foregroundColor(Color(red: 0.302, green: 0.302, blue: 0.302))
                                .padding()
                                .frame(width: UIScreen.main.bounds.width / 2 - 20)
                                .background(RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(red: 245 / 255, green: 234 / 255, blue: 222 / 255))
                                    .shadow(color: .gray, radius: 5, x: 0, y: 4))
                        }
                        
                        Button(action: openSettings) {
                            Text("設定へ")
                                .font(Font.custom("DelaGothicOne-Regular", size: 16))
                                .foregroundColor(Color(red: 0.302, green: 0.302, blue: 0.302))
                                .padding()
                                .frame(width: UIScreen.main.bounds.width / 2 - 20)
                                .background(RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(red: 255 / 255, green: 158 / 255, blue: 94 / 255))
                                    .shadow(color: .gray, radius: 5, x: 0, y: 4))
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
    }
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }
}
