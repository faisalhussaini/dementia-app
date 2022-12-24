//
//  ContentView.swift
//  DementiaApp
//
//  Created by Faisal Hussaini on 2022-09-18.
//


import SwiftUI
import AVKit
import Alamofire
import FirebaseStorage

let useBackend : Bool = true
var didLoad : Bool = false

func convertDictionaryToString(dic: [String : String]) -> String{
    var res:String = ""
    for (key,val) in dic{
        //TODO: do this cleaner, I cant use commas because the value can have commas in it...
        res += key + ":" + val + ";"
    }
    return res
}

func convertToDictionary(text: String) -> [String: String]? {
    if let data = text.data(using: .utf8) {
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: String]
        } catch {
            print(error.localizedDescription)
        }
    }
    return nil
}

func convertToDictionaryList(text: String) -> [String: [[String : String]]]? {
    if let data = text.data(using: .utf8) {
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: [[String : String]]]
        } catch {
            print(error.localizedDescription)
        }
    }
    return nil
}

struct PatientView: View {
    
    @StateObject var patientList = patients()
    @StateObject var lovedOneList = lovedOnes()
    @State var showPopup = false
    var body: some View {
        ZStack {
            NavigationView{
                List {
                    ForEach(patientList.items, id: \.id) { item in
                        HStack {
                            Text(item.name)
                            NavigationLink(destination: LovedOneView(patientID: item.id, lovedOneList: lovedOneList), label: {
                            })
                            .isDetailLink(false)
                        }
                        .padding(.top)
                    }
                    .onDelete(perform: removeItems)
                }
                .navigationTitle("Patients")
                .offset(y:80)
                .padding()
                .toolbar {
                    Button {
                        showPopup.toggle()
                    } label : {
                        Image(systemName: "plus")
                    }
                    .sheet(isPresented: $showPopup) {
                        newPatientView(patientList: patientList)
                    }
                }
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .onAppear {
                if (!didLoad) {
                    load_patients()
                    load_loved_ones()
                    didLoad = true
                }
            }
        }
        .ignoresSafeArea()
    }
    func removeItems(at offsets: IndexSet) {
        if(useBackend){
            for index in offsets{
                let patient : patient = patientList.items[index]
                guard let url: URL = URL(string: "http://127.0.0.1:5000/patients") else {
                    print("Invalid url")
                    return
                }
                var urlRequest: URLRequest = URLRequest(url: url)
                urlRequest.httpMethod = "DELETE"
                let parameters: [String: String] = [
                    "p_idx": patient.id
                ]
                let encoder = JSONEncoder()
                if let jsonData = try? encoder.encode(parameters) {
                    if let jsonString = String(data: jsonData, encoding: .utf8) {
                        print(jsonString)
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
                    print(responseStr)
                }).resume()
            }
            
        }
        patientList.items.remove(atOffsets: offsets)
    }
    //For now just hard code this, access API endpoint later
    func load_patients(){
        if(useBackend){
            //fetch all the patients
            guard let url: URL = URL(string: "http://127.0.0.1:5000/all_patients") else {
                print("Invalid url")
                return
            }
            
            var urlRequest: URLRequest = URLRequest(url: url)
            urlRequest.httpMethod = "GET"
            
            //urlRequest.httpBody = jsonData
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            URLSession.shared.dataTask(with: urlRequest, completionHandler: {
                (data, response, error) in
                guard let data = data else{
                    print("invalid data")
                    return
                }
                let responseStr : String = String(data: data, encoding: .utf8) ?? "No Response"
                print(responseStr)
                let res : [String:[[String : String]]] = convertToDictionaryList(text:responseStr) ?? ["" : [["":""]]]
                print(res)
                let all_patients : [[String : String]] = res["patients"] ?? [["":""]]
                for p in all_patients{
                    let gender : String = p["gender"] ?? ""
                    let id : String = p["p_idx"] ?? ""
                    let name : String  = p["name"] ?? ""
                    let dob : String = p["DOB"] ?? ""
                    let dF : DateFormatter = DateFormatter()
                    // Convert string to date
                    dF.dateFormat = "YYYY/MM/dd"
                    let date = dF.date(from: dob) ?? Date()
                    print(date)
                    let curr_patient: patient = patient(id: id, name: name, gender: gender, DOB: date)
                    patientList.items.append(curr_patient)
                }
            }).resume()
        }
        else{
            let patient1: patient = patient(id: "1", name: "Faisal Hussaini", gender: "male", DOB: Date())
            let patient2: patient = patient(id: "2", name: "Julian Humecki", gender: "male", DOB: Date())
            let patient3: patient = patient(id: "3", name: "Hassan Khan", gender: "male", DOB: Date())
            let patient4: patient = patient(id: "4", name: "Omar Abou El Naja", gender: "male", DOB: Date())
            patientList.items.append(patient1)
            patientList.items.append(patient2)
            patientList.items.append(patient3)
            patientList.items.append(patient4)
        }
    }
    func load_loved_ones(){
        if(useBackend){
            //fetch all the loved ones
            guard let url: URL = URL(string: "http://127.0.0.1:5000/all_loved_ones") else {
                print("Invalid url")
                return
            }
            
            var urlRequest: URLRequest = URLRequest(url: url)
            urlRequest.httpMethod = "GET"
            
            //urlRequest.httpBody = jsonData
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            URLSession.shared.dataTask(with: urlRequest, completionHandler: {
                (data, response, error) in
                guard let data = data else{
                    print("invalid data")
                    return
                }
                let responseStr : String = String(data: data, encoding: .utf8) ?? "No Response"
                print(responseStr)
                let res : [String:[[String : String]]] = convertToDictionaryList(text:responseStr) ?? ["" : [["":""]]]
                print(res)
                let all_loved_ones : [[String : String]] = res["loved_ones"] ?? [["":""]]
                for lo in all_loved_ones{
                    let gender : String = lo["gender"] ?? ""
                    let patientId : String = lo["p_idx"] ?? ""
                    let id : String = lo["lo_idx"] ?? ""
                    let name : String  = lo["name"] ?? ""
                    let dob : String = lo["DOB"] ?? ""
                    let dF : DateFormatter = DateFormatter()
                    // Convert string to date
                    dF.dateFormat = "YYYY/MM/dd"
                    let date = dF.date(from: dob) ?? Date()
                    //print(date)
                    let curr_loved_one: lovedOne = lovedOne(id: id, patientID: patientId, name: name, gender: gender, DOB: date)
                    lovedOneList.items.append(curr_loved_one)
                }
            }).resume()
        }
        else{
            for i in 1...15{
                let name = "Loved One" + String(i)
                let newLovedOne: lovedOne = lovedOne(id: String(i), patientID: String((i % 4) + 1), name: name, gender: "male", DOB: Date())
                lovedOneList.items.append(newLovedOne)
            }
        }
    }
}



struct LovedOneView: View {
    
