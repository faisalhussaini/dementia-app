//
//  SpeechManager.swift
//  speech
//
//  Created by Faisal Hussaini on 2022-10-30.
//

import Foundation
import Speech

//This file contains functions which are used to transcribe the users speech to text
//It uses the speech framework along with a 2 second timer to partition and transcribe the users speech
//Below are two functions to start and stop the transcription sessions
//developed by following a todo app tutorial youtube series
//https://www.youtube.com/playlist?list=PLbrKvTeCrFAffsnrKSa9mp9hM22E6kSjx


class SpeechManager {
    public var isRecording = false
    private var audioEngine: AVAudioEngine!
    private var inputNode: AVAudioInputNode!
    private var audioSession: AVAudioSession!
    var timer : Timer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    func checkPermissions() {
        SFSpeechRecognizer.requestAuthorization{ (authStatus) in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized: break
                default:
                    print("Speech recognition is not available")
                }
            }
        }
    }
    
    func start(completion: @escaping (String?) -> Void) {
        if isRecording {
            stopRecording()
        } else {
            startRecording(completion: completion)
        }
    }
    
    func startRecording(completion: @escaping (String?) -> Void) {
        guard let recognizer = SFSpeechRecognizer(), recognizer.isAvailable else {
            print("Speech recognition is not available")
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest!.shouldReportPartialResults = true
        
        recognizer.recognitionTask(with: recognitionRequest!) { (result, error) in
            guard error == nil else {
                print("got error \(error!.localizedDescription)")
                return
            }
            guard let result = result else { return }
            //how long after silence to continue listening
            self.timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false, block: { (timer) in
                self.timer?.invalidate()
                self.stopRecording()
                return
            })
            
            if result.isFinal {
                completion(result.bestTranscription.formattedString)
            }
        }
        
        audioEngine = AVAudioEngine()
        inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, _) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: .defaultToSpeaker)
            try audioSession.setActive(true, options:.notifyOthersOnDeactivation)
            try audioEngine.start()
        } catch {
            print(error)
        }
    }
    
    
    func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        inputNode.removeTap(onBus: 0)
        audioSession = nil
    }
}
