//
//  SampleSelectorItemView.swift
//  MusicMakerYaCup
//
//  Created by Denis Sharapov on 02.11.2023.
//

import UIKit

class SampleSelectorItemView: UIView {
    enum LongTapState {
        case undefined, inProgress, recognized
    }

    var onLongTap: ((_ location: CGPoint) -> Void)?
    var onShortTap: (() -> Void)?
    var onEndLongTap: (() -> Void)?
    var onMoveLongTap: ((_ location: CGPoint) -> Void)?

    private let iconImageView = UIImageView()
    private let leftArrowImageView = UIImageView()
    private let rightArrowImageView = UIImageView()

    private var longTapWorkItem: DispatchWorkItem?
    private var longTapState: LongTapState = .undefined
    private var initialTouchLocation: CGPoint = .zero

    init() {
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func configure(_ instrument: MusicalInstrument) {
        iconImageView.image = instrument.icon
    }

    private func setup() {
        setupContainer()
        setupIconImageView()
        setupLeftArrowImageView()
        setupRightArrowImageView()
    }

    private func setupContainer() {
        backgroundColor = .surface
        layer.borderWidth = 1
        layer.borderColor = UIColor.accent.cgColor
        layer.cornerRadius = 28
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 16
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0
        snp.makeConstraints { make in
            make.size.equalTo(56)
        }
    }

    private func setupIconImageView() {
        addSubview(iconImageView)
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.snp.makeConstraints { make in
            make.size.equalTo(32)
            make.center.equalToSuperview()
        }
    }

    private func setupLeftArrowImageView() {
        addSubview(leftArrowImageView)
        leftArrowImageView.contentMode = .scaleAspectFit
        leftArrowImageView.image = .doubleArrowIcon
        leftArrowImageView.transform = CGAffineTransform(scaleX: -1, y: 1)
        leftArrowImageView.alpha = 0
        leftArrowImageView.snp.makeConstraints { make in
            make.size.equalTo(56)
            make.trailing.equalTo(self.snp.leading).offset(8)
        }

        UIView.animate(withDuration: 1, delay: 0, options: [.repeat, .curveEaseInOut, .autoreverse]) {
            self.leftArrowImageView.transform = CGAffineTransform(scaleX: -1, y: 1).concatenating(CGAffineTransform(translationX: -8, y: 0))
        }
    }

    private func setupRightArrowImageView() {
        addSubview(rightArrowImageView)
        rightArrowImageView.contentMode = .scaleAspectFit
        rightArrowImageView.image = .doubleArrowIcon
        rightArrowImageView.alpha = 0
        rightArrowImageView.snp.makeConstraints { make in
            make.size.equalTo(56)
            make.leading.equalTo(self.snp.trailing).offset(-8)
        }

        UIView.animate(withDuration: 1, delay: 0, options: [.repeat, .curveEaseInOut, .autoreverse]) {
            self.rightArrowImageView.transform = CGAffineTransform(translationX: 8, y: 0)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        backgroundColor = .surfaceLight
        initialTouchLocation = touches.first?.location(in: superview) ?? .zero
        longTapState = .inProgress
        let workItem = DispatchWorkItem { [weak self] in
            guard let touch = touches.first else { return }
            self?.handleLongTap(location: touch.location(in: self?.superview))
        }
        longTapWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        backgroundColor = .surface
        handleTouchEnded()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        backgroundColor = .surface
        handleTouchEnded()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        backgroundColor = .surfaceLight
        if case .recognized = longTapState, let touch = touches.first {
            let location = touch.location(in: superview)
            onMoveLongTap?(location)
            transform = CGAffineTransform(translationX: location.x - initialTouchLocation.x, y: 0)
        }
    }

    private func handleTouchEnded() {
        switch longTapState {
        case .undefined:
            break
        case .inProgress:
            longTapWorkItem?.cancel()
            longTapWorkItem = nil
            longTapState = .undefined
            handleShortTap()
        case .recognized:
            onEndLongTap?()
        }

        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
            self.transform = .identity
            self.layer.shadowOpacity = 0
            self.leftArrowImageView.alpha = 0
            self.rightArrowImageView.alpha = 0
        }
    }

    private func handleLongTap(location: CGPoint) {
        longTapState = .recognized
        longTapWorkItem = nil
        superview?.bringSubviewToFront(self)
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut) {
            self.layer.shadowOpacity = 0.3
            self.leftArrowImageView.alpha = 1
            self.rightArrowImageView.alpha = 1
        }
        onLongTap?(location)
    }

    private func handleShortTap() {
        onShortTap?()
    }
}
