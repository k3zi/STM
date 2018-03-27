//
//  HostStreamCell.swift
//  STM
//
//  Created by Kesi Maduka on 2/2/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit
import SWXMLHash

class SelectSongCell: MCSwipeCell {
    let poster = UIImageView()
    let songNameLabel = UILabel()
    let songArtist = UILabel()

    required init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = RGB(255)
        self.selectionStyle = .none

        poster.backgroundColor = Constants.UI.Color.imageViewDefault
        self.contentView.addSubview(poster)

        songNameLabel.font = UIFont.systemFont(ofSize: 16)
        self.contentView.addSubview(songNameLabel)

        songArtist.font = UIFont.systemFont(ofSize: 14)
        self.contentView.addSubview(songArtist)
    }

    @objc override func estimatedHeight() -> CGFloat {
        return 65
    }

    override internal func getHeight() -> CGFloat {
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

        songNameLabel.autoPinEdge(toSuperviewEdge: .top, withInset: 10)
        songNameLabel.autoPinEdge(.left, to: .right, of: poster, withOffset: 10)
        songNameLabel.autoPinEdge(toSuperviewEdge: .right, withInset: 10)

        songArtist.autoPinEdge(.top, to: .bottom, of: songNameLabel, withOffset: 2)
        songArtist.autoPinEdge(.left, to: .right, of: poster, withOffset: 10)
        songArtist.autoPinEdge(toSuperviewEdge: .right, withInset: 10)
        songArtist.autoPinEdge(toSuperviewEdge: .bottom, withInset: 10)
    }

    override func fillInCellData(_ shallow: Bool) {
        guard !shallow else {
            return
        }
        if let song = model as? KZPlayerItem {
            songNameLabel.text = song.title
            songArtist.text = song.subTitle()

            if let artwork = song.artwork() {
                poster.image = artwork.image(at: CGSize(width: 65, height: 65))
            }
        } else if let song = model as? XMLIndexer {
            songNameLabel.text = song.value(ofAttribute: "title")
            let artist: String = song.value(ofAttribute: "originalTitle") ?? ""
            let album: String = song.value(ofAttribute: "parentTitle") ?? ""
            songArtist.text = [artist, album].filter({ $0.count > 0 }).joined(separator: " - ")
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
