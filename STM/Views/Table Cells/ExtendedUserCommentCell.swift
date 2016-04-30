//
//  ExtendedUserCommentCell.swift
//  STM
//
//  Created by Kesi Maduka on 2/2/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit
import KILabel
import DateTools

class ExtendedUserCommentCell: KZTableViewCell {
	let avatar = UIImageView()
	let nameLabel = UILabel()
	let dateLabel = UILabel()
	let messageLabel = KILabel()

    let likeButton = CellButton(imageName: "commentCell_heartBT", selectedImageName: "commentCell_heartSelectedBT", count: 0)
    let repostButton = CellButton(imageName: "commentCell_repostBT", selectedImageName: "commentCell_repostSelectedBT", count: 0)

    let line1 = UIView.lineWithBGColor(RGB(219))

    var timer: NSTimer?

	required init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		self.backgroundColor = RGB(250, g: 251, b: 252)
        self.selectionStyle = .None
        self.bottomSeperator.alpha = 1.0
        self.bottomSeperator.backgroundColor = line1.backgroundColor

		avatar.layer.cornerRadius = 45.0 / 9.0
		avatar.backgroundColor = RGB(72, g: 72, b: 72)
		avatar.clipsToBounds = true
		self.contentView.addSubview(avatar)

        dateLabel.textColor = RGB(180)
		dateLabel.font = UIFont.systemFontOfSize(14)
		self.contentView.addSubview(dateLabel)

		nameLabel.font = UIFont.boldSystemFontOfSize(14)
        nameLabel.textColor = Constants.UI.Color.tint
		self.contentView.addSubview(nameLabel)

        messageLabel.numberOfLines = 0
		messageLabel.font = UIFont.systemFontOfSize(14)
        messageLabel.tintColor = Constants.UI.Color.tint
		self.contentView.addSubview(messageLabel)

        likeButton.selectedColor = RGB(227, g: 67, b: 51)
        likeButton.actionButton.addTarget(self, action: #selector(self.toggleLike), forControlEvents: .TouchUpInside)
        self.contentView.addSubview(likeButton)

        repostButton.selectedColor = RGB(51, g: 227, b: 105)
        repostButton.actionButton.addTarget(self, action: #selector(self.toggleRepost), forControlEvents: .TouchUpInside)
        self.contentView.addSubview(repostButton)

        self.contentView.addSubview(line1)

        timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(CommentCell.updateTime), userInfo: nil, repeats: true)
	}

    func toggleLike() {
        guard let comment = model as? STMComment else {
            return
        }

        let method = likeButton.selected ? "unlike" : "like"
        UIView.transitionWithView(self.likeButton, duration: 0.2, options: .TransitionCrossDissolve, animations: {
            self.likeButton.selected = !self.likeButton.selected
            self.likeButton.count = self.likeButton.count + (self.likeButton.selected ? 1 : -1)
        }, completion: nil)

        Constants.Network.GET("/comment/\(method)/\(comment.id)", parameters: nil) { (response, error) in
            dispatch_async(dispatch_get_main_queue(), {
                comment.likes = self.likeButton.count
                comment.didLike = self.likeButton.selected
            })
        }
    }

    func toggleRepost() {
        guard let comment = model as? STMComment else {
            return
        }

        guard comment.user?.id != AppDelegate.del().currentUser?.id else {
            return
        }

        let method = likeButton.selected ? "unrepost" : "repost"
        Constants.Network.GET("/comment/\(method)/\(comment.id)", parameters: nil) { (response, error) in
            dispatch_async(dispatch_get_main_queue(), {
                UIView.transitionWithView(self.repostButton, duration: 0.2, options: .TransitionCrossDissolve, animations: {
                    self.repostButton.selected = !self.repostButton.selected
                    self.repostButton.count = self.repostButton.count + (self.repostButton.selected ? 1 : -1)
                    comment.reposts = self.repostButton.count
                    comment.didRepost = self.repostButton.selected
                }, completion: nil)
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
		avatar.autoPinEdgeToSuperviewEdge(.Left, withInset: 12)

		nameLabel.autoPinEdgeToSuperviewEdge(.Top, withInset: 13)
		nameLabel.autoPinEdge(.Left, toEdge: .Right, ofView: avatar, withOffset: 10)

		dateLabel.autoPinEdge(.Left, toEdge: .Right, ofView: nameLabel, withOffset: 10, relation: .GreaterThanOrEqual)
		dateLabel.autoPinEdgeToSuperviewEdge(.Right, withInset: 10)
		dateLabel.autoAlignAxis(.Horizontal, toSameAxisOfView: nameLabel)

		messageLabel.autoPinEdge(.Top, toEdge: .Bottom, ofView: nameLabel, withOffset: 2)
		messageLabel.autoPinEdge(.Left, toEdge: .Right, ofView: avatar, withOffset: 10)
		messageLabel.autoPinEdgeToSuperviewEdge(.Right, withInset: 10)

        NSLayoutConstraint.autoSetPriority(999) {
            self.line1.autoPinEdge(.Top, toEdge: .Bottom, ofView: self.messageLabel, withOffset: 10, relation: .GreaterThanOrEqual)
            self.line1.autoPinEdge(.Top, toEdge: .Bottom, ofView: self.avatar, withOffset: 10, relation: .GreaterThanOrEqual)
        }
        line1.autoPinEdgeToSuperviewEdge(.Left)
        line1.autoPinEdgeToSuperviewEdge(.Right)

        likeButton.autoPinEdge(.Top, toEdge: .Bottom, ofView: line1, withOffset: 10)
        likeButton.autoPinEdgeToSuperviewEdge(.Bottom, withInset: 8, relation: .GreaterThanOrEqual)
        likeButton.autoPinEdgeToSuperviewEdge(.Left, withInset: 12)

        repostButton.autoAlignAxis(.Horizontal, toSameAxisOfView: likeButton)
        repostButton.autoPinEdge(.Left, toEdge: .Right, ofView: likeButton, withOffset: 10)
	}

	override func fillInCellData() {
        guard let comment = model as? STMComment else {
            return
        }

        messageLabel.text = comment.text

        likeButton.selected = comment.didLike
        likeButton.count = comment.likes

        repostButton.selected = comment.didRepost
        repostButton.count = comment.reposts

        if let user = comment.user {
            repostButton.alpha = (AppDelegate.del().currentUser?.id == user.id) ? 0.4 : 1.0
            repostButton.actionButton.enabled = (AppDelegate.del().currentUser?.id != user.id)
            nameLabel.text = user.displayName

            avatar.kf_setImageWithURL(user.profilePictureURL(), placeholderImage: UIImage(named: "defaultProfilePicture"))
        }

        if let date = comment.date {
            dateLabel.text = date.shortTimeAgoSinceNow()
        }
	}

    func updateTime() {
        if let comment = model as? STMComment {
            if let date = comment.date {
                dateLabel.text = date.shortTimeAgoSinceNow()
            }
        }
    }

	override func prepareForReuse() {
		super.prepareForReuse()

		nameLabel.text = ""
		dateLabel.text = ""

        avatar.kf_cancelDownloadTask()
        avatar.image = nil
	}

    override func setIndexPath(indexPath: NSIndexPath, last: Bool) {
        topSeperator.alpha = 0.0
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        messageLabel.preferredMaxLayoutWidth = messageLabel.frame.size.width
        super.layoutSubviews()
    }

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

    deinit {
        if let timer = timer {
            timer.invalidate()
        }
    }
}
