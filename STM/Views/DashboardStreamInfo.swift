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

        streamNameLabel.textColor = Constants.Color.tint
        streamNameLabel.font = UIFont.systemFontOfSize(15, weight: UIFontWeightMedium)
        streamNameLabel.text = stream.name
        infoViewHolder.addSubview(streamNameLabel)

        startBT.setTitle("Tune In", forState: .Normal)
        startBT.enabled = stream.live
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
        infoViewHolder.autoSetDimension(.Height, toSize: 248)
        infoViewHolder.autoPinEdgeToSuperviewEdge(.Bottom)

        streamNameLabel.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsets(top: 15, left: 15, bottom: 0, right: 15), excludingEdge: .Bottom)

        startBT.autoPinEdgeToSuperviewEdge(.Left)
        startBT.autoPinEdgeToSuperviewEdge(.Right)
        startBT.autoPinEdgeToSuperviewEdge(.Bottom)
    }
}
