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
    var control: UIView

    init(text: String, control: UIView) {
        self.textLabel.text = text
        self.control = control
        super.init(frame:CGRect.zero)

        setup()
    }

    func setup() {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(textLabel)
        self.addSubview(control)

        textLabel.autoPinEdgeToSuperviewEdge(.Top, withInset: 12, relation: .GreaterThanOrEqual)
        textLabel.autoPinEdgeToSuperviewEdge(.Left, withInset: 12)
        textLabel.autoPinEdgeToSuperviewEdge(.Bottom, withInset: 12, relation: .GreaterThanOrEqual)

        control.autoPinEdgeToSuperviewEdge(.Top, withInset: 12, relation: .GreaterThanOrEqual)
        control.autoPinEdge(.Left, toEdge: .Right, ofView: textLabel, withOffset: 16)
        control.autoPinEdgeToSuperviewEdge(.Right, withInset: 12)
        control.autoPinEdgeToSuperviewEdge(.Bottom, withInset: 12, relation: .GreaterThanOrEqual)

        control.autoAlignAxis(.Horizontal, toSameAxisOfView: textLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
