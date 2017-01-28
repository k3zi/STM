//
//  DashboardItemCell.swift
//  STM
//
//  Created by Kesi Maduka on 2/2/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit

class DashboardItemCell: KZTableViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    let headerLabel = UILabel.styledForDashboardHeader()
    var collectionView: UICollectionView?

    required init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UIColor.clear

        self.contentView.addSubview(headerLabel)

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 62, height: 62)
        layout.minimumInteritemSpacing = 0.0
        layout.minimumLineSpacing = 10.0
        layout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0)

        collectionView = UICollectionView(frame: self.contentView.bounds, collectionViewLayout: layout)
        if let collectionView = collectionView {
            collectionView.clipsToBounds = true
            collectionView.delegate = self
            collectionView.dataSource = self
            collectionView.showsVerticalScrollIndicator = false
            collectionView.showsHorizontalScrollIndicator = false
            collectionView.alwaysBounceVertical = false
            collectionView.alwaysBounceHorizontal = true
            collectionView.backgroundColor = UIColor.darkGray
            collectionView.contentInset = UIEdgeInsetsMake(10, 10, 10, 10)
            collectionView.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0)
            collectionView.registerReusableCell(DashboardItemCollectionCell.self)
            self.contentView.addSubview(collectionView)
        }
    }

    override func usesEstimatedHeight() -> Bool {
        return false
    }

    override func getHeight() -> CGFloat {
        return 123
    }

    override func updateConstraints() {
        super.updateConstraints()
        headerLabel.autoPinEdge(toSuperviewEdge: .top, withInset: 10)
        headerLabel.autoPinEdge(toSuperviewEdge: .left, withInset: 12)
        headerLabel.autoPinEdge(toSuperviewEdge: .right, withInset: 12)

        if let collectionView = collectionView {
            collectionView.autoPinEdge(.top, to: .bottom, of: headerLabel, withOffset: 10)
            collectionView.autoPinEdge(toSuperviewEdge: .left)
            collectionView.autoPinEdge(toSuperviewEdge: .right)
            collectionView.autoPinEdge(toSuperviewEdge: .bottom)

            NSLayoutConstraint.autoSetPriority(999, forConstraints: { () -> Void in
                collectionView.autoSetDimension(.height, toSize: 62)
            })
        }
    }

    // MARK: UICollectionView

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let item = model as? STMDashboardItem {
            return item.items?.count ?? 0
        }

        return 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(for: indexPath, cellType: DashboardItemCollectionCell.self)
        cell.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0)

        if let item = model as? STMDashboardItem {
            if let items = item.items {
                cell.setContent(items[indexPath.row])
            }
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 62, height: 62)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        AppDelegate.del().removeBlurEffects()

        guard let window = self.window else {
            return
        }

        guard let cell = collectionView.cellForItem(at: indexPath) as? DashboardItemCollectionCell else {
            return
        }

        guard let stream = cell.model as? STMStream else {
            return
        }

        let lightBlurView = UIVisualEffectView()
        window.addSubview(lightBlurView)

        let touchGesture = UITapGestureRecognizer(target: self, action: #selector(DashboardItemCell.hideEffect))
        lightBlurView.addGestureRecognizer(touchGesture)

        let image = UIImage.imageFrom(view: cell)
        let imageView = UIImageView(image: image)
        imageView.frame = collectionView.convert(cell.frame, to: window)
        window.addSubview(imageView)

        let infoHolderView = DashboardStreamInfoView(stream: stream)
        infoHolderView.startBT.tag = indexPath.row
        infoHolderView.startBT.addTarget(self, action: #selector(DashboardItemCell.startStreamClicked(_:)), for: .touchUpInside)
        infoHolderView.alpha = 0.0
        window.addSubview(infoHolderView)

        infoHolderView.triangleIndicator.autoAlignAxis(.vertical, toSameAxisOf: imageView)
        infoHolderView.autoPinEdge(.top, to: .bottom, of: imageView, withOffset: 5)
        infoHolderView.autoPinEdge(toSuperviewEdge: .left, withInset: 15)
        infoHolderView.autoPinEdge(toSuperviewEdge: .right, withInset: 15)

        lightBlurView.autoPinEdgesToSuperviewEdges()
        AppDelegate.del().currentWindowEffects = [lightBlurView, imageView, infoHolderView]

        UIView.animate(withDuration: Constants.UI.Animation.visualEffectsLength, animations: { () -> Void in
            infoHolderView.alpha = 1.0
            let effect = UIBlurEffect(style: .dark)
            lightBlurView.effect = effect
        }) 
    }

    func startStreamClicked(_ startBT: UIButton) {
        guard let item = model as? STMDashboardItem else {
            return
        }

        guard let items = item.items else {
            return
        }

        guard let window = self.window else {
            return
        }

        guard let topVC = window.rootViewController else {
            return
        }

        hideEffect()

        let stream = items[startBT.tag]
        let vc = PlayerViewController()
        let activeVC = AppDelegate.del().activeStreamController

        vc.start(stream, vc: topVC) { (nothing, error) -> Void in
            if let error = error {
                (activeVC ?? topVC).showError(error)
            } else {
                AppDelegate.del().presentStreamController(vc)
            }
        }
    }

    func hideEffect() {
        AppDelegate.del().removeBlurEffects()
    }

    override func fillInCellData(_ shallow: Bool) {
        if let item = model as? STMDashboardItem {
            headerLabel.text = item.name?.uppercased()
            self.collectionView?.reloadData()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        headerLabel.text = ""
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        func change() {
            self.backgroundColor = highlighted ? RGB(250) : RGB(255)
        }

        if animated {
            UIView.animate(withDuration: 0.5, animations: change)
        } else {
            change()
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        func change() {
            self.backgroundColor = selected ? RGB(250) : RGB(255)
        }

        if animated {
            UIView.animate(withDuration: 0.5, animations: change)
        } else {
            change()
        }
    }
    
}
