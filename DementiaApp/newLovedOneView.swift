//
//  newLovedOneView.swift
//  DementiaApp
//
//  Created by Faisal Hussaini on 2023-03-27.
//

import SwiftUI
import AVKit
import Alamofire
import FirebaseStorage

struct newLovedOneView: View {
    
    //This is the view that is displayed when adding a new loved one
    //the view takes information about the patient in the form of text form
    //It also requires the loved one to upload an image of themselves, either via the camera roll or front camera
    //It requires the loved one to record themselves speaking. Users can listen to their recording and rerecord as neccesary
    //This data will be sent to the backend for ML training purposes
    
    @ObservedObject var audioRecorder: AudioRecorder
    var patientID: String
    @StateObject var lovedOneList : lovedOnes
    @Environment(\.presentationMode) var presentationMode
    
    var genders = ["Male", "Female", "Prefer not to say"]
    @State private var date = Date()
    @State private var name: String = ""
    @State private var gender: String = ""
    @State private var isShowingPhotoPicker = false
    //@State private var lovedOneImage = UIImage(named: "default-avatar")!
    @State private var children: String = ""
    @State private var spouse: String = ""
    @State private var placeOfResidence: String = ""
    @State private var hobbies: String = ""
    @State private var questionResponses = ["children": "",
                                            "spouse": "",
                                            "residence": "",
                                            "hobbies": ""]
    //@State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    //@State private var isImagePickerButtonClicked = false
    @State private var showVideoPicker = false
    @State private var videoURL : URL?
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section {
                        TextField("", text: $name)
                            .placeholder(when: name.isEmpty) {
                                Text("Loved One's Name").foregroundColor(.red)
                            }
                        DatePicker("Loved One's Date of birth", selection : $date, displayedComponents: .date)
                        Picker("Loved Ones's Gender", selection: $gender) {
                            ForEach(genders, id: \.self) {
                                Text($0)
                            }
                        }
                        TextField("Loved One's children seperated by commas. Example: 'John Smith, Jack Smith'", text: $children)
                        TextField("Loved One's spouse/partner", text: $spouse)
                        TextField("", text: $placeOfResidence)
                            .placeholder(when: placeOfResidence.isEmpty) {
                                Text("Loved One's place of residence").foregroundColor(.red)
                            }
                        TextField("", text: $hobbies)
                            .placeholder(when: hobbies.isEmpty) {
                                Text("Loved One's top 3 hobbies seperated by commas. Example: 'swimming, poetry, cooking'").foregroundColor(.red)
                            }
                    }
                    Section {
                        if let videoURL = videoURL {
                                        VideoPlayer(player: AVPlayer(url: videoURL))
                                            .frame(height: 900)
                        } else {
                            Text("No video recorded")
                                .foregroundColor(.gray)
                        }
                        Button(action: {
                            self.showVideoPicker.toggle()
                        }) {
                            Text("Please record a short clip of yourself nodding. Pretend like you are listening to the patient speak. This will be used to generate the deepfake")
                        }
                    }
                    .navigationTitle("New Loved One")
                    .sheet(isPresented: $showVideoPicker) {
                        VideoPicker(showVideoPicker: $showVideoPicker, videoURL: $videoURL)
                    }
                    
