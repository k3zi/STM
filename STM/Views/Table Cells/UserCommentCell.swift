//
//  UserCommentCell.swift
//  STM
//
//  Created by Kesi Maduka on 2/2/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit
import KILabel
import DateTools

class UserCommentCell: KZTableViewCell {
	let avatar = UIImageView()
	let nameLabel = UILabel()
	let dateLabel = UILabel()
	let messageLabel = KILabel()

    let likeButton = CellButton(imageName: "commentCell_heartBT", selectedImageName: "commentCell_heartSelectedBT", count: 0)
    let repostButton = CellButton(imageName: "commentCell_repostBT", selectedImageName: "commentCell_repostSelectedBT", count: 0)

    let streamView = UIView()
    let statusView = StreamStatusView()
    let streamNameLabel = Label()

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
        messageLabel.userHandleLinkTapHandler = AppDelegate.del().userHandleLinkTapHandler
		self.contentView.addSubview(messageLabel)

        likeButton.selectedColor = RGB(227, g: 67, b: 51)
        likeButton.actionButton.addTarget(self, action: #selector(self.toggleLike), for: .touchUpInside)
        self.contentView.addSubview(likeButton)

        repostButton.selectedColor = RGB(78, g: 188, b: 119)
        repostButton.actionButton.addTarget(self, action: #selector(self.toggleRepost), for: .touchUpInside)
        self.contentView.addSubview(repostButton)

        streamNameLabel.font = UIFont.systemFont(ofSize: 12.0)
        streamNameLabel.textColor = RGB(172)
        streamView.addSubview(streamNameLabel)

        streamView.addSubview(statusView)

        streamView.backgroundColor = RGB(235, g: 236, b: 237)
        streamView.layer.cornerRadius = 4.0
        streamView.clipsToBounds = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.goToStream))
        streamView.addGestureRecognizer(tap)
        self.contentView.addSubview(streamView)

        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(CommentCell.updateTime), userInfo: nil, repeats: true)
	}

    @objc func goToStream() {
        guard let comment = model as? STMComment, let stream = comment.stream else {
            return
        }

        guard let topVC = AppDelegate.del().topViewController() else {
            return
        }

        let vc = PlayerViewController()

        vc.start(stream, vc: topVC) { (nothing, error) -> Void in
            if let error = error {
                topVC.showError(error)
            } else {
                AppDelegate.del().presentStreamController(vc)
            }
        }
    }

    @objc func toggleLike() {
        guard let comment = model as? STMComment else {
            return
        }

        let method = likeButton.selected ? "unlike" : "like"
        UIView.transition(with: self.likeButton, duration: 0.2, options: .transitionCrossDissolve, animations: {
            self.likeButton.selected = !self.likeButton.selected
            self.likeButton.count = self.likeButton.count + (self.likeButton.selected ? 1 : -1)
        }, completion: nil)

        Constants.Network.GET("/comment/\(comment.id)/\(method)", parameters: nil) { (response, error) in
            DispatchQueue.main.async(execute: {
                comment.likes = self.likeButton.count
                comment.didLike = self.likeButton.selected
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.Notification.DidLikeComment), object: nil)
            })
        }
    }

    @objc func toggleRepost() {
        guard let comment = model as? STMComment else {
            return
        }

        guard comment.user?.id != AppDelegate.del().currentUser?.id else {
            return
        }

        let method = repostButton.selected ? "unrepost" : "repost"
        UIView.transition(with: self.repostButton, duration: 0.2, options: .transitionCrossDissolve, animations: {
            self.repostButton.selected = !self.repostButton.selected
            self.repostButton.count = self.repostButton.count + (self.repostButton.selected ? 1 : -1)
        }, completion: nil)

        Constants.Network.GET("/comment/\(comment.id)/\(method)", parameters: nil) { (response, error) in
            DispatchQueue.main.async(execute: {
                comment.reposts = self.repostButton.count
                comment.didRepost = self.repostButton.selected
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.Notification.DidRepostComment), object: nil)
            })
        }
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
		avatar.autoPinEdge(toSuperviewEdge: .left, withInset: 12)

		nameLabel.autoPinEdge(toSuperviewEdge: .top, withInset: 13)
		nameLabel.autoPinEdge(.left, to: .right, of: avatar, withOffset: 10)

		dateLabel.autoPinEdge(.left, to: .right, of: nameLabel, withOffset: 10, relation: .greaterThanOrEqual)
		dateLabel.autoPinEdge(toSuperviewEdge: .right, withInset: 10)
		dateLabel.autoAlignAxis(.horizontal, toSameAxisOf: nameLabel)

		messageLabel.autoPinEdge(.top, to: .bottom, of: nameLabel, withOffset: 2)
		messageLabel.autoPinEdge(.left, to: .right, of: avatar, withOffset: 10)
		messageLabel.autoPinEdge(toSuperviewEdge: .right, withInset: 10)

        likeButton.autoPinEdge(.top, to: .bottom, of: messageLabel, withOffset: 12)
        likeButton.autoPinEdge(toSuperviewEdge: .bottom, withInset: 8, relation: .greaterThanOrEqual)
        likeButton.autoPinEdge(.left, to: .right, of: avatar, withOffset: 10)

        repostButton.autoAlignAxis(.horizontal, toSameAxisOf: likeButton)
        repostButton.autoPinEdge(.left, to: .right, of: likeButton, withOffset: 10)

        streamView.autoPinEdge(toSuperviewEdge: .right, withInset: 10)
        streamView.autoAlignAxis(.horizontal, toSameAxisOf: repostButton)
        streamView.autoPinEdge(.left, to: .right, of: repostButton, withOffset: 10, relation: .greaterThanOrEqual)

        streamNameLabel.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 0), excludingEdge: .right)

        statusView.autoAlignAxis(.horizontal, toSameAxisOf: streamNameLabel)
        statusView.autoPinEdge(.left, to: .right, of: streamNameLabel, withOffset: 10)
        statusView.autoPinEdge(toSuperviewEdge: .right, withInset: 5)
	}

    @objc override func estimatedHeight() -> CGFloat {
        let rightSideWidth = Constants.UI.Screen.width - 12 - 45 - 10 - 10
        var height = CGFloat(13) //top padding
        height = height + nameLabel.estimatedHeight(rightSideWidth)
        height = height + 2 //padding
        height = height + messageLabel.estimatedHeight(rightSideWidth)
        height = height + 12 //padding
        height = height + likeButton.estimatedHeight(rightSideWidth)
        height = height + 8 //bottom padding
        return ceil(height)
    }

	override func fillInCellData(_ shallow: Bool) {
        guard let comment = model as? STMComment else {
            return
        }

        likeButton.shallow = shallow
        repostButton.shallow = shallow
        statusView.shallow = shallow

        messageLabel.text = comment.text

        likeButton.selected = comment.didLike
        likeButton.count = comment.likes

        repostButton.selected = comment.didRepost
        repostButton.count = comment.reposts

        if let user = comment.user {
            repostButton.alpha = (AppDelegate.del().currentUser?.id == user.id) ? 0.4 : 1.0
            repostButton.actionButton.isEnabled = (AppDelegate.del().currentUser?.id != user.id)
            nameLabel.text = user.displayName

            if !shallow {
                avatar.kf.setImage(with: user.profilePictureURL(), placeholder: UIImage(named: "defaultProfilePicture"))
            }
        }

        if let date = comment.date {
            dateLabel.text = date.shortRelativeDate()
        }

        if let stream = comment.stream {
            streamNameLabel.text = stream.name
            statusView.stream = stream
        }
	}

    @objc func updateTime() {
        guard let comment = model as? STMComment else {
            return
        }

        guard let date = comment.date else {
            return
        }

        dateLabel.text = date.shortRelativeDate()
    }

	override func prepareForReuse() {
		super.prepareForReuse()

		nameLabel.text = ""
		dateLabel.text = ""
        streamNameLabel.text = ""

        avatar.kf.cancelDownloadTask()
        avatar.image = nil

        statusView.stream = nil
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
