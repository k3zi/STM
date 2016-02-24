//
//  SettingJoinedView.swift
//  STM
//
//  Created by Kesi Maduka on 2/20/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit

class SettingJoinedView: UIView {
    var textLabel = UILabel()
    var detailLabel = UILabel()
    var holdingView = UILabel()
    var control: UIView

    let padding = CGFloat(12.0)

    init(text: String, detailText: String = "", control: UIView) {
        self.textLabel.font = UIFont.systemFontOfSize(16, weight: UIFontWeightMedium)
        self.textLabel.numberOfLines = 0
        self.detailLabel.font = UIFont.systemFontOfSize(13, weight: UIFontWeightLight)
        self.detailLabel.numberOfLines = 0

        self.detailLabel.text = detailText
        self.textLabel.text = text
        self.control = control
        super.init(frame:CGRect.zero)

        setup()
    }

    func setup() {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(holdingView)
        holdingView.addSubview(textLabel)
        self.addSubview(control)

        holdingView.autoPinEdgeToSuperviewEdge(.Top, withInset: padding, relation: .GreaterThanOrEqual)
        holdingView.autoPinEdgeToSuperviewEdge(.Left, withInset: padding)
        holdingView.autoMatchDimension(.Width, toDimension: .Width, ofView: self, withMultiplier: 0.4, relation: .LessThanOrEqual)
        holdingView.autoPinEdgeToSuperviewEdge(.Bottom, withInset: padding, relation: .GreaterThanOrEqual)

        textLabel.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero, excludingEdge: .Bottom)

        if detailLabel.text?.characters.count == 0 {
            textLabel.autoPinEdgeToSuperviewEdge(.Bottom)
        } else {
            holdingView.addSubview(detailLabel)
            detailLabel.autoPinEdge(.Top, toEdge: .Bottom, ofView: textLabel, withOffset: 4)
            detailLabel.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero, excludingEdge: .Top)
        }

        control.autoPinEdgeToSuperviewEdge(.Top, withInset: padding, relation: .GreaterThanOrEqual)
        control.autoPinEdge(.Left, toEdge: .Right, ofView: holdingView, withOffset: 25)
        control.autoPinEdgeToSuperviewEdge(.Right, withInset: padding)
        control.autoPinEdgeToSuperviewEdge(.Bottom, withInset: padding, relation: .GreaterThanOrEqual)

        control.autoAlignAxis(.Horizontal, toSameAxisOfView: holdingView)
    }

    func setPrevChain(prevChain: UIView?) {
        if let prevChain = prevChain as? SettingJoinedView {
            let line = UIView.lineWithBGColor(RGB(217))
            if let su = self.superview {
                su.addSubview(line)
                line.autoPinEdge(.Top, toEdge: .Bottom, ofView: prevChain)
                line.autoPinEdgeToSuperviewEdge(.Left)
                line.autoPinEdgeToSuperviewEdge(.Right)
                self.autoPinEdge(.Top, toEdge: .Bottom, ofView: line)
            }
            self.holdingView.autoMatchDimension(.Width, toDimension: .Width, ofView: prevChain.holdingView)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.textLabel.preferredMaxLayoutWidth = self.textLabel.frame.width
        self.detailLabel.preferredMaxLayoutWidth = self.detailLabel.frame.width
        super.layoutSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
