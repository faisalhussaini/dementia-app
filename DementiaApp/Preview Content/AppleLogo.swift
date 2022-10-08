//
//  AppleLogo.swift
//  DementiaApp
//
//  Created by Faisal Hussaini on 2022-09-29.
//

import Foundation
import SwiftUI
import AVFoundation

var audioPlayer: AVAudioPlayer?

func playSound(sound: String, type: String) {
    if let path = Bundle.main.path(forResource: sound, ofType: type) {
        do {
            audioPlayer = try AVAudioPlayer (contentsOf: URL(fileURLWithPath: path))
            audioPlayer?.play()
        }
        catch let error{
            print(error)
        }
    }
    
}


