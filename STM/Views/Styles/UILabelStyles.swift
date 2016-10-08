//
//  UILabelStyles.swift
//  STM
//
//  Created by Kesi Maduka on 2/20/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit

extension UILabel {

    class func styledForSettingsHeader(_ text: String = "{HEADER TEXT}") -> UILabel {
        let label = UILabel()
        label.backgroundColor = Constants.UI.Color.tint
        label.text = text
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 13, weight: UIFontWeightLight)
        label.textColor = RGB(255)
        label.autoSetDimension(.height, toSize: 22)
        return label
    }

    class func styledForDashboardHeader(_ text: String = "{HEADER TEXT}") -> UILabel {
        let label = UILabel()
        label.textColor = Constants.UI.Color.tint3
        label.text = text.uppercased()
        label.font = UIFont.systemFont(ofSize: 13, weight: UIFontWeightBold)
        label.backgroundColor = UIColor.clear
        label.autoSetDimension(.height, toSize: 20)
        return label
    }

}
