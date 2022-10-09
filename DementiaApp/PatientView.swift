//
//  ContentView.swift
//  DementiaApp
//
//  Created by Faisal Hussaini on 2022-09-18.
//


import SwiftUI
import AVKit

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
        patientList.items.remove(atOffsets: offsets)
    }
    //For now just hard code this, access API endpoint later
    func load_patients(){
        let mode:Int = 0;
        if(mode == 1){
            //TODO: At some point backend code needs to be deployed...
            let url = URL(string: "http://127.0.0.1:5000/all_patients")!
            
            let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
                guard let data = data else { return }
                //TODO: Actually parse this and store in a dictionary
                print(String(data: data, encoding: .utf8)!)
            }
            
            task.resume()
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
        let mode:Int = 0;
        if(mode == 1){
            //TODO: At some point backend code needs to be deployed...
            //TODO: should loop over patients and use their uuid as i here
            let i = 0
            let url = URL(string: "http://127.0.0.1:5000/all_loved_ones/" + String(i))!
            
            let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
                guard let data = data else { return }
                //TODO: Actually parse this
                print(String(data: data, encoding: .utf8)!)
            }
            
            task.resume()
        }
        else{
            for i in 1...15{
                let name = "Loved One" + String(i)
                let newLovedOne: lovedOne = lovedOne(id: String(i), patientID: String((i % 4) + 1), name: name, gender: "male", DOB: Date(), picture: Data())
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
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section {
                        TextField("Patient's Name", text: $name)
                        DatePicker("Patient's Birthday", selection : $date, displayedComponents: .date)
                        Picker("Patient's Gender", selection: $gender) {
                            ForEach(genders, id: \.self) {
                                Text($0)
                            }
                        }
                    }
                }
                .navigationBarTitle("New Patient")
                Button {
                    add_patient(id: "21", name: name, gender: gender, date: date)
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
    func add_patient(id: String, name: String, gender:String, date:Date){
        let newPatient = patient(id: id, name: name, gender: gender, DOB: date)
        patientList.items.append(newPatient)
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
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section {
                        TextField("Loved One's Name", text: $name)
                        DatePicker("Loved One's Birthday", selection : $date, displayedComponents: .date)
                        Picker("Loved Ones's Gender", selection: $gender) {
                            ForEach(genders, id: \.self) {
                                Text($0)
                            }
                        }
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
                    .navigationTitle("Profile")
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
                Button {
                    //Once we connect with Backend then pass mp4 file and image in add_loved_one
                    let imageData: Data = lovedOneImage.jpegData(compressionQuality: 0.1) ?? Data()
                    add_loved_one(id: "21", patiendID: patientID, name: name, gender: gender, date: date, picture: imageData)
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
    func add_loved_one(id:String, patiendID: String, name:String, gender:String, date:Date, picture:Data){
        let mode : Int = 0
        let newLovedOne = lovedOne(id: id, patientID: patientID,  name: name, gender: gender, DOB: date, picture: picture)
        lovedOneList.items.append(newLovedOne)
        
        if(mode == 1){
            //Upload the image to the server
            let imageStr : String = picture.base64EncodedString()
            guard let url: URL = URL(string: "http://127.0.0.1:5000/all_loved_ones/") else {
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

