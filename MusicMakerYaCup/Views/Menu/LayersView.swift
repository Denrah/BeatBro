//
//  LayersView.swift
//  MusicMakerYaCup
//
//  Created by Denis Sharapov on 02.11.2023.
//

import UIKit
import AVFoundation
import SnapKit

class LayerItemView: UIView {
    private let titleLabel = UILabel()
    private let deleteButton = UIButton(type: .system)
    private let muteButton = UIButton(type: .system)
    private let playButton = UIButton(type: .system)

    private let samplesPlayer = SampleConfigurationPadPlayer()
    private let recordPlayer = AVPlayer()
    private var isPlaying = false

    private(set) var layerModel: Layer?

    init() {
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func configure(with layer: Layer) {
        self.layerModel = layer
        titleLabel.text = "\(layer.number) • \(layer.name)"
        backgroundColor = CompositionController.shared.activeLayer?.id == layer.id ? .accent.withAlphaComponent(0.15) : .clear
        if layer.isMuted {
            muteButton.setImage(.muteIcon, for: .normal)
        } else {
            muteButton.setImage(.soundIcon, for: .normal)
        }

        switch layer.type {
        case .sample(let sample, let interval, let volume):
            if let url = sample.url {
                samplesPlayer.setSampleURL(url)
            }
            samplesPlayer.setInterval(interval)
            samplesPlayer.setVolume(volume)
        case .voice(let url):
            if let url = url {
                let item = AVPlayerItem(url: url)
                recordPlayer.replaceCurrentItem(with: item)
            }
        }
    }

    private func setup() {
        setupContainer()
        setupTitleLabel()
        setupDeleteButton()
        setupMuteButton()
        setupPlayButton()
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))

        NotificationCenter.default
            .addObserver(self,
            selector: #selector(playerDidFinishPlaying(sender:)),
            name: .AVPlayerItemDidPlayToEndTime,
            object: recordPlayer.currentItem
        )
    }

    @objc private func playerDidFinishPlaying(sender: Notification) {
        guard case .voice = layerModel?.type else { return }
        guard (sender.object as? AVPlayerItem) === recordPlayer.currentItem else { return }
        recordPlayer.seek(to: CMTime.zero)
        recordPlayer.play()
    }

    private func setupContainer() {
        snp.makeConstraints { make in
            make.height.equalTo(48)
        }
    }

    private func setupTitleLabel() {
        addSubview(titleLabel)
        titleLabel.font = .systemFont(ofSize: 16)
        titleLabel.textColor = .white
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().inset(16)
        }
    }

    private func setupDeleteButton() {
        addSubview(deleteButton)
        deleteButton.setImage(.closeIcon, for: .normal)
        deleteButton.tintColor = .white
        deleteButton.snp.makeConstraints { make in
            make.size.equalTo(40)
            make.trailing.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()
        }
        deleteButton.addTarget(self, action: #selector(handleDeleteButtonTap), for: .touchUpInside)
    }

    private func setupMuteButton() {
        addSubview(muteButton)
        muteButton.setImage(.soundIcon, for: .normal)
        muteButton.tintColor = .white
        muteButton.snp.makeConstraints { make in
            make.size.equalTo(40)
            make.trailing.equalTo(deleteButton.snp.leading)
            make.centerY.equalToSuperview()
        }
        muteButton.addTarget(self, action: #selector(handleMuteButtonTap), for: .touchUpInside)
    }

    private func setupPlayButton() {
        addSubview(playButton)
        playButton.setImage(.playIcon, for: .normal)
        playButton.tintColor = .white
        playButton.snp.makeConstraints { make in
            make.size.equalTo(40)
            make.trailing.equalTo(muteButton.snp.leading)
            make.centerY.equalToSuperview()
        }
        playButton.addTarget(self, action: #selector(handlePlayButtonTap), for: .touchUpInside)
    }

    @objc private func handleTap() {
        guard let layerID = layerModel?.id else { return }
        CompositionController.shared.setActiveLayer(layerID: layerID)
    }

    @objc private func handleDeleteButtonTap() {
        guard let id = layerModel?.id else { return }
        CompositionController.shared.deleteLayer(id: id)
    }

    @objc private func handleMuteButtonTap() {
        guard let id = layerModel?.id else { return }
        CompositionController.shared.toggleLayerMute(id: id)
    }

    @objc private func handlePlayButtonTap() {
        guard !CompositionController.shared.isRecording, !CompositionController.shared.isCompositionPlaying else { return }

        isPlaying.toggle()

        if isPlaying {
            switch layerModel?.type {
            case .sample:
                samplesPlayer.play()
            case .voice:
                recordPlayer.seek(to: CMTime.zero)
                recordPlayer.play()
            default:
                break
            }
            playButton.setImage(.pauseIcon, for: .normal)
        } else {
            samplesPlayer.stop()
            recordPlayer.pause()
            playButton.setImage(.playIcon, for: .normal)
        }
    }
}

class LayersView: UIView {

    private let scrollView = UIScrollView()
    private let stackView = UIStackView()

    private var heightConstraint: Constraint?

    init() {
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func update() {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        var activeIndex = 0
        CompositionController.shared.layers.enumerated().forEach { index, layer in
            let item = LayerItemView()
            item.configure(with: layer)
            stackView.addArrangedSubview(item)
            activeIndex = CompositionController.shared.activeLayer?.id == layer.id ? index : activeIndex
        }
        let height = min(CGFloat(stackView.arrangedSubviews.count * 48), UIScreen.main.bounds.height / 2)
        heightConstraint?.update(offset: height)
        layoutIfNeeded()
        scrollView.scrollRectToVisible(stackView.arrangedSubviews[activeIndex].frame, animated: true)
    }

    private func setup() {
        setupContainer()
        setupScrollView()
        setupStackView()
        update()
    }

    private func setupContainer() {
        backgroundColor = .surface
        layer.cornerRadius = 8
        layer.shadowOffset = CGSize(width: 0, height: 6)
        layer.shadowRadius = 16
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.3
    }

    private func setupScrollView() {
        addSubview(scrollView)
        scrollView.showsVerticalScrollIndicator = false
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            heightConstraint = make.height.equalTo(0).constraint
        }
    }

    private func setupStackView() {
        scrollView.addSubview(stackView)
        stackView.layer.cornerRadius = 8
        stackView.clipsToBounds = true
        stackView.axis = .vertical
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
    }
}
