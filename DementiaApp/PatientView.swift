//
//  ContentView.swift
//  DementiaApp
//
//  Created by Faisal Hussaini on 2022-09-18.
//


import SwiftUI


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
            //.accentColor(Color(.label))
            Button {
                let patient1: patient = patient(id: "1", name: "Faisal Hussaini", gender: "male", DOB: Date())
                let patient2: patient = patient(id: "2", name: "Julian Humecki", gender: "male", DOB: Date())
                let patient3: patient = patient(id: "3", name: "Hassan Khan", gender: "male", DOB: Date())
                let patient4: patient = patient(id: "4", name: "Omar Abou El Naja", gender: "male", DOB: Date())
                patientList.items.append(patient1)
                patientList.items.append(patient2)
                patientList.items.append(patient3)
                patientList.items.append(patient4)
                let newLovedOne1: lovedOne = lovedOne(id: "1", patientID: "1", name: "Loved One 1", gender: "male", DOB: Date())
                let newLovedOne2: lovedOne = lovedOne(id: "2", patientID: "2", name: "Loved One 1", gender: "male", DOB: Date())
                let newLovedOne3: lovedOne = lovedOne(id: "3", patientID: "2", name: "Loved One 2", gender: "male", DOB: Date())
                let newLovedOne4: lovedOne = lovedOne(id: "4", patientID: "3", name: "Loved One 1", gender: "male", DOB: Date())
                let newLovedOne5: lovedOne = lovedOne(id: "5", patientID: "3", name: "Loved One 2", gender: "male", DOB: Date())
                let newLovedOne6: lovedOne = lovedOne(id: "6", patientID: "3", name: "Loved One 3", gender: "male", DOB: Date())
                let newLovedOne7: lovedOne = lovedOne(id: "7", patientID: "4", name: "Loved One 1", gender: "male", DOB: Date())
                let newLovedOne8: lovedOne = lovedOne(id: "8", patientID: "4", name: "Loved One 2", gender: "male", DOB: Date())
                let newLovedOne9: lovedOne = lovedOne(id: "9", patientID: "4", name: "Loved One 3", gender: "male", DOB: Date())
                let newLovedOne10: lovedOne = lovedOne(id: "10", patientID: "4", name: "Loved One 4", gender: "male", DOB: Date())
                lovedOneList.items.append(newLovedOne1)
                lovedOneList.items.append(newLovedOne2)
                lovedOneList.items.append(newLovedOne3)
                lovedOneList.items.append(newLovedOne4)
                lovedOneList.items.append(newLovedOne5)
                lovedOneList.items.append(newLovedOne6)
                lovedOneList.items.append(newLovedOne7)
                lovedOneList.items.append(newLovedOne8)
                lovedOneList.items.append(newLovedOne9)
                lovedOneList.items.append(newLovedOne10)
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
}



struct LovedOneView: View {
    
    var patientID: String
    @State private var showPopup = false
    
    @StateObject var lovedOneList : lovedOnes
    var body: some View {
        ZStack {
            List {
                ForEach(lovedOneList.items, id: \.id) { item in
                    if (item.patientID == patientID) {
                        HStack {
                            Text(item.name)
                            NavigationLink(destination: CallView(color: .blue), label: {
                            })
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
                    newLovedOneView(patientID: patientID, lovedOneList: lovedOneList)
                }
            }
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
                    let newPatient = patient(id: "21", name: name, gender: gender, DOB: date)
                    patientList.items.append(newPatient)
                    presentationMode.wrappedValue.dismiss()
                } label : {
                    Text("Save")
                }
            }
        }
    }
}

struct newLovedOneView: View {
    var patientID: String
    @StateObject var lovedOneList : lovedOnes
    @Environment(\.presentationMode) var presentationMode
    
    var genders = ["Male", "Female", "Prefer not to say"]
    @State private var date = Date()
    @State private var name: String = ""
    @State private var gender: String = ""
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
                }
                .navigationBarTitle("New Loved One")
                Button {
                    let newLovedOne = lovedOne(id: "21", patientID: patientID,  name: name, gender: gender, DOB: date)
                    lovedOneList.items.append(newLovedOne)
                    presentationMode.wrappedValue.dismiss()
                } label : {
                    Text("Save")
                }
            }
        }
    }
}


struct CallView: View {
    var color: Color
    var body: some View {
        ZStack {
            Text("Display Call here")
                .padding()
        }
        .ignoresSafeArea()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        PatientView()
    }
}

