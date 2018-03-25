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
        self.textLabel.font = UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.medium)
        self.textLabel.numberOfLines = 0
        self.detailLabel.font = UIFont.systemFont(ofSize: 13, weight: UIFont.Weight.light)
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

        holdingView.autoPinEdge(toSuperviewEdge: .top, withInset: padding, relation: .greaterThanOrEqual)
        holdingView.autoPinEdge(toSuperviewEdge: .left, withInset: padding)
        holdingView.autoMatch(.width, to: .width, of: self, withMultiplier: 0.4, relation: .lessThanOrEqual)
        holdingView.autoPinEdge(toSuperviewEdge: .bottom, withInset: padding, relation: .greaterThanOrEqual)

        textLabel.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .bottom)

        if detailLabel.text?.count == 0 {
            textLabel.autoPinEdge(toSuperviewEdge: .bottom)
        } else {
            holdingView.addSubview(detailLabel)
            detailLabel.autoPinEdge(.top, to: .bottom, of: textLabel, withOffset: 4)
            detailLabel.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .top)
        }

        control.autoPinEdge(toSuperviewEdge: .top, withInset: padding, relation: .greaterThanOrEqual)
        control.autoPinEdge(.left, to: .right, of: holdingView, withOffset: 25)
        control.autoPinEdge(toSuperviewEdge: .right, withInset: padding)
        control.autoPinEdge(toSuperviewEdge: .bottom, withInset: padding, relation: .greaterThanOrEqual)

        control.autoAlignAxis(.horizontal, toSameAxisOf: holdingView)
    }

    func setPrevChain(_ prevChain: UIView?) {
        if let prevChain = prevChain as? SettingJoinedView {
            let line = UIView.lineWithBGColor(RGB(217))
            if let su = self.superview {
                su.addSubview(line)
                line.autoPinEdge(.top, to: .bottom, of: prevChain)
                line.autoPinEdge(toSuperviewEdge: .left)
                line.autoPinEdge(toSuperviewEdge: .right)
                self.autoPinEdge(.top, to: .bottom, of: line)
            }
            self.holdingView.autoMatch(.width, to: .width, of: prevChain.holdingView)
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
