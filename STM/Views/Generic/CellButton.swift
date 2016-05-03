//
//  CellButton.swift
//  STM
//
//  Created by Kesi Maduka on 4/29/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import Foundation

class CellButton: UIView {

    let actionButton = ExtendedButton()
    let countLabel = UILabel()
    var selectedColor: UIColor?
    var shallow = false
    var selected = false {
        didSet {
            if !shallow {
                actionButton.selected = selected
                countLabel.textColor = selected ? selectedColor : RGB(172)
            }
        }
    }

    var count = 0 {
        didSet {
            if !shallow {
                self.countLabel.text = count.formatUsingAbbrevation()
            }
        }
    }

    init(imageName: String, selectedImageName: String, count: Int) {
        super.init(frame: CGRect.zero)
        self.translatesAutoresizingMaskIntoConstraints = false

        actionButton.setImage(UIImage(named: imageName), forState: .Normal)
        actionButton.setImage(UIImage(named: selectedImageName), forState: .Selected)
        addSubview(actionButton)

        countLabel.font = UIFont.systemFontOfSize(12.0)
        countLabel.textColor = RGB(172)
        countLabel.text = count.formatUsingAbbrevation()
        addSubview(countLabel)

        setupConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupConstraints() {
        actionButton.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsets(top: 2, left: 10, bottom: 2, right: 0), excludingEdge: .Right)

        countLabel.autoPinEdge(.Left, toEdge: .Right, ofView: actionButton, withOffset: 10)
        countLabel.autoPinEdgeToSuperviewEdge(.Right, withInset: 10)
        countLabel.autoAlignAxis(.Horizontal, toSameAxisOfView: actionButton)
    }

    override func estimatedHeight(maxWidth: CGFloat) -> CGFloat {
        var height = CGFloat(2)
        height = height + actionButton.estimatedHeight(maxWidth)
        height = height + 2
        return height
    }

}
