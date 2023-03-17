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
var waiting_to_get_reply : Bool = true
let lock_audio : NSLock = NSLock()

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

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

struct PatientView: View {
    
    //This is the view that the user sees when they start the app.
    //From here they can view all patients as well as add and delete patients
    
    @StateObject var patientList = patients()
    @StateObject var lovedOneList = lovedOnes()
    @State var showPopup = false
    var body: some View {
        NavigationView{
            List {//list showing each patient
                ForEach(patientList.items, id: \.id) { item in
                    HStack {
                        NavigationLink(destination: LovedOneView(patientID: item.id, lovedOneList: lovedOneList)) {
                            Text(item.name)
                        }
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
        .onAppear { //load all the patients and loved ones once on startup
            if (!didLoad) {
                load_patients()
                load_loved_ones()
                didLoad = true
            }
        }
    }
    func removeItems(at offsets: IndexSet) {
        //This function is called when deleting patients, it removes them from the DB
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
    func load_patients(){
        //This function gets the list of patients from the backend DB and appends them to the local list of patients to display
        //One patient struct is created for each patient in the backend
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
            //for local testing when not using the backend, hardcode patients
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
        //This function gets the list of loved ones from the backend DB and appends them to the local list of loved ones to display
        //One loved one struct is created for each loved one in the backend
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
            //for local testing when not using the backend, hardcode loved ones
            for i in 1...15{
                let name = "Loved One" + String(i)
                let newLovedOne: lovedOne = lovedOne(id: String(i), patientID: String((i % 4) + 1), name: name, gender: "male", DOB: Date())
                lovedOneList.items.append(newLovedOne)
            }
        }
    }
}



struct LovedOneView: View {
    //This is the view that the user sees when they click a patient.
    //From here they can view all loved ones curresponding to that patient, as well as add and delete loved ones
    
    var patientID: String
    @State private var showPopup = false
    
    @StateObject var lovedOneList : lovedOnes
    var body: some View {
        List {
            ForEach(lovedOneList.items, id: \.id) { item in
                if (item.patientID == patientID) {
                    HStack {
                        NavigationLink(destination: CallView(color: .blue, lovedOneList: lovedOneList, id: item.id, p_id: patientID)) {
                            Text(item.name)
                        }
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
    func removeItems(at offsets: IndexSet) {
        //This function is called when deleting loved ones, it removes them from the DB and the local list of loves ones
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
    
    //This is the view that is displayed when adding a new patient
    //the view takes information about the patient in the form of text form
    
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
                        TextField("", text: $name)
                            .placeholder(when: name.isEmpty) {
                                Text("Patient's Name").foregroundColor(.red)
                            }
                        DatePicker("Patient's Date of Birth", selection : $date, displayedComponents: .date)
                        Picker("Patient's Gender", selection: $gender) {
                            ForEach(genders, id: \.self) {
                                Text($0)
                            }
                        }
                        TextField("Patient's children seperated by commas. Example: 'John Smith, Jack Smith'", text: $children)
                        TextField("Patient's spouse/partner", text: $spouse)
                        TextField("", text: $placeOfResidence)
                            .placeholder(when: placeOfResidence.isEmpty) {
                                Text("Patient's place of residence").foregroundColor(.red)
                            }
                        TextField("", text: $hobbies)
                            .placeholder(when: hobbies.isEmpty) {
                                Text("Patient's top 3 hobbies seperated by commas. Example: 'swimming, poetry, cooking'").foregroundColor(.red)
                            }
                        TextField("", text: $hospitalName)
                            .placeholder(when: hospitalName.isEmpty) {
                                Text("Name of the hospital patient is staying in").foregroundColor(.red)
                            }
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
                Section {
                    Button {
                        add_patient(id: "21", name: name, gender: gender, date: date, questionResponses: questionResponses)
                        presentationMode.wrappedValue.dismiss()
                    } label : {
                        Text("Save")
                    }
                }
                .disabled(name.isEmpty || placeOfResidence.isEmpty || hobbies.isEmpty || hospitalName.isEmpty || hobbies.filter { $0 == "," }.count != 2)//The save button is disabled if info is missing
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
    
    
    func add_patient(id: String, name: String, gender:String, date:Date, questionResponses: [String: String]){
        
        //This function is used to add the patient to the backend DB
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
                    /*
                    REMOVED NEED FOR PHOTO FOR NOW. INSTEAD USE VIDEO
                    //https://www.youtube.com/watch?v=V-kSSjh1T74
                    //This demo on youtube was followed to create the photopicker
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
                     */
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
                            Text("Please record a short clip of yourself nodding while as still as possible. This will be used to generate the deepfake")
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
                
                if(upload_vid){
                    //TODO: add p_id and lo_id in the upload path, (need to work around optional part...)
                    //Upload training data to firebase
                    // Create a reference to the file you want to upload
                    //TODO: this whole thing would be cleaner with async and await
                    let storRef = Storage.storage().reference()
                    let vidRef = storRef.child("training_data/\(patiendID)/\(loved_one_id!)/face.mov")
                    
                    let uploadTask = vidRef.putFile(from: video, metadata: nil) { (metadata, error) in
                        guard let metadata = metadata else {
                            // Uh-oh, an error occurred!
                            return
                        }
                        let audioRef = storRef.child("training_data/\(patiendID)/\(loved_one_id!)/voice.m4a")
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
    @State var videoURL = "https://storage.googleapis.com/virtual-presence-app.appspot.com/1/1/hello.mp4"
    @State var patientURL = ""
    @State var timer: Timer?
    @State var timer_me: Timer?
    @State var duplicateURL : Bool = false
    @State var promptURL : String = ""
    @State var inCall = true
    @State private var showingAlert = false
    
    var body: some View {
        ZStack (alignment: .bottomTrailing){
            ForEach(lovedOneList.items, id: \.id) { item in
                if (item.id == id) {
                    VStack {
                        //Make video play automatically
                        //https://stackoverflow.com/questions/65796552/ios-swiftui-video-autoplay
                        VideoPlayer(player: player)
                            .onAppear{
                                if (promptURL == "") {
                                    //the first prompt is fixed, everything after is chosen by the backend
                                    promptURL = "https://storage.googleapis.com/virtual-presence-app.appspot.com/\(p_id)/\(id)/" + "howareyoudoingtoday.mp4"
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

                        //code for speech recognition adopted from a todo app tutorial youtube series
                        //https://www.youtube.com/playlist?list=PLbrKvTeCrFAffsnrKSa9mp9hM22E6kSjx
                        //The call button must be clicked one to initiate the speech recognition
                        HStack{
                            Text(todos.last?.text ?? "----")
                            recordButton()
                        }
                    }
                    .onAppear {
                        speechManager.checkPermissions()
                        let InitialDelay = 2.0
                        DispatchQueue.main.asyncAfter(deadline: .now() + InitialDelay) {
                            addItem()
                        }
                    }
                    .onDisappear() {
                        deleteAllItems()//Delete the conversation data once you leave the call
                        inCall = false
                        print("Left call!")
                    }
                    .padding(.top)
                    .alert("Loved one is still being generated, please check back in a few minutes", isPresented: $showingAlert) {
                        Button("OK", role: .cancel) { dismiss()}
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
    func recordButton() -> some View {
        //This button starts the speech recognition when clicked. It only needs to be manually clicked once
        Button(action: addItem) {
            Image(systemName: "phone.fill")
                .font(.system(size: 40))
                .padding()
                .cornerRadius(10)
        }.foregroundColor(recording ? .red : .green)
    }
    
    func addItem() {
        //This is called each time speech recognition has started
        //It starts recording the user and transcribing their text to speech, then provides this text to the backend
        //It then updates the AVPlayer to play whatever the backend sent back
        
        print("J: adding item!!!!!!")
        if speechManager.isRecording {
            print("done recording")
            self.recording = false
            mic.stopMonitoring()
            speechManager.stopRecording()
            print("Speech manager toggled")
            speechManager.isRecording.toggle()
        } else {
            print("waiting to record")
            self.recording = true
            mic.startMonitoring()
            print("speech manager start")
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
                            var old_url = final_url
                            callBackend(text: todos.last?.text)
                            while(final_url == old_url && duplicateURL == false) {
                            //do nothing and wait for the url to update, there must be a more elegant way to do this
                            }
                            if (inCall) {
                                let item = AVPlayerItem(url: URL(string: final_url)!)
                                player.replaceCurrentItem(with: item)
                                player.play()
                            }
                            let time_to_wait = self.player.currentItem!.asset.duration
                            resetTimer(wait_n: time_to_wait)
                            
                            self.recording = false
                            mic.stopMonitoring()
                            speechManager.stopRecording()
                            print("Speech manager toggled")
                            waiting_to_get_reply = false
                        }
                    }
                    mic.stopMonitoring()
                    print("mic stopped monitoring")
                }
                
        }
    }
    func deleteItems(offsets: IndexSet) {
        //delete all speech to text transcriptions
        withAnimation {
            offsets.map {todos[$0]}.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                print(error)
            }
        }
    }
    
    func startTimer() {
        //This function is used to start the timer which is used to prompt the patient if they are not speaking
        //If you reach the end of the timer, the patient is prompted
        self.timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true, block: { _ in
            if (!inCall) {
                return
            }
            lock_audio.lock()
            //turn off mic
            self.recording = false
            mic.stopMonitoring()
            speechManager.stopRecording()
            waiting_to_get_reply = false
            
            print("timer done, prompting patient!!!!!!!!!!")
            print(promptURL)
            let item = AVPlayerItem(url: URL(string: promptURL)!)
            player.replaceCurrentItem(with: item)
            player.play()
            getPrompt()
            //restart mic monitoring post prompt
            let wait_n = self.player.currentItem!.asset.duration
            let time_to_wait = ceil(wait_n.seconds) + 0.1
            print("time of prompt = ", time_to_wait)
            startMe(wait_n: time_to_wait)
            lock_audio.unlock()
        })
    }
    func startMe(wait_n : Double) {
        //spinner to wait and restart prompt
        self.timer_me = Timer.scheduledTimer(withTimeInterval: wait_n, repeats: false, block: { _ in
            lock_audio.lock()
            print("spinning and waiting to restart prompt")
            if (waiting_to_get_reply) {
                return
            }
            print("done spinning, restarting")
            waiting_to_get_reply = true;
            addItem()
            lock_audio.unlock()
        })
    }
    func resetTimer(wait_n: CMTime) {
        //restarting the timer after the prompt is done playing
        print("wait = ", wait_n)
        print("seconds = ", wait_n.seconds)
        let compute = ceil(wait_n.seconds) + 0.1
        print("new wait = ", compute)
        self.timer?.invalidate()
        startTimer()
        startMe(wait_n: compute)
    }
    func getPrompt() {
        //function used to communicate with the backend to figure out what prompt to play to them
        
        if(useBackend){
            //Upload patient to the server
            guard let url: URL = URL(string: "http://127.0.0.1:5000/prompts") else {
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
                var old_final_url = final_url
                let responseStr : String = String(data: data, encoding: .utf8) ?? "No Response"
                print(responseStr)
                let res : [String : String]? = convertToDictionary(text: (responseStr))
                print(res)
                let prompt_name : String? = res?["response"]
                print(prompt_name)
                promptURL = patientURL + prompt_name! + ".mp4"
            }).resume()
        }
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
        
        //Function used to send the speech text to the backend and update the url response to play to the user
        
        print("Called backend!")
        print("text to send to backend: ", text)
        duplicateURL = false
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
                var old_final_url = final_url
                let responseStr : String = String(data: data, encoding: .utf8) ?? "No Response"
                print(responseStr)
                let res : [String : String]? = convertToDictionary(text: (responseStr))
                print(res)
                let response_name : String? = res?["response"]
                let base_url : String = "https://storage.googleapis.com/virtual-presence-app.appspot.com"
                new_url = "\(base_url)/\(p_id)/\(id)/\(response_name!)"
                print(new_url)
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        PatientView()
    }
}
