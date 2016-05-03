//
//  STMMessageOtherCell.swift
//  Dawgtown
//
//  Created by Kesi Maduka on 7/31/15.
//  Copyright (c) 2015 Storm Edge Apps LLC. All rights reserved.
//

import UIKit
import DateTools

class STMMessageOtherCell: KZTableViewCell {

    let avatar = UIImageView()
    let timeLabel = UILabel()
    let messageLabel = Label()

    var timer: NSTimer?

    required init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .None

        avatar.layer.cornerRadius = 40.0 / 9.0
        avatar.backgroundColor = Constants.UI.Color.imageViewDefault
        avatar.clipsToBounds = true
        avatar.userInteractionEnabled = true
        avatar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goToUser)))
        self.contentView.addSubview(avatar)

        timeLabel.font = UIFont.systemFontOfSize(14)
        timeLabel.numberOfLines = 1
        timeLabel.text = "Today"
        timeLabel.textColor = RGB(108, g: 108, b: 108)
        timeLabel.textAlignment = .Right
        self.contentView.addSubview(timeLabel)

        messageLabel.font = UIFont.systemFontOfSize(14)
        messageLabel.numberOfLines = 0
        messageLabel.textColor = UIColor.blackColor()
        messageLabel.backgroundColor = RGB(235, g: 236, b: 237)
        messageLabel.setContentEdgeInsets(UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
        self.contentView.addSubview(messageLabel)

        bottomSeperator.hidden = true
        topSeperator.hidden = true
        timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(CommentCell.updateTime), userInfo: nil, repeats: true)
    }

    func goToUser() {
        guard let message = model as? STMMessage else {
            return
        }

        guard let user = message.user else {
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
            self.avatar.autoSetDimensionsToSize(CGSize(width: 40, height: 40))
        }
        avatar.autoPinEdgeToSuperviewEdge(.Top, withInset: 12)
        avatar.autoPinEdgeToSuperviewEdge(.Bottom, withInset: 12, relation: .GreaterThanOrEqual)
        avatar.autoPinEdgeToSuperviewEdge(.Left, withInset: 12)

        messageLabel.autoPinEdge(.Left, toEdge: .Right, ofView: avatar, withOffset: 12)
        messageLabel.autoPinEdgeToSuperviewEdge(.Top, withInset: 12)
        messageLabel.autoPinEdgeToSuperviewEdge(.Bottom, withInset: 12)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.autoSetPriority(999) { () -> Void in
            self.messageLabel.autoSetDimension(.Height, toSize: 40, relation: .GreaterThanOrEqual)
        }
        let layoutAttribute = NSLayoutConstraint.al_layoutAttributeForAttribute(.Width)
        let toLayoutAttribute = NSLayoutConstraint.al_layoutAttributeForAttribute(.Width)
        let constraint = NSLayoutConstraint(item: messageLabel, attribute: layoutAttribute, relatedBy: .LessThanOrEqual, toItem: contentView, attribute: toLayoutAttribute, multiplier: 0.7, constant: -(40 + 12 + 12))
        constraint.autoInstall()

        timeLabel.autoPinEdge(.Left, toEdge: .Right, ofView: messageLabel, withOffset: 12)
        timeLabel.autoAlignAxis(.Horizontal, toSameAxisOfView: messageLabel)
    }

    override func estimatedHeight() -> CGFloat {
        let width = Constants.UI.Screen.width*0.7 - (40 + 12 + 12)
        var height = CGFloat(12) //top padding
        height = height + messageLabel.estimatedHeight(width)
        height = height + 12 //bottom padding
        return ceil(height)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        messageLabel.preferredMaxLayoutWidth = contentView.frame.size.width*0.7 - (40 + 12 + 12)
        super.layoutSubviews()
    }

    override func setIndexPath(indexPath: NSIndexPath, last: Bool) {
        topSeperator.alpha = 0.0
        bottomSeperator.alpha = 0.0
    }

    override func fillInCellData(shallow: Bool) {
        guard let message = model as? STMMessage else {
            return
        }

        messageLabel.text = message.text

        if !shallow {
            if let sender = message.user {
                avatar.kf_setImageWithURL(sender.profilePictureURL(), placeholderImage: UIImage(named: "defaultProfilePicture"))
            }
        }

        timeLabel.text = message.date?.shortTimeAgoSinceNow()
    }

    func updateTime() {
        if let message = model as? STMMessage {
            timeLabel.text = message.date?.shortTimeAgoSinceNow()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        timeLabel.text = ""
        messageLabel.text = ""

        avatar.kf_cancelDownloadTask()
        avatar.image = nil
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
