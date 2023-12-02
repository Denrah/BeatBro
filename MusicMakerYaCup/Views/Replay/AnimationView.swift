//
//  AnimationView.swift
//  MusicMakerYaCup
//
//  Created by Denis Sharapov on 02.12.2023.
//

import UIKit
import AVFoundation

let lowImages = ["v5", "v6", "v14", "v8"]
let midImages = ["v1", "v9", "v13", "v11", "v3", "v12"]
let highImages = ["v15", "v10", "v2", "v4", "v7"]

class AnimationView: UIView {
    let animationLayer = CALayer()
    let lowLayer = CALayer()
    let midLayer = CALayer()
    let highLayer = CALayer()

    var lowImagesLayer: [CALayer] = []
    var midImagesLayer: [CALayer] = []
    var highImagesLayer: [CALayer] = []

    var timer: Timer?

    let particleEmitter = CAEmitterLayer()

    init() {
        super.init(frame: .zero)
        layer.addSublayer(animationLayer)
        animationLayer.addSublayer(lowLayer)
        animationLayer.addSublayer(midLayer)
        animationLayer.addSublayer(highLayer)
        ReplayAudioPlayer.shared.onVisualizerMagnitudesDidUpdate = { [weak self] in
            DispatchQueue.main.async { [weak self] in
                self?.updateAnimation(data: ReplayAudioPlayer.shared.fftMagnitudes)
            }
        }

        for _ in 1...CompositionController.Constants.barAmount {
            addLow()
            addMid()
            addHigh()
        }

        timer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { [weak self] _ in
            self?.animateMove()
        }
    }

    func addLow() {
        let layer = CALayer()
        if let image = UIImage(named: lowImages.randomElement() ?? "v5") {
            layer.contents = image.cgImage
        }
        layer.opacity = 0
        lowImagesLayer.append(layer)
        lowLayer.addSublayer(layer)
    }

    func addMid() {
        let layer = CALayer()
        if let image = UIImage(named: midImages.randomElement() ?? "v1") {
            layer.contents = image.cgImage
        }
        layer.opacity = 0
        midImagesLayer.append(layer)
        midLayer.addSublayer(layer)
    }

