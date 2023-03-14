//
//  AudioRecorder.swift
//  mic
//
//  Created by Faisal Hussaini on 2022-09-30.
//

import Foundation
import SwiftUI
import Combine
import AVFoundation //recorder functionality

//This file contains the functions that are used to record the loved ones audio when creating a new loved one
//Code to record audio adapted from a SwiftUI Voice Recorder tutorial
//https://blckbirds.com/post/voice-recorder-app-in-swiftui-1/
//https://blckbirds.com/post/voice-recorder-app-in-swiftui-2/


class AudioRecorder: NSObject,ObservableObject { //NSObject to allow fetchRecordings to work w

    override init() { //fetch recordings when the app and therefore audiorecorder is launched for the first time
        super.init()
        fetchRecordings()
    }
    
    let objectWillChange = PassthroughSubject<AudioRecorder, Never>()//notify observing view about changes
    var audioRecorder: AVAudioRecorder!
    var recordings = [Recording]() //array to hold recordings
    var recording = false {
        didSet {
            objectWillChange.send(self)
        }
    }
    
    func startRecording() {
        let recordingSession = AVAudioSession.sharedInstance() //create recording
        do {//define type of recording and activate it
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
        } catch {
            print("Failed to set up recording session")
        }
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]//where do you want to save
        let audioFilename = documentPath.appendingPathComponent("Recording.m4a")
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder.record()
            recording = true
        } catch {
            print("Could not start recording")
        }
    }
    func stopRecording() {
            audioRecorder.stop()
            recording = false
            fetchRecordings() //called everytime a new recording is completed
    }
    func fetchRecordings() {
        recordings.removeAll() //need to empty array so that theyre not displayed multiple times
        
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0] //access documents folder
        let directoryContents = try! fileManager.contentsOfDirectory(at: documentDirectory, includingPropertiesForKeys: nil)
        for audio in directoryContents {
            let recording = Recording(fileURL: audio)
            recordings.append(recording) //create one recording instance per audio file and add to recordings array, we are overwriting file since we only want 1
        }
        objectWillChange.send(self)
    }
    func deleteRecording(urlsToDelete: [URL]) {
        
        for url in urlsToDelete {
            print(url)
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                print("File could not be deleted!")
            }
        }
        fetchRecordings()
    }
}
