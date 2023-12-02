//
//  ReplayAudioPlayer.swift
//  MusicMakerYaCup
//
//  Created by Denis Sharapov on 02.12.2023.
//

import AVFoundation
import Accelerate

class ReplayAudioPlayer {
    static let shared = ReplayAudioPlayer()

    var isPlaying: Bool {
        fileNode?.isPlaying ?? false
    }

    private(set) var fftMagnitudes: [Float] = []
    var onVisualizerMagnitudesDidUpdate: (() -> Void)?
    var onPlaybackComplete: (() -> Void)?

    private var audioEngine = AVAudioEngine()
    private var mixer = AVAudioMixerNode()

    private var fileNode: AVAudioPlayerNode?

    private init() {}

    func currentTime() -> TimeInterval {
        if let nodeTime = fileNode?.lastRenderTime,
           let playerTime = fileNode?.playerTime(forNodeTime: nodeTime) {
           return Double(Double(playerTime.sampleTime) / playerTime.sampleRate)
        }
        return 0
    }

    func stop() {
        fileNode?.stop()
    }

    func playFile(_ url: URL?) {
        audioEngine.stop()

        audioEngine = AVAudioEngine()
        mixer = AVAudioMixerNode()

        audioEngine.attach(mixer)
        audioEngine.connect(mixer, to: audioEngine.outputNode, format: nil)

        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
        try? AVAudioSession.sharedInstance().setActive(true)

        try? audioEngine.start()

        let node = AVAudioPlayerNode()
        self.fileNode = node
        audioEngine.attach(node)
        audioEngine.connect(node, to: mixer, format: nil)

        if let url = url, let file = try? AVAudioFile(forReading: url) {
            node.scheduleFile(file, at: nil, completionCallbackType: .dataPlayedBack) { [weak self] _ in
                self?.onPlaybackComplete?()
            }
        }

        if audioEngine.isRunning {
            node.play()
        }

        let fftSetup = vDSP_DFT_zop_CreateSetup(
            nil,
            UInt(CompositionController.Constants.bufferSize),
            vDSP_DFT_Direction.FORWARD
        )

        mixer.installTap(onBus: 0,
                         bufferSize: UInt32(CompositionController.Constants.bufferSize),
                         format: nil) { [weak self] buffer, _ in
            guard let data = buffer.floatChannelData?[0], let setup = fftSetup else { return }
            self?.fftMagnitudes = self?.fft(data: data, setup: setup) ?? []
            self?.onVisualizerMagnitudesDidUpdate?()
        }
    }

    private func fft(data: UnsafeMutablePointer<Float>, setup: OpaquePointer) -> [Float] {
        var realIn = [Float](repeating: 0, count: CompositionController.Constants.bufferSize)
        var imagIn = [Float](repeating: 0, count: CompositionController.Constants.bufferSize)
        var realOut = [Float](repeating: 0, count: CompositionController.Constants.bufferSize)
        var imagOut = [Float](repeating: 0, count: CompositionController.Constants.bufferSize)

        for i in 0 ..< CompositionController.Constants.bufferSize {
            realIn[i] = data[i]
        }

        vDSP_DFT_Execute(setup, &realIn, &imagIn, &realOut, &imagOut)

        var magnitudes = [Float](repeating: 0, count: CompositionController.Constants.barAmount)

        realOut.withUnsafeMutableBufferPointer { realBP in
            imagOut.withUnsafeMutableBufferPointer { imagBP in
                var complex = DSPSplitComplex(realp: realBP.baseAddress!, imagp: imagBP.baseAddress!)
                vDSP_zvabs(&complex, 1, &magnitudes, 1, UInt(CompositionController.Constants.barAmount))
            }
        }

        var normalizedMagnitudes = [Float](repeating: 0.0, count: CompositionController.Constants.barAmount)
        var mean = Float(0)
        var sddev = Float(0)
        vDSP_normalize(&magnitudes, 1, &normalizedMagnitudes, 1, &mean, &sddev, UInt(CompositionController.Constants.barAmount))

        return normalizedMagnitudes
    }
}
