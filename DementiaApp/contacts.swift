//
//  contacts.swift
//  DementiaApp
//
//  Created by Faisal Hussaini on 2022-09-19.
//

import SwiftUI

//Classes with lists of structs of patients and loved ones that are used to display names on the screen

class patients: ObservableObject {
    @Published var items = [patient]()
    init(items: [patient] = [patient]()) {
        self.items = items
    }
}

class lovedOnes: ObservableObject {
    @Published var items = [lovedOne]()
    init(items: [lovedOne] = [lovedOne]()) {
        self.items = items
    }
}
