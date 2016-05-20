//
//  CommentCell.swift
//  STM
//
//  Created by Kesi Maduka on 2/2/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit
import KILabel
import DateTools

class SearchUserCell: KZTableViewCell {
	let avatar = UIImageView()
	let nameLabel = UILabel()
	let messageLabel = KILabel()
    let followButton = UIButton.styledForCellButton("Follow", selectedTitle: "Unfollow")

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

        followButton.addTarget(self, action: #selector(self.toggleFollow), forControlEvents: .TouchUpInside)
        self.contentView.addSubview(followButton)
	}

    func toggleFollow() {
        guard let user = model as? STMUser else {
            return
        }

        let method = followButton.selected ? "unfollow" : "follow"
        UIView.transitionWithView(self.followButton, duration: 0.2, options: .TransitionCrossDissolve, animations: {
            self.followButton.selected = !self.followButton.selected
        }, completion: nil)
        Constants.Network.GET("/user/\(user.id)/\(method)", parameters: nil) { (response, error) in
            dispatch_async(dispatch_get_main_queue(), {
                NSNotificationCenter.defaultCenter().postNotificationName(Constants.Notification.UpdateUserProfile, object: nil)
            })
        }
    }

	override func updateConstraints() {
		super.updateConstraints()
		NSLayoutConstraint.autoSetPriority(999) { () -> Void in
			self.avatar.autoSetDimensionsToSize(CGSize(width: 45.0, height: 45.0))
		}

		avatar.autoPinEdgeToSuperviewEdge(.Top, withInset: 10)
		avatar.autoPinEdgeToSuperviewEdge(.Bottom, withInset: 10, relation: .GreaterThanOrEqual)
		avatar.autoPinEdgeToSuperviewEdge(.Left, withInset: 10)

		nameLabel.autoPinEdgeToSuperviewEdge(.Top, withInset: 13)
		nameLabel.autoPinEdge(.Left, toEdge: .Right, ofView: avatar, withOffset: 10)

		messageLabel.autoPinEdge(.Top, toEdge: .Bottom, ofView: nameLabel, withOffset: 2)
		messageLabel.autoPinEdge(.Left, toEdge: .Right, ofView: avatar, withOffset: 10)
        messageLabel.autoMatchDimension(.Width, toDimension: .Width, ofView: nameLabel)
		messageLabel.autoPinEdgeToSuperviewEdge(.Bottom, withInset: 10, relation: .GreaterThanOrEqual)

        followButton.autoPinEdge(.Left, toEdge: .Right, ofView: nameLabel, withOffset: 10)
        followButton.autoPinEdgeToSuperviewEdge(.Right, withInset: 10)
        followButton.autoAlignAxis(.Horizontal, toSameAxisOfView: avatar)
        followButton.autoSetDimension(.Height, toSize: 30.0)
        NSLayoutConstraint.autoSetPriority(999) {
            self.followButton.autoSetContentHuggingPriorityForAxis(.Horizontal)
        }
	}

	override func fillInCellData(shallow: Bool) {
        guard let user = model as? STMUser else {
            return
        }

        if !shallow {
            avatar.kf_setImageWithURL(user.profilePictureURL(), placeholderImage: UIImage(named: "defaultProfilePicture"))
        }

        nameLabel.text = user.displayName
        followButton.selected = user.isFollowing
        followButton.hidden = AppDelegate.del().currentUser?.id == user.id
        messageLabel.text = "@" + user.username
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
