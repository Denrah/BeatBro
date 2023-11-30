//
//  SampleMenuItemView.swift
//  MusicMakerYaCup
//
//  Created by Denis Sharapov on 26.11.2023.
//

import UIKit
import AVFoundation

class SampleMenuItemView: UIView {
    private(set) var sample: Sample?

    private let titleLabel = UILabel()
    private var player: AVPlayer?
    private var shouldPlay = true

    var isHighlighted: Bool = false {
        didSet {
            backgroundColor = isHighlighted ? .accent.withAlphaComponent(0.15) : .clear
            if isHighlighted, shouldPlay {
                player?.seek(to: CMTime.zero)
                player?.play()
                shouldPlay = false
            }
            shouldPlay = !isHighlighted
        }
    }

    init() {
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func configure(with sample: Sample) {
        self.sample = sample
        titleLabel.text = sample.name
        if let url = sample.url {
            player = AVPlayer(url: url)
        }
    }

    private func setup() {
        addSubview(titleLabel)
        titleLabel.font = .systemFont(ofSize: 16)
        titleLabel.textColor = .white
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}
