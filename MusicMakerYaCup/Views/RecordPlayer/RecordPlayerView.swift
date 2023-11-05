//
//  RecordPlayerView.swift
//  MusicMakerYaCup
//
//  Created by Denis Sharapov on 03.11.2023.
//

import UIKit
import AVFoundation

class RecordPlayerView: UIView {
    var isRecordingInProcess = false {
        didSet {
            if isRecordingInProcess {
                button.isHidden = true
                label.isHidden = false
            } else {
                button.isHidden = false
                label.isHidden = true
            }
        }
    }

    private let button = UIButton(type: .system)
    private let label = UILabel()
    private let audioPlayer = AVPlayer()

    init() {
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func setAudio(url: URL) {
        let item = AVPlayerItem(url: url)
        audioPlayer.replaceCurrentItem(with: item)
    }

    func stop() {
        button.setImage(.playCircleIcon, for: .normal)
        audioPlayer.pause()
        audioPlayer.seek(to: CMTime.zero)
    }

    private func setup() {
        addSubview(button)
        button.tintColor = .accent
        button.setImage(.playCircleIcon, for: .normal)
        button.contentHorizontalAlignment = .fill;
        button.contentVerticalAlignment = .fill;
        button.snp.makeConstraints { make in
            make.size.equalTo(88)
            make.edges.equalToSuperview()
        }
        button.addTarget(self, action: #selector(handleButtonTap), for: .touchUpInside)

        addSubview(label)
        label.textColor = .white
        label.font = .systemFont(ofSize: 16)
        label.isHidden = true
        label.text = "Идет запись..."
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(playerDidFinishPlaying(sender:)),
                         name: .AVPlayerItemDidPlayToEndTime,
                         object: audioPlayer.currentItem
            )
    }

    @objc private func playerDidFinishPlaying(sender: Notification) {
        guard (sender.object as? AVPlayerItem) === audioPlayer.currentItem else { return }
        audioPlayer.seek(to: CMTime.zero)
        audioPlayer.play()
    }

    @objc private func handleButtonTap() {
        if audioPlayer.rate > 0 {
            button.setImage(.playCircleIcon, for: .normal)
            audioPlayer.pause()
        } else {
            button.setImage(.pauseCircleIcon, for: .normal)
            audioPlayer.seek(to: CMTime.zero)
            audioPlayer.play()
        }
    }
}
