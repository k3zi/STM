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
        self.selectionStyle = .none
        self.accessoryType = .disclosureIndicator

		avatar.layer.cornerRadius = 45.0 / 9.0
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

        followButton.addTarget(self, action: #selector(self.toggleFollow), for: .touchUpInside)
        self.contentView.addSubview(followButton)
	}

    @objc func toggleFollow() {
        guard let user = model as? STMUser else {
            return
        }

        let method = followButton.isSelected ? "unfollow" : "follow"
        UIView.transition(with: self.followButton, duration: 0.2, options: .transitionCrossDissolve, animations: {
            self.followButton.isSelected = !self.followButton.isSelected
        }, completion: nil)
        Constants.Network.GET("/user/\(user.id)/\(method)", parameters: nil) { (response, error) in
            DispatchQueue.main.async(execute: {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.Notification.UpdateUserProfile), object: nil)
            })
        }
    }

	override func updateConstraints() {
		super.updateConstraints()
		NSLayoutConstraint.autoSetPriority(UILayoutPriority(rawValue: 999)) { () -> Void in
			self.avatar.autoSetDimensions(to: CGSize(width: 45.0, height: 45.0))
		}

		avatar.autoPinEdge(toSuperviewEdge: .top, withInset: 10)
		avatar.autoPinEdge(toSuperviewEdge: .bottom, withInset: 10, relation: .greaterThanOrEqual)
		avatar.autoPinEdge(toSuperviewEdge: .left, withInset: 10)

		nameLabel.autoPinEdge(toSuperviewEdge: .top, withInset: 13)
		nameLabel.autoPinEdge(.left, to: .right, of: avatar, withOffset: 10)

		messageLabel.autoPinEdge(.top, to: .bottom, of: nameLabel, withOffset: 2)
		messageLabel.autoPinEdge(.left, to: .right, of: avatar, withOffset: 10)
        messageLabel.autoMatch(.width, to: .width, of: nameLabel)
		messageLabel.autoPinEdge(toSuperviewEdge: .bottom, withInset: 10, relation: .greaterThanOrEqual)

        followButton.autoPinEdge(.left, to: .right, of: nameLabel, withOffset: 10)
        followButton.autoPinEdge(toSuperviewEdge: .right, withInset: 10)
        followButton.autoAlignAxis(.horizontal, toSameAxisOf: avatar)
        followButton.autoSetDimension(.height, toSize: 30.0)
        NSLayoutConstraint.autoSetPriority(UILayoutPriority(rawValue: 999)) {
            self.followButton.autoSetContentHuggingPriority(for: .horizontal)
        }
	}

	override func fillInCellData(_ shallow: Bool) {
        guard let user = model as? STMUser else {
            return
        }

        if !shallow {
            avatar.kf.setImage(with: user.profilePictureURL(), placeholder: UIImage(named: "defaultProfilePicture"))
        }

        nameLabel.text = user.displayName
        followButton.isSelected = user.isFollowing
        followButton.isHidden = AppDelegate.del().currentUser?.id == user.id
        messageLabel.text = "@" + user.username
	}

	override func prepareForReuse() {
		super.prepareForReuse()

		nameLabel.text = ""
		messageLabel.text = ""

        avatar.kf.cancelDownloadTask()
        avatar.image = nil
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
