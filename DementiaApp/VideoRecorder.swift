//
//  VideoRecorder.swift
//  DementiaApp
//
//  Created by Faisal Hussaini on 2023-03-14.
//

//This file contains the video recorder that uses UIViewControllerRepresentable to allow loved ones to use uikit to record and upload a video of themselves to train the deepfake
//developed by following tutorial on UIViewControllerRepresentable
//https://www.youtube.com/watch?v=V-kSSjh1T74

import SwiftUI

struct VideoRecorder: UIViewControllerRepresentable {
    @Binding var showVideoRecorder: Bool
    @Binding var videoURL: URL?
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.mediaTypes = ["public.movie"]
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(videoRecorder: self)
    }
    
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let videoRecorder: VideoRecorder
        init(videoRecorder: VideoRecorder) {
            self.videoRecorder = videoRecorder
        }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let videoURL = info[.mediaURL] as? URL {
                videoRecorder.videoURL = videoURL
                videoRecorder.showVideoRecorder = false
            }
        }
    }
}
