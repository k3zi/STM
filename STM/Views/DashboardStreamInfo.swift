//
//  DashboardStreamInfo.swift
//  STM
//
//  Created by Kesi Maduka on 3/1/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit

class DashboardStreamInfoView: UIView {
    var color = UIColor.white
    let triangleIndicator = TriangleView()
    let infoViewHolder = UIView()
    let startBT = UIButton.styledForStreamInfoView()
    let streamNameLabel = UILabel()
    let streamDescriptionLabel = UILabel()

    let statusView = StreamStatusView()

    var stream: STMStream

    init(stream: STMStream) {
        self.stream = stream
        super.init(frame: CGRect.zero)

        self.backgroundColor = UIColor.clear

        addSubview(triangleIndicator)

        infoViewHolder.layer.cornerRadius = 15.0
        infoViewHolder.backgroundColor = color
        infoViewHolder.clipsToBounds = true
        addSubview(infoViewHolder)

        statusView.stream = stream
        infoViewHolder.addSubview(statusView)

        streamNameLabel.textColor = Constants.UI.Color.tint
        streamNameLabel.font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.medium)
        streamNameLabel.text = stream.name
        infoViewHolder.addSubview(streamNameLabel)

        streamDescriptionLabel.textColor = RGB(91)
        streamDescriptionLabel.font = UIFont.systemFont(ofSize: 14)
        streamDescriptionLabel.text = stream.description
        streamDescriptionLabel.numberOfLines = 0
        infoViewHolder.addSubview(streamDescriptionLabel)

        startBT.setTitle("Tune In", for: UIControlState())
        startBT.setTitle("Tune In (Offline)", for: .disabled)
        startBT.isEnabled = true
        infoViewHolder.addSubview(startBT)

        setUpConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setUpConstraints() {
        triangleIndicator.autoPinEdge(toSuperviewEdge: .top)
        triangleIndicator.autoSetDimensions(to: CGSize(width: 62, height: 31))

        infoViewHolder.autoPinEdge(toSuperviewEdge: .top, withInset: 31)
        infoViewHolder.autoPinEdge(toSuperviewEdge: .left)
        infoViewHolder.autoPinEdge(toSuperviewEdge: .right)
        infoViewHolder.autoPinEdge(toSuperviewEdge: .bottom)

        statusView.autoPinEdge(toSuperviewEdge: .left, withInset: 15)
        statusView.autoAlignAxis(.horizontal, toSameAxisOf: streamNameLabel)

        streamNameLabel.autoPinEdge(toSuperviewEdge: .top, withInset: 15)
        streamNameLabel.autoPinEdge(.left, to: .right, of: statusView, withOffset: 10)
        streamNameLabel.autoPinEdge(toSuperviewEdge: .right, withInset: 15)

        streamDescriptionLabel.autoPinEdge(.top, to: .bottom, of: streamNameLabel, withOffset: 15)
        streamDescriptionLabel.autoPinEdge(toSuperviewEdge: .left, withInset: 15)
        streamDescriptionLabel.autoPinEdge(toSuperviewEdge: .right, withInset: 15)

        startBT.autoPinEdge(.top, to: .bottom, of: streamDescriptionLabel, withOffset: 15)
        startBT.autoPinEdge(toSuperviewEdge: .left)
        startBT.autoPinEdge(toSuperviewEdge: .right)
        startBT.autoPinEdge(toSuperviewEdge: .bottom)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        streamDescriptionLabel.preferredMaxLayoutWidth = streamDescriptionLabel.frame.size.width
    }
}
