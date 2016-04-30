//
//  PlayerViewController.swift
//  STM
//
//  Created by Kesi Maduka on 3/2/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit
import M13ProgressSuite
import AVFoundation
import MediaPlayer
import StreamingKit

//MARK: Variables
class PlayerViewController: KZViewController, UISearchBarDelegate {
    var streamType: StreamType?
    var stream: STMStream?
    var player: STKAudioPlayer?
    var isPreviewing = false

    var commentSocket: SocketIOClient?
    let commentBackgroundQueue = dispatch_queue_create("com.stormedgeapps.streamtome.comment", nil)

    var hud: M13ProgressHUD?

    let topView = UIView()
    let dismissBT = UIButton.styleForDismissButton()
    var dismissBTTopPadding: NSLayoutConstraint?
    let closeBT = UIButton.styleForCloseButton()
    let albumPoster = UIImageView()
    let gradientView = GradientView()
    let gradientColorView = UIView()
    let visualizer = STMVisualizer()
    var visualizerUpdateCount = 0

    let rewindBT = UIButton()

    let songInfoHolderView = UIView()
    var songInfoHolderViewTopPadding: NSLayoutConstraint? = nil
    let songInfoLabel1 = UILabel()
    let songInfoLabel2 = UILabel()
    let songInfoLabel3 = UILabel()

    let commentsTableView = UITableView()
    let commentContentView = UIView()
    let commentToolbar = MessageToolbarView()
    var comments = [Any]()
    var didPostComment = false

    let bottomBlurBar = UIToolbar()
    var bottomBlurBarConstraint: NSLayoutConstraint?
    let streamInfoHolder = PlayerInfoHolderView()

    // Keyboard Adjustment
    lazy var keynode: Keynode.Connector = Keynode.Connector(view: self.view)
    var commentFieldKeyboardConstraint: NSLayoutConstraint?

    init() {
        super.init(nibName: nil, bundle: nil)

        self.modalPresentationStyle = .OverCurrentContext
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = RGB(0)

        setupTopView()
        setupCommentView()
        setupToolbar()

        keynode.animationsHandler = { [weak self] show, rect in
            if let me = self {
                if let con = me.commentFieldKeyboardConstraint {
                    con.constant = (show ? rect.size.height - 44 : 0)
                    me.view.layoutIfNeeded()
                }
            }
        }

        fetchOnce()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        PlayerViewController.cancelPreviousPerformRequestsWithTarget(self, selector: #selector(self.close(soft:)), object: true)

        if let hud = hud {
            hud.dismiss(true)
        }
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)

        if isPreviewing {
            self.performSelector(#selector(self.close(soft:)), withObject: true, afterDelay: 0.5)
        }
    }

    // MARK: Constraints
    override func setupConstraints() {
        super.setupConstraints()

        // Top View
        topView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero, excludingEdge: .Bottom)
        topView.autoMatchDimension(.Height, toDimension: .Height, ofView: view, withMultiplier: 0.334)

        dismissBTTopPadding = dismissBT.autoPinEdgeToSuperviewEdge(.Top, withInset: 25)
        dismissBT.autoPinEdgeToSuperviewEdge(.Left, withInset: 20)

        closeBT.autoAlignAxis(.Horizontal, toSameAxisOfView: dismissBT)
        closeBT.autoPinEdgeToSuperviewEdge(.Right, withInset: 20)

        albumPoster.autoPinEdgesToSuperviewEdges()

        gradientView.autoPinEdgesToSuperviewEdges()
        gradientColorView.autoPinEdgesToSuperviewEdges()

        visualizer.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)

        rewindBT.autoPinEdgeToSuperviewEdge(.Left, withInset: 20)
        rewindBT.autoPinEdgeToSuperviewEdge(.Bottom, withInset: 20)

