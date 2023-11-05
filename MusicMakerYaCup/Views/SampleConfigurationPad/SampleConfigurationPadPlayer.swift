//
//  SampleConfigurationPadPlayer.swift
//  MusicMakerYaCup
//
//  Created by Denis Sharapov on 01.11.2023.
//

import Foundation
import AVFoundation

class SampleConfigurationPadPlayer {
    enum Constants {
        static let minBPM: Double = 60
        static let maxBPM: Double = 180
        static let minVolume: Double = 0
        static let maxVolume: Double = 1
    }

    var onDidPlay: ((_ timerInterval: TimeInterval) -> Void)?

    var volume: Double {
        Double(player.volume)
    }

    private(set) var timerInterval: TimeInterval = 0.5

    private let player = AVPlayer()
    private var timer: Timer?
    private var isPlaying = false
    private var lastPlayDate = Date()

    func setSampleURL(_ url: URL) {
        let playerItem =  AVPlayerItem(url: url)
        player.replaceCurrentItem(with: playerItem)
    }

    func setBPMFraction(_ fraction: Double) {
        let oldInterval = timerInterval
        timerInterval = 1 / ((Constants.minBPM + (Constants.maxBPM - Constants.minBPM) * fraction) / 60)
        guard oldInterval != timerInterval else { return }
        if isPlaying {
            play(shouldFire: false)
            if lastPlayDate.addingTimeInterval(timerInterval) <= Date() {
                timer?.fire()
            }
        }
    }

    func setVolumeFraction(_ fraction: Double) {
        player.volume = Float((Constants.minVolume + Constants.maxVolume) * fraction)
    }

    func setInterval(_ interval: TimeInterval) {
        timerInterval = interval
    }

    func setVolume(_ volume: Double) {
        player.volume = Float(volume)
    }

    func play(shouldFire: Bool = true) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: true) { [weak self] _ in
            self?.player.seek(to: CMTime.zero)
            self?.player.play()
            self?.lastPlayDate = Date()
            self?.onDidPlay?(self?.timerInterval ?? 0)
        }
        if shouldFire {
            timer?.fire()
        }
        isPlaying = true
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isPlaying = false
    }
}
