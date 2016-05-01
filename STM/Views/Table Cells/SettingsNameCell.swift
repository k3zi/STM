//
//  SettingsNameCell.swift
//  STM
//
//  Created by Kesi Maduka on 2/2/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit
import Kingfisher
import DateTools

class SettingsNameCell: KZTableViewCell {
    let nameLabel = UILabel()

    required init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = RGB(255)
        self.accessoryType = .DisclosureIndicator

        nameLabel.numberOfLines = 1
        nameLabel.text = ""
        nameLabel.textColor = RGB(167, g: 169, b: 172)
        self.contentView.addSubview(nameLabel)
    }

    override func updateConstraints() {
        super.updateConstraints()

        nameLabel.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20))
    }

    override func setIndexPath(indexPath: NSIndexPath, last: Bool) {
        topSeperator.alpha = 1.0
    }

    override func fillInCellData() {
        if let setting = model as? STMSetting {
            nameLabel.text = setting.name
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        nameLabel.text = ""
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
