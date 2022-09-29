//
//  ImagePicker.swift
//  DementiaApp
//
//  Created by Faisal Hussaini on 2022-09-21.
//

import SwiftUI
import PhotosUI

struct ImagePicker: View {
    @State var selectedItems: [PhotosPickerItem] = []
    @State var data: Data?
    
    var body: some View {
        VStack {
            if let data = data, let uiimage = UIImage(data: data) {
                Image(uiImage: uiimage)
                    .resizable()
            }
            Spacer()
            PhotosPicker(
                selection: $selectedItems,
                maxSelectionCount: 1,
                matching: .images
            ) {
                Text("Select Photo of Loved One")
            }
            .onChange(of: selectedItems) { newValue in
                guard let item = selectedItems.first else {
                    return
                }
                item.loadTransferable(type: Data.self) { result in
                    switch result {
                    case .success(let data):
                        if let data = data {
                            self.data = data
                        } else {
                            print("Date is NIL")
                        }
                    case .failure(let failure):
                        fatalError("\(failure)")
                    }
                }
            }
        }
    }
}
    

struct ImagePicker_Previews: PreviewProvider {
    static var previews: some View {
        ImagePicker()
    }
}
