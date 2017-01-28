//
//  GradientView.swift
//  STM
//
//  Created by Kesi Maduka on 2/2/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit

class GradientView: UIView {
    var gradientLayer = CAGradientLayer()

    override init (frame: CGRect) {
        super.init(frame : frame)

        gradientLayer.frame = self.bounds
        gradientLayer.colors = [UIColor.red.cgColor, UIColor.white.cgColor]
        self.layer.addSublayer(gradientLayer)
    }

    convenience init () {
        self.init(frame:CGRect.zero)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        gradientLayer.frame = self.bounds
    }
}
