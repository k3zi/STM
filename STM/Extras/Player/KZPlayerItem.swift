//
//  KZPlayerItem.swift
//  KZPlayer
//
//  Created by Kesi Maduka on 10/24/15.
//  Copyright © 2015 Storm Edge Apps LLC. All rights reserved.
//

import UIKit
import MediaPlayer

class KZPlayerItem {
    var title = "", artist = "", album = "", albumArtist = "", genre = "", composer = "", assetURL = "", systemID = ""
    var trackNum = 1, playCount = 1, position = 0
    var startTime = 0.0, endTime = -1.0, tempo = 4.0
    var liked = false

    convenience init(item: MPMediaItem) {
        self.init()

        self.title = item.title ?? ""
        self.artist = item.artist ?? ""
        self.album = item.albumTitle ?? ""
        self.genre = item.genre ?? ""
        self.composer = item.composer ?? ""
        self.assetURL = item.assetURL?.absoluteString ?? ""

        self.trackNum = item.albumTrackNumber
        self.playCount = item.playCount

        self.startTime = 0
        self.endTime = item.playbackDuration

        self.systemID = String(item.persistentID)
    }

    func fileURL() -> NSURL {
        return NSURL(string: assetURL)!
    }

    func artwork() -> MPMediaItemArtwork? {
        let p = MPMediaPropertyPredicate(value: self.systemID, forProperty: MPMediaItemPropertyPersistentID)
        let q = MPMediaQuery(filterPredicates: [p])

        if q.items?.count > 0 {
            let item = q.items![0]
            return item.artwork
        }

        return nil
    }

    func aggregateText() -> String {
        return title+artist+album
    }

    func subTitle() -> String {
        return [artist, album].filter({ $0.characters.count > 0 }).joinWithSeparator(" - ")
    }
}
