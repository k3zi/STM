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

        imageView.contentMode = .Center
        imageView.backgroundColor = RGB(255)
        imageView.layer.cornerRadius = 62.0/2.0
        self.addSubview(imageView)
        setupConstraints()
    }

    func setupConstraints() {
        imageView.autoSetDimensionsToSize(CGSize(width: 62, height: 62))
        imageView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero, excludingEdge: .Right)
    }

    func setContent(model: Any?) {
        self.model = model
        if let stream = model as? STMStream {
            if let streamID = stream.id {
                let colorHash = String(streamID).MD5()

                if let image = UIImage(named: "defaultStreamImage") {
                    imageView.image = image.imageWithRenderingMode(.AlwaysTemplate)
                    let hexHash = colorHash.substringToIndex(colorHash.startIndex.advancedBy(6))
                    var color = HEX(hexHash)

                    var h = CGFloat(0)
                    var s = CGFloat(0)
                    var b = CGFloat(0)
                    var a = CGFloat(0)
                    color.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
                    color = UIColor(hue: h, saturation: 0.4, brightness: 0.96, alpha: a)
                    imageView.tintColor = color
                }
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
