//
//  UILabelStyles.swift
//  STM
//
//  Created by Kesi Maduka on 2/20/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit

extension UILabel {

    class func styledForSettingsHeader(text: String = "{HEADER TEXT}") -> UILabel {
        let label = UILabel()
        label.backgroundColor = Constants.UI.Color.tint
        label.text = text
        label.textAlignment = .Center
        label.font = UIFont.systemFontOfSize(13, weight: UIFontWeightLight)
        label.textColor = RGB(255)
        label.autoSetDimension(.Height, toSize: 22)
        return label
    }

    class func styledForDashboardHeader(text: String = "{HEADER TEXT}") -> UILabel {
        let label = UILabel()
        label.textColor = Constants.UI.Color.tint
        label.text = text
        label.font = UIFont.systemFontOfSize(15, weight: UIFontWeightMedium)
        label.backgroundColor = UIColor.clearColor()
        label.autoSetDimension(.Height, toSize: 20)
        return label
    }

}
