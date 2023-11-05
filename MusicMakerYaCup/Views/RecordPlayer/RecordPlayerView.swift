//
//  RecordPlayerView.swift
//  MusicMakerYaCup
//
//  Created by Denis Sharapov on 03.11.2023.
//

import UIKit
import AVFoundation

class RecordPlayerView: UIView {
    private let button = UIButton(type: .system)
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

        NotificationCenter.default
            .addObserver(self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: audioPlayer.currentItem
        )
    }

    @objc private func playerDidFinishPlaying() {
        button.setImage(.playCircleIcon, for: .normal)
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
