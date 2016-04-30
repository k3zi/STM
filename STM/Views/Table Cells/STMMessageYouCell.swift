//
//  STMMessageYouCell.swift
//  Dawgtown
//
//  Created by Kesi Maduka on 7/31/15.
//  Copyright (c) 2015 Storm Edge Apps LLC. All rights reserved.
//

import UIKit
import DateTools
import KILabel

class STMMessageYouCell: KZTableViewCell {

    let timeLabel = UILabel()
    let messageLabel = Label()

    var timer: NSTimer?

    required init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .None

        timeLabel.font = UIFont.systemFontOfSize(14)
        timeLabel.numberOfLines = 1
        timeLabel.text = "Today"
        timeLabel.textColor = RGB(108, g: 108, b: 108)
        timeLabel.textAlignment = .Left
        self.contentView.addSubview(timeLabel)

        messageLabel.font = UIFont.systemFontOfSize(14)
        messageLabel.numberOfLines = 0
        messageLabel.textColor = RGB(255)
        messageLabel.textAlignment = .Left
        messageLabel.backgroundColor = Constants.UI.Color.tint.colorWithAlphaComponent(0.8)
        messageLabel.setContentEdgeInsets(UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
        self.contentView.addSubview(messageLabel)

        topSeperator.hidden = true
        bottomSeperator.hidden = true

        timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(CommentCell.updateTime), userInfo: nil, repeats: true)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateConstraints() {
        super.updateConstraints()

        messageLabel.autoPinEdgeToSuperviewEdge(.Right, withInset: 12)
        messageLabel.autoPinEdgeToSuperviewEdge(.Top, withInset: 12)
        messageLabel.autoMatchDimension(.Width, toDimension: .Width, ofView: contentView, withMultiplier: 0.7, relation: .LessThanOrEqual)
        messageLabel.autoPinEdgeToSuperviewEdge(.Bottom, withInset: 12)

        timeLabel.autoPinEdge(.Right, toEdge: .Left, ofView: messageLabel, withOffset: -12.0)
        timeLabel.autoAlignAxis(.Horizontal, toSameAxisOfView: messageLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        messageLabel.preferredMaxLayoutWidth = contentView.frame.size.width*0.7
        super.layoutSubviews()
    }

    override func fillInCellData() {
        if let message = model as? STMMessage {
            if let messageText = message.text {
                messageLabel.text = messageText
            }

            timeLabel.text = message.date?.shortTimeAgoSinceNow()
        }
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
    }

    deinit {
        if let timer = timer {
            timer.invalidate()
        }
    }
}
