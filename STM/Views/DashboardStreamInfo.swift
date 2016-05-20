//
//  DashboardStreamInfo.swift
//  STM
//
//  Created by Kesi Maduka on 3/1/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit

class DashboardStreamInfoView: UIView {
    var color = UIColor.whiteColor()
    let triangleIndicator = TriangleView()
    let infoViewHolder = UIView()
    let startBT = UIButton.styledForStreamInfoView()
    let streamNameLabel = UILabel()
    let streamDescriptionLabel = UILabel()

    var stream: STMStream

    init(stream: STMStream) {
        self.stream = stream
        super.init(frame: CGRect.zero)

        self.backgroundColor = UIColor.clearColor()

        addSubview(triangleIndicator)

        infoViewHolder.layer.cornerRadius = 15.0
        infoViewHolder.backgroundColor = color
        infoViewHolder.clipsToBounds = true
        addSubview(infoViewHolder)

        streamNameLabel.textColor = Constants.UI.Color.tint
        streamNameLabel.font = UIFont.systemFontOfSize(17, weight: UIFontWeightMedium)
        streamNameLabel.text = stream.name
        infoViewHolder.addSubview(streamNameLabel)

        streamDescriptionLabel.textColor = RGB(91)
        streamDescriptionLabel.font = UIFont.systemFontOfSize(14)
        streamDescriptionLabel.text = stream.description
        streamDescriptionLabel.numberOfLines = 0
        infoViewHolder.addSubview(streamDescriptionLabel)

        startBT.setTitle("Tune In", forState: .Normal)
        startBT.setTitle("Tune In (Offline)", forState: .Disabled)
        startBT.enabled = true
        infoViewHolder.addSubview(startBT)

        setUpConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setUpConstraints() {
        triangleIndicator.autoPinEdgeToSuperviewEdge(.Top)
        triangleIndicator.autoSetDimensionsToSize(CGSize(width: 62, height: 31))

        infoViewHolder.autoPinEdgeToSuperviewEdge(.Top, withInset: 31)
        infoViewHolder.autoPinEdgeToSuperviewEdge(.Left)
        infoViewHolder.autoPinEdgeToSuperviewEdge(.Right)
        infoViewHolder.autoPinEdgeToSuperviewEdge(.Bottom)

        streamNameLabel.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsets(top: 15, left: 15, bottom: 0, right: 15), excludingEdge: .Bottom)

        streamDescriptionLabel.autoPinEdge(.Top, toEdge: .Bottom, ofView: streamNameLabel, withOffset: 15)
        streamDescriptionLabel.autoPinEdgeToSuperviewEdge(.Left, withInset: 15)
        streamDescriptionLabel.autoPinEdgeToSuperviewEdge(.Right, withInset: 15)

        startBT.autoPinEdge(.Top, toEdge: .Bottom, ofView: streamDescriptionLabel, withOffset: 15)
        startBT.autoPinEdgeToSuperviewEdge(.Left)
        startBT.autoPinEdgeToSuperviewEdge(.Right)
        startBT.autoPinEdgeToSuperviewEdge(.Bottom)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        streamDescriptionLabel.preferredMaxLayoutWidth = streamDescriptionLabel.frame.size.width
    }
}