    var patientID: String
    @State private var showPopup = false
    
    @StateObject var lovedOneList : lovedOnes
    var body: some View {
        ZStack {
            NavigationView() {
                List {
                    ForEach(lovedOneList.items, id: \.id) { item in
                        if (item.patientID == patientID) {
                            HStack {
                                Text(item.name)
                                NavigationLink(destination: CallView(color: .blue, lovedOneList: lovedOneList, id: item.id, p_id: patientID), label: {
                                })
                                .isDetailLink(false)
                            }
                            .padding(.top)
                        }
                    }
                    .onDelete(perform: removeItems)
                }
                .navigationTitle("Call A Loved One")
                .offset(y:80)
                .padding()
                .toolbar {
                    Button {
                        showPopup.toggle()
                    } label : {
                        Image(systemName: "plus")
                    }
                    .sheet(isPresented: $showPopup) {
                        newLovedOneView(audioRecorder: AudioRecorder(), patientID: patientID, lovedOneList: lovedOneList)
                    }
                }
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
        .ignoresSafeArea()
    }
    func removeItems(at offsets: IndexSet) {
        if(useBackend){
            for index in offsets{
                let lovedOne : lovedOne = lovedOneList.items[index]
                guard let url: URL = URL(string: "http://127.0.0.1:5000/loved_ones") else {
                    print("Invalid url")
                    return
                }
                var urlRequest: URLRequest = URLRequest(url: url)
                urlRequest.httpMethod = "DELETE"
                let parameters: [String: String] = [
                    "p_idx": lovedOne.patientID,
                    "lo_idx": lovedOne.id
                ]
                let encoder = JSONEncoder()
                if let jsonData = try? encoder.encode(parameters) {
                    if let jsonString = String(data: jsonData, encoding: .utf8) {
                        print(jsonString)
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
                    print(responseStr)
                }).resume()
            }
            
        }
        lovedOneList.items.remove(atOffsets: offsets)
    }
}

struct newPatientView: View {
    @StateObject var patientList : patients
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dismiss) var dismiss
    var genders = ["Male", "Female", "Prefer not to say"]
    @State private var date = Date()
    @State private var name: String = ""
    @State private var gender: String = ""
    @State private var children: String = ""
    @State private var spouse: String = ""
    @State private var placeOfResidence: String = ""
    @State private var hobbies: String = ""
    @State private var hospitalName: String = ""
    @State private var questionResponses = ["children": "",
                                            "spouse": "",
                                            "residence": "",
                                            "hobbies": "",
                                            "hospital": ""]
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section {
                        TextField("Patient's Name", text: $name)
                        DatePicker("Patient's Date of Birth", selection : $date, displayedComponents: .date)
                        Picker("Patient's Gender", selection: $gender) {
                            ForEach(genders, id: \.self) {
                                Text($0)
                            }
                        }
                        TextField("Patient's children seperated by commas. Example: 'John Smith, Jack Smith'", text: $children)
                        TextField("Patient's spouse/partner", text: $spouse)
                        TextField("Patient's place of residence", text: $placeOfResidence)
                        TextField("Patient's hobbies seperated by commas. Example: 'swimming, poetry, cooking'", text: $hobbies)
                        TextField("Name of the hospital patient is staying in", text: $hospitalName)
                    }
                }
                
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
                .onChange(of: hospitalName, perform: { string in
                    questionResponses["hospital"] = hospitalName
                })
                
