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

class CommentCell: KZTableViewCell {
	let avatar = UIImageView()
	let nameLabel = UILabel()
	let dateLabel = UILabel()
	let messageLabel = KILabel()

    var timer: NSTimer?

	required init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		self.backgroundColor = RGB(255)
        self.selectionStyle = .None

		avatar.layer.cornerRadius = 45.0 / 9.0
		avatar.backgroundColor = Constants.UI.Color.imageViewDefault
		avatar.clipsToBounds = true
        avatar.userInteractionEnabled = true
        avatar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goToUser)))
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

        timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(CommentCell.updateTime), userInfo: nil, repeats: true)
	}

    func goToUser() {
        guard let comment = model as? STMComment else {
            return
        }

        guard let user = comment.user else {
            return
        }

        let vc = ProfileViewController(user: user, isOwner: AppDelegate.del().currentUser?.id == user.id)
        if let topVC = AppDelegate.del().topViewController() {
            if let navVC = topVC.navigationController {
                navVC.pushViewController(vc, animated: true)
            } else {
                let nav = NavigationController(rootViewController: vc)
                vc.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "navBarDismissBT"), style: .Plain, target: topVC, action: #selector(topVC.dismissPopup))
                topVC.presentViewController(nav, animated: true, completion: nil)
            }
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

		dateLabel.autoPinEdge(.Left, toEdge: .Right, ofView: nameLabel, withOffset: 10, relation: .GreaterThanOrEqual)
		dateLabel.autoPinEdgeToSuperviewEdge(.Right, withInset: 10)
		dateLabel.autoAlignAxis(.Horizontal, toSameAxisOfView: nameLabel)

		messageLabel.autoPinEdge(.Top, toEdge: .Bottom, ofView: nameLabel, withOffset: 2)
		messageLabel.autoPinEdge(.Left, toEdge: .Right, ofView: avatar, withOffset: 10)
		messageLabel.autoPinEdgeToSuperviewEdge(.Right, withInset: 10)
		messageLabel.autoPinEdgeToSuperviewEdge(.Bottom, withInset: 10, relation: .GreaterThanOrEqual)
	}

    override func estimatedHeight() -> CGFloat {
        let minHeight = CGFloat(10 + 45 + 10)

        let rightSideWidth = Constants.UI.Screen.width - 10 - 45 - 10 - 10
        var height = CGFloat(13) //top padding
        height = height + nameLabel.estimatedHeight(rightSideWidth)
        height = height + 2 //padding
        height = height + messageLabel.estimatedHeight(rightSideWidth)
        height = height + 10 //bottom padding
        return ceil(max(minHeight, height))
    }

	override func fillInCellData(shallow: Bool) {
		if let comment = model as? STMComment {
			messageLabel.text = comment.text

			if let user = comment.user {
				nameLabel.text = user.displayName

                if !shallow {
                    avatar.kf_setImageWithURL(user.profilePictureURL(), placeholderImage: UIImage(named: "defaultProfilePicture"))
                }
			}

            if let date = comment.date {
                dateLabel.text = date.shortRelativeDate()
            }
		}
	}

    func updateTime() {
        if let comment = model as? STMComment {
            if let date = comment.date {
                dateLabel.text = date.shortRelativeDate()
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

    deinit {
        if let timer = timer {
            timer.invalidate()
        }
    }
}
