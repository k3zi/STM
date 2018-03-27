//
//  KZPlayerItem.swift
//  KZPlayer
//
//  Created by Kesi Maduka on 10/24/15.
//  Copyright © 2015 Storm Edge Apps LLC. All rights reserved.
//

import UIKit
import MediaPlayer
fileprivate func < <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}

class KZPlayerItem: NSObject, NSCoding {
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

    func fileURL() -> URL {
        return URL(string: assetURL)!
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
        return [artist, album].filter({ $0.count > 0 }).joined(separator: " - ")
    }

    required convenience init(coder aDecoder: NSCoder) {
        self.init()
        self.title = (aDecoder.decodeObject(forKey: "title") as? String) ?? ""
        self.artist = (aDecoder.decodeObject(forKey: "artist") as? String) ?? ""
        self.album = (aDecoder.decodeObject(forKey: "album") as? String) ?? ""
        self.albumArtist = (aDecoder.decodeObject(forKey: "albumArtist") as? String) ?? ""
        self.genre = (aDecoder.decodeObject(forKey: "genre") as? String) ?? ""
        self.composer = (aDecoder.decodeObject(forKey: "composer") as? String) ?? ""
        self.assetURL = (aDecoder.decodeObject(forKey: "assetURL") as? String) ?? ""
        self.systemID = (aDecoder.decodeObject(forKey: "systemID") as? String) ?? ""

        self.trackNum = aDecoder.decodeInteger(forKey: "trackNum")
        self.playCount = aDecoder.decodeInteger(forKey: "playCount")
        self.position = aDecoder.decodeInteger(forKey: "position")

        self.startTime = aDecoder.decodeDouble(forKey: "startTime")
        self.endTime = aDecoder.decodeDouble(forKey: "endTime")
        self.tempo = aDecoder.decodeDouble(forKey: "tempo")

        self.liked = aDecoder.decodeBool(forKey: "liked")
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(title, forKey: "title")
        aCoder.encode(artist, forKey: "artist")
        aCoder.encode(album, forKey: "album")
        aCoder.encode(albumArtist, forKey: "albumArtist")
        aCoder.encode(genre, forKey: "genre")
        aCoder.encode(composer, forKey: "composer")
        aCoder.encode(assetURL, forKey: "assetURL")
        aCoder.encode(systemID, forKey: "systemID")

        aCoder.encode(trackNum, forKey: "trackNum")
        aCoder.encode(playCount, forKey: "playCount")
        aCoder.encode(position, forKey: "position")

        aCoder.encode(startTime, forKey: "startTime")
        aCoder.encode(endTime, forKey: "endTime")
        aCoder.encode(tempo, forKey: "tempo")

        aCoder.encode(liked, forKey: "liked")
    }
}