        // Info Holder
        songInfoHolderViewTopPadding = songInfoHolderView.autoAlignAxis(.Horizontal, toSameAxisOfView: topView, withOffset: 5)
        songInfoHolderView.autoAlignAxisToSuperviewAxis(.Vertical)
        songInfoHolderView.autoPinEdgeToSuperviewEdge(.Left, withInset: 20)
        songInfoHolderView.autoPinEdgeToSuperviewEdge(.Right, withInset: 20)

        songInfoLabel1.autoPinEdgeToSuperviewEdge(.Top)
        songInfoLabel1.autoPinEdgeToSuperviewEdge(.Left)
        songInfoLabel1.autoPinEdgeToSuperviewEdge(.Right)

        songInfoLabel2.autoPinEdge(.Top, toEdge: .Bottom, ofView: songInfoLabel1, withOffset: 5)
        songInfoLabel2.autoPinEdgeToSuperviewEdge(.Left)
        songInfoLabel2.autoPinEdgeToSuperviewEdge(.Right)

        songInfoLabel3.autoPinEdge(.Top, toEdge: .Bottom, ofView: songInfoLabel2, withOffset: 5)
        songInfoLabel3.autoPinEdgeToSuperviewEdge(.Left)
        songInfoLabel3.autoPinEdgeToSuperviewEdge(.Right)
        songInfoLabel3.autoPinEdgeToSuperviewEdge(.Bottom)

        // Segment Control
        commentContentView.autoPinEdge(.Top, toEdge: .Bottom, ofView: topView)
        commentContentView.autoPinEdgeToSuperviewEdge(.Left)
        commentContentView.autoPinEdgeToSuperviewEdge(.Right)
        commentContentView.autoPinEdgeToSuperviewEdge(.Bottom)

