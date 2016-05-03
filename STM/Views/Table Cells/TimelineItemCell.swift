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

    var timer: NSTimer?

	required init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		self.backgroundColor = RGB(255)
        self.selectionStyle = .None

		avatar.layer.cornerRadius = 45.0 / 9.0
		avatar.backgroundColor = Constants.UI.Color.imageViewDefault
		avatar.clipsToBounds = true
		self.contentView.addSubview(avatar)

        dateLabel.textColor = RGB(180)
		dateLabel.font = UIFont.systemFontOfSize(14)
		self.contentView.addSubview(dateLabel)

		messageLabel.font = UIFont.boldSystemFontOfSize(14)
        messageLabel.textColor = Constants.UI.Color.tint
		self.contentView.addSubview(messageLabel)

        timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(self.updateTime), userInfo: nil, repeats: true)
	}

	override func updateConstraints() {
		super.updateConstraints()
		NSLayoutConstraint.autoSetPriority(999) { () -> Void in
			self.avatar.autoSetDimensionsToSize(CGSize(width: 45.0, height: 45.0))
		}

		avatar.autoPinEdgeToSuperviewEdge(.Top, withInset: 10)
		avatar.autoPinEdgeToSuperviewEdge(.Bottom, withInset: 10)
		avatar.autoPinEdgeToSuperviewEdge(.Left, withInset: 10)

		messageLabel.autoPinEdge(.Left, toEdge: .Right, ofView: avatar, withOffset: 10)
        messageLabel.autoAlignAxis(.Horizontal, toSameAxisOfView: avatar)

		dateLabel.autoPinEdge(.Left, toEdge: .Right, ofView: messageLabel, withOffset: 10, relation: .GreaterThanOrEqual)
		dateLabel.autoPinEdgeToSuperviewEdge(.Right, withInset: 10)
		dateLabel.autoAlignAxis(.Horizontal, toSameAxisOfView: messageLabel)
	}

	override func fillInCellData(shallow: Bool) {
        guard let item = model as? STMTimelineItem else {
            return
        }

        if !shallow {
            if let user = item.user {
                avatar.kf_setImageWithURL(user.profilePictureURL(), placeholderImage: UIImage(named: "defaultProfilePicture"))
            }
        }

        messageLabel.text = item.message
        dateLabel.text = item.date.shortTimeAgoSinceNow()
	}

    func updateTime() {
        guard let item = model as? STMTimelineItem else {
            return
        }

        dateLabel.text = item.date.shortTimeAgoSinceNow()
    }

	override func prepareForReuse() {
		super.prepareForReuse()

		messageLabel.text = ""
		dateLabel.text = ""
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
