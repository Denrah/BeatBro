//
//  MenuView.swift
//  MusicMakerYaCup
//
//  Created by Denis Sharapov on 02.11.2023.
//

import UIKit
import AVFoundation

class MenuButtonView: UIView {
    var onDidTap: (() -> Void)?

    var isEnabled = true {
        didSet {
            alpha = isEnabled ? 1 : 0.1
            isUserInteractionEnabled = isEnabled
        }
    }

    private let iconImageView = UIImageView()

    init() {
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        backgroundColor = .surfaceLight
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        backgroundColor = .clear
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        backgroundColor = .clear
    }

    func setupIcon(_ icon: UIImage?) {
        iconImageView.image = icon
    }

    private func setup() {
        layer.cornerRadius = 22
        snp.makeConstraints { make in
            make.size.equalTo(44)
        }

        addSubview(iconImageView)
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.snp.makeConstraints { make in
            make.size.equalTo(24)
            make.center.equalToSuperview()
        }

        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        gesture.cancelsTouchesInView = false
        addGestureRecognizer(gesture)
    }

    @objc private func handleTap() {
        onDidTap?()
    }
}

class LayersButtonView: UIView {
    var onDidUpdateState: ((_ isOpened: Bool) -> Void)?

    var layerName: String? {
        get {
            subtitleLabel.text
        }
        set {
            subtitleLabel.text = newValue
        }
    }

    private let stackView = UIStackView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let iconImageView = UIImageView()

    private var isOpened = false

    init() {
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        backgroundColor = .surfaceLight
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        backgroundColor = .clear
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        backgroundColor = .clear
    }

    func toggleOpenedState() {
        isOpened.toggle()
        onDidUpdateState?(isOpened)
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut) {
            let multiplier: Double = self.isOpened ? 1 : -2
            let angle = CGFloat(multiplier * CGFloat.pi)
            self.iconImageView.transform = CGAffineTransform(rotationAngle: angle)
        }
    }

    func hideLayers() {
        if isOpened {
            toggleOpenedState()
        }
    }

    private func setup() {
        setupContainer()
        setupStackView()
        setupTitleLabel()
        setupSubtitleView()
        setupIconImageView()

        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        gesture.cancelsTouchesInView = false
        addGestureRecognizer(gesture)
    }

    private func setupContainer() {
        layer.cornerRadius = 22
        snp.makeConstraints { make in
            make.height.equalTo(44)
        }
    }

    private func setupStackView() {
        addSubview(stackView)
        stackView.axis = .vertical
        stackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }
    }

    private func setupTitleLabel() {
        stackView.addArrangedSubview(titleLabel)
        titleLabel.text = "Слои"
        titleLabel.font = .systemFont(ofSize: 16)
        titleLabel.textColor = .white
    }

    private func setupSubtitleView() {
        stackView.addArrangedSubview(subtitleLabel)
        subtitleLabel.font = .systemFont(ofSize: 10)
        subtitleLabel.textColor = .textTertiary
    }

    private func setupIconImageView() {
        addSubview(iconImageView)
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.image = .arrowDown
        iconImageView.snp.makeConstraints { make in
            make.size.equalTo(24)
            make.leading.equalTo(stackView.snp.trailing).offset(4)
            make.trailing.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
        }
    }

    @objc private func handleTap() {
        toggleOpenedState()
    }
}

class MenuView: UIView {
    var onLayersStateUpdate: ((_ isOpened: Bool) -> Void)? {
        get {
            layersButtonView.onDidUpdateState
        }
        set {
            layersButtonView.onDidUpdateState = newValue
        }
    }

    private let layersButtonView = LayersButtonView()
    private let rightStackView = UIStackView()
    private let micButtonView = MenuButtonView()
    private let recordButtonView = MenuButtonView()
    private let playbackButtonView = MenuButtonView()

    private let audioRecorder = AudioRecorder()
    private(set) var isAudioRecording = false

    private var audioPlayer = AVPlayer()

