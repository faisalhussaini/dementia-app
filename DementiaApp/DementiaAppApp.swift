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
    let persistenceController = PersistenceController.shared
    var body: some Scene {
        WindowGroup {
            PatientView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
    
    init() {
        FirebaseApp.configure()
    }
}
