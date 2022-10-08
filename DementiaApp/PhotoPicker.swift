//
//  PhotoPicker.swift
//  Photo
//
//  Created by Faisal Hussaini on 2022-10-08.
//

import SwiftUI

struct PhotoPicker: UIViewControllerRepresentable {
    
    @Binding var lovedOneImage: UIImage//whenever this variable changes, its bounded to lovedOneImage in ContentView, triggering an update
    
    func makeUIViewController(context: Context) -> UIImagePickerController { //called automatically
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator //cordinator is delegate to uiimmagepickercontroler
        picker.allowsEditing = true//crop photo
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator { //called automatically
        return Coordinator(photoPicker: self) //pass in our self
    }
    
    //This is so uikit and swiftui can communicate and you can pass the uiimage
    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        
        let photoPicker: PhotoPicker
        init(photoPicker: PhotoPicker){//take photoPicker we pass into to Coordinator, and set property photoPicker to this
            self.photoPicker = photoPicker
        }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.editedImage] as? UIImage {
                
                guard let data = image.jpegData(compressionQuality: 0.5), let compressedImage = UIImage(data:data) else { //compress image on scale from 0 to 1, aka 50%
                    //error
                    return
                }
                
                //when they select, we want avatar to popululate with image
                photoPicker.lovedOneImage = compressedImage
                //image is selected, lovedOneImage image is set to this photo. lovedOneImage image is bound to image in content view, so content view image will change, which will trigger update
            } else {
                //return an error
            }
            //dismiss controler after you select image
            picker.dismiss(animated: true)
        }
    }
    
    
}
