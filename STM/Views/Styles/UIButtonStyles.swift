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

    class func styleForCreateAccountButton() -> UIButton {
        let string = NSMutableAttributedString()
        string.append(NSAttributedString(string: "New to STM?", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 14), NSForegroundColorAttributeName: UIColor.white]))
        string.append(NSAttributedString(string: " Create Account ->", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14), NSForegroundColorAttributeName: RGB(129, g: 136, b: 168)]))
        let button = ExtendedButton()
        button.setAttributedTitle(string, for: .normal)
        return button
    }

    class func styleForBackButton() -> UIButton {
        let button = ExtendedButton()
        button.setImage(UIImage(named: "navBarBackBT"), for: .normal)
        return button
    }

    class func styleForDismissButton() -> UIButton {
        let button = ExtendedButton()
        button.setImage(#imageLiteral(resourceName: "miniPlayerDismissBT"), for: .normal)
        button.setImage(#imageLiteral(resourceName: "miniPlayerMaximizeBT"), for: .selected)
        return button
    }

    class func styleForCloseButton() -> UIButton {
        let button = ExtendedButton()
        button.setImage(UIImage(named: "navBarCloseBT"), for: .normal)
        return button
    }

    class func styleForMiscButton() -> UIButton {
        let button = ExtendedButton()
        button.setImage(UIImage(named: "navBarMiscBT"), for: .normal)
        button.setImage(UIImage(named: "navBarMiscHighlightedBT"), for: .highlighted)
        return button
    }

    class func styledForLaunchScreen() -> UIButton {
        let button = UIButton()
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: UIFontWeightMedium)
        button.setTitleColor(RGB(255), for: .normal)
        button.setBackgroundColor(UIColor.clear, forState: .normal)
        button.setTitleColor(Constants.UI.Color.tint, for: .highlighted)
        button.setBackgroundColor(RGB(255), forState: .highlighted)
        button.clipsToBounds = true
        button.layer.cornerRadius = 10
        button.layer.borderColor = RGB(255).cgColor
        button.layer.borderWidth = 2

        return button
    }

    class func styledForStreamInfoView() -> UIButton {
        let button = UIButton()
        button.autoSetDimension(.height, toSize: 50)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: UIFontWeightMedium)
        button.setTitleColor(RGB(255), for: .normal)
        button.setBackgroundColor(Constants.UI.Color.tint, forState: .normal)
        button.setBackgroundColor(Constants.UI.Color.off, forState: .disabled)
        button.isEnabled = false
        button.clipsToBounds = true

        return button
    }

    class func styledForCellButton(_ normalTitle: String, selectedTitle: String? = nil) -> UIButton {
        let button = UIButton()
        button.setBackgroundColor(UIColor.clear, forState: .normal)
        button.setBackgroundColor(Constants.UI.Color.tint, forState: .selected)
        button.setTitleColor(Constants.UI.Color.tint, for: .normal)
        button.setTitleColor(RGB(255), for: .selected)
        button.setTitle(normalTitle, for: UIControlState())
        button.setTitle(selectedTitle, for: .selected)

        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: UIFontWeightMedium)
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 15, bottom: 5, right: 15)
        button.clipsToBounds = true
        button.layer.cornerRadius = 10
        button.layer.borderColor = Constants.UI.Color.tint.cgColor
        button.layer.borderWidth = 1

        return button
    }

    func showIndicator() {
        hideIndicator()
        self.isEnabled = false

        let indicatorView = UIView()
        indicatorView.alpha = 0.0
        indicatorView.backgroundColor = RGB(255)
        indicatorView.tag = indicatorViewTag
        self.addSubview(indicatorView)

        let indicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        indicator.color = Constants.UI.Color.tint
        indicatorView.addSubview(indicator)
        indicator.startAnimating()

        indicatorView.autoPinEdgesToSuperviewEdges()
        indicator.autoAlignAxis(toSuperviewAxis: .horizontal)
        indicator.autoAlignAxis(toSuperviewAxis: .vertical)
        self.layoutIfNeeded()

        UIView.animate(withDuration: 0.4, animations: {
            indicatorView.alpha = 1.0
        })
    }

    func hideIndicator() {
        self.isEnabled = true
        if let view = self.viewWithTag(indicatorViewTag) {
            UIView.animate(withDuration: 0.4, animations: {
                view.alpha = 0.0
                }, completion: { (finished) in
                    view.removeFromSuperview()
            })
        }
    }

}
