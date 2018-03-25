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
                actionButton.isSelected = selected
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

        actionButton.setImage(UIImage(named: imageName), for: .normal)
        actionButton.setImage(UIImage(named: selectedImageName), for: .selected)
        addSubview(actionButton)

        countLabel.font = UIFont.systemFont(ofSize: 12.0)
        countLabel.textColor = RGB(172)
        countLabel.text = count.formatUsingAbbrevation()
        addSubview(countLabel)

        setupConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupConstraints() {
        actionButton.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 2, left: 10, bottom: 2, right: 0), excludingEdge: .right)

        countLabel.autoPinEdge(.left, to: .right, of: actionButton, withOffset: 10)
        countLabel.autoPinEdge(toSuperviewEdge: .right, withInset: 10)
        countLabel.autoAlignAxis(.horizontal, toSameAxisOf: actionButton)
    }

    @objc override func estimatedHeight(_ maxWidth: CGFloat) -> CGFloat {
        var height = CGFloat(2)
        height = height + actionButton.estimatedHeight(maxWidth)
        height = height + 2
        return height
    }

}
