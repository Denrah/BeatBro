//
//  LayerItemView.swift
//  MusicMakerYaCup
//
//  Created by Denis Sharapov on 26.11.2023.
//

import UIKit
import AVFoundation

class LayerItemViewModel {
    private let samplesPlayer = SamplePlayer()
    private let recordPlayer = AVPlayer()
    private(set) var isPlaying = false

    var onDidUpdate: (() -> Void)?

    var name: String {
        "\(layer.number) • \(layer.name)"
    }

    var isSelected: Bool {
        CompositionController.shared.activeLayer?.id == layer.id
    }

    var isMuted: Bool {
        layer.isMuted
    }

    var isLoopButtonHidden: Bool {
        if case .sample = layer.type {
            return true
        }
        return false
    }

    var isLooping: Bool {
        layer.isLooping
    }

    let layer: Layer

    init(layer: Layer) {
        self.layer = layer

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

        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(playerDidFinishPlaying(sender:)),
                         name: .AVPlayerItemDidPlayToEndTime,
                         object: recordPlayer.currentItem
            )
    }

    func stop() {
        samplesPlayer.stop()
        recordPlayer.pause()
        recordPlayer.seek(to: CMTime.zero)
    }

    @objc private func playerDidFinishPlaying(sender: Notification) {
        guard case .voice = layer.type else { return }
        guard (sender.object as? AVPlayerItem) === recordPlayer.currentItem else { return }
        if layer.isLooping == true {
            recordPlayer.seek(to: CMTime.zero)
            recordPlayer.play()
        } else {
            recordPlayer.pause()
        }
        onDidUpdate?()
    }

    func select() {
        CompositionController.shared.setActiveLayer(layerID: layer.id)
        onDidUpdate?()
    }

    func delete() {
        CompositionController.shared.deleteLayer(id: layer.id)
    }

    func mute() {
        CompositionController.shared.toggleLayerMute(id: layer.id)
        onDidUpdate?()
    }

    func loop() {
        CompositionController.shared.toggleLayerLoop(id: layer.id)
        onDidUpdate?()
    }

    func play() {
        guard !CompositionController.shared.isRecording, !CompositionController.shared.isCompositionPlaying else { return }

        isPlaying.toggle()

        if isPlaying {
            switch layer.type {
            case .sample:
                samplesPlayer.play()
            case .voice:
                recordPlayer.seek(to: CMTime.zero)
                recordPlayer.play()
            }
        } else {
            samplesPlayer.stop()
            recordPlayer.pause()
        }
        onDidUpdate?()
    }
}

class LayerItemView: UIView {
    private let titleLabel = UILabel()
    private let deleteButton = UIButton(type: .system)
    private let muteButton = UIButton(type: .system)
    private let playButton = UIButton(type: .system)
    private let loopButton = UIButton(type: .system)

    private(set) var viewModel: LayerItemViewModel?

    init() {
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func configure(with viewModel: LayerItemViewModel) {
        self.viewModel = viewModel
        titleLabel.text = viewModel.name
        backgroundColor = viewModel.isSelected ? .accent.withAlphaComponent(0.15) : .clear

        if viewModel.isMuted {
            muteButton.setImage(.muteIcon, for: .normal)
        } else {
            muteButton.setImage(.soundIcon, for: .normal)
        }

        loopButton.isHidden = viewModel.isLoopButtonHidden
        loopButton.tintColor = viewModel.isLooping ? .accent : .white

        viewModel.onDidUpdate = { [weak self] in
            self?.updateButtons()
        }

        updateButtons()
    }

    func stop() {
        viewModel?.stop()
        playButton.setImage(.playIcon, for: .normal)
    }

    private func setup() {
        setupContainer()
        setupTitleLabel()
        setupDeleteButton()
        setupMuteButton()
        setupPlayButton()
        setupLoopButton()
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
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

    private func setupLoopButton() {
        addSubview(loopButton)
        loopButton.setImage(.loopIcon, for: .normal)
        loopButton.tintColor = .white
        loopButton.snp.makeConstraints { make in
            make.size.equalTo(40)
            make.trailing.equalTo(playButton.snp.leading)
            make.centerY.equalToSuperview()
        }
        loopButton.addTarget(self, action: #selector(handleLoopButtonTap), for: .touchUpInside)
    }

    @objc private func handleTap() {
        viewModel?.select()
    }

    @objc private func handleDeleteButtonTap() {
        viewModel?.delete()
    }

    @objc private func handleMuteButtonTap() {
        viewModel?.mute()
    }

    @objc private func handlePlayButtonTap() {
        viewModel?.play()
    }

    @objc private func handleLoopButtonTap() {
        viewModel?.loop()
    }

    private func updateButtons() {
        if viewModel?.isLooping == false {
            playButton.setImage(.playIcon, for: .normal)
        }
        if viewModel?.isPlaying == true {
            playButton.setImage(.pauseIcon, for: .normal)
        } else {
            playButton.setImage(.playIcon, for: .normal)
        }
        if viewModel?.isMuted  == true {
            muteButton.setImage(.muteIcon, for: .normal)
        } else {
            muteButton.setImage(.soundIcon, for: .normal)
        }
    }
}

class LayerItemViewCell: UITableViewCell {
    private let itemView = LayerItemView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func configure(with viewModel: LayerItemViewModel) {
        itemView.configure(with: viewModel)
    }

    func stop() {
        itemView.stop()
    }

    private func setup() {
        backgroundColor = .clear
        selectionStyle = .none
        contentView.backgroundColor = .clear

        contentView.addSubview(itemView)
        itemView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
