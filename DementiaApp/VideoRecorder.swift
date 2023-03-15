//
//  VideoRecorder.swift
//  DementiaApp
//
//  Created by Faisal Hussaini on 2023-03-14.
//

//code to record a video adapted from a ChatGPT answer to "swiftui record and view video" on Feb 13

import SwiftUI
import UIKit

struct VideoPicker: UIViewControllerRepresentable {
    @Binding var showVideoPicker: Bool
    @Binding var videoURL: URL?
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = ["public.movie"]
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        //
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: VideoPicker

        init(parent: VideoPicker) {
            self.parent = parent
        }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let videoURL = info[.mediaURL] as? URL {
                parent.videoURL = videoURL
                parent.showVideoPicker = false
            }
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.showVideoPicker = false
        }
    }
}