        // Comments
        commentsTableView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero, excludingEdge: .Bottom)

        commentToolbar.autoPinEdge(.Top, toEdge: .Bottom, ofView: commentsTableView)
        commentToolbar.autoPinEdgeToSuperviewEdge(.Left)
        commentToolbar.autoPinEdgeToSuperviewEdge(.Right)

        // Toolbar
        bottomBlurBar.autoSetDimension(.Height, toSize: 44)
        commentFieldKeyboardConstraint = bottomBlurBar.autoPinEdge(.Top, toEdge: .Bottom, ofView: commentToolbar)
        bottomBlurBar.autoPinEdgeToSuperviewEdge(.Left)
        bottomBlurBar.autoPinEdgeToSuperviewEdge(.Right)
        bottomBlurBar.autoPinEdgeToSuperviewEdge(.Bottom)

        streamInfoHolder.autoPinEdgeToSuperviewEdge(.Top, withInset: 14)
        streamInfoHolder.autoAlignAxisToSuperviewAxis(.Vertical)
    }

    // MARK: Setup Views
    func setupTopView() {
        topView.backgroundColor = RGB(255)
        view.addSubview(topView)

        albumPoster.contentMode = .ScaleAspectFill
        topView.addSubview(albumPoster)

        gradientView.gradientLayer.colors = [RGB(0, a: 0).CGColor, RGB(0, a: 0).CGColor, RGB(0).CGColor]
        gradientView.gradientLayer.locations = [NSNumber(float: 0.0), NSNumber(float: 0.5), NSNumber(float: 1.0)]
        topView.addSubview(gradientView)

        gradientColorView.backgroundColor = Constants.UI.Color.off.colorWithAlphaComponent(0.66)
        topView.addSubview(gradientColorView)

        topView.addSubview(visualizer)

        dismissBT.addTarget(self, action: #selector(self.toggleDismiss), forControlEvents: .TouchUpInside)
        topView.addSubview(dismissBT)

        closeBT.addTarget(self, action: #selector(self.closeButtonPressed), forControlEvents: .TouchUpInside)
        topView.addSubview(closeBT)

        topView.addSubview(songInfoHolderView)
        [songInfoLabel1, songInfoLabel2, songInfoLabel3].forEach { (label) -> () in
            label.textAlignment = .Center
            label.textColor = RGB(255)
            if label != songInfoLabel1 {
                label.alpha = 0.66
                label.font = UIFont.systemFontOfSize(13, weight: UIFontWeightMedium)
            } else {
                label.text = "No Song Playing"
                label.font = UIFont.systemFontOfSize(18, weight: UIFontWeightMedium)
            }
            songInfoHolderView.addSubview(label)
        }

        rewindBT.addTarget(self, action: #selector(PlayerViewController.didPressRewindBT), forControlEvents: .TouchUpInside)
        rewindBT.setImage(UIImage(named: "rewindBT"), forState: .Normal)
        topView.addSubview(rewindBT)
    }

    func setupCommentView() {
        commentsTableView.delegate = self
        commentsTableView.dataSource = self
        commentsTableView.registerReusableCell(CommentCell)
        commentsTableView.registerReusableCell(TimelineItemCell)
        commentsTableView.estimatedRowHeight = 50
        commentsTableView.rowHeight = UITableViewAutomaticDimension
        commentContentView.backgroundColor = RGB(255)
        view.addSubview(commentContentView)
        commentContentView.addSubview(commentsTableView)

        commentToolbar.delegate = self
        commentContentView.addSubview(commentToolbar)
    }

    func setupToolbar() {
        commentContentView.addSubview(bottomBlurBar)

        streamInfoHolder.listeners = 0
        streamInfoHolder.comments = 0
        bottomBlurBar.addSubview(streamInfoHolder)
    }

    // **********************************************************************
    // **********************************************************************
    // **********************************************************************

    // MARK: View Changes/Updates

    func closeButtonPressed() {
        close(soft: false)
    }

    /**
     Close the host player view controller
     */
    func close(soft soft: Bool = false) {

        if AppDelegate.del().activeStreamController == self {
            AppDelegate.del().activeStreamController = nil
        }

        self.stop()
        self.commentSocket?.disconnect()

        if soft {
            return
        }

        guard let holderView = view.superview else {
            return
        }

        guard let pVC = self.presentingViewController as? UITabBarController else {
            return
        }

        self.view.endEditing(true)

        func innerClose() {
            if let vc = presentingViewController {
                vc.dismissViewControllerAnimated(true, completion: nil)
            }
        }

        if self.dismissBT.selected {
            let oldHeight = holderView.frame.origin.y + 40
            UIView.animateWithDuration(0.4, animations: {
                holderView.frame.origin.y += 40
                pVC.view.frame.size.height = oldHeight
                pVC.view.layoutSubviews()
                }, completion: { (finished) in
                    innerClose()
            })
        } else {
            innerClose()
        }
    }

    func showShareDialog() {
        guard let stream = stream else {
            return
        }

        let streamURL = stream.url()
        let vc = UIActivityViewController(activityItems: [streamURL], applicationActivities: nil)
        self.presentViewController(vc, animated: true, completion: nil)
    }

    func toggleDismiss() {
        innerToggleDismiss(nil)
    }

    /**
     Minimizes or maximizes the host player view controller
     */
    func innerToggleDismiss(minimize: Bool? = nil) {
        guard let holderView = view.superview else {
            return
        }

        guard let pVC = self.presentingViewController as? UITabBarController else {
            return
        }

        guard let minimize = minimize != nil ? minimize : !self.dismissBT.selected else {
            return
        }

        pVC.view.superview?.backgroundColor = RGB(0)
        self.view.endEditing(true)

        if minimize && !self.dismissBT.selected {
            pVC.view.frame.size.height = pVC.view.frame.size.height - 40
            pVC.view.layoutSubviews()
            pVC.selectedIndex = 0

            UIView.animateWithDuration(0.4, animations: {
                holderView.frame.origin.y = pVC.view.frame.size.height

                self.dismissBTTopPadding?.constant = 10
                self.dismissBT.selected = true
            })
        } else if !minimize && self.dismissBT.selected {
            let oldHeight = holderView.frame.origin.y + 40
            UIView.animateWithDuration(0.4, animations: {
                holderView.frame.origin.y = 0

                self.dismissBTTopPadding?.constant = 25
                self.dismissBT.selected = false
                }, completion: { (finished) in
                    pVC.view.frame.size.height = oldHeight
                    pVC.view.layoutSubviews()
            })
        }
    }

    /**
    Dismiss the host player view controller
    */
    func dismiss() {
        if let vc = presentingViewController {
            vc.dismissViewControllerAnimated(true, completion: nil)
        }
    }

    /**
     Toggles the extended layout of the toolbar

     - parameter show: whether to extend(true) or collapse(false) the toolbar
     */
    func toggleToolbar(show: Bool? = nil) {
        if let con = bottomBlurBarConstraint {
            if let show = show != nil ? show : (con.constant == 44) {
                UIView.animateWithDuration(0.5, animations: { () -> Void in
                    con.constant = show ? 0 : 44
                    self.view.layoutIfNeeded()
                })
            }
        }
    }

    func didPressRewindBT() {

    }

    /**
     Updates the controller's views with the correct song info/artwork

     - parameter song: The song that has started playing
     */
    func updateCurrentSong(song: KZPlayerItem?) {
        updateNowPlayingInfo(song)

        if let song = song {
            if let artwork = song.artwork() {
                UIView.transitionWithView(albumPoster, duration: 0.5, options: .TransitionCrossDissolve, animations: { () -> Void in
                    self.albumPoster.image = artwork.imageWithSize(CGSize(width: self.albumPoster.frame.width, height: self.albumPoster.frame.width))
                    }, completion: nil)
            }

            songInfoLabel1.text = song.title
            songInfoLabel2.text = song.artist
            songInfoLabel3.text = song.album
        } else {
            songInfoLabel1.text = "No Song Playing"
            songInfoLabel2.text = nil
            songInfoLabel3.text = nil
        }

        if (songInfoLabel2.text?.characters.count == 0 && songInfoLabel3.text?.characters.count == 0) || (songInfoLabel2.text == nil || songInfoLabel3.text == nil) {
            songInfoHolderViewTopPadding?.constant = 5
        } else if (songInfoLabel2.text?.characters.count != 0 && songInfoLabel3.text?.characters.count != 0) || (songInfoLabel2.text != nil && songInfoLabel3.text != nil) {
            songInfoHolderViewTopPadding?.constant = -5
        } else {
            songInfoHolderViewTopPadding?.constant = 0
        }

        songInfoHolderView.layoutIfNeeded()
    }

    /**
     Updates the MPNowPlayingInfoCenter (lock screen) with the song info

     - parameter item: The song that has started playing
     */
    func updateNowPlayingInfo(item: KZPlayerItem?) {
        let center = MPNowPlayingInfoCenter.defaultCenter()

        var dict = [String : AnyObject]()
        dict[MPNowPlayingInfoPropertyPlaybackRate] = NSNumber(double: Double(1))

        if let item = item {
            dict[MPMediaItemPropertyTitle] = item.title ?? ""
            dict[MPMediaItemPropertyArtist] = item.artist ?? ""
            dict[MPMediaItemPropertyAlbumTitle] = item.album ?? ""
            dict[MPMediaItemPropertyArtwork] = item.artwork() ?? MPMediaItemArtwork(image: UIImage())
            dict[MPMediaItemPropertyPlaybackDuration] = item.endTime - item.startTime
        } else {
            dict[MPMediaItemPropertyTitle] = "No Song Playing"
        }
        center.nowPlayingInfo = dict
    }

    // **********************************************************************
    // **********************************************************************
    // **********************************************************************

    // MARK: TableView Data Source
    override func tableViewCellData(tableView: UITableView, section: Int) -> [Any] {
        if tableView == commentsTableView {
            return comments
        }

        return super.tableViewCellData(tableView, section: section)
    }

    override func tableViewCellClass(tableView: UITableView, indexPath: NSIndexPath?) -> KZTableViewCell.Type {
        if tableView == commentsTableView {
            if comments[indexPath?.row ?? 0] is STMTimelineItem {
                return TimelineItemCell.self
            } else {
                return CommentCell.self
            }
        }

        return super.tableViewCellClass(tableView, indexPath: indexPath)
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 50
    }

    override func tableViewNoDataText(tableView: UITableView) -> String {
        if tableView == commentsTableView {
            return "No Comments\n\nBe the first one to comment :)"
        }

        return super.tableViewNoDataText(tableView)
    }

    // MARK: Handle Data
    dynamic override func fetchData() {
        fetchData(false)
    }
}

//**********************************************************************
//**********************************************************************
//**********************************************************************

//MARK: Comment Updates
extension PlayerViewController: MessageToolbarDelegate {

    /**
     Called on comment submit

     - parameter text: the text that was posted
     */
    func handlePost(text: String) {
        guard text.characters.count > 0 else {
            return
        }

        guard let socket = self.commentSocket else {
            return
        }

        dispatch_async(commentBackgroundQueue) { () -> Void in
            while socket.status != .Connected {
                NSRunLoop.mainRunLoop().runMode(NSDefaultRunLoopMode, beforeDate: NSDate.distantFuture())
            }

            self.didPostComment = true
            var params = [String: AnyObject]()
            params["text"] = text
            socket.emitWithAck("addComment", params)(timeoutAfter: 0) { data in
                Answers.logCustomEventWithName("Comment", customAttributes: [:])
                NSNotificationCenter.defaultCenter().postNotificationName(Constants.Notification.DidPostComment, object: nil)
            }
        }

        view.endEditing(true)
    }

    func didBeginEditing() {
        commentsTableView.scrollToBottom(true)
    }

    func didReciveComment(response: AnyObject) {
        if let result = response as? JSON {
            if let comment = STMComment(json: result) {
                let isAtBottom = commentsTableView.indexPathsForVisibleRows?.contains({ $0.row == (comments.count - 1) })
                let shouldScrollDown = (didPostComment ?? false) || (isAtBottom ?? false)
                comments.append(comment)
                didUpdateComments(shouldScrollDown)
            }
        }
    }

    func didReciveUserJoined(response: AnyObject) {
        guard let result = response as? JSON else {
            return
        }

        guard let item = STMTimelineItem(json: result) else {
            return
        }

        guard item.user?.id != AppDelegate.del().currentUser?.id else {
            return
        }

        let isAtBottom = commentsTableView.indexPathsForVisibleRows?.contains({ $0.row == (comments.count - 1) })
        let shouldScrollDown = (didPostComment ?? false) || (isAtBottom ?? false)
        comments.append(item)
        didUpdateComments(shouldScrollDown)
    }

    func didUpdateComments(shouldScrollDown: Bool) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            if self.comments.count > 1 {
                self.commentsTableView.beginUpdates()
                self.commentsTableView.insertRowsAtIndexPaths([NSIndexPath(forRow: self.comments.count - 1, inSection: 0)], withRowAnimation: .Fade)
                self.commentsTableView.endUpdates()
                if shouldScrollDown {
                    self.commentsTableView.scrollToBottom(true)
                }
            } else {
                self.commentsTableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Fade)
            }
        })
    }

    func fetchOnce() {
        guard let stream = stream else {
            return
        }

        Constants.Network.GET("/stream/\(stream.id)/comments", parameters: nil, completionHandler: { (response, error) -> Void in
            self.handleResponse(response, error: error, successCompletion: { (result) -> Void in
                self.comments.removeAll()
                if let result = result as? [JSON] {
                    let comments = [STMComment].fromJSONArray(result)
                    comments.forEach({ self.comments.insert($0, atIndex: 0) })
                    self.streamInfoHolder.comments = comments.count
                    self.commentsTableView.reloadData()
                    self.commentsTableView.scrollToBottom(false)
                }
            })
        })
    }

    func fetchData(scrollToBottom: Bool) {

    }
}

