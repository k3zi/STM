//
//  KZPlayer.swift
//  KZPlayer
//
//  Created by Kesi Maduka on 10/24/15.
//  Copyright © 2015 Storm Edge Apps LLC. All rights reserved.
//

import UIKit
import AVFoundation
import Accelerate
import MediaPlayer

import RealmSwift
import PRTween

//MARK: Settings
struct Settings {
    var repeatMode: KZPLayerRepeatMode = .RepeatAll
    var shuffleMode: KZPLayerShuffleMode = .NoShuffle
    var crossFadeMode: KZPLayerCrossFadeMode = .CrossFade
    var crossFadePrevious = false
}

enum KZPLayerRepeatMode {
    case NoRepeat
    case RepeatSong
    case RepeatAll
}

enum KZPLayerShuffleMode {
    case NoShuffle
    case Shuffle
}

enum KZPLayerCrossFadeMode {
    case NoCrossFade
    case CrossFade
}

protocol KZPlayerDelegate {
    func updateAveragePower(power: Float)
}

//MARK: Main Player
// swiftlint:disable force_try
class KZPlayer: NSObject {
    var converter = KZConverter()
    var inner = KZPlayerInner()
    var auFile1: EZAudioFile?
    var auFile2: EZAudioFile?

    var activePlayer = 1
    var wasStopped = false

    var item1: KZPlayerItem?
    var item2: KZPlayerItem?

    var settings = Settings()
    var delegate: KZPlayerDelegate?

    var crossFading = false
    var crossFadeDuration = 5.0, crossFadeTime = 5.0
    var crossFadeCount = 1

    //Volume
    var averagePower: Float = 0.0
    var volumeView = MPVolumeView()
    var musicPaused = false
    var reachedEnd = false
    var engine = FUXEngine()

    /// ------ Library ------- ///
    var realm: Realm?
    let thread = dispatch_queue_create("com.stormedgeapps.KZPlayer", DISPATCH_QUEUE_SERIAL)
    var allItems: Results<KZPlayerItem>?

    var itemArray: Results<KZPlayerItem>?
    var shuffledArray: Results<KZPlayerItem>?
    var upNextItems: Results<KZPlayerUpNextItem>?

    override init() {
        super.init()
        inner.delegate = self
        setUpAudioSession()

        //Setup Library
        dispatch_sync(thread) { () -> Void in
            self.realm = try! Realm()
            self.saveItems(self.getAllItems())
            self.allItems =  self.realm!.objects(KZPlayerItem)
            self.upNextItems = self.realm!.objects(KZPlayerUpNextItem)
        }
    }
}

//MARK:  Session / Remote / Now Playing
extension KZPlayer {
    func setUpAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setPreferredSampleRate(48000)
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord, withOptions: .DefaultToSpeaker)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Error starting audio sesssion")
        }

        volumeView.frame = CGRect(x: -2000, y: -2000, width: 0, height: 0)
        volumeView.alpha = 0.1
        volumeView.userInteractionEnabled = false

        if UIApplication.sharedApplication().windows.count > 0 {
            let window = UIApplication.sharedApplication().windows[0]
            window.addSubview(volumeView)
        }

        AppDelegate.del().window?.addSubview(volumeView)
        volumeView.hidden = true

        MPRemoteCommandCenter.sharedCommandCenter().playCommand.addTarget(self, action: Selector("play"))
        MPRemoteCommandCenter.sharedCommandCenter().pauseCommand.addTarget(self, action: Selector("pause"))
        MPRemoteCommandCenter.sharedCommandCenter().nextTrackCommand.addTarget(self, action: Selector("next"))

        MPRemoteCommandCenter.sharedCommandCenter().playCommand.enabled = true
        MPRemoteCommandCenter.sharedCommandCenter().pauseCommand.enabled = true
        MPRemoteCommandCenter.sharedCommandCenter().nextTrackCommand.enabled = true
        MPRemoteCommandCenter.sharedCommandCenter().previousTrackCommand.enabled = false
    }

    func updateNowPlayingInfo(item: KZPlayerItem) {
        let center = MPNowPlayingInfoCenter.defaultCenter()

        var dict = [String : AnyObject]()
        dict[MPMediaItemPropertyTitle] = item.title ?? ""
        dict[MPMediaItemPropertyArtist] = item.artist ?? ""
        dict[MPMediaItemPropertyAlbumTitle] = item.album ?? ""
        dict[MPMediaItemPropertyArtwork] = item.artwork() ?? MPMediaItemArtwork(image: UIImage())
        dict[MPMediaItemPropertyPlaybackDuration] = item.endTime - item.startTime
        dict[MPNowPlayingInfoPropertyPlaybackRate] = NSNumber(double: Double(inner.isPlaying()))
        center.nowPlayingInfo = dict
        MPRemoteCommandCenter.sharedCommandCenter().likeCommand.active = item.liked
    }

    func toggleLike() {
        if let item = itemForChannel() {
            MPRemoteCommandCenter.sharedCommandCenter().likeCommand.active = !item.liked

            if item.liked {
                unLikeItem(item)
            } else {
                likeItem(item)
            }
        }
    }
}

