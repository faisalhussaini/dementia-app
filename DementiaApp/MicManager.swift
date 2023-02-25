//
//  MicManager.swift
//  speechtodo
//
//  Created by Faisal Hussaini on 2022-10-30.
//

import Foundation
import AVFoundation

//This file contains functions which are used to record the users speech for transcription
//It uses the AV foundation to access the mic and record the users speech
//Below are two functions to start and stop the microphone sessions
//code for speech recognition adopted from a todo app tutorial youtube series
//https://www.youtube.com/playlist?list=PLbrKvTeCrFAffsnrKSa9mp9hM22E6kSjx

class MicMonitor: ObservableObject {
    private var audioRecorder: AVAudioRecorder
    private var timer: Timer?
    
    private var currentSample: Int
    private let numberOfSamples: Int
    
    @Published public var soundSamples: [Float]
    
    init(numberOfSamples: Int) {
        self.numberOfSamples = numberOfSamples > 0 ? numberOfSamples : 10
        self.soundSamples = [Float](repeating: .zero, count: numberOfSamples)
        self.currentSample = 0
        
        let audioSession = AVAudioSession.sharedInstance()
        //check if record permission is there or not
        if audioSession.recordPermission != .granted {
            audioSession.requestRecordPermission { (success)  in
                if !success {
                    fatalError("We need audio recording permission to allow you to talk to your loved one")
                }
            }
        }
        //create recording
        let url = URL(fileURLWithPath: "/dev/null", isDirectory: true)
        let recorderSettings: [String: Any] = [
            AVFormatIDKey: NSNumber(value: kAudioFormatAppleLossless),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: recorderSettings)
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: .defaultToSpeaker)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    public func startMonitoring() {
        audioRecorder.isMeteringEnabled = true
        audioRecorder.record()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: { (timer) in
            self.audioRecorder.updateMeters()
            self.soundSamples[self.currentSample] = self.audioRecorder.averagePower(forChannel: 0)
            self.currentSample = (self.currentSample + 1) % self.numberOfSamples
        })
    }
    
    public func stopMonitoring() {
        audioRecorder.stop()
    }
    
    deinit {
        timer?.invalidate()
        audioRecorder.stop()
    }
}
