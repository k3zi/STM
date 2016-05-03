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
        self.accessoryType = .DisclosureIndicator

        nameLabel.numberOfLines = 1
        nameLabel.text = "Profile Image"
        nameLabel.textColor = RGB(167, g: 169, b: 172)
        self.contentView.addSubview(nameLabel)

        avatar.layer.borderWidth = 0.5
        avatar.layer.borderColor = RGB(179).CGColor
        avatar.layer.cornerRadius = 85.0/9.0
        avatar.clipsToBounds = true
        self.contentView.addSubview(avatar)
    }

    override func updateConstraints() {
        super.updateConstraints()

        nameLabel.autoAlignAxisToSuperviewAxis(.Horizontal)
        nameLabel.autoPinEdgeToSuperviewEdge(.Left, withInset: 11)

        NSLayoutConstraint.autoSetPriority(999) {
            self.avatar.autoSetDimension(.Height, toSize: 85)
        }
        avatar.autoSetDimension(.Width, toSize: 85)
        avatar.autoPinEdgeToSuperviewEdge(.Top, withInset: 12)
        avatar.autoPinEdgeToSuperviewEdge(.Right, withInset: 12)
        avatar.autoPinEdgeToSuperviewEdge(.Bottom, withInset: 12)
    }

    override func setIndexPath(indexPath: NSIndexPath, last: Bool) {
        topSeperator.alpha = 1.0
    }

    override func fillInCellData(shallow: Bool) {
        if let setting = model as? STMSetting {
            nameLabel.text = setting.name
        }

        if !shallow {
            if let user = AppDelegate.del().currentUser {
                avatar.kf_setImageWithURL(user.profilePictureURL(), placeholderImage: UIImage(named: "defaultProfilePicture"), optionsInfo: [KingfisherOptionsInfoItem.ForceRefresh], progressBlock: nil, completionHandler: nil)
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        nameLabel.text = ""

        avatar.kf_cancelDownloadTask()
        avatar.image = nil
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
