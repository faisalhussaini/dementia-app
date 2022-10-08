//
//  AppleLogoView.swift
//  DementiaApp
//
//  Created by Faisal Hussaini on 2022-09-29.
//

import SwiftUI

struct AppleLogoView: View {
    @State var lyrics = ""
    var body: some View {
        VStack(){
            Color.white
                .mask{
                    Image(systemName: "applelogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                .frame(width:180, height: 180)
            Text(lyrics)
        }
        .onAppear {
            playSound(sound: "bob", type: "mp3")
            requestionPermission { result in
                lyrics = result
            }
        }
    }
}

struct AppleLogoView_Previews: PreviewProvider {
    static var previews: some View {
        AppleLogoView()
    }
}
