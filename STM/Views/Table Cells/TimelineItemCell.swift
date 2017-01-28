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

class TimelineItemCell: KZTableViewCell {
	let avatar = UIImageView()
	let messageLabel = UILabel()
	let dateLabel = UILabel()

    var timer: Timer?

	required init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		self.backgroundColor = RGB(255)
        self.selectionStyle = .none

		avatar.layer.cornerRadius = 45.0 / 9.0
		avatar.backgroundColor = Constants.UI.Color.imageViewDefault
		avatar.clipsToBounds = true
        avatar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goToUser)))
		self.contentView.addSubview(avatar)

        dateLabel.textColor = RGB(180)
		dateLabel.font = UIFont.systemFont(ofSize: 14)
		self.contentView.addSubview(dateLabel)

		messageLabel.font = UIFont.boldSystemFont(ofSize: 14)
        messageLabel.textColor = Constants.UI.Color.tint
		self.contentView.addSubview(messageLabel)

        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.updateTime), userInfo: nil, repeats: true)
	}

	override func updateConstraints() {
		super.updateConstraints()
		NSLayoutConstraint.autoSetPriority(999) { () -> Void in
			self.avatar.autoSetDimensions(to: CGSize(width: 45.0, height: 45.0))
		}

		avatar.autoPinEdge(toSuperviewEdge: .top, withInset: 10)
		avatar.autoPinEdge(toSuperviewEdge: .bottom, withInset: 10)
		avatar.autoPinEdge(toSuperviewEdge: .left, withInset: 10)

		messageLabel.autoPinEdge(.left, to: .right, of: avatar, withOffset: 10)
        messageLabel.autoAlignAxis(.horizontal, toSameAxisOf: avatar)

		dateLabel.autoPinEdge(.left, to: .right, of: messageLabel, withOffset: 10, relation: .greaterThanOrEqual)
		dateLabel.autoPinEdge(toSuperviewEdge: .right, withInset: 10)
		dateLabel.autoAlignAxis(.horizontal, toSameAxisOf: messageLabel)
	}

	override func fillInCellData(_ shallow: Bool) {
        guard let item = model as? STMTimelineItem else {
            return
        }

        if !shallow {
            if let user = item.user {
                avatar.kf.setImage(with: user.profilePictureURL(), placeholder: UIImage(named: "defaultProfilePicture"))
            }
        }

        messageLabel.text = item.message
        dateLabel.text = item.date.shortRelativeDate()
	}

    func updateTime() {
        guard let item = model as? STMTimelineItem else {
            return
        }

        dateLabel.text = item.date.shortRelativeDate()
    }

    func goToUser() {
        guard let item = model as? STMTimelineItem else {
            return
        }

        guard let user = item.user else {
            return
        }

        let vc = ProfileViewController(user: user, isOwner: AppDelegate.del().currentUser?.id == user.id)
        if let topVC = AppDelegate.del().topViewController() {
            if let navVC = topVC.navigationController {
                navVC.pushViewController(vc, animated: true)
            } else {
                let nav = NavigationController(rootViewController: vc)
                vc.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "navBarDismissBT"), style: .plain, target: topVC, action: #selector(topVC.dismissPopup))
                topVC.present(nav, animated: true, completion: nil)
            }
        }
    }

	override func prepareForReuse() {
		super.prepareForReuse()

		messageLabel.text = ""
		dateLabel.text = ""
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

    deinit {
        if let timer = timer {
            timer.invalidate()
        }
    }
}
