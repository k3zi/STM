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
import MessageUI

// MARK: Variables
class PlayerViewController: KZViewController, UISearchBarDelegate, UIViewControllerPreviewingDelegate, MFMailComposeViewControllerDelegate {
    var streamType: StreamType?
    var stream: STMStream?
    var player: STKAudioPlayer?
    var isPreviewing = false

    var commentSocket: SocketIOClient?
    let commentBackgroundQueue = DispatchQueue(label: "com.stormedgeapps.streamtome.comment", attributes: [])

    var hud: M13ProgressHUD?

    let topView = UIView()
    let innerTopView = UIView()
    let dismissBT = UIButton.styleForDismissButton()
    var dismissBTTopPadding: NSLayoutConstraint?
    let miscBT = UIButton.styleForMiscButton()
    let streamTitleLabel = Label()
    let albumPoster = UIImageView()
    let streamPictureView = UIImageView()
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

        self.modalPresentationStyle = .overCurrentContext
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        self.stop()
        self.commentSocket?.disconnect()
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        PlayerViewController.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.closeButtonPressed), object: nil)

        if let hud = hud {
            hud.dismiss(true)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if isPreviewing {
            self.perform(#selector(self.closeButtonPressed), with: nil, afterDelay: 0.5)
        }
    }

    // MARK: Constraints
    override func setupConstraints() {
        super.setupConstraints()

        // Top View
        topView.autoPin(toTopLayoutGuideOf: self, withInset: -20)
        topView.autoPinEdge(toSuperviewEdge: .left, withInset: 0)
        topView.autoPinEdge(toSuperviewEdge: .right, withInset: 0)
        topView.autoMatch(.height, to: .height, of: view, withMultiplier: 0.4)

        dismissBTTopPadding = dismissBT.autoPinEdge(toSuperviewEdge: .top, withInset: 25)
        dismissBT.autoPinEdge(toSuperviewEdge: .left, withInset: 20)

        miscBT.autoAlignAxis(.horizontal, toSameAxisOf: dismissBT)
        miscBT.autoPinEdge(toSuperviewEdge: .right, withInset: 20)

        innerTopView.autoPinEdge(.top, to: .bottom, of: streamTitleLabel)
        innerTopView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .top)

        streamTitleLabel.autoAlignAxis(.horizontal, toSameAxisOf: dismissBT)
        streamTitleLabel.autoAlignAxis(toSuperviewAxis: .vertical)

        albumPoster.autoPinEdgesToSuperviewEdges()

        gradientView.autoPinEdgesToSuperviewEdges()
        gradientColorView.autoPinEdgesToSuperviewEdges()

        visualizer.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero)

        rewindBT.autoPinEdge(toSuperviewEdge: .left, withInset: 20)
        rewindBT.autoPinEdge(toSuperviewEdge: .bottom, withInset: 20)

        // Info Holder
        songInfoHolderView.autoAlignAxis(toSuperviewAxis: .horizontal)
        songInfoHolderView.autoAlignAxis(toSuperviewAxis: .vertical)
        songInfoHolderView.autoPinEdge(toSuperviewEdge: .left, withInset: 20)
        songInfoHolderView.autoPinEdge(toSuperviewEdge: .right, withInset: 20)

        streamPictureView.autoPinEdge(toSuperviewEdge: .top)
        streamPictureView.autoSetDimensions(to: CGSize(width: 80, height: 80))
        streamPictureView.autoAlignAxis(toSuperviewAxis: .vertical)

        songInfoLabel1.autoPinEdge(.top, to: .bottom, of: streamPictureView, withOffset: 20)
        songInfoLabel1.autoPinEdge(toSuperviewEdge: .left)
        songInfoLabel1.autoPinEdge(toSuperviewEdge: .right)

        songInfoLabel2.autoPinEdge(.top, to: .bottom, of: songInfoLabel1, withOffset: 5)
        songInfoLabel2.autoPinEdge(toSuperviewEdge: .left)
        songInfoLabel2.autoPinEdge(toSuperviewEdge: .right)

        songInfoLabel3.autoPinEdge(.top, to: .bottom, of: songInfoLabel2, withOffset: 5)
        songInfoLabel3.autoPinEdge(toSuperviewEdge: .left)
        songInfoLabel3.autoPinEdge(toSuperviewEdge: .right)
        songInfoLabel3.autoPinEdge(toSuperviewEdge: .bottom)

        // Segment Control
        commentContentView.autoPinEdge(.top, to: .bottom, of: topView)
        commentContentView.autoPinEdge(toSuperviewEdge: .left)
        commentContentView.autoPinEdge(toSuperviewEdge: .right)
        commentContentView.autoPinEdge(toSuperviewEdge: .bottom)

        // Comments
        commentsTableView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .bottom)

        commentToolbar.autoPinEdge(.top, to: .bottom, of: commentsTableView)
        commentToolbar.autoPinEdge(toSuperviewEdge: .left)
        commentToolbar.autoPinEdge(toSuperviewEdge: .right)

        // Toolbar
        bottomBlurBar.autoSetDimension(.height, toSize: 44)
        commentFieldKeyboardConstraint = bottomBlurBar.autoPinEdge(.top, to: .bottom, of: commentToolbar)
        bottomBlurBar.autoPinEdge(toSuperviewEdge: .left)
        bottomBlurBar.autoPinEdge(toSuperviewEdge: .right)
        bottomBlurBar.autoPinEdge(toSuperviewEdge: .bottom)

        streamInfoHolder.autoPinEdge(toSuperviewEdge: .top, withInset: 14)
        streamInfoHolder.autoAlignAxis(toSuperviewAxis: .vertical)
    }

    // MARK: Setup Views
    func setupTopView() {
        topView.backgroundColor = RGB(255)
        view.addSubview(topView)

        albumPoster.contentMode = .scaleAspectFill
        albumPoster.clipsToBounds = true
        topView.addSubview(albumPoster)

        gradientView.gradientLayer.colors = [RGB(0, a: 0).cgColor, RGB(0, a: 0).cgColor, RGB(0).cgColor]
        gradientView.gradientLayer.locations = [NSNumber(value: 0.0 as Float), NSNumber(value: 0.5 as Float), NSNumber(value: 1.0 as Float)]
        topView.addSubview(gradientView)

        gradientColorView.backgroundColor = Constants.UI.Color.off.withAlphaComponent(0.66)
        topView.addSubview(gradientColorView)

        topView.addSubview(visualizer)

        dismissBT.addTarget(self, action: #selector(self.toggleDismiss), for: .touchUpInside)
        topView.addSubview(dismissBT)

        miscBT.addTarget(self, action: #selector(HostViewController.showMenu), for: .touchUpInside)
        topView.addSubview(miscBT)

        streamTitleLabel.text = stream?.name
        streamTitleLabel.textColor = themeColor()
        streamTitleLabel.backgroundColor = RGB(255)
        streamTitleLabel.layer.cornerRadius = 6.0
        streamTitleLabel.clipsToBounds = true
        streamTitleLabel.font = UIFont.systemFont(ofSize: 13.0)
        streamTitleLabel.setContentEdgeInsets(UIEdgeInsets(top: 5, left: 20, bottom: 5, right: 20))
        innerTopView.addSubview(streamTitleLabel)

        innerTopView.addSubview(songInfoHolderView)
        [songInfoLabel1, songInfoLabel2, songInfoLabel3].forEach { (label) -> () in
            label.textAlignment = .center
            label.textColor = RGB(255)
            if label != songInfoLabel1 {
                label.alpha = 0.66
                label.font = UIFont.systemFont(ofSize: 12, weight: UIFontWeightMedium)
            } else {
                label.text = "No Song Playing"
                label.font = UIFont.systemFont(ofSize: 14, weight: UIFontWeightMedium)
            }
            songInfoHolderView.addSubview(label)
        }

        streamPictureView.layer.cornerRadius = 80.0/2.0
        streamPictureView.clipsToBounds = true
        streamPictureView.backgroundColor = Constants.UI.Color.imageViewDefault
        if let stream = stream {
            streamPictureView.kf.setImage(with: stream.pictureURL(), placeholder: UIImage(named: "defaultStreamImage"))
        }
        songInfoHolderView.addSubview(streamPictureView)

        rewindBT.isHidden = true
        rewindBT.addTarget(self, action: #selector(PlayerViewController.didPressRewindBT), for: .touchUpInside)
        rewindBT.setImage(UIImage(named: "rewindBT"), for: UIControlState())
        innerTopView.addSubview(rewindBT)

        topView.addSubview(innerTopView)
    }

    func setupCommentView() {
        commentsTableView.delegate = self
        commentsTableView.dataSource = self
        commentsTableView.registerReusableCell(CommentCell.self)
        commentsTableView.registerReusableCell(TimelineItemCell.self)
        commentsTableView.estimatedRowHeight = 50
        commentsTableView.rowHeight = UITableViewAutomaticDimension
        commentContentView.backgroundColor = RGB(255)
        view.addSubview(commentContentView)
        commentContentView.addSubview(commentsTableView)

        registerForPreviewing(with: self, sourceView: commentsTableView)

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
    func close(soft: Bool = false, completion: (() -> Void)? = nil) {

        if AppDelegate.del().activeStreamController == self {
            AppDelegate.del().activeStreamController = nil
        }

        self.stop()
        self.commentSocket?.disconnect()

        if soft {
            return
        }

        self.view.endEditing(true)

        func innerClose() {
            if let vc = presentingViewController {
                vc.dismiss(animated: true, completion: completion)
            }
        }

        if self.dismissBT.isSelected {
            guard let holderView = view.superview else {
                return innerClose()
            }

            guard let pVC = self.presentingViewController as? UITabBarController else {
                return innerClose()
            }

            let oldHeight = holderView.frame.origin.y + 40
            UIView.animate(withDuration: 0.4, animations: {
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

    func showMenu() {
        let menu = UIAlertController(title: "Player Menu", message: nil, preferredStyle: .actionSheet)
        menu.popoverPresentationController?.sourceView = miscBT

        menu.addAction(UIAlertAction(title: "Report", style: .default, handler: { (action) in
            guard let stream = self.stream else {
                return
            }

            var streamName = ""
            if let name = stream.name {
                streamName = name
            }

            let mailComposerVC = MFMailComposeViewController()
            mailComposerVC.mailComposeDelegate = self
            mailComposerVC.setToRecipients(["support@stm.io"])
            mailComposerVC.setSubject("Report Content: \(streamName) (\(stream.alphaID()))")

            if MFMailComposeViewController.canSendMail() {
                Answers.logCustomEvent(withName: "Stream Reported", customAttributes: nil)
                self.present(mailComposerVC, animated: true, completion: nil)
            }
        }))

        menu.addAction(UIAlertAction(title: "Share", style: .default, handler: { (action) in
            self.showShareDialog()
        }))

        menu.addAction(UIAlertAction(title: "Close Stream", style: .destructive, handler: { (action) in
            self.close()
        }))

        menu.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        present(menu, animated: true, completion: nil)
    }

    func showShareDialog() {
        guard let stream = stream else {
            return
        }

        let streamURL = stream.shareURL()
        let vc = UIActivityViewController(activityItems: [streamURL as Any], applicationActivities: nil)
        self.present(vc, animated: true, completion: nil)
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        self.dismiss(animated: true, completion: nil)
    }

    func toggleDismiss() {
        innerToggleDismiss(nil)
    }

    /**
     Minimizes or maximizes the host player view controller
     */
    func innerToggleDismiss(_ minimize: Bool? = nil) {
        guard let holderView = view.superview else {
            return
        }

        guard let pVC = self.presentingViewController as? UITabBarController else {
            return
        }

        guard let minimize = minimize != nil ? minimize : !self.dismissBT.isSelected else {
            return
        }

        pVC.view.superview?.backgroundColor = RGB(0)
        self.view.endEditing(true)

        if minimize && !self.dismissBT.isSelected {
            pVC.view.frame.size.height = pVC.view.frame.size.height - 40
            pVC.view.layoutSubviews()
            pVC.selectedIndex = 0

            UIView.animate(withDuration: 0.4, animations: {
                holderView.frame.origin.y = pVC.view.frame.size.height

                self.dismissBTTopPadding?.constant = 10
                self.dismissBT.isSelected = true
                self.topView.layoutIfNeeded()
            })
        } else if !minimize && self.dismissBT.isSelected {
            let oldHeight = holderView.frame.origin.y + 40
            UIView.animate(withDuration: 0.4, animations: {
                holderView.frame.origin.y = 0

                self.dismissBTTopPadding?.constant = 25
                self.dismissBT.isSelected = false
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
            vc.dismiss(animated: true, completion: nil)
        }
    }

    /**
     Toggles the extended layout of the toolbar

     - parameter show: whether to extend(true) or collapse(false) the toolbar
     */
    func toggleToolbar(_ show: Bool? = nil) {
        if let con = bottomBlurBarConstraint {
            if let show = show != nil ? show : (con.constant == 44) {
                UIView.animate(withDuration: 0.5, animations: { () -> Void in
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
    func updateCurrentSong(_ meta: STMStreamMeta?) {
        updateNowPlayingInfo(meta)

        if let meta = meta {
            if let artwork = meta.image {
                UIView.transition(with: albumPoster, duration: 0.5, options: .transitionCrossDissolve, animations: { () -> Void in
                    self.albumPoster.image = artwork
                }, completion: nil)
            } else {
                UIView.transition(with: albumPoster, duration: 0.5, options: .transitionCrossDissolve, animations: { () -> Void in
                    self.albumPoster.image = nil
                }, completion: nil)
            }

            songInfoLabel1.text = meta.title
            songInfoLabel2.text = meta.artist
            songInfoLabel3.text = meta.album
        } else {
            songInfoLabel1.text = "No Song Playing"
            songInfoLabel2.text = nil
            songInfoLabel3.text = nil
        }

        songInfoHolderView.layoutIfNeeded()
    }

    /**
     Updates the MPNowPlayingInfoCenter (lock screen) with the song info

     - parameter item: The song that has started playing
     */
    func updateNowPlayingInfo(_ item: STMStreamMeta?) {
        let center = MPNowPlayingInfoCenter.default()

        var dict = [String : AnyObject]()
        dict[MPNowPlayingInfoPropertyPlaybackRate] = NSNumber(value: Double(1) as Double)

        if let item = item {
            dict[MPMediaItemPropertyTitle] = item.title as AnyObject?? ?? "" as AnyObject?
            dict[MPMediaItemPropertyArtist] = item.artist as AnyObject?? ?? "" as AnyObject?
            dict[MPMediaItemPropertyAlbumTitle] = item.album as AnyObject?? ?? "" as AnyObject?
            if let image = item.image {
                dict[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: image)
            } else {
                dict[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: UIImage())
            }
        } else {
            dict[MPMediaItemPropertyTitle] = "No Song Playing" as AnyObject?
        }
        center.nowPlayingInfo = dict
    }

    // **********************************************************************
    // **********************************************************************
    // **********************************************************************

    // MARK: TableView Data Source
    override func tableViewCellData(_ tableView: UITableView, section: Int) -> [Any] {
        if tableView == commentsTableView {
            return comments
        }

        return super.tableViewCellData(tableView, section: section)
    }

    override func tableViewCellClass(_ tableView: UITableView, indexPath: IndexPath?) -> KZTableViewCell.Type {
        if tableView == commentsTableView {
            if comments[indexPath?.row ?? 0] is STMTimelineItem {
                return TimelineItemCell.self
            } else {
                return CommentCell.self
            }
        }

        return super.tableViewCellClass(tableView, indexPath: indexPath)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        super.tableView(tableView, didSelectRowAt: indexPath)

        guard tableViewCellData(tableView, section: indexPath.section).count > 0 else {
            return
        }

        if let comment = tableViewCellData(tableView, section: indexPath.section)[indexPath.row] as? STMComment {
            let vc = CommentViewController(comment: comment)
            let nav = NavigationController(rootViewController: vc)
            vc.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "navBarDismissBT"), style: .plain, target: self, action: #selector(self.dismissPopup))
            self.present(nav, animated: true, completion: nil)
        }
    }

    override func tableViewNoDataText(_ tableView: UITableView) -> String {
        if tableView == commentsTableView {
            return "No Comments\n\nBe the first one to comment :)"
        }

        return super.tableViewNoDataText(tableView)
    }

    // MARK: UIViewController Previewing Delegate

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = commentsTableView.indexPathForRow(at: location), let cell = commentsTableView.cellForRow(at: indexPath) else {
            return nil
        }

        var vc: UIViewController?
        previewingContext.sourceRect = cell.frame

        if comments.count > 0 {
            if let comment = comments[indexPath.row] as? STMComment {
                vc = CommentViewController(comment: comment)
            }
        }

        if let vc = vc {
            vc.preferredContentSize = CGSize(width: 0.0, height: 0.0)
        }

        return vc
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        let vc = NavigationController(rootViewController: viewControllerToCommit)
        viewControllerToCommit.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "navBarDismissBT"), style: .plain, target: self, action: #selector(self.dismissPopup))
        self.present(vc, animated: true, completion: nil)
    }

    // MARK: Handle Data
    dynamic override func fetchData() {
        fetchData(false)
    }

    func themeColor() -> UIColor {
        if let stream = stream {
            return stream.color()
        } else {
            return Constants.UI.Color.tint
        }
    }
}

//**********************************************************************
//**********************************************************************
//**********************************************************************

// MARK: Comment Updates
extension PlayerViewController: MessageToolbarDelegate {

    /**
     Called on comment submit

     - parameter text: the text that was posted
     */
    func handlePost(_ text: String) {
        guard text.characters.count > 0 else {
            return
        }

        guard let socket = self.commentSocket else {
            return
        }

        commentBackgroundQueue.async { () -> Void in
            while socket.status != .connected {
                RunLoop.main.run(mode: RunLoopMode.defaultRunLoopMode, before: Date.distantFuture)
            }

            self.didPostComment = true
            var params = [String: AnyObject]()
            params["text"] = text as AnyObject?
            socket.emitWithAck("addComment", params).timingOut(after: 15, callback: { (data) in
                Answers.logCustomEvent(withName: "Comment", customAttributes: [:])
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.Notification.DidPostComment), object: nil)
            })
        }

        view.endEditing(true)
    }

    func messageToolbarPrefillText() -> String {
        return ""
    }

    func didBeginEditing() {
        commentsTableView.scrollToBottom(true)
    }

    func didReciveComment(_ response: AnyObject) {
        if let result = response as? JSON {
            if let comment = STMComment(json: result) {
                comment.stream = self.stream
                let isAtBottom = commentsTableView.indexPathsForVisibleRows?.contains(where: { ($0 as IndexPath).row == (comments.count - 1) })
                let shouldScrollDown = didPostComment || (isAtBottom ?? false)
                comments.append(comment)
                self.streamInfoHolder.comments = comments.count
                didUpdateComments(shouldScrollDown)
            }
        }
    }

    func didReciveUserJoined(_ response: AnyObject) {
        guard let result = response as? JSON else {
            return
        }

        guard let item = STMTimelineItem(json: result) else {
            return
        }

        guard item.user?.id != AppDelegate.del().currentUser?.id else {
            return
        }

        let isAtBottom = commentsTableView.indexPathsForVisibleRows?.contains(where: { ($0 as IndexPath).row == (comments.count - 1) })
        let shouldScrollDown = didPostComment || (isAtBottom ?? false)
        comments.append(item)
        didUpdateComments(shouldScrollDown)
    }

    func didUpdateComments(_ shouldScrollDown: Bool) {
        DispatchQueue.main.async(execute: { () -> Void in
            if self.comments.count > 1 {
                self.commentsTableView.beginUpdates()
                self.commentsTableView.insertRows(at: [IndexPath(row: self.comments.count - 1, section: 0)], with: .fade)
                self.commentsTableView.endUpdates()
                if shouldScrollDown {
                    self.commentsTableView.scrollToBottom(true)
                }
            } else {
                self.commentsTableView.reloadSections(IndexSet(integer: 0), with: .fade)
            }
        })
    }

    func didUpdateThemeColor(_ response: AnyObject) {
        guard let result = response as? JSON else {
            return
        }

        guard let hexString = result["hexString"] as? String else {
            return
        }

        let color = HEX(hexString)
        self.stream?.colorHex = hexString
        UIView.animate(withDuration: 0.5) {
            self.updateThemeColor(color)
        }
    }

    func updateThemeColor(_ color: UIColor) {
        if player?.state == .playing || player?.state == .buffering {
            gradientColorView.backgroundColor = color.withAlphaComponent(0.66)
        } else {
            gradientColorView.backgroundColor = Constants.UI.Color.off.withAlphaComponent(0.66)
        }

        streamTitleLabel.textColor = color

        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
    }

    func fetchMeta() {
        guard let stream = stream else {
            return
        }

        Constants.Network.GET("/stream/\(stream.id)/meta") { (response, error) in
            self.handleResponse(response as AnyObject?, error: error as NSError?, successCompletion: { (result) -> Void in
                if let result = result as? JSON, let meta = STMStreamMeta(json: result) {
                    self.updateCurrentSong(meta)
                } else {
                    self.updateCurrentSong(nil)
                }
            })
        }
    }

    func fetchOnce() {
        guard let stream = stream else {
            return
        }

        Constants.Network.GET("/stream/\(stream.id)/comments", parameters: nil, completionHandler: { (response, error) -> Void in
            self.handleResponse(response as AnyObject?, error: error as NSError?, successCompletion: { (result) -> Void in
                self.comments.removeAll()
                if let result = result as? [JSON] {
                    let comments = [STMComment].from(jsonArray:result)
                    comments?.forEach({
                        $0.stream = self.stream
                        self.comments.insert($0, at: 0)
                    })
                    self.streamInfoHolder.comments = (comments?.count)!
                    self.commentsTableView.reloadData()
                    self.commentsTableView.scrollToBottom(false)
                }
            })
        })

        fetchMeta()
    }

    func fetchData(_ scrollToBottom: Bool) {

    }
}

//**********************************************************************
//**********************************************************************
//**********************************************************************

// MARK: Initialize Stream
extension PlayerViewController: STKAudioPlayerDelegate {

    /**
     Plays the passed in stream

     - parameter stream:   The stream to play
     - parameter callback: Any error or nil if there was none
     */
    func start(_ stream: STMStream, vc: UIViewController, showHUD: Bool = true, callback: ((Bool, String?) -> Void)? = nil) {
        let progressView = M13ProgressViewRing()
        progressView.primaryColor = stream.color()
        progressView.secondaryColor = Constants.UI.Color.disabled
        progressView.indeterminate = true

        func innerStart() {
            hud = M13ProgressHUD(progressView: progressView)
            if let hud = hud, showHUD {
                hud.frame = (AppDelegate.del().window?.bounds)!
                hud.progressViewSize = CGSize(width: 60, height: 60)
                hud.animationPoint = CGPoint(x: UIScreen.main.bounds.size.width / 2, y: UIScreen.main.bounds.size.height / 2)
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
                    callback(false, "You must close out of the stream you are currently hosting before you can listen to a different one")
                }

                return
            }

            if activeVC.stream?.id == stream.id {
                if let vc = AppDelegate.del().topViewController() {
                    return vc.showError("You are already playing this stream")
                }
            }

            let alertVC = UIAlertController(title: "Confirm", message: "Continuing will stop the playback of the current stream", preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: "Continue", style: .default, handler: { (action) in
                activeVC.close(soft: false, completion: {
                    innerStart()
                })
            }))
            alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            AppDelegate.del().topViewController()?.present(alertVC, animated: true, completion: nil)
        } else {
            innerStart()
        }
    }

    func connectToStream(_ vc: UIViewController? = nil, callback: ((Bool, String?) -> Void)? = nil) {
        guard let stream = stream else {
            return
        }

        updateThemeColor(stream.color())

        func proccessError(_ error: String? = nil, callback: ((Bool, String?) -> Void)?) {
            if let hud = self.hud {
                hud.dismiss(true)
            }

            if let callback = callback {
                callback(false, error)
            }
        }

        Constants.Network.GET("/stream/\(stream.id)/startSession", parameters: nil, completionHandler: { (response, error) -> Void in
            (vc ?? self).handleResponse(response as AnyObject?, error: error as NSError?, successCompletion: { (result) -> Void in
                guard let result = result as? [String: AnyObject] else {
                    return proccessError("Invalid response", callback: callback)
                }

                guard let authKey = result["auth"] as? String else {
                    return proccessError("Invalid session", callback: callback)
                }

                guard let user = AppDelegate.del().currentUser else {
                    return proccessError("Invalid session", callback: callback)
                }

                AppDelegate.del().setUpAudioSession(false)

                let streamURL = Constants.Config.apiBaseURL + "/stream/\(stream.id)/playStream/\(user.id)/\(authKey)"

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
                player.appendFrameFilter(withName: "visualizer", block: { (channelsPerFrame, bytesPerFrame, frameCount, ioData) -> Void in
                    if self.visualizerUpdateCount == 2 {
                        let decibels = player.averagePowerInDecibels(forChannel: 0)
                        let level = MeterTable.shared().value(at: decibels)

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
                Answers.logCustomEvent(withName: "Played Stream", customAttributes: [:])

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

        guard let baseURL = URL(string: Constants.Config.apiBaseURL) else {
            return
        }

        let oForcePolling = SocketIOClientOption.forcePolling(true)
        let oAuth = SocketIOClientOption.connectParams(["streamID": stream.id, "userID": user.id, "stmHash": Constants.Config.streamHash])
        let commentHost = SocketIOClientOption.nsp("/comment")
        let commentOptions = SocketIOClientConfiguration(arrayLiteral: oForcePolling, commentHost, oAuth)

        self.commentSocket = SocketIOClient(socketURL: baseURL, config: commentOptions)
        if let socket = self.commentSocket {
            socket.on("connect") { data, ack in
                print("Comment: Socket Connected")
            }

            socket.on("newComment") { data, ack in
                self.didReciveComment(data[0] as AnyObject)
            }

            socket.on("item") { data, ack in
                self.didReciveUserJoined(data[0] as AnyObject)
            }

            socket.on("didUpdateMetadata") { data, ack in
                self.fetchMeta()
            }

            socket.on("didUpdateHex") { data, ack in
                self.didUpdateThemeColor(data[0] as AnyObject)
            }

            socket.connect()
        }
    }

    // MARK: Audio Player Delegate

    func audioPlayer(_ audioPlayer: STKAudioPlayer, stateChanged state: STKAudioPlayerState, previousState: STKAudioPlayerState) {
        let active = state == .playing || state == .buffering
        UIView.animate(withDuration: 0.5, animations: { () -> Void in
            if active {
                self.gradientColorView.backgroundColor = self.stream?.color().withAlphaComponent(0.66)
            } else {
                self.gradientColorView.backgroundColor = Constants.UI.Color.off.withAlphaComponent(0.66)
            }
        })
    }

    func audioPlayer(_ audioPlayer: STKAudioPlayer, didStartPlayingQueueItemId queueItemId: NSObject) {

    }

    func audioPlayer(_ audioPlayer: STKAudioPlayer, unexpectedError errorCode: STKAudioPlayerErrorCode) {

    }

    func audioPlayer(_ audioPlayer: STKAudioPlayer, didFinishBufferingSourceWithQueueItemId queueItemId: NSObject) {

    }

    func audioPlayer(_ audioPlayer: STKAudioPlayer, didFinishPlayingQueueItemId queueItemId: NSObject, with stopReason: STKAudioPlayerStopReason, andProgress progress: Double, andDuration duration: Double) {

    }

}

//**********************************************************************
//**********************************************************************
//**********************************************************************

// MARK: Audio Playback
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
