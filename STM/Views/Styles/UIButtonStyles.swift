//
//  UIButtonStyles.swift
//  STM
//
//  Created by Kesi Maduka on 1/29/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit

extension UIButton {

    class func styleForBackButton() -> UIButton {
        let button = ExtendedButton()
        button.setImage(UIImage(named: "navBarBackBT"), forState: .Normal)
        return button
    }

    class func styleForDismissButton() -> UIButton {
        let button = ExtendedButton()
        button.setImage(UIImage(named: "navBarDismissBT"), forState: .Normal)
        return button
    }

    class func styledForLaunchScreen() -> UIButton {
        let button = UIButton()
        button.titleLabel?.font = UIFont.systemFontOfSize(17, weight: UIFontWeightMedium)
        button.setTitleColor(RGB(255), forState: .Normal)
        button.setBackgroundColor(UIColor.clearColor(), forState: .Normal)
        button.setTitleColor(Constants.Color.tint, forState: .Highlighted)
        button.setBackgroundColor(RGB(255), forState: .Highlighted)
        button.clipsToBounds = true
        button.layer.cornerRadius = 10
        button.layer.borderColor = RGB(255).CGColor
        button.layer.borderWidth = 2

        return button
    }

    class func styledForStreamInfoView() -> UIButton {
        let button = UIButton()
        button.autoSetDimension(.Height, toSize: 50)
        button.titleLabel?.font = UIFont.systemFontOfSize(17, weight: UIFontWeightMedium)
        button.setTitleColor(RGB(255), forState: .Normal)
        button.setBackgroundColor(Constants.Color.tint, forState: .Normal)
        button.setBackgroundColor(Constants.Color.off, forState: .Disabled)
        button.enabled = false
        button.clipsToBounds = true

        return button
    }

}
