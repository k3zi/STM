//
//  ConvoCell.swift
//  STM
//
//  Created by Kesi Maduka on 2/2/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit
import KILabel
import DateTools

class ConvoCell: KZTableViewCell {
	let avatar = UIImageView()
	let nameLabel = UILabel()
	let messageLabel = KILabel()

	required init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		self.backgroundColor = RGB(255)
        self.selectionStyle = .None
        self.accessoryType = .DisclosureIndicator

		avatar.layer.cornerRadius = 45.0 / 9.0
		avatar.backgroundColor = Constants.UI.Color.imageViewDefault
		avatar.clipsToBounds = true
		self.contentView.addSubview(avatar)

		nameLabel.font = UIFont.boldSystemFontOfSize(14)
        nameLabel.textColor = Constants.UI.Color.tint
		self.contentView.addSubview(nameLabel)

        messageLabel.numberOfLines = 0
		messageLabel.font = UIFont.systemFontOfSize(14)
        messageLabel.tintColor = Constants.UI.Color.tint
		self.contentView.addSubview(messageLabel)
	}

	override func updateConstraints() {
		super.updateConstraints()
		NSLayoutConstraint.autoSetPriority(999) { () -> Void in
			self.avatar.autoSetDimensionsToSize(CGSize(width: 45.0, height: 45.0))
		}

		avatar.autoPinEdgeToSuperviewEdge(.Top, withInset: 10)
		avatar.autoPinEdgeToSuperviewEdge(.Bottom, withInset: 10)
		avatar.autoPinEdgeToSuperviewEdge(.Left, withInset: 10)

		nameLabel.autoPinEdgeToSuperviewEdge(.Top, withInset: 13)
		nameLabel.autoPinEdge(.Left, toEdge: .Right, ofView: avatar, withOffset: 10)
        nameLabel.autoPinEdgeToSuperviewEdge(.Right, withInset: 10)

		messageLabel.autoPinEdge(.Top, toEdge: .Bottom, ofView: nameLabel, withOffset: 2)
		messageLabel.autoPinEdge(.Left, toEdge: .Right, ofView: avatar, withOffset: 10)
		messageLabel.autoPinEdgeToSuperviewEdge(.Bottom, withInset: 10)
        messageLabel.autoPinEdgeToSuperviewEdge(.Right, withInset: 10)
	}

    override func estimatedHeight() -> CGFloat {
        let rightSideWidth = Constants.UI.Screen.width - 10 - 45 - 10 - 10
        var height = CGFloat(13) //top padding
        height = height + nameLabel.estimatedHeight(rightSideWidth)
        height = height + 2 //padding
        height = height + messageLabel.estimatedHeight(rightSideWidth)
        height = height + 10 //bottom padding
        return ceil(height)
    }

	override func fillInCellData(shallow: Bool) {
        guard let convo = model as? STMConversation else {
            return
        }

        nameLabel.text = convo.listNames()

        if convo.users?.count > 2 {
            let colorHash = String(convo.id).MD5()
            let hexHash = colorHash.substringToIndex(colorHash.startIndex.advancedBy(6))
            var color = HEX(hexHash)

            var h = CGFloat(0)
            var s = CGFloat(0)
            var b = CGFloat(0)
            var a = CGFloat(0)
            color.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
            color = UIColor(hue: h, saturation: 0.4, brightness: 0.96, alpha: a)
            avatar.backgroundColor = color
        } else if let users = convo.users {
            for user in users {
                if user.id != AppDelegate.del().currentUser?.id && !shallow {
                    avatar.kf_setImageWithURL(user.profilePictureURL(), placeholderImage: UIImage(named: "defaultProfilePicture"))
                }
            }
        }

        if let message = convo.lastMessage {
            messageLabel.text = message.text
        }

        backgroundColor = convo.unreadCount == 0 ? RGB(241, g: 242, b: 243) : RGB(255)
	}

	override func prepareForReuse() {
		super.prepareForReuse()

		nameLabel.text = ""
		messageLabel.text = ""

        avatar.kf_cancelDownloadTask()
        avatar.image = nil
	}

    override func setIndexPath(indexPath: NSIndexPath, last: Bool) {
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