//MARK: Basic Functions
extension KZPlayer: EZAudioFileDelegate, KZPlayerInnerDelegate {
    //Play Collection
    func play(items: Results<KZPlayerItem>?, shuffle: Bool = false) {
        reset()

        setCollection(items, shuffle: shuffle)
        if shuffle {
            settings.shuffleMode = .Shuffle
        }

        if let collection = shuffle ? shuffledArray : itemArray {
            if collection.count > 0 {
                let item = collection[0]
                if settings.crossFadeMode == .CrossFade {
                    crossFadeTo(item)
                } else {
                    play(item)
                }
            }
        }
    }

    //Play Single Item
    func play(item: KZPlayerItem, var channel: Int = -1, silent: Bool = false) -> Bool {
        if channel == -1 {
            channel = activePlayer
        }

        if silent {
            inner.setVolume(0.0, forPlayer: Int32(channel))
        } else {
            inner.setVolume(1.0, forPlayer: Int32(channel))
        }
        self.setPlayerForChannel(EZAudioFile(URL: item.fileURL(), andDelegate: self, outputFormat: inner.audioStreamBasicDescription()), channel: channel)

        activePlayer = channel
        setItemForChannel(item)
        updateNowPlayingInfo(item)

        self.play()
        return true
    }

    func play() {
        inner.startPlayback()
        musicPaused = false
    }

    func pause() {
        self.musicPaused = true
    }

    func togglePlay() {
        if !musicPaused {
            pause()
        } else {
            play()
        }
    }

    func next() {
        playerCompleted(activePlayer, force: true)
    }

    func setSpeed(var value: AudioUnitParameterValue, channel: Int = -1) {
        if value < 1 || value > 16 {
            value = 4
        }

        inner.setRateValue(value)
    }

    var systemVolume: Float {
        set {
            if let view = volumeView.subviews.first as? UISlider {
                view.value = newValue
            }
        }

        get {
            if let view = volumeView.subviews.first as? UISlider {
                return view.value
            }
            return 0.0
        }
    }

    func volume(channel: Int = -1) -> Float {
        return inner.volumeForPlayer(Int32(channel))
    }

    func setVolume(value: Float, var channel: Int = -1) {
        if channel == -1 {
            channel = activePlayer
        }

        inner.setVolume(value, forPlayer: Int32(channel))
    }

    func playerCompleted(channel: Int, force: Bool = false) {
        if force || (!self.wasStopped && !(self.settings.crossFadeMode == .CrossFade)) {
            dispatch_async(thread) { () -> Void in
                if let nextItem = self.rotateSongs() {
                    if self.settings.crossFadeMode == .CrossFade {
                        self.crossFadeTo(nextItem)
                    } else {
                        self.play(nextItem)
                    }
                }
            }
        }
    }

