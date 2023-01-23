//
//  RecordingsList.swift
//  mic
//
//  Created by Faisal Hussaini on 2022-10-01.
//

import SwiftUI

struct RecordingsList: View {
    
    @ObservedObject var audioRecorder: AudioRecorder
    @State private var recording: RecordingRow?
    var body: some View {
        List {
            ForEach(audioRecorder.recordings, id: \.id) { recording in
                RecordingRow(audioURL: recording.fileURL)
            }
            .onDelete(perform: delete)
        }
    }
    func delete(at offsets: IndexSet) {//set of indexes of recording rows that the user has chosen to delete
        
        var urlsToDelete = [URL]()//array of the file paths of the recordings to be deleted
        for index in offsets {
            urlsToDelete.append(audioRecorder.recordings[index].fileURL)
        }
        audioRecorder.deleteRecording(urlsToDelete: urlsToDelete)
    }
    func isEmpty() {
        return
    }
}

struct RecordingRow: View { //to display one row for each stored recording
    
    var audioURL: URL
    
    @ObservedObject var audioPlayer = AudioPlayer() //each recordingrow needs its own audio player for the respective audio recording
    //initialize one seperate audio player instance as an obersvedobject for each recording row
    
    var body: some View {
        HStack {
            Text("\(audioURL.lastPathComponent)")
            Spacer()
            if audioPlayer.isPlaying == false { //if its not playing, we want to display a play button that allows the user to listen to the recording
                Button(action: {
                    self.audioPlayer.startPlayback(audio: self.audioURL)
                }) {
                    Image(systemName: "play.circle")
                        .imageScale(.large)
                }
            } else { //if it is playing, display a button to stop the playback
                Button(action: {
                    self.audioPlayer.stopPlayback()
                }) {
                    Image(systemName: "stop.fill")
                        .imageScale(.large)
                }
            }
        }
    }
}


struct RecordingsList_Previews: PreviewProvider {
    static var previews: some View {
        RecordingsList(audioRecorder: AudioRecorder())
    }
}
