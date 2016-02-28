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
        self.selectionStyle = .None

        poster.backgroundColor = RGB(72, g: 72, b: 72)
        self.contentView.addSubview(poster)

        positionLabel.backgroundColor = RGB(204, a: 0.86)
        positionLabel.textColor = RGB(26, a: 1.0)
        positionLabel.textAlignment = .Center
        positionLabel.font = UIFont.systemFontOfSize(16)
        poster.addSubview(positionLabel)

        songNameLabel.font = UIFont.systemFontOfSize(16)
        self.contentView.addSubview(songNameLabel)

        songArtist.font = UIFont.systemFontOfSize(14)
        self.contentView.addSubview(songArtist)
    }

    override internal func getHeight() -> CGFloat {
        return 65
    }

    override func updateConstraints() {
        super.updateConstraints()
        NSLayoutConstraint.autoSetPriority(999) { () -> Void in
            self.poster.autoSetDimensionsToSize(CGSize(width: 65.0, height: 65.0))
        }
        poster.autoPinEdgeToSuperviewEdge(.Top)
        poster.autoPinEdgeToSuperviewEdge(.Bottom)
        poster.autoPinEdgeToSuperviewEdge(.Left)

        positionLabel.autoPinEdgesToSuperviewEdges()

        songNameLabel.autoPinEdgeToSuperviewEdge(.Top, withInset: 10)
        songNameLabel.autoPinEdge(.Left, toEdge: .Right, ofView: poster, withOffset: 10)
        songNameLabel.autoPinEdgeToSuperviewEdge(.Right, withInset: 10)

        songArtist.autoPinEdge(.Top, toEdge: .Bottom, ofView: songNameLabel, withOffset: 2)
        songArtist.autoPinEdge(.Left, toEdge: .Right, ofView: poster, withOffset: 10)
        songArtist.autoPinEdgeToSuperviewEdge(.Right, withInset: 10)
        songArtist.autoPinEdgeToSuperviewEdge(.Bottom, withInset: 10)
    }

    override func setIndexPath(indexPath: NSIndexPath, last: Bool) {
        super.setIndexPath(indexPath, last: last)

        positionLabel.text = String(indexPath.row + 1)
    }

    override func fillInCellData() {
        if let song = model as? KZPlayerItem {
            songNameLabel.text = song.title
            songArtist.text = song.subTitle()

            if let artwork = song.artwork() {
                poster.image = artwork.imageWithSize(CGSize(width: 65, height: 65))
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
