//
//  LayersView.swift
//  MusicMakerYaCup
//
//  Created by Denis Sharapov on 02.11.2023.
//

import UIKit
import SnapKit

class LayersView: UIView {

    private let tableView = UITableView()

    private var heightConstraint: Constraint?

    private var viewModels: [LayerItemViewModel] = []

    func update() {
        viewModels = CompositionController.shared.layers.map { .init(layer: $0) }
        tableView.reloadData()
        let height = min(CGFloat(viewModels.count * 48), UIScreen.main.bounds.height / 2)
        heightConstraint?.update(offset: height)
        layoutIfNeeded()
        if let activeIndex = CompositionController.shared.layers.firstIndex(where: {
            return $0.id == CompositionController.shared.activeLayer?.id
        }), viewModels.count > activeIndex {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.tableView.scrollToRow(at: IndexPath(row: activeIndex, section: 0), at: .none, animated: true)
            }
        }
    }

    func stop() {
        viewModels.forEach { $0.stop() }
    }

    func setup() {
        setupContainer()
        setupTableView()
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

    private func setupTableView() {
        addSubview(tableView)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.layer.cornerRadius = 8
        tableView.clipsToBounds = true
        tableView.register(LayerItemViewCell.self, forCellReuseIdentifier: "layerCell")
        tableView.showsVerticalScrollIndicator = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.alwaysBounceVertical = false
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            heightConstraint = make.height.equalTo(0).constraint
        }
    }
}

extension LayersView: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return CompositionController.shared.layers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "layerCell", for: indexPath)
        (cell as? LayerItemViewCell)?.configure(with: viewModels[indexPath.row])
        return cell
    }
}
