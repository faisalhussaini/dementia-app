//
//  newPatientView.swift
//  DementiaApp
//
//  Created by Faisal Hussaini on 2022-09-20.
//
/*
import SwiftUI

struct newPatientView: View {
    @StateObject var patientList : patients
    
    var genders = ["Male", "Female", "Prefer not to say"]
    @State private var date = Date()
    @State private var name: String = ""
    @State private var gender: String = ""
    //@State private var DOB: String = "YYYY-MM-DD"
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
            }
        }
    }
}


struct newPatientView_Previews: PreviewProvider {
    static var previews: some View {
        newPatientView()
    }
}
*/
