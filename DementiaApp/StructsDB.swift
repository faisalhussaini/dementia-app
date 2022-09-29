//
//  StructsDB.swift
//  DementiaApp
//
//  Created by Faisal Hussaini on 2022-09-19.
//

import SwiftUI

struct patient: Identifiable {
    //let id = UUID()
    let id: String
    let name: String
    let gender: String
    let DOB: Date
}

struct lovedOne: Identifiable {
    //let id = UUID()
    //let patientID: UUID
    let id: String
    let patientID: String
    let name: String
    let gender: String
    let DOB: Date
}
