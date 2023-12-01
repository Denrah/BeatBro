//
//  ViewController.swift
//  MusicMakerYaCup
//
//  Created by Denis Sharapov on 31.10.2023.
//

import UIKit
import SnapKit
import CoreMedia
import AVFoundation

var showError: ((_ text: String) -> Void)?
var showMicError: (() -> Void)?

class HitView: UIView {
    var onDidTapView: (() -> Void)?

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        if view == self {
            onDidTapView?()
        }
        return view
    }
}

class ViewController: UIViewController {

    private let sampleConfigurationPadView = SampleConfiguratorPadView()
    private let sampleSelectorView = SampleSelectorView()
    private let menuView = MenuView()
    private let layersView = LayersView()
    private let recordPlayerView = RecordPlayerView()
    private let audioVisualizerView = AudioVisualizerView()
    private let infoStackView = UIStackView()
    private let layerLabel = UILabel()
    private let bpmLabel = UILabel()
    private let recordNameLabel = UILabel()
    private let loadingOverlay = UIView()
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        let hitView = HitView()
        hitView.onDidTapView = { [weak self] in
            self?.menuView.hideLayers()
        }
        view = hitView
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        let hitView = HitView()
        hitView.onDidTapView = { [weak self] in
            self?.menuView.hideLayers()
        }
        view = hitView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    private func setup() {
        view.backgroundColor = .bgColor
        setupRecordPlayerView()
        setupAudioVisualizerView()
        setupSampleConfigurationPadView()
        setupInfoStackView()
        setupMenuView()
        setupSampleSelectorView()
        setupLayersView()
        setupLoadingOverlay()

        CompositionController.shared.onDidChangeLayers = { [weak self] in
            self?.layersView.update()
            self?.menuView.update()
        }

        CompositionController.shared.onActiveLayerUpdate = { [weak self] in
            let activeLayer = CompositionController.shared.activeLayer
            self?.layerLabel.text = activeLayer?.name
            self?.recordNameLabel.text = "\(activeLayer?.number ?? 0) • \(activeLayer?.name ?? "")"

            self?.recordPlayerView.isRecordingInProcess = (self?.menuView.isAudioRecording ?? false)

            if self?.menuView.isAudioRecording == true {
                self?.recordPlayerView.stop()
            }

            switch activeLayer?.type {
            case .sample(_, let interval, let volume):
                self?.bpmLabel.text = "\(Int(60 / interval)) BPM • \(Int(volume * 100))%"
            default:
                self?.bpmLabel.text = ""
            }

            switch activeLayer?.type {
            case .sample(let sample, let interval, let volume):
                self?.recordPlayerView.isHidden = true
                self?.recordNameLabel.isHidden = true
                self?.sampleConfigurationPadView.isHidden = false
                self?.infoStackView.isHidden = false
                self?.sampleConfigurationPadView.setParameters(interval: interval, volume: volume)
                self?.sampleConfigurationPadView.setSample(sample)
            case .voice(let url):
                self?.recordPlayerView.isHidden = false
                self?.recordNameLabel.isHidden = false
                self?.infoStackView.isHidden = true
                self?.sampleConfigurationPadView.isHidden = true
                if let url = url {
                    self?.recordPlayerView.setAudio(url: url)
                }
            default:
                break
            }
        }

        CompositionController.shared.onDidFinishRecord = { [weak self] url in
            self?.loadingOverlay.isHidden = false
            let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            self?.present(activityViewController, animated: true) { [weak self] in
                self?.loadingOverlay.isHidden = true
            }
        }

        showError = { [weak self] text in
            let alert = UIAlertController(title: "Ошибка", message: text, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "ОК", style: .cancel))
            self?.present(alert, animated: true)
        }

        showMicError = { [weak self] in
            let alert = UIAlertController(title: "Доступ к микрофону не выдан", message: "Вы можете разрешить запись с микрофона в настройках приложения", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Настройки", style: .default, handler: { _ in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }))
            alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
            self?.present(alert, animated: true)
        }

        CompositionController.shared.onStartPlayback = { [weak self] in
            self?.recordPlayerView.stop()
            self?.layersView.stop()
        }
    }

    private func setupSampleConfigurationPadView() {
        view.addSubview(sampleConfigurationPadView)
        sampleConfigurationPadView.snp.makeConstraints { make in
            make.top.equalTo(audioVisualizerView.snp.bottom).offset(24)
            make.height.equalTo(sampleConfigurationPadView.snp.width)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        sampleConfigurationPadView.onDidUpdateParameters = { interval, volume in
            CompositionController.shared.updateActiveLayer(interval: interval, volume: volume)
        }

        if let sample = sampleSelectorView.selectedSample {
            sampleConfigurationPadView.setSample(sample)
        }
    }

    private func setupInfoStackView() {
        view.addSubview(infoStackView)
        infoStackView.distribution = .equalSpacing
        infoStackView.snp.makeConstraints { make in
            make.top.equalTo(sampleConfigurationPadView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        infoStackView.addArrangedSubview(layerLabel)
        layerLabel.font = .systemFont(ofSize: 14)
        layerLabel.textColor = .textTertiary

        infoStackView.addArrangedSubview(bpmLabel)
        bpmLabel.font = .systemFont(ofSize: 14)
        bpmLabel.textColor = .textTertiary
    }

    private func setupMenuView() {
        view.addSubview(menuView)
        menuView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(40)
        }

        menuView.onLayersStateUpdate = { [weak self] isOpened in
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut) { [weak self] in
                self?.layersView.alpha = isOpened ? 1 : 0
                self?.layersView.transform = isOpened ? .identity : CGAffineTransform(translationX: 0, y: 8)
            }
        }

        menuView.update()
    }

    private func setupSampleSelectorView() {
        view.addSubview(sampleSelectorView)
        sampleSelectorView.snp.makeConstraints { make in
            make.bottom.equalTo(menuView.snp.top).offset(-24)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        sampleSelectorView.onDidSelectSample = { sample in
            CompositionController.shared.addInstrumentalLayer(sample: sample)
        }
    }

    private func setupLayersView() {
        view.addSubview(layersView)
        layersView.transform = CGAffineTransform(translationX: 0, y: 8)
        layersView.alpha = 0
        layersView.setup()
        layersView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(menuView)
            make.bottom.equalTo(menuView.snp.top).offset(-8)
        }
    }

    private func setupRecordPlayerView() {
        view.addSubview(recordPlayerView)
        recordPlayerView.isHidden = true
        recordPlayerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        view.addSubview(recordNameLabel)
        recordNameLabel.font = .systemFont(ofSize: 16)
        recordNameLabel.textColor = .white
        recordNameLabel.isHidden = true
        recordNameLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(recordPlayerView.snp.top).offset(-24)
        }
    }

    private func setupAudioVisualizerView() {
        view.addSubview(audioVisualizerView)
        audioVisualizerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
        }

        CompositionController.shared.onMagnitudesDidUpdate = { [weak self] in
            DispatchQueue.main.async {
                self?.audioVisualizerView.setupBars(data: CompositionController.shared.fftMagnitudes)
            }
        }
    }

    private func setupLoadingOverlay() {
        view.addSubview(loadingOverlay)
        loadingOverlay.backgroundColor = .black.withAlphaComponent(0.6)
        loadingOverlay.isHidden = true
        loadingOverlay.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        loadingOverlay.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}