    func shouldFillAudio1BufferList(audioBufferList: UnsafeMutablePointer<AudioBufferList>, frames: UInt32) {
        if !musicPaused {
            if let auFile1 = auFile1 {
                var bufferSize = UInt32()
                var eof = ObjCBool(false)
                auFile1.readFrames(frames, audioBufferList: audioBufferList, bufferSize: &bufferSize, eof: &eof)
                if eof && !reachedEnd && auFile2 == nil {
                    self.auFile1 = nil
                    self.next()
                } else if upNextItems?.count > 0 && auFile2 == nil && (auFile1.totalDuration() - auFile1.duration()) < Float(crossFadeTime) {
                    self.next()
                }
            } else {
                memset(audioBufferList.memory.mBuffers.mData, 0, Int(audioBufferList.memory.mBuffers.mDataByteSize))
            }
        }
    }

    func shouldFillAudio2BufferList(audioBufferList: UnsafeMutablePointer<AudioBufferList>, frames: UInt32) {
        if !musicPaused {
            if let auFile2 = auFile2 {
                var bufferSize = UInt32()
                var eof = ObjCBool(false)
                auFile2.readFrames(frames, audioBufferList: audioBufferList, bufferSize: &bufferSize, eof: &eof)
                if eof && !reachedEnd && auFile1 == nil {
                    self.auFile2 = nil
                    self.next()
                } else if upNextItems?.count > 0 && auFile1 == nil && (auFile2.totalDuration() - auFile2.duration()) < Float(crossFadeTime) {
                    self.next()
                }
            } else {
                memset(audioBufferList.memory.mBuffers.mData, 0, Int(audioBufferList.memory.mBuffers.mDataByteSize))
            }
        }
    }

    func hasDataWithMic(audioBufferList: UnsafeMutablePointer<AudioBufferList>, numberOfFrames frames: UInt32, format: AudioStreamBasicDescription) {
        self.converter.pipeData(audioBufferList, format: format)
    }
}

//MARK: CrossFade Functions
extension KZPlayer {
    func crossFadeTo(item: KZPlayerItem) {
        crossFadeCount += 1
        let currentCFCount = crossFadeCount
        self.crossFading = true

        if play(item, channel: inactivePlayer(), silent: true) {
            let tween1 = FUXTween.Tween(Float(crossFadeDuration), fromToValueFunc(from: volume(activePlayer), to: 1.0, valueFunc: { (value) -> () in
                self.inner.setVolume(value, forPlayer: Int32(self.activePlayer))
            }))

            engine + createOnComplete(tween1, onComplete: { () -> () in
                if currentCFCount == self.crossFadeCount {
                    self.crossFading = false
                }
            })

            engine + FUXTween.Tween(Float(crossFadeDuration), fromToValueFunc(from: volume(inactivePlayer()), to: 0.0, valueFunc: { (value) -> () in
                self.inner.setVolume(value, forPlayer: Int32(self.activePlayer))
            }))
        }
    }
}

//MARK: Helper
extension KZPlayer {
    func channelForPlayer(player: EZAudioFile) -> Int {
        return player == auFile1 ? 1 : 2
    }

    func playerForChannel(var channel: Int = -1) -> EZAudioFile? {
        if channel == -1 {
            channel = activePlayer
        }

        return channel == 1 ? auFile1 : auFile2
    }

    func itemForChannel(var channel: Int = -1) -> KZPlayerItem? {
        if channel == -1 {
            channel = activePlayer
        }

        return channel == 1 ? item1 : item2
    }

    func setItemForChannel(item: KZPlayerItem, var channel: Int = -1) {
        if channel == -1 {
            channel = activePlayer
        }

        if channel == 1 {
            item1 = item
        } else {
            item2 = item
        }
    }

