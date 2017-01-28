//
//  SearchStreamCell.swift
//  STM
//
//  Created by Kesi Maduka on 2/2/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit
import KILabel
import DateTools

class SearchStreamCell: KZTableViewCell {
    let statusView = StreamStatusView()
	let avatar = UIImageView()
	let nameLabel = UILabel()
	let messageLabel = KILabel()

	required init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		self.backgroundColor = RGB(255)
        self.selectionStyle = .none
        self.accessoryType = .disclosureIndicator

        self.contentView.addSubview(statusView)

		avatar.layer.cornerRadius = 45.0 / 2.0
		avatar.backgroundColor = Constants.UI.Color.imageViewDefault
		avatar.clipsToBounds = true
		self.contentView.addSubview(avatar)

		nameLabel.font = UIFont.boldSystemFont(ofSize: 14)
        nameLabel.textColor = Constants.UI.Color.tint
		self.contentView.addSubview(nameLabel)

        messageLabel.numberOfLines = 0
		messageLabel.font = UIFont.systemFont(ofSize: 14)
        messageLabel.tintColor = Constants.UI.Color.tint
		self.contentView.addSubview(messageLabel)
	}

	override func updateConstraints() {
		super.updateConstraints()
		NSLayoutConstraint.autoSetPriority(999) { () -> Void in
			self.avatar.autoSetDimensions(to: CGSize(width: 45.0, height: 45.0))
		}

        statusView.autoAlignAxis(.horizontal, toSameAxisOf: avatar)
        statusView.autoPinEdge(toSuperviewEdge: .left, withInset: 10)

		avatar.autoPinEdge(toSuperviewEdge: .top, withInset: 10)
		avatar.autoPinEdge(toSuperviewEdge: .bottom, withInset: 10, relation: .greaterThanOrEqual)
		avatar.autoPinEdge(.left, to: .right, of: statusView, withOffset: 10)

		nameLabel.autoPinEdge(toSuperviewEdge: .top, withInset: 13)
		nameLabel.autoPinEdge(.left, to: .right, of: avatar, withOffset: 10)
		nameLabel.autoPinEdge(toSuperviewEdge: .right, withInset: 10)

		messageLabel.autoPinEdge(.top, to: .bottom, of: nameLabel, withOffset: 2)
		messageLabel.autoPinEdge(.left, to: .right, of: avatar, withOffset: 10)
		messageLabel.autoPinEdge(toSuperviewEdge: .right, withInset: 10)
		messageLabel.autoPinEdge(toSuperviewEdge: .bottom, withInset: 10, relation: .greaterThanOrEqual)
	}

    override func estimatedHeight() -> CGFloat {
        let minHeight = CGFloat(10 + 45 + 10)
        let rightWidth = Constants.UI.Screen.width - 10 - 10 - 45 - 10

        var height = CGFloat(0)
        height = height + 10
        height = height + nameLabel.estimatedHeight(rightWidth)
        height = height + 2
        height = height + messageLabel.estimatedHeight(rightWidth)
        height = height + 10

        return max(minHeight, height)
    }

	override func fillInCellData(_ shallow: Bool) {
		if let stream = model as? STMStream {
            statusView.stream = stream
            nameLabel.text = stream.name
            messageLabel.text = stream.description

            if !shallow {
                avatar.kf.setImage(with: stream.pictureURL(), placeholder: UIImage(named: "defaultStreamImage"), options: nil, progressBlock: nil, completionHandler: nil)
            }
		}
	}

	override func prepareForReuse() {
		super.prepareForReuse()

		nameLabel.text = ""
		messageLabel.text = ""
	}

    override func setIndexPath(_ indexPath: IndexPath, last: Bool) {
        topSeperator.alpha = 0.0
        bottomSeperator.alpha = 0.0
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        messageLabel.preferredMaxLayoutWidth = messageLabel.frame.size.width
        super.layoutSubviews()
    }

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

}
