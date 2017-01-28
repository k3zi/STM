//
//  SettingsProfilePictureCell.swift
//  STM
//
//  Created by Kesi Maduka on 2/2/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit
import Kingfisher
import DateTools

class SettingsProfilePictureCell: KZTableViewCell {
    let nameLabel = UILabel()
    let avatar = UIImageView()

    required init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = RGB(255)
        self.accessoryType = .disclosureIndicator

        nameLabel.numberOfLines = 1
        nameLabel.text = "Profile Image"
        nameLabel.textColor = RGB(167, g: 169, b: 172)
        self.contentView.addSubview(nameLabel)

        avatar.layer.borderWidth = 0.5
        avatar.layer.borderColor = RGB(179).cgColor
        avatar.layer.cornerRadius = 85.0/9.0
        avatar.clipsToBounds = true
        self.contentView.addSubview(avatar)
    }

    override func updateConstraints() {
        super.updateConstraints()

        nameLabel.autoAlignAxis(toSuperviewAxis: .horizontal)
        nameLabel.autoPinEdge(toSuperviewEdge: .left, withInset: 11)

        NSLayoutConstraint.autoSetPriority(999) {
            self.avatar.autoSetDimension(.height, toSize: 85)
        }
        avatar.autoSetDimension(.width, toSize: 85)
        avatar.autoPinEdge(toSuperviewEdge: .top, withInset: 12)
        avatar.autoPinEdge(toSuperviewEdge: .right, withInset: 12)
        avatar.autoPinEdge(toSuperviewEdge: .bottom, withInset: 12)
    }

    override func setIndexPath(_ indexPath: IndexPath, last: Bool) {
        topSeperator.alpha = 1.0
    }

    override func fillInCellData(_ shallow: Bool) {
        if let setting = model as? STMSetting {
            nameLabel.text = setting.name
        }

        if !shallow {
            if let user = AppDelegate.del().currentUser {
                avatar.kf.setImage(with: user.profilePictureURL(), placeholder: UIImage(named: "defaultProfilePicture"), options: [KingfisherOptionsInfoItem.forceRefresh], progressBlock: nil, completionHandler: nil)
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        nameLabel.text = ""

        avatar.kf.cancelDownloadTask()
        avatar.image = nil
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
