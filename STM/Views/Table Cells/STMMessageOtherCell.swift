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

    var timer: Timer?

    required init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        avatar.layer.cornerRadius = 40.0 / 9.0
        avatar.backgroundColor = Constants.UI.Color.imageViewDefault
        avatar.clipsToBounds = true
        avatar.isUserInteractionEnabled = true
        avatar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goToUser)))
        self.contentView.addSubview(avatar)

        timeLabel.font = UIFont.systemFont(ofSize: 14)
        timeLabel.numberOfLines = 1
        timeLabel.text = "Today"
        timeLabel.textColor = RGB(108, g: 108, b: 108)
        timeLabel.textAlignment = .right
        self.contentView.addSubview(timeLabel)

        messageLabel.font = UIFont.systemFont(ofSize: 14)
        messageLabel.numberOfLines = 0
        messageLabel.textColor = UIColor.black
        messageLabel.backgroundColor = RGB(235, g: 236, b: 237)
        messageLabel.setContentEdgeInsets(UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
        self.contentView.addSubview(messageLabel)

        bottomSeperator.isHidden = true
        topSeperator.isHidden = true
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(CommentCell.updateTime), userInfo: nil, repeats: true)
    }

    @objc func goToUser() {
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
                vc.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "navBarDismissBT"), style: .plain, target: topVC, action: #selector(topVC.dismissPopup))
                topVC.present(nav, animated: true, completion: nil)
            }
        }
    }

    override func updateConstraints() {
        super.updateConstraints()

        NSLayoutConstraint.autoSetPriority(UILayoutPriority(rawValue: 999)) { () -> Void in
            self.avatar.autoSetDimensions(to: CGSize(width: 40, height: 40))
        }
        avatar.autoPinEdge(toSuperviewEdge: .top, withInset: 12)
        avatar.autoPinEdge(toSuperviewEdge: .bottom, withInset: 12, relation: .greaterThanOrEqual)
        avatar.autoPinEdge(toSuperviewEdge: .left, withInset: 12)

        messageLabel.autoPinEdge(.left, to: .right, of: avatar, withOffset: 12)
        messageLabel.autoPinEdge(toSuperviewEdge: .top, withInset: 12)
        messageLabel.autoPinEdge(toSuperviewEdge: .bottom, withInset: 12)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.autoSetPriority(UILayoutPriority(rawValue: 999)) { () -> Void in
            self.messageLabel.autoSetDimension(.height, toSize: 40, relation: .greaterThanOrEqual)
        }
        let layoutAttribute = NSLayoutConstraint.al_layoutAttribute(for: .width)
        let toLayoutAttribute = NSLayoutConstraint.al_layoutAttribute(for: .width)
        let constraint = NSLayoutConstraint(item: messageLabel, attribute: layoutAttribute, relatedBy: .lessThanOrEqual, toItem: contentView, attribute: toLayoutAttribute, multiplier: 0.7, constant: -(40 + 12 + 12))
        constraint.autoInstall()

        timeLabel.autoPinEdge(.left, to: .right, of: messageLabel, withOffset: 12)
        timeLabel.autoAlignAxis(.horizontal, toSameAxisOf: messageLabel)
    }

    @objc override func estimatedHeight() -> CGFloat {
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

    override func setIndexPath(_ indexPath: IndexPath, last: Bool) {
        topSeperator.alpha = 0.0
        bottomSeperator.alpha = 0.0
    }

    override func fillInCellData(_ shallow: Bool) {
        guard let message = model as? STMMessage else {
            return
        }

        messageLabel.text = message.text

        if !shallow {
            if let sender = message.user {
                avatar.kf.setImage(with: sender.profilePictureURL(), placeholder: UIImage(named: "defaultProfilePicture"))
            }
        }

        timeLabel.text = message.date?.shortRelativeDate()
    }

    @objc func updateTime() {
        if let message = model as? STMMessage {
            timeLabel.text = message.date?.shortRelativeDate()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        timeLabel.text = ""
        messageLabel.text = ""

        avatar.kf.cancelDownloadTask()
        avatar.image = nil
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
