//
//  UILabelStyles.swift
//  STM
//
//  Created by Kesi Maduka on 2/20/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit

extension UILabel {
    class func styledForSettingsHeader(text: String) -> UILabel {
        let label = UILabel()
        label.backgroundColor = Constants.Color.tint
        label.text = text
        label.textAlignment = .Center
        label.font = UIFont.systemFontOfSize(13, weight: UIFontWeightLight)
        label.textColor = RGB(255)
        label.autoSetDimension(.Height, toSize: 22)
        return label
    }
}
