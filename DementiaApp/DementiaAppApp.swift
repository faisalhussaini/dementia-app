//
//  DementiaAppApp.swift
//  DementiaApp
//
//  Created by Faisal Hussaini on 2022-09-18.
//

import SwiftUI
import Firebase

@main
struct DementiaAppApp: App {
    var body: some Scene {
        WindowGroup {
            PatientView()
        }
    }
    
    init() {
        FirebaseApp.configure()
    }
}
