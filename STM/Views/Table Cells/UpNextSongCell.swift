//
//  UpNextSongCell.swift
//  STM
//
//  Created by Kesi Maduka on 2/7/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit

class UpNextSongCell: MCSwipeCell {
    let poster = UIImageView()
    let songNameLabel = UILabel()
    let songArtist = UILabel()
    let positionLabel = UILabel()

    required init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = RGB(255)
        self.selectionStyle = .none

        poster.backgroundColor = Constants.UI.Color.imageViewDefault
        self.contentView.addSubview(poster)

        positionLabel.backgroundColor = RGB(204, a: 0.86)
        positionLabel.textColor = RGB(26, a: 1.0)
        positionLabel.textAlignment = .center
        positionLabel.font = UIFont.systemFont(ofSize: 16)
        poster.addSubview(positionLabel)

        songNameLabel.font = UIFont.systemFont(ofSize: 16)
        self.contentView.addSubview(songNameLabel)

        songArtist.font = UIFont.systemFont(ofSize: 14)
        self.contentView.addSubview(songArtist)
    }

    @objc override func estimatedHeight() -> CGFloat {
        return 65
    }

    override func getHeight() -> CGFloat {
        return 65
    }

    override func updateConstraints() {
        super.updateConstraints()
        NSLayoutConstraint.autoSetPriority(UILayoutPriority(rawValue: 999)) { () -> Void in
            self.poster.autoSetDimensions(to: CGSize(width: 65.0, height: 65.0))
        }
        poster.autoPinEdge(toSuperviewEdge: .top)
        poster.autoPinEdge(toSuperviewEdge: .bottom)
        poster.autoPinEdge(toSuperviewEdge: .left)

        positionLabel.autoPinEdgesToSuperviewEdges()

        songNameLabel.autoPinEdge(toSuperviewEdge: .top, withInset: 10)
        songNameLabel.autoPinEdge(.left, to: .right, of: poster, withOffset: 10)
        songNameLabel.autoPinEdge(toSuperviewEdge: .right, withInset: 10)

        songArtist.autoPinEdge(.top, to: .bottom, of: songNameLabel, withOffset: 2)
        songArtist.autoPinEdge(.left, to: .right, of: poster, withOffset: 10)
        songArtist.autoPinEdge(toSuperviewEdge: .right, withInset: 10)
        songArtist.autoPinEdge(toSuperviewEdge: .bottom, withInset: 10)
    }

    override func setIndexPath(_ indexPath: IndexPath, last: Bool) {
        super.setIndexPath(indexPath, last: last)

        positionLabel.text = String(indexPath.row + 1)
    }

    override func fillInCellData(_ shallow: Bool) {
        if let song = model as? KZPlayerItem {
            songNameLabel.text = song.title
            songArtist.text = song.subTitle()

            if let artwork = song.artwork() {
                poster.image = artwork.image(at: CGSize(width: 65, height: 65))
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        poster.image = nil
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
