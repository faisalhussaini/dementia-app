//
//  AudioPlayer.swift
//  mic
//
//  Created by Faisal Hussaini on 2022-10-01.
//

import Foundation
import SwiftUI
import Combine
import AVFoundation

//This file contains the functions that are used to play the loved ones audio when creating a new loved one
//developed by following a SwiftUI Voice Recorder tutorial
//https://blckbirds.com/post/voice-recorder-app-in-swiftui-1/
//https://blckbirds.com/post/voice-recorder-app-in-swiftui-2/

class AudioPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
 
    let objectWillChange = PassthroughSubject<AudioPlayer, Never>()  //notify observing views about changes such as if an audio is being played or not
    var isPlaying = false {
        didSet {
            objectWillChange.send(self)
        }
    }
    var audioPlayer: AVAudioPlayer!
    
    func startPlayback (audio: URL) {
        let playbackSession = AVAudioSession.sharedInstance()
        do {
            try playbackSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker) //play in speaker instead of earpiece
        } catch {
            print("Playing over the device's speakers failed")
        }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audio)
            audioPlayer.delegate = self
            audioPlayer.play()
            isPlaying = true
        } catch {
            print("Playback failed.")
        }
    }
    func stopPlayback() {
        audioPlayer.stop()
        isPlaying = false
    }
    
    //audiplayer will call this func as its own delgate after the audio has been finished playing. Playing atirbute will be false again, eventually causing the particular recording row to yupdate itself and display the play button again
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) { //if the audio was succefully played, we set the playing properties back to false
        if flag {
            isPlaying = false
        }
    }
}
