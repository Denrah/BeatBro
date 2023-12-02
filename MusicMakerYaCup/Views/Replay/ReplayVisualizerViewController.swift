//
//  ReplayVisualizerViewController.swift
//  MusicMakerYaCup
//
//  Created by Denis Sharapov on 02.12.2023.
//

import UIKit
import AVFoundation
import ReplayKit

class ReplayVisualizerViewController: UIViewController {
    private let backButton = UIButton(type: .system)
    private let playButton = UIButton(type: .system)
    private let sbackButton = UIButton(type: .system)
    private let animationView = AnimationView()
    private let playbackTimerLabel = UILabel()
    private let saveButton = UIButton(type: .system)
    private let nameLabel = UILabel()
    private let renameIcon = UIImageView()

    private let file: URL
    private var isPlaying = false
    private var timer: Timer?
    private var isVideoRecording = false
    private let recorder = RPScreenRecorder.shared()
    private var name: String?
    private var recordIsPending = false
    private var didPlayFileOnce = false

    init(file: URL) {
        self.file = file
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if CompositionController.shared.isCompositionPlaying {
            CompositionController.shared.stopComposition()
        }

        view.backgroundColor = .bgColor

        view.addSubview(backButton)
        backButton.tintColor = .white
        backButton.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        backButton.setImage(UIImage(named: "back"), for: .normal)
        backButton.snp.makeConstraints { make in
            make.size.equalTo(40)
            make.top.leading.equalTo(view.safeAreaLayoutGuide).inset(16)
        }

        view.addSubview(playButton)
        playButton.tintColor = .white
        playButton.setImage(UIImage(named: "play-icon"), for: .normal)
        playButton.addTarget(self, action: #selector(play), for: .touchUpInside)
        playButton.snp.makeConstraints { make in
            make.size.equalTo(40)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
        }

        view.addSubview(sbackButton)
        sbackButton.tintColor = .white
        sbackButton.setImage(UIImage(named: "sback"), for: .normal)
        sbackButton.addTarget(self, action: #selector(stop), for: .touchUpInside)
        sbackButton.snp.makeConstraints { make in
            make.size.equalTo(40)
            make.trailing.equalTo(playButton.snp.leading).offset(-8)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
        }

        view.addSubview(playbackTimerLabel)
        playbackTimerLabel.font = .systemFont(ofSize: 16)
        playbackTimerLabel.textColor = .white
        playbackTimerLabel.text = "00:00"
        playbackTimerLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalTo(playButton)
        }

        view.addSubview(animationView)

        animationView.snp.makeConstraints { make in
            make.top.equalTo(backButton.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(playButton.snp.top)
        }

        view.addSubview(saveButton)
        saveButton.tintColor = .white
        saveButton.setImage(UIImage(named: "save"), for: .normal)
        saveButton.snp.makeConstraints { make in
            make.size.equalTo(40)
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalTo(backButton)
        }

        saveButton.addTarget(self, action: #selector(saveVideo), for: .touchUpInside)

        view.addSubview(nameLabel)
        nameLabel.font = .systemFont(ofSize: 14)
        nameLabel.text = "BeatBro_Video_\(Int(Date().timeIntervalSince1970))"
        name = nameLabel.text
        nameLabel.isUserInteractionEnabled = true
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(backButton.snp.trailing).offset(8)
            make.height.equalTo(40)
            make.centerY.equalTo(backButton)
        }
        nameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(editName)))

        view.addSubview(renameIcon)
        renameIcon.contentMode = .scaleAspectFit
        renameIcon.image = UIImage(named: "edit")
        renameIcon.isUserInteractionEnabled = true
        renameIcon.snp.makeConstraints { make in
            make.size.equalTo(16)
            make.centerY.equalTo(nameLabel)
            make.leading.equalTo(nameLabel.snp.trailing).offset(4)
            make.trailing.lessThanOrEqualTo(saveButton.snp.leading).offset(-8)
        }
        renameIcon.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(editName)))

        ReplayAudioPlayer.shared.onPlaybackComplete = { [weak self] in
            if self?.isVideoRecording == true, (!(self?.recordIsPending == true) || !(self?.didPlayFileOnce == true)) {
                let fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(self?.name ?? "BeatBro_Video_\(Int(Date().timeIntervalSince1970))").mov")
                self?.recorder.stopRecording(withOutput: fileURL) { error in
                    print(fileURL)
                    print(error)
                    DispatchQueue.main.async {
                        self?.backButton.isHidden = false
                        self?.playButton.isHidden = false
                        self?.playbackTimerLabel.isHidden = false
                        self?.isVideoRecording = false
                        self?.saveButton.isHidden = false
                        self?.nameLabel.isHidden = false
                        self?.renameIcon.isHidden = false
                        self?.recordIsPending = false
                        self?.didPlayFileOnce = false
                        self?.sbackButton.isHidden = false
                        let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
                        self?.present(activityViewController, animated: true)
                    }
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.isPlaying = false
                    self?.timer?.invalidate()
                    self?.timer = nil
                    self?.playButton.setImage(UIImage(named: "play-icon"), for: .normal)
                }
            }
            self?.recordIsPending = false
        }
    }

    @objc private func editName() {
        let alert = UIAlertController(title: "Изменить название", message: nil, preferredStyle: .alert)
        alert.addTextField { field in
            field.text = self.nameLabel.text
        }
        alert.addAction(UIAlertAction(title: "Изменить", style: .default, handler: { _ in
            let name = alert.textFields?.first?.text
            if let name = name, !name.isEmpty {
                self.nameLabel.text = name
            } else {
                self.nameLabel.text = "BeatBro_Video_\(Int(Date().timeIntervalSince1970))"
            }
            self.name = self.nameLabel.text
        }))
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func goBack() {
        ReplayAudioPlayer.shared.stop()
        dismiss(animated: true)
    }

    @objc private func stop() {
        ReplayAudioPlayer.shared.stop()
        didPlayFileOnce = false
        recordIsPending = false
    }

    @objc private func play() {
        if isPlaying {
            isPlaying = false
            ReplayAudioPlayer.shared.pause()
            playButton.setImage(UIImage(named: "play-icon"), for: .normal)
            timer?.invalidate()
            timer = nil
        } else {
            didPlayFileOnce = true
            isPlaying = true
            ReplayAudioPlayer.shared.playFile(file)
            playButton.setImage(UIImage(named: "pause-icon"), for: .normal)
            timer?.invalidate()
            timer = nil
            timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { [weak self] _ in
                let formatter = DateFormatter()
                let date = Date(timeIntervalSince1970: ReplayAudioPlayer.shared.currentTime())
                formatter.dateFormat = "mm:ss"
                var text = formatter.string(from: date)
                if text == "59:59" {
                    text = "00:00"
                }
                self?.playbackTimerLabel.text = text

            })
            timer?.fire()
        }
    }

    @objc private func saveVideo() {
        let alert = UIAlertController(title: "Дополнительные эффекты!",
                                      message: "Вы можете водить пальцем по экрану во время воспроизведения, чтобы добавить дополнительные эффекты",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Хорошо!", style: .default, handler: { _ in
            if self.isPlaying {
                self.isPlaying = false
                ReplayAudioPlayer.shared.stop()
                self.playButton.setImage(UIImage(named: "play-icon"), for: .normal)
                self.timer?.invalidate()
                self.timer = nil
            }

            self.backButton.isHidden = true
            self.playButton.isHidden = true
            self.sbackButton.isHidden = true
            self.playbackTimerLabel.isHidden = true
            self.isVideoRecording = true
            self.saveButton.isHidden = true
            self.nameLabel.isHidden = true
            self.renameIcon.isHidden = true
            self.recordIsPending = true

            self.recorder.isMicrophoneEnabled = false
            self.recorder.startRecording { (error) in
                if error != nil {
                    self.backButton.isHidden = false
                    self.playButton.isHidden = false
                    self.playbackTimerLabel.isHidden = false
                    self.isVideoRecording = false
                    self.saveButton.isHidden = false
                    self.nameLabel.isHidden = false
                    self.renameIcon.isHidden = false
                    self.recordIsPending = false
                    self.sbackButton.isHidden = false
                    return
                }
                ReplayAudioPlayer.shared.playFile(self.file, forced: true)
            }
        }))

        present(alert, animated: true)
    }
}