                    //Code to record audio adapted from a SwiftUI Voice Recorder tutorial
                    //https://blckbirds.com/post/voice-recorder-app-in-swiftui-1/
                    //https://blckbirds.com/post/voice-recorder-app-in-swiftui-2/
                    RecordingsList(audioRecorder: audioRecorder)
                    if audioRecorder.recording == false { //button to start
                        Button(action: {self.audioRecorder.startRecording()}) {
                            Text("Start Recording Audio Sample of Loved One")
                                .frame(maxWidth: .infinity, alignment: .center)
                            Image(systemName: "circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .clipped()
                                .foregroundColor(.red)
                        }
                    } else {
                        Button(action: {self.audioRecorder.stopRecording()}) { //button to stop
                            Text("Stop Recording Audio Sample of Loved One")
                                .frame(maxWidth: .infinity, alignment: .center)
                            Image(systemName: "stop.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .clipped()
                                .foregroundColor(.red)
                        }
                    }
                    Text("Please record yourself saying the following three sentences:\n1. The quick brown fox jumps over the lazy dog.\n2. I am feeling happy today.\n3. The temperature outside is 25 degrees.")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .navigationBarTitle("New Loved One")
                
                .onChange(of: children, perform: { string in
                    questionResponses["children"] = children
                })
                .onChange(of: spouse, perform: { string in
                    questionResponses["spouse"] = spouse
                })
                .onChange(of: placeOfResidence, perform: { string in
                    questionResponses["residence"] = placeOfResidence
                })
                .onChange(of: hobbies, perform: { string in
                    questionResponses["hobbies"] = hobbies
                })
                Section {
                    Button {

                        //let imageData: Data = lovedOneImage.jpegData(compressionQuality: 0.5) ?? Data()
                        //Send this loved one data to the backend
                        if let url = videoURL {
                            add_loved_one(id: "21", patiendID: patientID, name: name, gender: gender, date: date, video: url, questionResponses: questionResponses)
                        }
                        presentationMode.wrappedValue.dismiss()
                    } label : {
                        Text("Save")
                    }
                }
                .disabled(name.isEmpty || placeOfResidence.isEmpty || hobbies.isEmpty || audioRecorder.recordings.isEmpty || hobbies.filter { $0 == "," }.count != 2 || videoURL == nil)
            }
            .toolbar {
                Button("Cancel") {
                    dismiss()
                }
                Spacer()
            }
        }
        .navigationViewStyle(.stack)
    }
    
    func add_loved_one(id:String, patiendID: String, name:String, gender:String, date:Date, video:URL, questionResponses: [String: String]){
        
        //This function is called when adding a loved one and sending their data like audio and image to the backend
        
        let upload_vid : Bool = true
        if(useBackend){
            //Upload patient to the server
            guard let url: URL = URL(string: "http://" + backendIpPort + "/loved_ones") else {
                print("Invalid url")
                return
            }
            let dF : DateFormatter = DateFormatter()
            // Convert Date to String
            dF.dateFormat = "YYYY/MM/dd"
            let dob = dF.string(from: date)
            var urlRequest: URLRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            let parameters: [String: String] = [
                "p_idx": patiendID,
                "name": name,
                "gender": gender,
                "DOB": dob,
                "responses" : convertDictionaryToString(dic: questionResponses),
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
                let loved_one_id : String? = res?["id"]
                let newLovedOne = lovedOne(id: loved_one_id ?? "0", patientID: patientID,  name: name, gender: gender, DOB: date)
                lovedOneList.items.append(newLovedOne)
                
                if(upload_vid){
                    //TODO: add p_id and lo_id in the upload path, (need to work around optional part...)
                    //Upload training data to firebase
                    // Create a reference to the file you want to upload
                    //TODO: this whole thing would be cleaner with async and await
                    let storRef = Storage.storage().reference()
                    let vidRef = storRef.child("training_data/\(patiendID)/\(loved_one_id!)/face.mov")
                    
                    let _ = vidRef.putFile(from: video, metadata: nil) { (metadata, error) in
                        guard let metadata = metadata else {
                            // Uh-oh, an error occurred!
                            return
                        }
                        let audioRef = storRef.child("training_data/\(patiendID)/\(loved_one_id!)/voice.m4a")
                        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]//where do you want to save
                        let audioFilename = documentPath.appendingPathComponent("Recording.m4a")
                        
                        let _ = audioRef.putFile(from: audioFilename, metadata: nil) { (metadata, error) in
                            guard let metadata = metadata else {
                                // Uh-oh, an error occurred!
                                return
                            }
                            //Notify backend of upload
                            //TODO: possibly use some event hook here instead so we dont have to do this
                            guard let url: URL = URL(string: "http://" + backendIpPort + "/training_data") else {
                                print("Invalid url")
                                return
                            }
                            
                            var urlRequest: URLRequest = URLRequest(url: url)
                            urlRequest.httpMethod = "POST"
                            let parameters: [String: String] = [
                                "p_idx": patiendID,
                                "lo_idx": loved_one_id!
                            ]
                            let encoder = JSONEncoder()
                            if let jsonData = try? encoder.encode(parameters) {
                                if let jsonString = String(data: jsonData, encoding: .utf8) {
                                    urlRequest.httpBody = jsonData
                                }
                            }
                            
                            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                            URLSession.shared.dataTask(with: urlRequest, completionHandler: {
                                (data, response, error) in
                                guard let data = data else{
                                    print("invalid data")
                                    return
                                }
                                let responseStr : String = String(data: data, encoding: .utf8) ?? "No Response"
                            }).resume()
                            
                            // Metadata contains file metadata such as size, content-type.
                            let _ = metadata.size
                            // You can also access to download URL after upload.
                            storRef.downloadURL { (url, error) in
                                guard let downloadURL = url else {
                                    // Uh-oh, an error occurred!
                                    return
                                }
                            }
                        }
                        
                        // Metadata contains file metadata such as size, content-type.
                        let _ = metadata.size
                        // You can also access to download URL after upload.
                        storRef.downloadURL { (url, error) in
                            guard let downloadURL = url else {
                                // Uh-oh, an error occurred!
                                return
                            }
                        }
                    }
                    
                    
                }
                
            }).resume()
            
            
        }
        else{
            let newLovedOne = lovedOne(id: id, patientID: patientID,  name: name, gender: gender, DOB: date)
            lovedOneList.items.append(newLovedOne)
        }
        
    }
}