                .navigationBarTitle("New Patient")
                Button {
                    add_patient(id: "21", name: name, gender: gender, date: date, questionResponses: questionResponses)
                    presentationMode.wrappedValue.dismiss()
                } label : {
                    Text("Save")
                }
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
    
    //hard code for now, add API access
    func add_patient(id: String, name: String, gender:String, date:Date, questionResponses: [String: String]){
        if(useBackend){
            //Upload patient to the server
            guard let url: URL = URL(string: "http://127.0.0.1:5000/patients") else {
                print("Invalid url")
                return
            }
            let dF : DateFormatter = DateFormatter()
            // Convert Date to String
            dF.dateFormat = "YYYY/MM/dd"
            let dob = dF.string(from: date)
            print(dob)
            var urlRequest: URLRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            
            let parameters: [String: String] = [
                "name": name,
                "gender": gender,
                "DOB": dob,
                "responses": convertDictionaryToString(dic: questionResponses),
            ]
            let encoder = JSONEncoder()
            if let jsonData = try? encoder.encode(parameters) {
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    print(jsonString)
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
                print(responseStr)
                let res : [String : String]? = convertToDictionary(text: (responseStr))
                print(res)
                let patient_id : String? = res?["id"]
                print("Patient id is \(patient_id ?? "0")")
                let newPatient = patient(id: patient_id ?? "0", name: name, gender: gender, DOB: date)
                patientList.items.append(newPatient)
            }).resume()
        }
        else{
            let newPatient = patient(id: id, name: name, gender: gender, DOB: date)
            patientList.items.append(newPatient)
        }
    }
}

struct newLovedOneView: View {
    
    @ObservedObject var audioRecorder: AudioRecorder
    var patientID: String
    @StateObject var lovedOneList : lovedOnes
    @Environment(\.presentationMode) var presentationMode
    
