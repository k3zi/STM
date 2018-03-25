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

    var timer: Timer?

    required init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        timeLabel.font = UIFont.systemFont(ofSize: 14)
        timeLabel.numberOfLines = 1
        timeLabel.text = "Today"
        timeLabel.textColor = RGB(108, g: 108, b: 108)
        timeLabel.textAlignment = .left
        self.contentView.addSubview(timeLabel)

        messageLabel.font = UIFont.systemFont(ofSize: 14)
        messageLabel.numberOfLines = 0
        messageLabel.textColor = RGB(255)
        messageLabel.textAlignment = .left
        messageLabel.backgroundColor = Constants.UI.Color.tint.withAlphaComponent(0.8)
        messageLabel.setContentEdgeInsets(UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
        self.contentView.addSubview(messageLabel)

        topSeperator.isHidden = true
        bottomSeperator.isHidden = true

        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(CommentCell.updateTime), userInfo: nil, repeats: true)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateConstraints() {
        super.updateConstraints()

        messageLabel.autoPinEdge(toSuperviewEdge: .right, withInset: 12)
        messageLabel.autoPinEdge(toSuperviewEdge: .top, withInset: 12)
        messageLabel.autoMatch(.width, to: .width, of: contentView, withMultiplier: 0.7, relation: .lessThanOrEqual)
        messageLabel.autoPinEdge(toSuperviewEdge: .bottom, withInset: 12)

        timeLabel.autoPinEdge(.right, to: .left, of: messageLabel, withOffset: -12.0)
        timeLabel.autoAlignAxis(.horizontal, toSameAxisOf: messageLabel)
    }

    @objc override func estimatedHeight() -> CGFloat {
        let width = Constants.UI.Screen.width*0.7
        var height = CGFloat(12) // top padding
        height = height + messageLabel.estimatedHeight(width)
        height = height + 12 // bottom padding
        return ceil(height)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        messageLabel.preferredMaxLayoutWidth = contentView.frame.size.width*0.7
        super.layoutSubviews()
    }

    override func fillInCellData(_ shallow: Bool) {
        if let message = model as? STMMessage {
            if let messageText = message.text {
                messageLabel.text = messageText
            }

            timeLabel.text = message.date?.shortRelativeDate()
        }
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
    }

    deinit {
        if let timer = timer {
            timer.invalidate()
        }
    }
}
