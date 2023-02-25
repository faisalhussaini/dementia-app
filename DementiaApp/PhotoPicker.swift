//
//  PhotoPicker.swift
//  Photo
//
//  Created by Faisal Hussaini on 2022-10-08.
//

import SwiftUI

//This file contains functions which are used to allow the loved one to pick and upload a photo of themselves to train the deepfake
//https://www.youtube.com/watch?v=V-kSSjh1T74
//This demo on youtube was followed to create the photopicker

struct PhotoPicker: UIViewControllerRepresentable {
    
    @Binding var lovedOneImage: UIImage//whenever this variable changes, its bounded to lovedOneImage in ContentView, triggering an update
    var sourceType: UIImagePickerController.SourceType
    
    func makeUIViewController(context: Context) -> UIImagePickerController { //called automatically
        let picker = UIImagePickerController()
        picker.sourceType = self.sourceType
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
