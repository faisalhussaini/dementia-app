//
//  SpeechManager.swift
//  speechtodo
//
//  Created by Faisal Hussaini on 2022-10-30.
//

import Foundation
import Speech

class SpeechManager {
    public var isRecording = false
    
    private var audioEngine: AVAudioEngine!
    private var inputNode: AVAudioInputNode!
    private var audioSession: AVAudioSession!
    var timer : Timer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var text = String()
    
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
            //let defaultText = self.text
            guard error == nil else {
                print("got error \(error!.localizedDescription)")
                return
            }
            guard let result = result else { return }
            /*
            self.timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false, block: { (timer) in
                self.timer?.invalidate()
                print("invalidated timer")
                self.text = result.bestTranscription.formattedString
                self.text = self.text.replacingOccurrences(of : defaultText, with: "")
                
                completion(self.text)
                print("in speech manager")
                print(result.bestTranscription.formattedString)
                //self.audioEngine.stop()
                //self.recognitionRequest?.endAudio()
                return
            })
            */
            if result.isFinal {
                completion(result.bestTranscription.formattedString)
               // print("final")
                //print(result.bestTranscription.formattedString)
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
            try audioSession.setCategory(.record, mode: .spokenAudio, options: .duckOthers)
            try audioSession.setActive(true, options:.notifyOthersOnDeactivation)
            try audioEngine.start()
        } catch {
            print(error)
        }
    }
    
    
    func stopRecording() {
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        audioEngine.stop()
        inputNode.removeTap(onBus: 0)
        
        try? audioSession.setActive(false)
        audioSession = nil
    }
}