//**********************************************************************
//**********************************************************************
//**********************************************************************

//MARK: Initialize Stream
extension PlayerViewController: STKAudioPlayerDelegate {

    /**
     Plays the passed in stream

     - parameter stream:   The stream to play
     - parameter callback: Any error or nil if there was none
     */
    func start(stream: STMStream, vc: UIViewController, showHUD: Bool = true, callback: ((Bool, String?) -> Void)? = nil) {
        let progressView = M13ProgressViewRing()
        progressView.primaryColor = Constants.UI.Color.tint
        progressView.secondaryColor = Constants.UI.Color.disabled
        progressView.indeterminate = true

        func innerStart() {
            hud = M13ProgressHUD(progressView: progressView)
            if let hud = hud where showHUD {
                hud.frame = (AppDelegate.del().window?.bounds)!
                hud.progressViewSize = CGSize(width: 60, height: 60)
                hud.animationPoint = CGPoint(x: UIScreen.mainScreen().bounds.size.width / 2, y: UIScreen.mainScreen().bounds.size.height / 2)
                hud.status = "Playing Stream"
                hud.applyBlurToBackground = true
                hud.maskType = M13ProgressHUDMaskTypeIOS7Blur
                AppDelegate.del().window?.addSubview(hud)
                hud.show(true)
            }

            self.stream = stream
            connectToStream(vc, callback: callback)
        }

        if let activeVC = AppDelegate.del().activeStreamController {
            guard let activeVC = activeVC as? PlayerViewController else {
                if let callback = callback {
                    callback(false, "You are currently hosting a stream")
                }

                return
            }

            let alertVC = UIAlertController(title: "Confirm", message: "Continuing will stop the playback of the current stream", preferredStyle: .Alert)
            alertVC.addAction(UIAlertAction(title: "Continue", style: .Default, handler: { (action) in
                activeVC.close()
                innerStart()
            }))
            alertVC.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
            AppDelegate.topViewController()?.presentViewController(alertVC, animated: true, completion: nil)
        } else {
            innerStart()
        }
    }

