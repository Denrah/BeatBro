//
//  CompositionController.swift
//  MusicMakerYaCup
//
//  Created by Denis Sharapov on 03.11.2023.
//

import Foundation
import AVFoundation
import Accelerate
import UIKit

class CompositionController {
    enum Constants {
        static let bufferSize = 1024
        static let barAmount = min(40, Int((UIScreen.main.bounds.width - 32) / 4))
    }

    var onActiveLayerUpdate: (() -> Void)?
    var onDidChangeLayers: (() -> Void)?
    var onDidFinishRecord: ((_ fileURL: URL) -> Void)?
    var onMagnitudesDidUpdate: (() -> Void)?
    var onStartPlayback: (() -> Void)?

    static let shared = CompositionController()

    var layersCount: Int {
        layers.count
    }

    var isCompositionPlaying: Bool {
        audioEngine.isRunning
    }

    private(set) var fftMagnitudes: [Float] = []

    private(set) var layers: [Layer] = []
    private(set) var activeLayer: Layer?

    private(set) var isRecording: Bool = false

    private var layersCounter = 1

    private var audioEngine = AVAudioEngine()
    private var mixer = AVAudioMixerNode()
    private var nodes: [UUID: AVAudioPlayerNode] = [:]

    private var writingFile: AVAudioFile?
    private var writingFileURL: URL?

    private let playbackQueue = DispatchQueue(label: "playback.queue", qos: .userInitiated)

    private init() {
        addInstrumentalLayer(sample: nil)
    }

    func addInstrumentalLayer(sample: Sample?) {
        let layer = Layer(number: layersCounter,
                          type: .sample(sample: sample ??  MusicalInstrument.drums.samples.first ?? Sample(name: "", url: nil, instrument: .drums),
                                        interval: 0.5,
                                        volume: 0.5))
        layers.append(layer)
        layersCounter += 1
        activeLayer = layer
        onActiveLayerUpdate?()
        onDidChangeLayers?()
        if audioEngine.isRunning {
            playLayer(layer)
        }
    }

    func addVocalLayer() {
        let layer = Layer(number: layersCounter,
                          type: .voice(url: nil))
        layers.append(layer)
        layersCounter += 1
        activeLayer = layer
        onActiveLayerUpdate?()
        onDidChangeLayers?()
        if audioEngine.isRunning {
            playLayer(layer)
        }
    }

    func setActiveLayer(layerID: UUID) {
        guard let layer = layers.first(where: { $0.id == layerID }) else { return }
        activeLayer = layer
        onActiveLayerUpdate?()
        onDidChangeLayers?()
    }

    func updateActiveLayer(sample: Sample? = nil,
                           interval: TimeInterval? = nil,
                           volume: Double? = nil) {
        activeLayer?.update(sample: sample, interval: interval, volume: volume)
        onActiveLayerUpdate?()
        if audioEngine.isRunning, let layer = activeLayer {
            nodes[layer.id]?.stop()
            nodes.removeValue(forKey: layer.id)
            playLayer(layer)
        }
    }

    func updateActiveLayer(recordURL: URL) {
        activeLayer?.update(recordURL: recordURL)
        onActiveLayerUpdate?()
        if audioEngine.isRunning, let layer = activeLayer {
            nodes[layer.id]?.stop()
            nodes.removeValue(forKey: layer.id)
            playLayer(layer)
        }
    }

    func deleteLayer(id: UUID) {
        nodes[id]?.stop()
        nodes.removeValue(forKey: id)
        layers.removeAll { $0.id == id }
        if activeLayer?.id == id {
            activeLayer = layers.first
        }
        if layers.isEmpty {
            layersCounter = 1
            addInstrumentalLayer(sample: nil)
        }
        onActiveLayerUpdate?()
        onDidChangeLayers?()
    }

    func toggleLayerMute(id: UUID) {
        guard let layer = layers.first(where: { $0.id == id }) else { return }
        layer.isMuted.toggle()
        onActiveLayerUpdate?()
        nodes[id]?.volume = layer.isMuted ? 0 : 1
    }

    func toggleLayerLoop(id: UUID) {
        guard let layer = layers.first(where: { $0.id == id }) else { return }
        layer.isLooping.toggle()
        onActiveLayerUpdate?()
        onDidChangeLayers?()
        nodes[id]?.volume = layer.isMuted ? 0 : 1
        if (isRecording || isCompositionPlaying) && layer.isLooping && !layer.isPlaying {
            playLayer(layer)
        }
    }

    func playComposition(shouldAddTap: Bool = true) {
        onStartPlayback?()
        
        audioEngine.stop()

        audioEngine = AVAudioEngine()
        mixer = AVAudioMixerNode()

        audioEngine.attach(mixer)
        audioEngine.connect(mixer, to: audioEngine.outputNode, format: nil)

        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
        try? AVAudioSession.sharedInstance().setActive(true)

        try? audioEngine.start()

        layers.forEach { layer in
            playLayer(layer)
        }

        if shouldAddTap {
            let fftSetup = vDSP_DFT_zop_CreateSetup(
                nil,
                UInt(Constants.bufferSize),
                vDSP_DFT_Direction.FORWARD
            )

            mixer.installTap(onBus: 0,
                             bufferSize: UInt32(Constants.bufferSize),
                             format: nil) { [weak self] buffer, _ in
                guard let data = buffer.floatChannelData?[0], let setup = fftSetup else { return }
                self?.fftMagnitudes = self?.fft(data: data, setup: setup) ?? []
                self?.onMagnitudesDidUpdate?()
            }
        }
    }

