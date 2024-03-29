//
//  CallView.swift
//  DementiaApp
//
//  Created by Faisal Hussaini on 2023-03-27.
//

import SwiftUI
import AVKit
import Alamofire
import FirebaseStorage

struct CallView: View {
    
    //This is the view that is displayed when calling a loved one
    //It uses speech to text provided by apple to convert the users speech to text
    //It sends this text to the backend and then plays whatever mp4 is sent back using AVPlayer
    //It also has a prompter that prompts the patient if they are not participiating in the conversation
    
    @Environment(\.dismiss) private var dismiss
    var color: Color
    @StateObject var lovedOneList : lovedOnes
    var id: String
    var p_id: String
    var player = AVPlayer()
    
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Todo.created, ascending: true)], animation: .default) private var todos: FetchedResults<Todo>
    @State var recording = false
    @ObservedObject var mic = MicMonitor(numberOfSamples: 30)
    var speechManager = SpeechManager()
    @State var final_url = ""
    @State var videoURL = ""
    @State var patientURL = ""
    @State var timer: Timer?
    @State var timer_me: Timer?
    @State var duplicateURL : Bool = false
    @State var promptURL : String = ""
    @State var noddingURL : String = ""
    @State var inCall = true
    @State private var showingAlert = false
    
    var body: some View {
        ZStack (alignment: .bottomTrailing){
            ForEach(lovedOneList.items, id: \.id) { item in
                if (item.id == id) {
                    VStack {
                        VideoPlayer(player: player)
                            .onAppear{
                                if (promptURL == "") {
                                    //the first prompt is fixed, everything after is chosen by the backend
                                    promptURL = "https://storage.googleapis.com/virtual-presence-app.appspot.com/\(p_id)/\(id)/" + "howareyoudoingtoday.mp4"
                                    noddingURL = "https://storage.googleapis.com/virtual-presence-app.appspot.com/\(p_id)/\(id)/" + "nod.mp4"
                                }
                                if player.currentItem == nil {
                                    //the chat should open up with hello
                                    videoURL = "https://storage.googleapis.com/virtual-presence-app.appspot.com/\(p_id)/\(id)/hello.mp4"
                                    let videoAsset = AVAsset(url: URL(string: videoURL)!)
                                    let assetLength = Float(videoAsset.duration.value) / Float(videoAsset.duration.timescale)
                                    if (assetLength > 0) {//deepfake is ready
                                        let item = AVPlayerItem(url: URL(string: videoURL)!)
                                        player.replaceCurrentItem(with: item)
                                    }
                                    else {//deepfake is not ready, alert user and dismiss view
                                        showingAlert = true
                                        inCall = false
                                    }
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                                    player.play()
                                })
                            }
                        Text("Chatting with \(item.name)")
                            .padding()
                        //Text(todos.last?.text ?? "----") //the recognized speech
                    }
                    .onAppear {
                        speechManager.checkPermissions()
                        let InitialDelay = 2.0
                        DispatchQueue.main.asyncAfter(deadline: .now() + InitialDelay) {
                            recognizeSpeech()
                        }
                    }
                    .onDisappear() {
                        deleteRecognizedSpeech()//Delete the conversation data once you leave the call
                        inCall = false
                        self.recording = false
                        mic.stopMonitoring()
                        speechManager.stopRecording()
                    }
                    .padding(.top)
                    .alert("Loved one is still being generated, please check back later", isPresented: $showingAlert) {
                        Button("OK", role: .cancel) { dismiss()}
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
    
    func recognizeSpeech() {
        //This is called each time speech recognition has started
        //It starts recording the user and transcribing their text to speech, then provides this text to the backend
        //It then updates the AVPlayer to play whatever the backend sent back
        
        if speechManager.isRecording {
            self.recording = false
            mic.stopMonitoring()
            speechManager.stopRecording()
            speechManager.isRecording.toggle()
        } else {
            self.recording = true
            mic.startMonitoring()
                speechManager.start { (speechText) in
                    guard let text = speechText, !text.isEmpty else {
                        self.recording = false
                        return
                    }
                    DispatchQueue.main.async {
                        withAnimation {
                            let newItem = Todo(context: viewContext)
                            newItem.id = UUID()
                            newItem.text = text
                            newItem.created = Date()
                            
                            do {
                                try viewContext.save()
                            } catch {
                            }
                            let old_url = final_url
                            callBackend(text: todos.last?.text)
                            while(final_url == old_url && duplicateURL == false) {
                            //do nothing and wait for the url to update, there must be a more elegant way to do this
                            }
                            if (inCall) {
                                var item = AVPlayerItem(url: URL(string: final_url)!)
                                player.replaceCurrentItem(with: item)
                                player.play()
                                
                                if (shouldNod) {
                                    NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: nil) { _ in
                                        item = AVPlayerItem(url: URL(string: noddingURL)!)
                                        player.replaceCurrentItem(with: item)
                                        let delay = 1.0 // delay in seconds
                                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                                            player.play()
                                        }
                                    }
                                }
                            }
                            let time_to_wait = self.player.currentItem!.asset.duration
                            resetTimer(wait_n: time_to_wait)
                            
                            self.recording = false
                            mic.stopMonitoring()
                            speechManager.stopRecording()
                            waiting_to_get_reply = false
                        }
                    }
                    mic.stopMonitoring()
                }
                
        }
    }
    func startTimer() {
        //This function is used to start the timer which is used to prompt the patient if they are not speaking
        //If you reach the end of the timer, the patient is prompted
        self.timer = Timer.scheduledTimer(withTimeInterval: promptTime, repeats: true, block: { _ in
            if (!inCall) {
                return
            }
            lock_audio.lock()
            //turn off mic
            self.recording = false
            mic.stopMonitoring()
            speechManager.stopRecording()
            waiting_to_get_reply = false
            
            let item = AVPlayerItem(url: URL(string: promptURL)!)
            player.replaceCurrentItem(with: item)
            player.play()
            getPrompt()
            //restart mic monitoring post prompt
            let wait_n = self.player.currentItem!.asset.duration
            let time_to_wait = ceil(wait_n.seconds) + 0.1
            startMe(wait_n: time_to_wait)
            lock_audio.unlock()
        })
    }
    func startMe(wait_n : Double) {
        //spinner to wait and restart prompt for recognizing user speech
        self.timer_me = Timer.scheduledTimer(withTimeInterval: wait_n, repeats: false, block: { _ in
            lock_audio.lock()
            waiting_to_get_reply = true;
            recognizeSpeech()
            lock_audio.unlock()
        })
    }
    func resetTimer(wait_n: CMTime) {
        //restarting the timer after the prompt is done playing
        let compute = ceil(wait_n.seconds) + 0.1
        self.timer?.invalidate()
        startTimer()
        startMe(wait_n: compute)
    }
    func getPrompt() {
        //function used to communicate with the backend to figure out what prompt to play to them
        
        if(useBackend){
            //Upload patient to the server
            guard let url: URL = URL(string: "http://" + backendIpPort + "/prompts") else {
                print("Invalid url")
                return
            }
            var urlRequest: URLRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            let parameters: [String: String] = [
                "lo_idx": id,
                "p_idx": p_id,
            ]
            let encoder = JSONEncoder()
            if let jsonData = try? encoder.encode(parameters) {
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    urlRequest.httpBody = jsonData
                }
            }
            //urlRequest.httpBody = jsonData
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            URLSession.shared.dataTask(with: urlRequest, completionHandler: {
                (data, response, error) in
                guard let data = data else{
                    print("invalid data")
                    return
                }
                let responseStr : String = String(data: data, encoding: .utf8) ?? "No Response"
                let res : [String : String]? = convertToDictionary(text: (responseStr))
                let prompt_name : String? = res?["response"]
                promptURL = patientURL + prompt_name! + ".mp4"
            }).resume()
        }
    }
    func deleteRecognizedSpeech() {
        todos.forEach(viewContext.delete)
        do {
            try viewContext.save()
        } catch {
            print(error)
        }
    }
    func callBackend(text: String?) {
        
        //Function used to send the speech text to the backend and update the url response to play to the user
        
        duplicateURL = false
        var new_url = ""
        if(useBackend){
            //Upload patient to the server
            guard let url: URL = URL(string: "http://" + backendIpPort + "/responses") else {
                print("Invalid url")
                return
            }
            var urlRequest: URLRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            let parameters: [String: String] = [
                "lo_idx": id,
                "input": text ?? "",
                "p_idx": p_id,
            ]
            let encoder = JSONEncoder()
            if let jsonData = try? encoder.encode(parameters) {
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    urlRequest.httpBody = jsonData
                }
            }
            
            //urlRequest.httpBody = jsonData
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            URLSession.shared.dataTask(with: urlRequest, completionHandler: {
                (data, response, error) in
                guard let data = data else{
                    print("invalid data")
                    return
                }
                let old_final_url = final_url
                let responseStr : String = String(data: data, encoding: .utf8) ?? "No Response"
                let res : [String : String]? = convertToDictionary(text: (responseStr))
                let response_name : String? = res?["response"]
                let base_url : String = "https://storage.googleapis.com/virtual-presence-app.appspot.com"
                new_url = "\(base_url)/\(p_id)/\(id)/\(response_name!)"
                final_url = new_url
                patientURL = "\(base_url)/\(p_id)/\(id)/"
                if (old_final_url == new_url) {
                    duplicateURL = true
                }
                else {
                    duplicateURL = false
                }
            }).resume()
        }
    }
}