    func connectToStream(vc: UIViewController? = nil, callback: ((Bool, String?) -> Void)? = nil) {
        guard let stream = stream else {
            return
        }

        func proccessError(error: String? = nil, callback: ((Bool, String?) -> Void)?) {
            if let hud = self.hud {
                hud.dismiss(true)
            }

            if let callback = callback {
                callback(false, error)
            }
        }

        Constants.Network.POST("/playStream/" + String(stream.id ?? 0), parameters: nil, completionHandler: { (response, error) -> Void in
            (vc ?? self).handleResponse(response, error: error, successCompletion: { (result) -> Void in
                guard let result = result as? [String: AnyObject] else {
                    return proccessError("Invalid response", callback: callback)
                }

                guard let authKey = result["auth"] as? String else {
                    return proccessError("Invalid session", callback: callback)
                }

                guard let user = AppDelegate.del().currentUser else {
                    return proccessError("Invalid session", callback: callback)
                }

                AppDelegate.del().setUpAudioSession(withMic: false)

                let streamURL = Constants.Config.apiBaseURL + "/streamLiveToDevice/\(stream.id)/\(user.id)/" + authKey

                var options = STKAudioPlayerOptions()
                if let setting = result["secondsRequiredToStartPlaying"] as? Float32 {
                    options.secondsRequiredToStartPlaying = setting
                }

                if let setting = result["secondsRequiredToStartPlayingAfterBufferUnderun"] as? Float32 {
                    options.secondsRequiredToStartPlayingAfterBufferUnderun = setting
                }

                if let setting = result["bufferSizeInSeconds"] as? Float32 {
                    options.bufferSizeInSeconds = setting
                }

                let player = STKAudioPlayer(options: options)
                player.meteringEnabled = true
                player.delegate = self
                player.play(streamURL)
                player.appendFrameFilterWithName("visualizer", block: { (channelsPerFrame, bytesPerFrame, frameCount, ioData) -> Void in
                    if self.visualizerUpdateCount == 2 {
                        let decibels = player.averagePowerInDecibelsForChannel(0)
                        let level = MeterTable.sharedTable().ValueAt(decibels)

                        ObjectiveCProcessing.proccessVisualizerBufferData(ioData, audioLevel: level, frames: UInt32(frameCount), bytesPerFrame: bytesPerFrame, channelsPerFrame: channelsPerFrame, size: self.visualizer.frame.size, update: { (barIndex, height) -> Void in
                            self.visualizer.setBarHeight(Int(barIndex), height: height)
                        })

                        self.visualizerUpdateCount = 0
                    } else {
                        self.visualizerUpdateCount += 1
                    }
                })

                self.player = player
                self.stream = stream

                self.connectGlobalStream()

                if let callback = callback {
                    callback(true, nil)
                }
                Answers.logCustomEventWithName("Played Stream", customAttributes: [:])

                }, errorCompletion: { (error) -> Void in
                    proccessError(error, callback: callback)
            })
        })
    }

