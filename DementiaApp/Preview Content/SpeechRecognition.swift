//
//  SpeechRecognition.swift
//  DementiaApp
//
//  Created by Faisal Hussaini on 2022-09-29.
//

import Foundation
import Speech


func requestionPermission(completion: @escaping (String) -> Void) {
    SFSpeechRecognizer.requestAuthorization { authStatus in
        if authStatus == .authorized{
            
            if let path = Bundle.main.path(forResource: "bob", ofType: "mp3"){
                recognizeAudio(url: URL(fileURLWithPath: path), completion: completion)
            }
        }else {
            print("Speech failed")
        }
    }
}

func recognizeAudio(url: URL, completion: @escaping (String) -> Void){
    let recognizer = SFSpeechRecognizer()
    let request = SFSpeechURLRecognitionRequest(url: url)
    recognizer?.recognitionTask(with: request, resultHandler: {
        result, error in
        guard let result = result else{
            print("No results for recognition")
            return
        }
        completion(result.bestTranscription.formattedString)
    })
}