    func addHigh() {
        let layer = CALayer()
        if let image = UIImage(named: highImages.randomElement() ?? "v15") {
            layer.contents = image.cgImage
        }
        layer.opacity = 0
        highImagesLayer.append(layer)
        highLayer.addSublayer(layer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if let position = touches.first?.location(in: self) {
            particleEmitter.emitterPosition = position
            particleEmitter.birthRate = 1
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        if let position = touches.first?.location(in: self) {
            particleEmitter.emitterPosition = position
            particleEmitter.birthRate = 1
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        particleEmitter.birthRate = 0
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        particleEmitter.birthRate = 0
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        animationLayer.frame = bounds
        lowLayer.frame = bounds
        midLayer.frame = bounds
        highLayer.frame = bounds

        lowImagesLayer.forEach { layer in
            layer.frame = CGRect(x: CGFloat.random(in: 0...(frame.width - 50)),
                                 y: CGFloat.random(in: (frame.height * 0.666)...(frame.height - 50)),
                                 width: 50,
                                 height: 50)
        }
        midImagesLayer.forEach { layer in
            layer.frame = CGRect(x: CGFloat.random(in: 0...(frame.width - 50)),
                                 y: CGFloat.random(in: (frame.height * 0.333)...(frame.height * 0.666)),
                                 width: 50,
                                 height: 50)
        }
        highImagesLayer.forEach { layer in
            layer.frame = CGRect(x: CGFloat.random(in: 0...(frame.width - 50)),
                                 y: CGFloat.random(in: 0...(frame.height * 0.333)),
                                 width: 50,
                                 height: 50)
        }
        animateMove()
        createParticles()
    }

    private func updateAnimation(data: [Float]) {
        let fp = data.count / 3
        let sp = data.count / 3 * 2
        let low = Array(data[0..<fp])
        let mid = Array(data[fp..<sp])
        let high = Array(data[sp..<data.count])

        updateLows(data: low)
        updateMids(data: mid)
        updateHighs(data: high)
    }

    private func updateLows(data: [Float]) {
        data.enumerated().forEach { index, value in
            guard index < lowImagesLayer.count else { return }
            lowImagesLayer[index].opacity = min(1, max(0, value))
        }
    }

    private func updateMids(data: [Float]) {
        data.enumerated().forEach { index, value in
            guard index < midImagesLayer.count else { return }
            midImagesLayer[index].opacity = min(1, max(0, value))
        }
    }

    private func updateHighs(data: [Float]) {
        data.enumerated().forEach { index, value in
            guard index < highImagesLayer.count else { return }
            highImagesLayer[index].opacity = min(1, max(0, value))
        }
    }

    private func normals(data: [Float]) -> [Float] {
        let min = data.min() ?? 0
        let max = data.max() ?? 0
        let offset = 0 - min
        let amp = max - min
        return data.map { ($0 + offset) / amp }
    }

    private func animateMove() {
        CATransaction.begin()

        lowImagesLayer.forEach { layer in
            let start = layer.value(forKey: "position")
            let point = CGPoint(x: CGFloat.random(in: 0...(frame.width - 50)),
                                y: CGFloat.random(in: (frame.height * 0.666)...(frame.height - 50)))
            let toValue = NSValue(cgPoint: point)
            let animation = CABasicAnimation(keyPath: "position")
            animation.fromValue = start
            animation.toValue = toValue
            animation.duration = 4
            layer.position = point
            layer.add(animation, forKey: "position")

            let oldBounds = layer.bounds;
            var newBounds = oldBounds;
            newBounds.size = CGSize(width: CGFloat.random(in: 50...150),
                                    height: CGFloat.random(in: 50...150))
            let animation2 = CABasicAnimation(keyPath: "bounds")
            animation2.fromValue = oldBounds
            animation2.toValue = newBounds
            animation2.duration = 4
            layer.bounds = newBounds
            layer.add(animation2, forKey: "bounds")

            let animation3 = CABasicAnimation(keyPath: "transform.rotation.z")
            animation3.fromValue = 0
            animation3.duration = 4
            animation3.toValue = NSNumber(value: CGFloat.pi * 2)
            layer.add(animation3, forKey: "rotationAnimation")
        }

        midImagesLayer.forEach { layer in
            let start = layer.value(forKey: "position")
            let point = CGPoint(x: CGFloat.random(in: 0...(frame.width - 50)),
                                y: CGFloat.random(in: (frame.height * 0.333)...(frame.height * 0.666)))
            let toValue = NSValue(cgPoint: point)
            let animation = CABasicAnimation(keyPath: "position")
            animation.fromValue = start
            animation.toValue = toValue
            animation.duration = 4
            layer.position = point
            layer.add(animation, forKey: "position")

            let oldBounds = layer.bounds;
            var newBounds = oldBounds;
            newBounds.size = CGSize(width: CGFloat.random(in: 50...150),
                                    height: CGFloat.random(in: 50...150))
            let animation2 = CABasicAnimation(keyPath: "bounds")
            animation2.fromValue = oldBounds
            animation2.toValue = newBounds
            animation2.duration = 4
            layer.bounds = newBounds
            layer.add(animation2, forKey: "bounds")

            let animation3 = CABasicAnimation(keyPath: "transform.rotation.z")
            animation3.fromValue = 0
            animation3.duration = 4
            animation3.toValue = NSNumber(value: CGFloat.pi * 2)
            layer.add(animation3, forKey: "rotationAnimation")
        }

        highImagesLayer.forEach { layer in
            let start = layer.value(forKey: "position")
            let point = CGPoint(x: CGFloat.random(in: 0...(frame.width - 50)),
                                y: CGFloat.random(in: (frame.height * 0)...(frame.height * 0.333)))
            let toValue = NSValue(cgPoint: point)
            let animation = CABasicAnimation(keyPath: "position")
            animation.fromValue = start
            animation.toValue = toValue
            animation.duration = 4
            layer.position = point
            layer.add(animation, forKey: "position")

            let oldBounds = layer.bounds;
            var newBounds = oldBounds;
            newBounds.size = CGSize(width: CGFloat.random(in: 50...150),
                                    height: CGFloat.random(in: 50...150))
            let animation2 = CABasicAnimation(keyPath: "bounds")
            animation2.fromValue = oldBounds
            animation2.toValue = newBounds
            animation2.duration = 4
            layer.bounds = newBounds
            layer.add(animation2, forKey: "bounds")

            let animation3 = CABasicAnimation(keyPath: "transform.rotation.z")
            animation3.fromValue = 0
            animation3.duration = 4
            animation3.toValue = NSNumber(value: CGFloat.pi * 2)
            layer.add(animation3, forKey: "rotationAnimation")
        }

        CATransaction.commit()
    }

    func createParticles() {
        particleEmitter.emitterPosition = CGPoint(x: frame.width / 2.0, y: frame.height / 2.0)
        particleEmitter.emitterShape = .point
        particleEmitter.emitterSize = CGSize(width: 1, height: 1)
        particleEmitter.renderMode = .additive
        particleEmitter.birthRate = 0

        let cell = CAEmitterCell()
        cell.birthRate = 10
        cell.lifetime = 5.0
        cell.velocity = 300
        cell.velocityRange = 100
        cell.emissionLongitude = .pi / 2
        cell.spinRange = 5
        cell.scale = 0.5
        cell.scaleRange = 0.25
        cell.emissionRange = .pi / 4
        cell.color = UIColor(white: 1, alpha: 0.1).cgColor
        cell.redRange = 1.0;
        cell.greenRange = 1.0;
        cell.blueRange = 1.0;
        cell.contents = UIImage(named: "note")?.cgImage
        particleEmitter.emitterCells = [cell]

        animationLayer.addSublayer(particleEmitter)
    }
}
