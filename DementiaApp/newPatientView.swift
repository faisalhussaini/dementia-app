//
//  newPatientView.swift
//  DementiaApp
//
//  Created by Faisal Hussaini on 2023-03-26.
//

import SwiftUI

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
            guard let url: URL = URL(string: "http://" + backendIpPort + "/patients") else {
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
                "name": name,
                "gender": gender,
                "DOB": dob,
                "responses": convertDictionaryToString(dic: questionResponses),
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
                let patient_id : String? = res?["id"]
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
