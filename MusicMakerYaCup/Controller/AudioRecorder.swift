//
//  AudioRecorder.swift
//  MusicMakerYaCup
//
//  Created by Denis Sharapov on 03.11.2023.
//

import AVFoundation

class AudioRecorder: NSObject {
    var onDidFinishRecording: ((_ fileURL: URL?, _ success: Bool) -> Void)?

    private let recordingSession = AVAudioSession.sharedInstance()
    private var audioRecorder: AVAudioRecorder?
    private var fileURL: URL?

    func requestPermissions(completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { allowed in
                DispatchQueue.main.async {
                    if allowed {
                        completion(.success(()))
                    } else {
                        completion(.failure(NSError(domain: "Permission not granted", code: 403)))
                        showError?("Permission not granted")
                    }
                }
            }
        } catch {
            completion(.failure(error))
            showError?(error.localizedDescription)
        }
    }

    func startRecording() throws {
        try recordingSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try recordingSession.setActive(true)

        let audioFilename = getDocumentsDirectory().appendingPathComponent("\(UUID().uuidString).m4a")
        fileURL = audioFilename

        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
        audioRecorder?.delegate = self
        audioRecorder?.record()
    }

    func stopRecording() {
        finishRecording(success: true)
    }

    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    private func finishRecording(success: Bool) {
        audioRecorder?.stop()
        onDidFinishRecording?(fileURL, success)
        audioRecorder = nil
    }
}

extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
}
