//
//  SampleConfiguratorPadView.swift
//  MusicMakerYaCup
//
//  Created by Denis Sharapov on 01.11.2023.
//

import UIKit

class SampleConfiguratorPadView: UIView {

    var onDidUpdateParameters: ((_ interval: TimeInterval, _ volume: Double) -> Void)?

    var timerInterval: TimeInterval {
        player.timerInterval
    }

    private let contentView = UIView()
    private let volumeLineView = UIView()
    private let speedLineView = UIView()
    private let touchCircleView = UIView()
    private let rippleCircleView = UIView()

    private let speedLabel = UILabel()
    private let volumeLabel = UILabel()

    private var touchPosition: CGPoint?

    private let player = SampleConfigurationPadPlayer()
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .soft)

    private var sample: Sample?

    init() {
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateOnTouches()

        volumeLabel.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
            .concatenating(CGAffineTransform(translationX: (volumeLabel.frame.height - volumeLabel.frame.width) / 2, y: 0))
    }

    func setSample(_ sample: Sample) {
        guard let url = sample.url, self.sample?.url != url else { return }
        self.sample = sample
        player.setSampleURL(url)
    }

    func setParameters(interval: TimeInterval, volume: Double) {
        player.setInterval(interval)
        player.setVolume(volume)

        let speedLineX = 2 + (frame.width - 4) * CGFloat((60.0 / interval - 60.0) / 120.0)
        let volumeLineY = 2 + (frame.height - 4) * CGFloat(1 - volume)


        speedLineView.frame = CGRect(x: speedLineX - 0.5, y: 0, width: 1, height: frame.height)
        volumeLineView.frame = CGRect(x: 0, y: volumeLineY - 0.5, width: frame.width, height: 1)
        touchCircleView.frame = CGRect(x: speedLineX - 4, y: volumeLineY - 4, width: 8, height: 8)
    }

    private func setup() {
        setupContainer()
        setupSpeedLabel()
        setupVolumeLabel()
        setupContentView()
        setupRippleCircleView()
        setupVolumeLineView()
        setupSpeedLineView()
        setupTouchCircleView()

        player.onDidPlay = { [weak self] interval in
            self?.handlePlay(interval: interval)
        }
    }

    private func setupContainer() {
        backgroundColor = UIColor(patternImage: .samplePadBg ?? UIImage())
        layer.cornerRadius = 8
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 16
        layer.shadowColor = UIColor.accentDark.cgColor
        layer.shadowOpacity = 0.15
    }

    private func setupContentView() {
        addSubview(contentView)
        contentView.layer.cornerRadius = 8
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.accentDark.cgColor
        contentView.clipsToBounds = true
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setupSpeedLabel() {
        addSubview(speedLabel)
        speedLabel.text = "СКОРОСТЬ"
        speedLabel.font = .systemFont(ofSize: 14)
        speedLabel.textColor = .textSecondary
        speedLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset(8)
            make.centerX.equalToSuperview()
        }
    }

    private func setupVolumeLabel() {
        addSubview(volumeLabel)
        volumeLabel.text = "ГРОМКОСТЬ"
        volumeLabel.font = .systemFont(ofSize: 14)
        volumeLabel.textColor = .textSecondary
        volumeLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()
        }
    }

    private func setupRippleCircleView() {
        contentView.addSubview(rippleCircleView)
        rippleCircleView.backgroundColor = .accent
    }

    private func setupVolumeLineView() {
        contentView.addSubview(volumeLineView)
        volumeLineView.backgroundColor = .accent
    }

    private func setupSpeedLineView() {
        contentView.addSubview(speedLineView)
        speedLineView.backgroundColor = .accent
    }

    private func setupTouchCircleView() {
        contentView.addSubview(touchCircleView)
        touchCircleView.backgroundColor = .accent
        touchCircleView.layer.cornerRadius = 4
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first else { return }
        handleTouchUpdate(touch)
        if !CompositionController.shared.isCompositionPlaying {
            player.play()
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard let touch = touches.first else { return }
        handleTouchUpdate(touch)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        player.stop()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        player.stop()
    }

    private func handleTouchUpdate(_ touch: UITouch) {
        touchPosition = touch.location(in: self)
        updateOnTouches()
    }

    private func updateOnTouches() {
        var speedLineX = (touchPosition?.x ?? frame.width / 2)
        var volumeLineY = (touchPosition?.y ?? frame.height / 2)

        speedLineX = min(frame.width - 2, max(2, speedLineX))
        volumeLineY = min(frame.height - 2, max(2, volumeLineY))

//        speedLineView.frame = CGRect(x: speedLineX - 0.5, y: 0, width: 1, height: frame.height)
//        volumeLineView.frame = CGRect(x: 0, y: volumeLineY - 0.5, width: frame.width, height: 1)
//        touchCircleView.frame = CGRect(x: speedLineX - 4, y: volumeLineY - 4, width: 8, height: 8)

        let minX: CGFloat = 2
        let maxX = frame.width - 2
        let minY: CGFloat = 2
        let maxY = frame.height - 2

        let xFraction = (speedLineX - minX) / (maxX - minX)
        let yFraction = 1 - (volumeLineY - minY) / (maxY - minY)

        player.setBPMFraction(Double(xFraction))
        player.setVolumeFraction(Double(yFraction))

        onDidUpdateParameters?(player.timerInterval, player.volume)
    }

    private func handlePlay(interval: TimeInterval) {
        rippleCircleView.frame = touchCircleView.frame
        rippleCircleView.layer.cornerRadius = touchCircleView.layer.cornerRadius
        rippleCircleView.alpha = 0.5

        let rippleSize = frame.width

        UIView.animate(withDuration: interval * 0.9) {
            self.rippleCircleView.frame = CGRect(origin: CGPoint(x: self.touchCircleView.center.x - rippleSize / 2,
                                                                 y: self.touchCircleView.center.y - rippleSize / 2),
                                                 size: CGSize(width: rippleSize, height: rippleSize))
            self.rippleCircleView.layer.cornerRadius = rippleSize / 2
            self.rippleCircleView.alpha = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.feedbackGenerator.impactOccurred()
            self.feedbackGenerator.prepare()
        }
    }
}