    var genders = ["Male", "Female", "Prefer not to say"]
    @State private var date = Date()
    @State private var name: String = ""
    @State private var gender: String = ""
    @State private var audioFile: Recording?
    @State private var isShowingPhotoPicker = false
    @State private var lovedOneImage = UIImage(named: "default-avatar")!
    @State private var children: String = ""
    @State private var spouse: String = ""
    @State private var placeOfResidence: String = ""
    @State private var hobbies: String = ""
    @State private var questionResponses = ["children": "",
                                            "spouse": "",
                                            "residence": "",
                                            "hobbies": ""]
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var isImagePickerButtonClicked = false
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section {
                        TextField("Loved One's Name", text: $name)
                        DatePicker("Loved One's Date of birth", selection : $date, displayedComponents: .date)
                        Picker("Loved Ones's Gender", selection: $gender) {
                            ForEach(genders, id: \.self) {
                                Text($0)
                            }
                        }
                        TextField("Loved One's children seperated by commas. Example: 'John Smith, Jack Smith'", text: $children)
                        TextField("Loved One's spouse/partner", text: $spouse)
                        TextField("Loved One's place of residence", text: $placeOfResidence)
                        TextField("Loved One's hobbies seperated by commas. Example: 'swimming, poetry, cooking'", text: $hobbies)
                    }
                    //https://www.youtube.com/watch?v=V-kSSjh1T74
                    //once we connect with backend then upload lovedOneImage in add_loved_one, for now do nothing
                    Section {
                        Image(uiImage: lovedOneImage) //swiftui does not have a native way in ios 15 to interact with photopicker. Have to use with uiimagepickercontroller in uikit which returns uiimage
                            .resizable()
                            .scaledToFill()
                            .frame(width: 150, height:150)
                            .clipShape(Circle())
                            .padding()
                            .onTapGesture {
                                isShowingPhotoPicker = true
                            }
                            Button("Camera") {
                                self.sourceType = .camera
                                self.isImagePickerButtonClicked.toggle()
                            }.padding()
                            
                            Button("Photo Library") {
                                self.sourceType = .photoLibrary
                                self.isImagePickerButtonClicked.toggle()
                            }.padding()
                        Text("Select Image of Loved One")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .navigationTitle("New Loved One")
                    //.sheet(isPresented: $isShowingPhotoPicker) {
                    //    PhotoPicker(lovedOneImage: $lovedOneImage, sourceType: self.sourceType)
                    //}
                    .sheet(isPresented: self.$isImagePickerButtonClicked) {
                        PhotoPicker(lovedOneImage: $lovedOneImage, sourceType: self.sourceType)
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
                
                Button {
                    //Once we connect with Backend then pass mp4 file and image in add_loved_one
                    let imageData: Data = lovedOneImage.jpegData(compressionQuality: 0.5) ?? Data()
                    
                    add_loved_one(id: "21", patiendID: patientID, name: name, gender: gender, date: date, picture: imageData, questionResponses: questionResponses)
                    presentationMode.wrappedValue.dismiss()
                } label : {
                    Text("Save")
                }
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
    
    //hard code for now, add API access later
    //Once we connect with Backend then pass mp4 file in add_loved_one
    func add_loved_one(id:String, patiendID: String, name:String, gender:String, date:Date, picture:Data, questionResponses: [String: String]){
        let upload_img : Bool = true
        print("Adding a loved one\n");
        if(useBackend){
            //Upload patient to the server
            guard let url: URL = URL(string: "http://127.0.0.1:5000/loved_ones") else {
                print("Invalid url")
                return
            }
            let dF : DateFormatter = DateFormatter()
            // Convert Date to String
            dF.dateFormat = "YYYY/MM/dd"
            let dob = dF.string(from: date)
            print(dob)
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
                    print(jsonString)
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
                print(responseStr)
                let res : [String : String]? = convertToDictionary(text: (responseStr))
                print(res)
                let loved_one_id : String? = res?["id"]
                print("Loved one id is \(loved_one_id ?? "0")")
                let newLovedOne = lovedOne(id: loved_one_id ?? "0", patientID: patientID,  name: name, gender: gender, DOB: date)
                lovedOneList.items.append(newLovedOne)
                if(upload_img){
                    //TODO: add p_id and lo_id in the upload path, (need to work around optional part...)
                    //Upload training data to firebase
                    // Create a reference to the file you want to upload
                    //TODO: this whole thing would be cleaner with async and await
                    let storRef = Storage.storage().reference()
                    let imgRef = storRef.child("training_data/face.jpeg")
                    
                    let uploadTask = imgRef.putData(picture, metadata: nil) { (metadata, error) in
                        guard let metadata = metadata else {
                            // Uh-oh, an error occurred!
                            return
                        }
                        let audioRef = storRef.child("training_data/voice.m4a")
                        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]//where do you want to save
                        let audioFilename = documentPath.appendingPathComponent("Recording.m4a")
                        
                        let audioUploadTask = audioRef.putFile(from: audioFilename, metadata: nil) { (metadata, error) in
                            guard let metadata = metadata else {
                                // Uh-oh, an error occurred!
                                return
                            }
                            //Notify backend of upload
                            //TODO: possibly use some event hook here instead so we dont have to do this
                            guard let url: URL = URL(string: "http://127.0.0.1:5000/training_data") else {
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
                                    print(jsonString)
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
                                print(responseStr)
                            }).resume()
                            
                            // Metadata contains file metadata such as size, content-type.
                            let size = metadata.size
                            // You can also access to download URL after upload.
                            storRef.downloadURL { (url, error) in
                                guard let downloadURL = url else {
                                    // Uh-oh, an error occurred!
                                    return
                                }
                            }
                        }
                        
                        // Metadata contains file metadata such as size, content-type.
                        let size = metadata.size
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


struct CallView: View {
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
    
    @State var videoURL = "https://storage.googleapis.com/virtual-presence-app.appspot.com/1/1/hello.mp4"
    var body: some View {
        ZStack (alignment: .bottomTrailing){
            ForEach(lovedOneList.items, id: \.id) { item in
                if (item.id == id) {
                    VStack {
                        //Make video play automatically
                        //https://stackoverflow.com/questions/65796552/ios-swiftui-video-autoplay
                        VideoPlayer(player: player)
                            .onAppear{
                                if player.currentItem == nil {
                                    videoURL = "https://storage.googleapis.com/virtual-presence-app.appspot.com/\(p_id)/\(id)/hello.mp4"
                                    let item = AVPlayerItem(url: URL(string: videoURL)!)
                                    player.replaceCurrentItem(with: item)
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                                    player.play()
                                })
                            }
                        Text("Chatting with \(item.name)")
                            .padding()
                        
                        //TODO: MAKE CALL HANDS FREE RATHER THAN WITH BUTTON
                        //We would then pass this into chatbot and get an output text
                        
                        //code for speech recognition adopted from a todo app tutorial youtube series
                        //https://www.youtube.com/playlist?list=PLbrKvTeCrFAffsnrKSa9mp9hM22E6kSjx
                        HStack{
                            Text(todos.last?.text ?? "----")
                            recordButton(text: todos.last?.text)
                            deleteButton()//to delete all elements in list of texts, figure out how to do this automatically when you leave call view
                            backendButton(text: todos.last?.text)
                        }
                    }
                    .onAppear {
                        speechManager.checkPermissions()
                    }
                    .padding(.top)
                }
            }
        }
        .ignoresSafeArea()
    }
    func recordButton(text: String?) -> some View {
        Button(action: {
            addItem()
        }) {
            Image(systemName: recording ? "stop.fill" : "mic.fill")
                .font(.system(size: 40))
                .padding()
                .cornerRadius(10)
        }.foregroundColor(.red)
    }
    
    func addItem() {
        if speechManager.isRecording {
            self.recording = false
            mic.stopMonitoring()
            speechManager.stopRecording()
        } else {
            self.recording = true
            mic.startMonitoring()
            speechManager.start { (speechText) in
                guard let text = speechText, !text.isEmpty else {
                    self.recording = false
                    return
                }
                print("text: ", text)
                DispatchQueue.main.async {
                    withAnimation {
                        let newItem = Todo(context: viewContext)
                        newItem.id = UUID()
                        newItem.text = text
                        newItem.created = Date()
                        
                        do {
                            try viewContext.save()
                        } catch {
                            print(error)
                        }
                    }
                }
            }
        }
        speechManager.isRecording.toggle()
    }
    func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map {todos[$0]}.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                print(error)
            }
        }
    }
    
    func deleteButton() -> some View {
        Button(action: deleteAllItems) {
            Image(systemName: "trash" )
                .font(.system(size: 40))
                .padding()
                .cornerRadius(10)
        }.foregroundColor(.red)
    }
    func deleteAllItems() {
        todos.forEach(viewContext.delete)
        do {
            try viewContext.save()
        } catch {
            print(error)
        }
    }
    func callBackend(text: String?) {
        print("Called backend!")
        print("text to send to backend: ", text)
        
        //TODO: GET VIDEO URL, FOR NOW GETTING A RANDOM VID
        var new_url = ""
        if(useBackend){
            //Upload patient to the server
            guard let url: URL = URL(string: "http://127.0.0.1:5000/responses") else {
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
                    print(jsonString)
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
                print(responseStr)
                let res : [String : String]? = convertToDictionary(text: (responseStr))
                print(res)
                let response_name : String? = res?["response"]
                let base_url : String = "https://storage.googleapis.com/virtual-presence-app.appspot.com"
                new_url = "\(base_url)/\(p_id)/\(id)/\(response_name!)"
                print(new_url)
                let item = AVPlayerItem(url: URL(string: new_url)!)
                player.replaceCurrentItem(with: item)
                player.play()
            }).resume()
        }
    }
    
    func backendButton(text: String?) -> some View {
        Button(action: {
            callBackend(text: text)
        }) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 40))
                .padding()
                .cornerRadius(10)
        }.foregroundColor(.red)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        PatientView()
    }
}

