//
//  DementiaAppApp.swift
//  DementiaApp
//
//  Created by Faisal Hussaini on 2022-09-18.
//

import SwiftUI
import Firebase

let useBackend : Bool = true
var didLoad : Bool = false
var waiting_to_get_reply : Bool = true
let lock_audio : NSLock = NSLock()
let backendIpPort : String = "127.0.0.1:5000"

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

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

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
