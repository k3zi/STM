//
//  DashboardItemCollectionCell.swift
//  STM
//
//  Created by Kesi Maduka on 2/27/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit

class DashboardItemCollectionCell: UICollectionViewCell, Reusable {
    var imageView = UIImageView()
    var model: Any?

    override init(frame: CGRect) {
        super.init(frame: frame)

        imageView.contentMode = .ScaleAspectFit
        imageView.backgroundColor = RGB(255)
        imageView.layer.cornerRadius = 62.0/2.0
        imageView.clipsToBounds = true
        self.addSubview(imageView)
        setupConstraints()
    }

    func setupConstraints() {
        imageView.autoSetDimensionsToSize(CGSize(width: 62, height: 62))
        imageView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)
    }

    func setContent(model: Any?) {
        self.model = model
        if let stream = model as? STMStream {
            imageView.kf_setImageWithURL(stream.pictureURL(), placeholderImage: UIImage(named: "defaultStreamImage"), optionsInfo: nil, progressBlock: nil, completionHandler: nil)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
