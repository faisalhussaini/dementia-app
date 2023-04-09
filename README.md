# Familiar Faces
![image](https://user-images.githubusercontent.com/64606546/230535601-96059f5e-029a-4d33-bec6-f3e7f3c24ba2.png)

## This is the swift frontend for our virtual presence software for agitated inpatients with dementia, our final year ECE496 capstone project at the University of Toronto. It goes hand in hand with the backend located here https://github.com/hassank1187/Capstone_server

### This app can be broken down into 5 parts. 

#### The first two parts are the views that the user interacts with to see the lists of patients and their respective loved ones. 
* PatientView.swift and LovedOneView.swift: 
* Navigation links allows the user to intuitively view all patients and then traverse all loved ones that correspond to that patient. It also allows the user to delete patients and loved ones. 

#### The next two parts that are the views that the user uses to create a new patient and loved one respectively. 
* newPatientView.swift: 
* This view used to add a new patient allows the user to conveniently fill in personal information about the patient needed for chatbot  training. The view specifies what questions are mandatory in red and also has a prevention mechanism to prevent invalid input. 
* newLovedOneView.swift: 
* This view, used to add a loved one, is similar but contains extra functionality for the loved one to record and upload an audio clip of them speaking using AVFoundation (for voice cloning), as well as use the camera to upload a video to generate the deepfakes.

#### The fifth part is the call view.
* CallView.swift: 
* This view allows the user to make a call with a loved one. This view will listen to the user’s speech and detect when they stop speaking, use speech recognition to convert it to text using the Speech framework, and then play the appropriate video response that the backend sent back with AVKit. It will then begin the cycle again to let the user have a continuous conversation. It also has a prompting functionality where the patient is prompted with a stimulating and personalized question in the case that they are not actively participating in the conversation.

#### DementiaAppApp.swift is the entry point of the app 
* It also contains global variables that dictate the prompt time, whether or not a video of the loved one nodding should play between clips, the backend IP and port, etc.

#### The rest of the files contain helper functions for: 
1. Speech recognition (SpeechManager.swift, MicManager.swift)
2. Recording and playing an audio sample (AudioRecorder.swift, AudioPlayer.swift, RecordingsList.swift)
3. Recording a video (VideoRecorder.swift)

# Instructions to run on Xcode
## This project is compatible with iOS devices with iOS 15+.
## You can clone this project from within Xcode, or download it from git. Make sure to open the xcworkspace and not the xcodeproj.
## This project requires Alamofire to work. To make sure this runs without any issues, please do the following:

1) brew install cocoapods
2) go the directory containing the Podfile, and run: "pod install"
-> This allows Alamofire to work.
3) Build Xcode project as usual


Note:
If you get into the project and it says something about a missing xc environment, do:
1) goto General Project settings
2) scroll down to Frameworks, Libraries, and Embedded Content
3) Finally make sure the one package that is there has Embed label: Embed & Sign
-> If not, change it to Embed and Sign, then rebuild and all will be well

# Demonstration without clip between responses
https://user-images.githubusercontent.com/64606546/230792729-f934d7e3-3805-4981-a86f-5dacd381a47b.mp4

# Demonstration with clip between responses
https://user-images.githubusercontent.com/64606546/230792765-830b91a2-6bcb-4443-aa9a-e6d01bfec938.mp4



