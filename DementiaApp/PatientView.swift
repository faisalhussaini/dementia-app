//
//  ContentView.swift
//  DementiaApp
//
//  Created by Faisal Hussaini on 2022-09-18.
//


import SwiftUI
import AVKit
import Alamofire

let useBackend : Bool = true

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
            Button {
                load_patients()
                load_loved_ones()
            } label : {
                Text("Add patients and loved ones who would already be in our db. In the future we populate this data from the db...")
            }
            .offset(y:300)
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
                    dF.dateFormat = "YY/MM/dd"
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
                    dF.dateFormat = "YY/MM/dd"
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
                                NavigationLink(destination: CallView(color: .blue, lovedOneList: lovedOneList, id: item.id), label: {
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
                             "placeOfResidence": "",
                             "hobbies": "",
                             "hospitalName": ""]
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
                        TextField("Patient's spouse/partner and their name. Example: 'husband: Harry Smith'", text: $spouse)
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
                    questionResponses["placeOfResidence"] = placeOfResidence
                })
                .onChange(of: hobbies, perform: { string in
                    questionResponses["hobbies"] = hobbies
                })
                .onChange(of: hospitalName, perform: { string in
                    questionResponses["hospitalName"] = hospitalName
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
            dF.dateFormat = "YY/MM/dd"
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
                             "placeOfResidence": "",
                             "hobbies": ""]
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
                        TextField("Loved One's spouse/partner and their name. Example: 'husband: Harry Smith'", text: $spouse)
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
                        Text("Select Image of Loved One")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .navigationTitle("New Loved One")
                    .sheet(isPresented: $isShowingPhotoPicker) {
                        PhotoPicker(lovedOneImage: $lovedOneImage)
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
                    questionResponses["placeOfResidence"] = placeOfResidence
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
            dF.dateFormat = "YY/MM/dd"
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
                    //Upload the image to the server
                    let imageStr : String = picture.base64EncodedString()
                    //print(imageStr)
                    guard let url: URL = URL(string: "http://127.0.0.1:5000/upload_image/" + patiendID + "/" + (loved_one_id ?? "0")) else {
                        print("Invalid url")
                        return
                    }
                    let paramStr : String = "image=\(imageStr)"
                    let paramData : Data = paramStr.data(using: .utf8) ?? Data()
                    var urlRequest: URLRequest = URLRequest(url: url)
                    urlRequest.httpMethod = "POST"
                    urlRequest.httpBody = paramData
                    
                    urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
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
                //send the recorded audio file to server
                let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]//where do you want to save
                let audioFilename = documentPath.appendingPathComponent("Recording.m4a")
                var response: DataResponse<Data?, AFError>?
                guard let data = try? Data(contentsOf: audioFilename) else {
                    print("failed")
                    return
                }
                let request = AF.upload(multipartFormData: { multipartFormData in multipartFormData.append(data, withName: "loved_one.mp3")
                    },
                    to: "http://127.0.0.1:5000/upload_audio/" + patiendID + "/" + (loved_one_id ?? "0")
                    ,method: .post ).response { resp in
                            response = resp
                            print("got response")
                            print(resp)

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
    var player = AVPlayer()
    var body: some View {
        ZStack {
            ForEach(lovedOneList.items, id: \.id) { item in
                if (item.id == id) {
                    VStack {
                        
                        //we would get video URL from api call, for now play something random
                        var videoURL = "https://bit.ly/swswift"
                        
                        //Make video play automatically
                        //https://stackoverflow.com/questions/65796552/ios-swiftui-video-autoplay
                        VideoPlayer(player: player)
                            .onAppear{
                                if player.currentItem == nil {
                                    let item = AVPlayerItem(url: URL(string: videoURL)!)
                                    player.replaceCurrentItem(with: item)
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                                    player.play()
                                })
                            }
                        Text("Display Call to \(item.name) here")
                            .padding()
                        
                        //Add code to capture speech when user starts talking, stop mic when they stop
                        //Use speech recognition to convert to text
                        //We would then pass this into chatbot and get an output text
                    }
                    .padding(.top)
                }
            }
        }
        .ignoresSafeArea()
    }
    func play_video(url: String) -> some View{
        VideoPlayer(player: AVPlayer(url:  URL(string: url)!))
            .frame(width: 700, height: 500)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        PatientView()
    }
}

