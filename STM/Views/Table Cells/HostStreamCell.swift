//
//  HostStreamCell.swift
//  STM
//
//  Created by Kesi Maduka on 2/2/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit

class HostStreamCell: KZTableViewCell {
    let avatar = UIImageView()
    let nameLabel = UILabel()
    let tagLabel = Label()

    required init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = RGB(255)

        avatar.layer.cornerRadius = 35.0/2.0
        avatar.backgroundColor = RGB(72, g: 72, b: 72)
        avatar.clipsToBounds = true
        self.contentView.addSubview(avatar)

        nameLabel.font = UIFont.systemFontOfSize(14)
        self.contentView.addSubview(nameLabel)

        tagLabel.textColor = RGB(127, g: 127, b: 127)
        tagLabel.font = UIFont.systemFontOfSize(12, weight: UIFontWeightBold)
        tagLabel.setContentEdgeInsets(UIEdgeInsets(top: 4, left: 5, bottom: 4, right: 5))
        tagLabel.backgroundColor = RGB(230)
        tagLabel.layer.cornerRadius = 5
        self.contentView.addSubview(tagLabel)

        self.accessoryType = .DisclosureIndicator
    }

    override func updateConstraints() {
        super.updateConstraints()
        NSLayoutConstraint.autoSetPriority(999) { () -> Void in
            self.avatar.autoSetDimensionsToSize(CGSize(width: 35.0, height: 35.0))
        }
        avatar.autoPinEdgeToSuperviewEdge(.Top, withInset: 10)
        avatar.autoPinEdgeToSuperviewEdge(.Bottom, withInset: 10)
        avatar.autoPinEdgeToSuperviewEdge(.Left, withInset: 10)

        nameLabel.autoPinEdgeToSuperviewEdge(.Top, withInset: 10)
        nameLabel.autoPinEdge(.Left, toEdge: .Right, ofView: avatar, withOffset: 10)
        nameLabel.autoPinEdgeToSuperviewEdge(.Bottom, withInset: 10)

        tagLabel.autoPinEdgeToSuperviewEdge(.Right, withInset: 10)
        tagLabel.autoPinEdge(.Left, toEdge: .Right, ofView: nameLabel, withOffset: 10, relation: .GreaterThanOrEqual)
        tagLabel.autoAlignAxis(.Horizontal, toSameAxisOfView: nameLabel)
    }

    override func fillInCellData() {
        if let stream = model as? STMStream {
            nameLabel.text = stream.name
            tagLabel.text = stream.alphaID()

            avatar.kf_setImageWithURL(stream.pictureURL(), placeholderImage: UIImage(named: "defaultStreamImage"), optionsInfo: nil, progressBlock: nil, completionHandler: nil)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        nameLabel.text = ""
        tagLabel.text = ""
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setHighlighted(highlighted: Bool, animated: Bool) {
        func change() {
            self.backgroundColor = highlighted ? RGB(250) : RGB(255)
        }

        if animated {
            UIView.animateWithDuration(0.5, animations: change)
        } else {
            change()
        }
    }

    override func setSelected(selected: Bool, animated: Bool) {
        func change() {
            self.backgroundColor = selected ? RGB(250) : RGB(255)
        }

        if animated {
            UIView.animateWithDuration(0.5, animations: change)
        } else {
            change()
        }
    }
}
