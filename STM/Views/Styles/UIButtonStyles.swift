//
//  UIButtonStyles.swift
//  STM
//
//  Created by Kesi Maduka on 1/29/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit

let indicatorViewTag = 10001

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

    func showIndicator() {
        hideIndicator()
        self.enabled = false

        let indicatorView = UIView()
        indicatorView.alpha = 0.0
        indicatorView.backgroundColor = RGB(255)
        indicatorView.tag = indicatorViewTag
        self.addSubview(indicatorView)

        let indicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        indicator.color = Constants.Color.tint
        indicatorView.addSubview(indicator)
        indicator.startAnimating()

        indicatorView.autoPinEdgesToSuperviewEdges()
        indicator.autoAlignAxisToSuperviewAxis(.Horizontal)
        indicator.autoAlignAxisToSuperviewAxis(.Vertical)
        self.layoutIfNeeded()

        UIView.animateWithDuration(0.4) {
            indicatorView.alpha = 1.0
        }
    }

    func hideIndicator() {
        self.enabled = true
        if let view = self.viewWithTag(indicatorViewTag) {
            UIView.animateWithDuration(0.4, animations: {
                view.alpha = 0.0
                }, completion: { (finished) in
                    view.removeFromSuperview()
            })
        }
    }

}
