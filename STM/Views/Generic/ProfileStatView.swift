//
//  ProfileStatView.swift
//  STM
//
//  Created by Kesi Maduka on 4/27/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import Foundation

class ProfileStatView: UIView {
    let countLabel = UILabel()
    let nameLabel = UILabel()

    var count = 0 {
        didSet {
            self.countLabel.text = count.formatUsingAbbrevation()
        }
    }

    init(count: Int, name: String) {
        super.init(frame: CGRect.zero)
        self.translatesAutoresizingMaskIntoConstraints = false

        countLabel.text = count.formatUsingAbbrevation()
        countLabel.textAlignment = .Center
        countLabel.textColor = RGB(255)
        countLabel.font = UIFont.systemFontOfSize(27, weight: UIFontWeightLight)
        addSubview(countLabel)

        nameLabel.text = name
        nameLabel.textAlignment = .Center
        nameLabel.textColor = RGB(244)
        nameLabel.font = UIFont.systemFontOfSize(13, weight: UIFontWeightMedium)
        addSubview(nameLabel)

        setupConstraints()
    }

    func setupConstraints() {

        countLabel.autoPinEdgeToSuperviewEdge(.Top, withInset: 10)
        countLabel.autoAlignAxisToSuperviewAxis(.Vertical)

        nameLabel.autoPinEdge(.Top, toEdge: .Bottom, ofView: countLabel, withOffset: 10)
        NSLayoutConstraint.autoSetPriority(999) {
            self.nameLabel.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10), excludingEdge: .Top)
        }

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
