//
//  StructsDB.swift
//  DementiaApp
//
//
//  Created by Faisal Hussaini on 2022-09-19.
//

import SwiftUI

struct patient: Identifiable {
    let id: String
    let name: String
    let gender: String
    let DOB: Date
}

struct Recording {
    let fileURL: URL
    let id = UUID()
}

struct lovedOne: Identifiable {
    let id: String
    let patientID: String
    let name: String
    let gender: String
    let DOB: Date
}