    init() {
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func hideLayers() {
        layersButtonView.hideLayers()
    }

    func update() {
        layersButtonView.layerName = CompositionController.shared.activeLayer?.name
    }

    private func setup() {
        setupContainer()
        setupLayersButtonView()
        setupRightStackView()
        setupMicButtonView()
        setupRecordButtonView()
        setupPlaybackButtonView()

        audioRecorder.requestPermissions { _ in

        }

        audioRecorder.onDidFinishRecording = { url, _ in
            if let url = url {
                CompositionController.shared.updateActiveLayer(recordURL: url)
            }
        }
    }

    private func setupContainer() {
        backgroundColor = .surface
        layer.cornerRadius = 28
        layer.shadowOffset = CGSize(width: 0, height: 6)
        layer.shadowRadius = 16
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.3
        snp.makeConstraints { make in
            make.height.equalTo(56)
        }
    }

    private func setupLayersButtonView() {
        addSubview(layersButtonView)
        layersButtonView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(6)
            make.centerY.equalToSuperview()
        }
    }

    private func setupRightStackView() {
        addSubview(rightStackView)
        rightStackView.spacing = 4
        rightStackView.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(6)
            make.centerY.equalToSuperview()
        }
    }

    private func setupMicButtonView() {
        rightStackView.addArrangedSubview(micButtonView)
        micButtonView.setupIcon(.micIcon?.withRenderingMode(.alwaysTemplate))
        micButtonView.tintColor = .white
        micButtonView.onDidTap = { [weak self] in
            guard let self = self else { return }
            let startRecording = { [weak self] in
                guard let self = self else { return }
                self.isAudioRecording.toggle()
                if !self.isAudioRecording {
                    self.recordButtonView.isEnabled = true
                    self.playbackButtonView.isEnabled = true
                    self.micButtonView.tintColor = .white
                    self.audioRecorder.stopRecording()
                } else {
                    self.recordButtonView.isEnabled = false
                    self.playbackButtonView.isEnabled = false
                    self.micButtonView.tintColor = .accentRed
                    CompositionController.shared.addVocalLayer()
                    do {
                        try self.audioRecorder.startRecording()
                    } catch {
                        showError?(error.localizedDescription)
                    }
                }
            }
            switch self.audioRecorder.recordingSession.recordPermission {
            case .denied:
                showMicError?()
                break
            case .undetermined:
                self.audioRecorder.requestPermissions { [startRecording] _ in
                    startRecording()
                }
            case .granted:
                startRecording()
            @unknown default:
                startRecording()
            }
        }
    }

    private func setupRecordButtonView() {
        rightStackView.addArrangedSubview(recordButtonView)
        recordButtonView.tintColor = .white
        recordButtonView.setupIcon(.recordIcon?.withRenderingMode(.alwaysTemplate))
        recordButtonView.onDidTap = { [weak self] in
            if CompositionController.shared.isRecording {
                self?.micButtonView.isEnabled = true
                self?.playbackButtonView.isEnabled = true
                self?.recordButtonView.tintColor = .white
                CompositionController.shared.stopRecord()
            } else {
                self?.micButtonView.isEnabled = false
                self?.playbackButtonView.isEnabled = false
                self?.recordButtonView.tintColor = .accentRed
                do {
                    try CompositionController.shared.recordComposition()
                } catch {
                    showError?(error.localizedDescription)
                }
            }
        }
    }

    private func setupPlaybackButtonView() {
        rightStackView.addArrangedSubview(playbackButtonView)
        playbackButtonView.setupIcon(.playIcon)
        playbackButtonView.onDidTap = { [weak self] in
            if CompositionController.shared.isCompositionPlaying{
                self?.micButtonView.isEnabled = true
                self?.recordButtonView.isEnabled = true
                CompositionController.shared.stopComposition()
                self?.playbackButtonView.setupIcon(.playIcon)
            } else {
                self?.micButtonView.isEnabled = false
                self?.recordButtonView.isEnabled = false
                CompositionController.shared.playComposition()
                self?.playbackButtonView.setupIcon(.pauseIcon)
            }
        }
    }
}
