//
//  Layer.swift
//  MusicMakerYaCup
//
//  Created by Denis Sharapov on 03.11.2023.
//

import Foundation

class Layer {
    enum LayerType {
        case sample(sample: Sample, interval: TimeInterval, volume: Double)
        case voice(url: URL?)
    }

    let id = UUID()
    var number: Int
    var type: LayerType
    var isMuted = false

    var name: String {
        switch type {
        case .sample(let sample, _, _):
            return "\(sample.instrument.name) – \(sample.name)"
        case .voice:
            return "Запись"
        }
    }

    init(number: Int, type: LayerType) {
        self.number = number
        self.type = type
    }

    func update(sample: Sample? = nil, interval: TimeInterval? = nil, volume: Double? = nil) {
        guard case .sample(let oldSample, let oldInterval, let oldVolume) = type else {
            return
        }
        type = .sample(sample: sample ?? oldSample,
                       interval: interval ?? oldInterval,
                       volume: volume ?? oldVolume)
    }

    func update(recordURL: URL) {
        guard case .voice = type else {
            return
        }
        type = .voice(url: recordURL)
    }
}
