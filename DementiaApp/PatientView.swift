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
                guard let url: URL = URL(string: "http://" + backendIpPort + "/patients") else {
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
                        urlRequest.httpBody = jsonData
                    }
                }
                
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                URLSession.shared.dataTask(with: urlRequest, completionHandler: {
                    (data, response, error) in
                    guard let data = data else{
                        return
                    }
                    let responseStr : String = String(data: data, encoding: .utf8) ?? "No Response"
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
            guard let url: URL = URL(string: "http://" + backendIpPort + "/all_patients") else {
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
                let res : [String:[[String : String]]] = convertToDictionaryList(text:responseStr) ?? ["" : [["":""]]]
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
            guard let url: URL = URL(string: "http://" + backendIpPort + "/all_loved_ones") else {
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
                let res : [String:[[String : String]]] = convertToDictionaryList(text:responseStr) ?? ["" : [["":""]]]
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        PatientView()
    }
}
