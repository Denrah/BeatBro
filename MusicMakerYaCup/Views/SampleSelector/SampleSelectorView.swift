//
//  SampleSelectorView.swift
//  MusicMakerYaCup
//
//  Created by Denis Sharapov on 02.11.2023.
//

import UIKit
import AVFoundation

class SampleSelectorView: UIView {
    var onDidSelectSample: ((_ sample: Sample) -> Void)?

    private let categoriesStackView = UIStackView()
    private let samplesStackContainerView = UIView()
    private let samplesStackView = UIStackView()
    private let hintContainerView = UIView()
    private let hintLabel = UILabel()

    private let player = AVPlayer()

    private(set) var selectedSample: Sample? = MusicalInstrument.drums.samples.first

    private var isHintShown = false

    init() {
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        setupCategoriesStackView()
        setupSamplesStackView()
        setupHint()

        MusicalInstrument.allCases.forEach { instrument in
            let itemView = SampleSelectorItemView()
            itemView.configure(instrument)
            itemView.onShortTap = { [weak self] in
                if let sample = instrument.samples.first {
                    if let url = sample.url {
                        self?.player.replaceCurrentItem(with: AVPlayerItem(url: url))
                        self?.player.seek(to: CMTime.zero)
                        self?.player.play()
                    }
                    self?.showHint()
                    self?.onDidSelectSample?(sample)
                }
            }
            itemView.onLongTap = { [weak self] location in
                self?.updateSamples(instrument: instrument)
                self?.showAllSamples()
                self?.isHintShown = true
                self?.handleSelectionMove(location: location)
            }
            itemView.onEndLongTap = { [weak self] in
                self?.hideAllSamples()
                if let sample = self?.selectedSample {
                    self?.onDidSelectSample?(sample)
                }
            }
            itemView.onMoveLongTap = { [weak self] location in
                self?.handleSelectionMove(location: location)
            }
            categoriesStackView.addArrangedSubview(itemView)
        }
    }

    private func setupCategoriesStackView() {
        addSubview(categoriesStackView)
        categoriesStackView.distribution = .equalSpacing
        categoriesStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setupSamplesStackView() {
        addSubview(samplesStackContainerView)
        samplesStackContainerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        samplesStackContainerView.layer.shadowRadius = 16
        samplesStackContainerView.layer.shadowColor = UIColor.black.cgColor
        samplesStackContainerView.layer.shadowOpacity = 0.3
        samplesStackContainerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(snp.top).offset(-8)
            make.height.equalTo(48)
        }

        samplesStackContainerView.addSubview(samplesStackView)
        samplesStackView.backgroundColor = .surface
        samplesStackView.clipsToBounds = true
        samplesStackView.layer.cornerRadius = 8
        samplesStackView.distribution = .fillEqually
        samplesStackView.alpha = 0
        samplesStackView.transform = CGAffineTransform(translationX: 0, y: 8)
        samplesStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setupHint() {
        addSubview(hintContainerView)
        hintContainerView.backgroundColor = .surfaceLight
        hintContainerView.layer.cornerRadius = 8
        hintContainerView.alpha = 0
        hintContainerView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
            make.bottom.equalTo(self.snp.top).offset(-16)
        }

        hintContainerView.addSubview(hintLabel)
        hintLabel.font = .systemFont(ofSize: 16)
        hintLabel.textColor = .white
        hintLabel.numberOfLines = 0
        hintLabel.textAlignment = .center
        hintLabel.text = "Зажмите иконку инструмента, чтобы увидеть больше вариантов"
        hintLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
    }

    private func showHint() {
        guard !isHintShown else { return }
        isHintShown = true

        hintContainerView.alpha = 0
        hintContainerView.transform = CGAffineTransform(translationX: 0, y: 8)

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            self.hintContainerView.alpha = 1
            self.hintContainerView.transform = .identity
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
                self.hintContainerView.alpha = 0
                self.hintContainerView.transform = CGAffineTransform(translationX: 0, y: -8)
            }
        }
    }

    private func showAllSamples() {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
            self.samplesStackView.alpha = 1
            self.samplesStackView.transform = .identity
            self.hintContainerView.alpha = 0
            self.hintContainerView.transform = CGAffineTransform(translationX: 0, y: -8)
        }
    }

    private func hideAllSamples() {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
            self.samplesStackView.alpha = 0
            self.samplesStackView.transform = CGAffineTransform(translationX: 0, y: 8)
        }
    }

    private func handleSelectionMove(location: CGPoint) {
        samplesStackView.layoutIfNeeded()
        
        samplesStackView.arrangedSubviews.forEach { item in
            if item.frame.minX <= location.x, item.frame.maxX >= location.x {
                (item as? SampleMenuItemView)?.isHighlighted = true
                selectedSample = (item as? SampleMenuItemView)?.sample
            } else {
                (item as? SampleMenuItemView)?.isHighlighted = false
            }
        }

        if location.x < samplesStackView.arrangedSubviews.first?.frame.minX ?? 0 {
            (samplesStackView.arrangedSubviews.first as? SampleMenuItemView)?.isHighlighted = true
            selectedSample = (samplesStackView.arrangedSubviews.first as? SampleMenuItemView)?.sample
        }

        if location.x > samplesStackView.arrangedSubviews.last?.frame.maxX ?? 0 {
            (samplesStackView.arrangedSubviews.last as? SampleMenuItemView)?.isHighlighted = true
            selectedSample = (samplesStackView.arrangedSubviews.last as? SampleMenuItemView)?.sample
        }
    }

    private func updateSamples(instrument: MusicalInstrument) {
        samplesStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        instrument.samples.forEach { sample in
            let item = SampleMenuItemView()
            item.configure(with: sample)
            samplesStackView.addArrangedSubview(item)
        }
    }
}
