//
//  AudioVisualizerView.swift
//  MusicMakerYaCup
//
//  Created by Denis Sharapov on 03.11.2023.
//

import UIKit

class AudioVisualizerView: UIView {
    private let stackView = UIStackView()

    init() {
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func setupBars(data: [Float]) {
        stackView.arrangedSubviews.enumerated().forEach { index, view in
            view.snp.remakeConstraints { make in
                make.width.equalTo(2)
                make.height.equalTo(min(48, max(2, data[index] * 8)))
            }
        }
    }

    private func setup() {
        addSubview(stackView)
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(48)
        }

        for _ in 1...CompositionController.Constants.barAmount {
            let view = UIView()
            view.backgroundColor = .accent
            view.layer.cornerRadius = 1
            view.snp.makeConstraints { make in
                make.size.equalTo(2)
            }
            stackView.addArrangedSubview(view)
        }
    }
}
