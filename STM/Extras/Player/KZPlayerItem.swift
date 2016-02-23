//
//  KZPlayerItem.swift
//  KZPlayer
//
//  Created by Kesi Maduka on 10/24/15.
//  Copyright © 2015 Storm Edge Apps LLC. All rights reserved.
//

import UIKit
import MediaPlayer
import RealmSwift

class KZPlayerItem: Object {
    dynamic var title = "", artist = "", album = "", albumArtist = "", genre = "", composer = "", assetURL = "", systemID = ""
    dynamic var trackNum = 1, playCount = 1, position = 0
    dynamic var startTime = 0.0, endTime = -1.0, tempo = 4.0
    dynamic var oItem: KZPlayerItem? = nil
    dynamic var liked = false
    let tags = List<KZPlayerTag>()

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
        self.oItem = self
    }

    func originalItem() -> KZPlayerItem {
        if oItem == self || oItem == nil {
            return self
        } else {
            return oItem!.originalItem()
        }
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
        return [artist, album].joinWithSeparator(" - ")
    }
}

class KZPlayerUpNextItem: KZPlayerItem {
    convenience init(orig: KZPlayerItem) {
        self.init()

        self.title = orig.title
        self.artist = orig.artist
        self.album = orig.album
        self.genre = orig.genre
        self.composer = orig.composer
        self.assetURL = orig.assetURL

        self.trackNum = orig.trackNum
        self.playCount = orig.playCount

        self.startTime = orig.startTime
        self.endTime = orig.endTime

        self.systemID = orig.systemID
        self.oItem = orig
    }
}

extension Results where T: KZPlayerItem {
    func shuffled() -> Results<T> {
        for result in self {
            result.position = Int(arc4random_uniform(UInt32(self.count)))
        }

        return self.sorted("position")
    }

    func toArray() -> [T] {
        var arr = [T]()

        for result in self {
            arr.append(result)
        }

        return arr
    }
}