    /**
     Connects to the Output/Comment Socket.IO
     */
    func connectGlobalStream() {
        if let hud = self.hud {
            hud.dismiss(true)
        }

        guard let user = AppDelegate.del().currentUser else {
            return
        }

        guard let stream = self.stream else {
            return
        }

        guard let baseURL = NSURL(string: Constants.Config.apiBaseURL) else {
            return
        }

        let oForcePolling = SocketIOClientOption.ForcePolling(true)
        let oAuth = SocketIOClientOption.ConnectParams(["streamID": stream.id, "userID": user.id, "stmHash": Constants.Config.streamHash])
        let commentHost = SocketIOClientOption.Nsp("/comment")
        let commentOptions = [oForcePolling, commentHost, oAuth] as Set<SocketIOClientOption>

        self.commentSocket = SocketIOClient(socketURL: baseURL, options: commentOptions)
        if let socket = self.commentSocket {
            socket.on("connect") { data, ack in
                print("Comment: Socket Connected")
            }

            socket.on("newComment") { data, ack in
                self.didReciveComment(data[0])
            }

            socket.on("item") { data, ack in
                self.didReciveUserJoined(data[0])
            }

            socket.connect()
        }
    }

    //MARK: Audio Player Delegate

    func audioPlayer(audioPlayer: STKAudioPlayer, stateChanged state: STKAudioPlayerState, previousState: STKAudioPlayerState) {
        let active = state == .Playing || state == .Buffering
        UIView.animateWithDuration(0.5) { () -> Void in
            if active {
                self.gradientColorView.backgroundColor = Constants.UI.Color.tint.colorWithAlphaComponent(0.66)
            } else {
                self.gradientColorView.backgroundColor = Constants.UI.Color.off.colorWithAlphaComponent(0.66)
            }
        }
    }

    func audioPlayer(audioPlayer: STKAudioPlayer, didStartPlayingQueueItemId queueItemId: NSObject) {

    }

    func audioPlayer(audioPlayer: STKAudioPlayer, unexpectedError errorCode: STKAudioPlayerErrorCode) {

    }

    func audioPlayer(audioPlayer: STKAudioPlayer, didFinishBufferingSourceWithQueueItemId queueItemId: NSObject) {

    }

    func audioPlayer(audioPlayer: STKAudioPlayer, didFinishPlayingQueueItemId queueItemId: NSObject, withReason stopReason: STKAudioPlayerStopReason, andProgress progress: Double, andDuration duration: Double) {

    }

}

//**********************************************************************
//**********************************************************************
//**********************************************************************

//MARK: Audio Playback
extension PlayerViewController {
    func play() {
        self.connectGlobalStream()
    }

    func stop() {
        self.player?.stop()
    }
}

//**********************************************************************
//**********************************************************************
//**********************************************************************

protocol PlayerPreviewDelegate {
    func playerShouldContinuePlaying() -> Bool
}
