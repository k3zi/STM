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
        countLabel.textAlignment = .center
        countLabel.textColor = RGB(255)
        countLabel.font = UIFont.systemFont(ofSize: 27, weight: UIFontWeightLight)
        addSubview(countLabel)

        nameLabel.text = name
        nameLabel.textAlignment = .center
        nameLabel.textColor = RGB(244)
        nameLabel.font = UIFont.systemFont(ofSize: 13, weight: UIFontWeightMedium)
        addSubview(nameLabel)

        setupConstraints()
    }

    func setupConstraints() {

        countLabel.autoPinEdge(toSuperviewEdge: .top, withInset: 10)
        countLabel.autoAlignAxis(toSuperviewAxis: .vertical)

        nameLabel.autoPinEdge(.top, to: .bottom, of: countLabel, withOffset: 10)
        NSLayoutConstraint.autoSetPriority(999) {
            self.nameLabel.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10), excludingEdge: .top)
        }

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