    func setPlayerForChannel(player: EZAudioFile, var channel: Int = -1) {
        if channel == -1 {
            channel = activePlayer
        }

        if channel == 1 {
            auFile1 = player
        } else {
            auFile2 = player
        }
    }

    func inactivePlayer() -> Int {
        return activePlayer == 1 ? 2 : 1
    }

    func reset() {
        activePlayer = 1
        averagePower = 0.0
    }
}

//MARK: Library
extension KZPlayer {
    func find(query: String) -> Results<KZPlayerItem> {
        return self.allItems!.filter("title CONTAINS[c] %@ OR artist CONTAINS[c] %@ OR album CONTAINS[c] %@ OR albumArtist CONTAINS[c] %@", query, query, query, query)
    }

    //MARK: Session
    func rotateSongs() -> KZPlayerItem? {
        if settings.repeatMode == .RepeatSong {
            return itemForChannel()
        }

        var x: KZPlayerItem?

        if let item = self.popUpNext() {
            x = item
        } else if let collection = (settings.shuffleMode == .Shuffle ? self.shuffledArray : self.itemArray) {
            if collection.count > 0 {
                x = collection[0]
            }

            if let item = itemForChannel() {
                if let position = collection.indexOf(item) {
                    if (position + 1) < collection.count {
                        x = collection[position + 1]
                    } else {
                        if settings.repeatMode == .RepeatAll {
                            x = collection[0]
                        } else {
                            x = nil
                        }
                    }
                }
            }
        }

        return x
    }

    func setCollection(items: Results<KZPlayerItem>?, shuffle: Bool) {
        itemArray = items
        if shuffle {
            dispatch_sync(thread) { () -> Void in
                try! self.realm!.write {
                    self.shuffledArray = self.itemArray!.shuffled()
                }
            }
        }
    }

    func addUpNext(orig: KZPlayerItem) {
        let newItem = KZPlayerUpNextItem(orig: orig)
        try! self.realm!.write {
            self.realm!.add(newItem)
        }
    }

    func popUpNext() -> KZPlayerUpNextItem? {

        var x: KZPlayerUpNextItem?

        if self.upNextItems!.count > 0 {
            if let item = self.upNextItems?.first {
                try! self.realm!.write {
                    self.realm!.delete(item)
                }
                x = item
            }
        }

        return x
    }

    //MARK: Song Interaction

    func likeItem(var item: KZPlayerItem) {
        dispatch_sync(thread) { () -> Void in
            try! self.realm!.write {
                item = item.originalItem()
                item.liked = true
            }
        }
    }

    func unLikeItem(var item: KZPlayerItem) {
        dispatch_sync(thread) { () -> Void in
            try! self.realm!.write {
                item = item.originalItem()
                item.liked = false
            }
        }
    }


    //MARK: MediaPlayer Abstraction

    private func getAllItems() -> [MPMediaItem] {
        let predicate1 = MPMediaPropertyPredicate(value: MPMediaType.AnyAudio.rawValue, forProperty: MPMediaItemPropertyMediaType)
        let predicate12 = MPMediaPropertyPredicate(value: 0, forProperty: MPMediaItemPropertyIsCloudItem)
        let query = MPMediaQuery(filterPredicates: [predicate1, predicate12])

        return query.items!
    }

    private func saveItems(items: [MPMediaItem]) {
        var changed = false
        for item in items {
            let results = self.realm!.objects(KZPlayerItem).filter("systemID = '\(item.persistentID)'")
            if results.count == 0 {
                let newItem = KZPlayerItem(item: item)
                if newItem.assetURL.characters.count > 0 {
                    try! self.realm!.write {
                        self.realm!.add(newItem)
                    }
                    changed = true
                }
            }
        }

        if changed {
            NSNotificationCenter.defaultCenter().postNotificationName("KZPlayerLibraryDataChanged", object: nil)
        }
    }
}
