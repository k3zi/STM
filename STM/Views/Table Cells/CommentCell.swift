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

    var timer: Timer?

	required init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		self.backgroundColor = RGB(255)
        self.selectionStyle = .none

		avatar.layer.cornerRadius = 45.0 / 9.0
		avatar.backgroundColor = Constants.UI.Color.imageViewDefault
		avatar.clipsToBounds = true
        avatar.isUserInteractionEnabled = true
        avatar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goToUser)))
		self.contentView.addSubview(avatar)

        dateLabel.textColor = RGB(180)
		dateLabel.font = UIFont.systemFont(ofSize: 14)
		self.contentView.addSubview(dateLabel)

		nameLabel.font = UIFont.boldSystemFont(ofSize: 14)
        nameLabel.textColor = Constants.UI.Color.tint
		self.contentView.addSubview(nameLabel)

        messageLabel.numberOfLines = 0
		messageLabel.font = UIFont.systemFont(ofSize: 14)
        messageLabel.tintColor = Constants.UI.Color.tint
		self.contentView.addSubview(messageLabel)

        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(CommentCell.updateTime), userInfo: nil, repeats: true)
	}

    @objc func goToUser() {
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
                vc.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "navBarDismissBT"), style: .plain, target: topVC, action: #selector(topVC.dismissPopup))
                topVC.present(nav, animated: true, completion: nil)
            }
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

		dateLabel.autoPinEdge(.left, to: .right, of: nameLabel, withOffset: 10, relation: .greaterThanOrEqual)
		dateLabel.autoPinEdge(toSuperviewEdge: .right, withInset: 10)
		dateLabel.autoAlignAxis(.horizontal, toSameAxisOf: nameLabel)

		messageLabel.autoPinEdge(.top, to: .bottom, of: nameLabel, withOffset: 2)
		messageLabel.autoPinEdge(.left, to: .right, of: avatar, withOffset: 10)
		messageLabel.autoPinEdge(toSuperviewEdge: .right, withInset: 10)
		messageLabel.autoPinEdge(toSuperviewEdge: .bottom, withInset: 10, relation: .greaterThanOrEqual)
	}

    @objc override func estimatedHeight() -> CGFloat {
        let minHeight = CGFloat(10 + 45 + 10)

        let rightSideWidth = Constants.UI.Screen.width - 10 - 45 - 10 - 10
        var height = CGFloat(13) //top padding
        height = height + nameLabel.estimatedHeight(rightSideWidth)
        height = height + 2 //padding
        height = height + messageLabel.estimatedHeight(rightSideWidth)
        height = height + 10 //bottom padding
        return ceil(max(minHeight, height))
    }

	override func fillInCellData(_ shallow: Bool) {
		if let comment = model as? STMComment {
			messageLabel.text = comment.text

			if let user = comment.user {
				nameLabel.text = user.displayName

                if !shallow {
                    avatar.kf.setImage(with: user.profilePictureURL(), placeholder: UIImage(named: "defaultProfilePicture"))
                }
			}

            if let date = comment.date {
                dateLabel.text = date.shortRelativeDate()
            }
		}
	}

    @objc func updateTime() {
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

    deinit {
        if let timer = timer {
            timer.invalidate()
        }
    }
}
