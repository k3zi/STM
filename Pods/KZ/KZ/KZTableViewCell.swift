//
//  KZTableViewCell.swift
//  KZ
//
//  Created by Kesi Maduka on 1/25/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit
import PureLayout
import Reusable

public class KZTableViewCell: UITableViewCell, Reusable {
    public let topSeperator = UIView()
    public let bottomSeperator = UIView()

    var didSetupConstraints = false
    var trailingDetailConstraint = NSLayoutConstraint()
    public var model: Any?

    override required public init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UIColor.clearColor()

        self.contentView.addSubview(topSeperator)
        self.contentView.addSubview(bottomSeperator)

        self.contentView.bounds.size.height = 99999
    }

    //MARK: Setup Constraints
    override public func updateConstraints() {
        super.updateConstraints()
        if didSetupConstraints {
            return
        }

        bottomSeperator.autoSetDimension(.Height, toSize: (1.0/UIScreen.mainScreen().scale))
        bottomSeperator.autoPinEdgeToSuperviewEdge(.Bottom)
        bottomSeperator.autoPinEdgeToSuperviewEdge(.Left)
        bottomSeperator.autoPinEdgeToSuperviewEdge(.Right)

        topSeperator.autoSetDimension(.Height, toSize: (1.0/UIScreen.mainScreen().scale))
        topSeperator.autoPinEdgeToSuperviewEdge(.Top)
        topSeperator.autoPinEdgeToSuperviewEdge(.Left)
        topSeperator.autoPinEdgeToSuperviewEdge(.Right)

        didSetupConstraints = true
    }

    public func usesEstimatedHeight() -> Bool {
        return true
    }

    public func estimatedHeight() -> CGFloat {
        if usesEstimatedHeight() {
            print("AutoLayout: \"\(self.dynamicType)\" estimatedHeight isn't implemented")
        }

        return UITableViewAutomaticDimension
    }

    func heightForRow() -> CGFloat {
        if self.usesEstimatedHeight() {
            return UITableViewAutomaticDimension
        } else {
            return self.getHeight()
        }
    }

    public func getHeight() -> CGFloat {
        self.contentView.bounds.size.height = 99999
        self.setNeedsUpdateConstraints()
        self.updateConstraints()

        self.bounds.size.width = UIScreen.mainScreen().bounds.size.width

        self.setNeedsLayout()
        self.layoutIfNeeded()

        let height = self.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
        return height + CGFloat(1.0)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        self.contentView.layoutIfNeeded()
    }

    public func setIndexPath(indexPath: NSIndexPath, last: Bool) {
        if indexPath.row == 0 {
            topSeperator.alpha = 0.0
        } else {
            topSeperator.alpha = 1.0
        }
    }

    public func setContent(content: Any, shallow: Bool) {
        model = content

        fillInCellData(shallow)
    }

    public func fillInCellData(shallow: Bool) {

    }

    override public func prepareForReuse() {
        super.prepareForReuse()

        model = nil
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