    func stopComposition() {
        audioEngine.stop()
        fftMagnitudes = [Float](repeating: 0, count: Constants.bufferSize)
        onMagnitudesDidUpdate?()
    }

    func recordComposition() throws {
        let fileURL = getDocumentsDirectory().appendingPathComponent("BeatBro_Song_\(Int(Date().timeIntervalSince1970)).wav")
        self.writingFileURL = fileURL
        writingFile = try AVAudioFile(forWriting: fileURL,
                                      settings: mixer.outputFormat(forBus: 0).settings,
                                      commonFormat: .pcmFormatFloat32,
                                      interleaved: false)
        playComposition(shouldAddTap: false)

        let fftSetup = vDSP_DFT_zop_CreateSetup(
            nil,
            UInt(Constants.bufferSize),
            vDSP_DFT_Direction.FORWARD
        )

        mixer.installTap(onBus: 0,
                         bufferSize: AVAudioFrameCount(Constants.bufferSize),
                         format: mixer.outputFormat(forBus: 0)) { [weak self] buffer, _ in
            do {
                try self?.writingFile?.write(from: buffer)
            } catch {
                print(error)
            }
            guard let data = buffer.floatChannelData?[0], let setup = fftSetup else { return }
            self?.fftMagnitudes = self?.fft(data: data, setup: setup) ?? []
            self?.onMagnitudesDidUpdate?()
        }
        isRecording = isCompositionPlaying
    }

    func stopRecord() {
        stopComposition()
        writingFile = nil
        isRecording = false

        if let url = writingFileURL {
            onDidFinishRecord?(url)
        }
    }

    private func playLayer(_ layer: Layer) {
        playbackQueue.async { [weak self] in
            guard let self = self else { return }
            let node = AVAudioPlayerNode()
            audioEngine.attach(node)
            audioEngine.connect(node, to: mixer, format: nil)
            switch layer.type {
            case .sample(let sample, let interval, let volume):
                if let url = sample.url, let file = try? AVAudioFile(forReading: url) {
                    node.volume = layer.isMuted ? 0 : Float(volume)
                    scheduleFile(file, node: node, interval: interval)
                }
            case .voice(let url):
                if let url = url, let file = try? AVAudioFile(forReading: url) {
                    node.volume = layer.isMuted ? 0 : 1
                    scheduleVocal(file, node: node, layer: layer)
                }
            }
            if audioEngine.isRunning {
                node.play()
            }
            nodes[layer.id] = node
        }
    }

    private func scheduleFile(_ file: AVAudioFile, node: AVAudioPlayerNode, interval: TimeInterval) {
        node.stop()
        node.scheduleFile(file, at: nil)
        playbackQueue.asyncAfter(deadline: .now() + interval) { [weak self, weak node, weak file] in
            guard self?.audioEngine.isRunning == true, let node = node, let file = file else { return }
            self?.scheduleFile(file, node: node, interval: interval)
        }
        if audioEngine.isRunning {
            node.play()
        }
    }

    private func scheduleVocal(_ file: AVAudioFile, node: AVAudioPlayerNode, layer: Layer) {
        layer.isPlaying = true
        node.stop()
        node.scheduleFile(file, at: nil)
        let interval = Double(file.length) / file.processingFormat.sampleRate
        playbackQueue.asyncAfter(deadline: .now() + interval) { [weak self, weak node, weak file, weak layer] in
            layer?.isPlaying = false
            guard self?.audioEngine.isRunning == true, let node = node, let file = file, let layer = layer, layer.isLooping else { return }
            self?.scheduleVocal(file, node: node, layer: layer)
        }
        if audioEngine.isRunning {
            node.play()
        }
    }

    private func fft(data: UnsafeMutablePointer<Float>, setup: OpaquePointer) -> [Float] {
        var realIn = [Float](repeating: 0, count: Constants.bufferSize)
        var imagIn = [Float](repeating: 0, count: Constants.bufferSize)
        var realOut = [Float](repeating: 0, count: Constants.bufferSize)
        var imagOut = [Float](repeating: 0, count: Constants.bufferSize)

        for i in 0 ..< Constants.bufferSize {
            realIn[i] = data[i]
        }

        vDSP_DFT_Execute(setup, &realIn, &imagIn, &realOut, &imagOut)

        var magnitudes = [Float](repeating: 0, count: Constants.barAmount)

        realOut.withUnsafeMutableBufferPointer { realBP in
            imagOut.withUnsafeMutableBufferPointer { imagBP in
                var complex = DSPSplitComplex(realp: realBP.baseAddress!, imagp: imagBP.baseAddress!)
                vDSP_zvabs(&complex, 1, &magnitudes, 1, UInt(Constants.barAmount))
            }
        }

        var normalizedMagnitudes = [Float](repeating: 0.0, count: Constants.barAmount)
        var mean = Float(0)
        var sddev = Float(0)
        vDSP_normalize(&magnitudes, 1, &normalizedMagnitudes, 1, &mean, &sddev, UInt(Constants.barAmount))

        return normalizedMagnitudes
    }

    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}
