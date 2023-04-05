//
//  LovedOneView.swift
//  DementiaApp
//
//  Created by Faisal Hussaini on 2023-03-26.
//

import SwiftUI

struct LovedOneView: View {
    //This is the view that the user sees when they click a patient.
    //From here they can view all loved ones curresponding to that patient, as well as add and delete loved ones
    
    var patientID: String
    @State private var showPopup = false
    
    @StateObject var lovedOneList : lovedOnes
    var body: some View {
        List {
            ForEach(lovedOneList.items, id: \.id) { item in
                if (item.patientID == patientID) {
                    HStack {
                        NavigationLink(destination: CallView(color: .blue, lovedOneList: lovedOneList, id: item.id, p_id: patientID)) {
                            Text(item.name)
                        }
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
    func removeItems(at offsets: IndexSet) {
        //This function is called when deleting loved ones, it removes them from the DB and the local list of loves ones
        if(useBackend){
            for index in offsets{
                let lovedOne : lovedOne = lovedOneList.items[index]
                guard let url: URL = URL(string: "http://" + backendIpPort + "/loved_ones") else {
                    print("Invalid url")
                    return
                }
                var urlRequest: URLRequest = URLRequest(url: url)
                urlRequest.httpMethod = "DELETE"
                let parameters: [String: String] = [
                    "p_idx": lovedOne.patientID,
                    "lo_idx": lovedOne.id
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
                        print("invalid data")
                        return
                    }
                    let responseStr : String = String(data: data, encoding: .utf8) ?? "No Response"
                }).resume()
            }
            
        }
        lovedOneList.items.remove(atOffsets: offsets)
    }
}
