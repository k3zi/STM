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
        button.setImage(UIImage(named: "navBarMaximizeBT"), forState: .Selected)
        return button
    }

    class func styleForCloseButton() -> UIButton {
        let button = ExtendedButton()
        button.setImage(UIImage(named: "navBarCloseBT"), forState: .Normal)
        return button
    }

    class func styleForMiscButton() -> UIButton {
        let button = ExtendedButton()
        button.setImage(UIImage(named: "navBarMiscBT"), forState: .Normal)
        button.setImage(UIImage(named: "navBarMiscHighlightedBT"), forState: .Highlighted)
        return button
    }

    class func styledForLaunchScreen() -> UIButton {
        let button = UIButton()
        button.titleLabel?.font = UIFont.systemFontOfSize(17, weight: UIFontWeightMedium)
        button.setTitleColor(RGB(255), forState: .Normal)
        button.setBackgroundColor(UIColor.clearColor(), forState: .Normal)
        button.setTitleColor(Constants.UI.Color.tint, forState: .Highlighted)
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
        button.setBackgroundColor(Constants.UI.Color.tint, forState: .Normal)
        button.setBackgroundColor(Constants.UI.Color.off, forState: .Disabled)
        button.enabled = false
        button.clipsToBounds = true

        return button
    }

    class func styledForCellButton(normalTitle: String, selectedTitle: String? = nil) -> UIButton {
        let button = UIButton()
        button.setBackgroundColor(UIColor.clearColor(), forState: .Normal)
        button.setBackgroundColor(Constants.UI.Color.tint, forState: .Selected)
        button.setTitleColor(Constants.UI.Color.tint, forState: .Normal)
        button.setTitleColor(RGB(255), forState: .Selected)
        button.setTitle(normalTitle, forState: .Normal)
        button.setTitle(selectedTitle, forState: .Selected)

        button.titleLabel?.font = UIFont.systemFontOfSize(14, weight: UIFontWeightMedium)
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 15, bottom: 5, right: 15)
        button.clipsToBounds = true
        button.layer.cornerRadius = 10
        button.layer.borderColor = Constants.UI.Color.tint.CGColor
        button.layer.borderWidth = 1

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
        indicator.color = Constants.UI.Color.tint
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
