//
//  DashboardItemCell.swift
//  STM
//
//  Created by Kesi Maduka on 2/2/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit

class FeaturedStreamCell: KZTableViewCell {

    let blurredPosterView = UIImageView()
    let posterView = UIImageView()
    let colorOverlay = UIView()

    let streamTitleLabel = UILabel()
    let streamHostLabel = UILabel()

    required init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UIColor.clear

        blurredPosterView.contentMode = .scaleAspectFill
        blurredPosterView.clipsToBounds = true
        contentView.addSubview(blurredPosterView)

        colorOverlay.backgroundColor = Constants.UI.Color.tint5
        colorOverlay.alpha = 0.6
        contentView.addSubview(colorOverlay)

        streamTitleLabel.textColor = UIColor.white
        streamTitleLabel.font = UIFont.systemFont(ofSize: 19, weight: UIFontWeightSemibold)
        contentView.addSubview(streamTitleLabel)

        streamHostLabel.textColor = UIColor.white
        streamHostLabel.font = UIFont.systemFont(ofSize: 13, weight: UIFontWeightBold)
        streamHostLabel.alpha = 0.7
        contentView.addSubview(streamHostLabel)

        posterView.contentMode = .scaleAspectFill
        posterView.clipsToBounds = true
        posterView.backgroundColor = Constants.UI.Color.disabled
        contentView.addSubview(posterView)
    }

    override func usesEstimatedHeight() -> Bool {
        return false
    }

    override func getHeight() -> CGFloat {
        return 112
    }

    override func updateConstraints() {
        super.updateConstraints()

        blurredPosterView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4))
        colorOverlay.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4))

        streamTitleLabel.autoPinEdge(toSuperviewEdge: .top, withInset: 12)
        streamTitleLabel.autoPinEdge(toSuperviewEdge: .left, withInset: 12)

        streamHostLabel.autoPinEdge(.top, to: .bottom, of: streamTitleLabel, withOffset: 3)
        streamHostLabel.autoPinEdge(toSuperviewEdge: .left, withInset: 12)

        posterView.autoPinEdge(.left, to: .right, of: streamTitleLabel, withOffset: 0, relation: .greaterThanOrEqual)
        posterView.autoPinEdge(.left, to: .right, of: streamHostLabel, withOffset: 0, relation: .greaterThanOrEqual)
        posterView.autoPinEdge(toSuperviewEdge: .top, withInset: 6)
        posterView.autoPinEdge(toSuperviewEdge: .right, withInset: 10)
        posterView.autoPinEdge(toSuperviewEdge: .bottom, withInset: 6)
        posterView.autoMatch(.width, to: .height, of: posterView)
    }

    func startStreamClicked(_ startBT: UIButton) {
        guard let item = model as? STMDashboardItem else {
            return
        }

        guard let items = item.items else {
            return
        }

        guard let window = self.window else {
            return
        }

        guard let topVC = window.rootViewController else {
            return
        }

        hideEffect()

        let stream = items[startBT.tag]
        let vc = PlayerViewController()
        let activeVC = AppDelegate.del().activeStreamController

        vc.start(stream, vc: topVC) { (nothing, error) -> Void in
            if let error = error {
                (activeVC ?? topVC).showError(error)
            } else {
                AppDelegate.del().presentStreamController(vc)
            }
        }
    }

    func hideEffect() {
        AppDelegate.del().removeBlurEffects()
    }

    override func fillInCellData(_ shallow: Bool) {
        if let item = model as? STMStream {
            colorOverlay.backgroundColor = item.color()
            streamTitleLabel.text = item.name
            if let meta = item.meta, let url = meta.imageURL() {
                blurredPosterView.kf.setImage(with: url, options: [.processor(BlurImageProcessor(blurRadius: 10.0))])
                posterView.kf.setImage(with: url)
            } else if let url = item.pictureURL() {
                blurredPosterView.kf.setImage(with: url, options: [.processor(BlurImageProcessor(blurRadius: 10.0))])
                posterView.kf.setImage(with: url)
            }

            if let user = item.user {
                streamHostLabel.text = "@" + user.username
            } else {
                streamHostLabel.text = item.description
            }
        }
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        blurredPosterView.image = nil
        posterView.image = nil
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
