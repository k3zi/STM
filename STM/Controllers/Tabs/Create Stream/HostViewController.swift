//
//  HostViewController.swift
//  STM
//
//  Created by Kesi Maduka on 1/30/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit
import M13ProgressSuite
import MediaPlayer

struct HostSettings {
	var crossfadeDuration = Float(5.0)
}

//MARK: Variables
class HostViewController: KZViewController {
	var streamType: StreamType?
	var stream: STMStream?
	var socket: SocketIOClient?
	let backgroundQueue = dispatch_queue_create("com.stormedgeapps.streamtome.stream", nil)
	var songs = [Any]()
	var upNextSongs = [Any]()
	let engine = FUXEngine()

	var settings = HostSettings()
	var playbackReachedEnd = true
	var playbackPaused = false

	var statsPacketsReceived = Float(0)

	var audioFile0: EZAudioFile?
	var audioFile1: EZAudioFile?

	let topView = UIView()
	let albumPoster = UIImageView()
	let gradientView = GradientView()
	let gradientColorView = UIView()
	let visualizer = STMVisualizer()

	let songInfoHolderView = UIView()
	var songInfoHolderViewTopPadding: NSLayoutConstraint? = nil
	let songInfoLabel1 = UILabel()
	let songInfoLabel2 = UILabel()
	let songInfoLabel3 = UILabel()

	let switcherControl = UISegmentedControl(items: ["Songs", "Queue", "Comments", "Settings"])
	let switcherControlHolder = UIView()
	let switcherScrollView = UIScrollView()
	let switcherContentView = UIView()

	let songsTableView = UITableView()
	let queueTableView = UITableView()
	let commentsTableView = UITableView()
	let settingsScrollView = UIScrollView()
	let settingsContentView = UIView()

	let searchBar = UISearchBar()
	let searchResults = [Any]()

	let recordSwitch = UISwitch()
	let recordingStatusLabel = UILabel()
	let broadcastingStatusBG = UIView()

	let micVolumeSlider = UISlider()
	let micActiveMusicVolumeSlider = UISlider()
	let micInactiveMusicVolumeSlider = UISlider()
	let micFadeTimeSlider = UISlider()

	let bottomBlurBar = UIToolbar()
	var bottomBlurBarConstraint: NSLayoutConstraint?
	let streamInfoHolder = HostInfoHolderView()

	let micToggleBT = ExtendedButton()
	let micIndicatorView = UIView()
	let micIndicatorGradientView = GradientView()
	var micIndicatorWidthConstraint: NSLayoutConstraint?

	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = RGB(0)

		setupTopView()
		setupSwitcher()
		setupContentView()
		setupToolbar()
		setupSettingsContentView()

		NSTimer.scheduledTimerWithTimeInterval(1.5, target: self, selector: Selector("refresh"), userInfo: nil, repeats: true)
	}

	// MARK: Constraints
	override func setupConstraints() {
		super.setupConstraints()

		// Top View
		topView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero, excludingEdge: .Bottom)
		topView.autoMatchDimension(.Height, toDimension: .Height, ofView: view, withMultiplier: 0.334)

		albumPoster.autoPinEdgesToSuperviewEdges()

		gradientView.autoPinEdgesToSuperviewEdges()
		gradientColorView.autoPinEdgesToSuperviewEdges()

		visualizer.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0))

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
		switcherControlHolder.autoPinEdge(.Top, toEdge: .Bottom, ofView: topView)
		switcherControlHolder.autoPinEdgeToSuperviewEdge(.Left)
		switcherControlHolder.autoPinEdgeToSuperviewEdge(.Right)
		switcherControlHolder.autoSetDimension(.Height, toSize: 44)

		switcherControl.autoAlignAxisToSuperviewAxis(.Horizontal)
		switcherControl.autoPinEdgeToSuperviewEdge(.Left, withInset: 22)
		switcherControl.autoPinEdgeToSuperviewEdge(.Right, withInset: 22)

		// Scroll View
		switcherScrollView.autoPinEdge(.Top, toEdge: .Bottom, ofView: switcherControlHolder)
		switcherScrollView.autoPinEdgeToSuperviewEdge(.Left)
		switcherScrollView.autoPinEdgeToSuperviewEdge(.Right)

		switcherContentView.autoPinEdgesToSuperviewEdges()
		switcherContentView.autoMatchDimension(.Height, toDimension: .Height, ofView: switcherScrollView)

		for view in [songsTableView, queueTableView, commentsTableView, settingsScrollView] {
			view.autoPinEdgeToSuperviewEdge(.Top)
			view.autoMatchDimension(.Width, toDimension: .Width, ofView: switcherScrollView)
			view.autoPinEdgeToSuperviewEdge(.Bottom)
		}

		songsTableView.autoPinEdgeToSuperviewEdge(.Left)
		queueTableView.autoPinEdge(.Left, toEdge: .Right, ofView: songsTableView)
		commentsTableView.autoPinEdge(.Left, toEdge: .Right, ofView: queueTableView)
		settingsScrollView.autoPinEdge(.Left, toEdge: .Right, ofView: commentsTableView)
		settingsScrollView.autoPinEdgeToSuperviewEdge(.Right)

		// Settings Content View
		settingsContentView.autoPinEdgesToSuperviewEdges()
		settingsContentView.autoMatchDimension(.Width, toDimension: .Width, ofView: settingsScrollView)
		settingsContentView.autoMatchDimension(.Height, toDimension: .Height, ofView: settingsScrollView)

		// Settings
		broadcastingStatusBG.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero, excludingEdge: .Bottom)
		recordSwitch.autoPinEdgeToSuperviewEdge(.Top, withInset: 22)
		recordSwitch.autoPinEdgeToSuperviewEdge(.Left, withInset: 22)
		recordSwitch.autoPinEdgeToSuperviewEdge(.Bottom, withInset: 22)

		recordingStatusLabel.autoAlignAxis(.Horizontal, toSameAxisOfView: recordSwitch)
		recordingStatusLabel.autoPinEdge(.Left, toEdge: .Right, ofView: recordSwitch, withOffset: 22)
		recordingStatusLabel.autoPinEdgeToSuperviewEdge(.Right, withInset: 22)
		recordingStatusLabel.autoMatchDimension(.Height, toDimension: .Height, ofView: recordSwitch)

		// Toolbar
		bottomBlurBar.autoSetDimension(.Height, toSize: 88)
		bottomBlurBar.autoPinEdge(.Top, toEdge: .Bottom, ofView: switcherScrollView)
		bottomBlurBar.autoPinEdgeToSuperviewEdge(.Left)
		bottomBlurBar.autoPinEdgeToSuperviewEdge(.Right)
		bottomBlurBarConstraint = bottomBlurBar.autoPinEdgeToSuperviewEdge(.Bottom, withInset: -44)

		streamInfoHolder.autoPinEdgeToSuperviewEdge(.Top, withInset: 14)
		streamInfoHolder.autoAlignAxisToSuperviewAxis(.Vertical)

		micToggleBT.autoPinEdgeToSuperviewEdge(.Top, withInset: 11)
		micToggleBT.autoPinEdgeToSuperviewEdge(.Right, withInset: 11)

		micIndicatorGradientView.autoSetDimension(.Height, toSize: 22)
		micIndicatorGradientView.autoPinEdgeToSuperviewEdge(.Left, withInset: 11)
		micIndicatorGradientView.autoPinEdgeToSuperviewEdge(.Right, withInset: 11)
		micIndicatorGradientView.autoPinEdgeToSuperviewEdge(.Bottom, withInset: 11)

		micIndicatorWidthConstraint = micIndicatorView.autoPinEdgeToSuperviewEdge(.Left, withInset: 0)
		micIndicatorView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero, excludingEdge: .Left)
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

		gradientColorView.backgroundColor = Constants.Color.off.colorWithAlphaComponent(0.66)
		topView.addSubview(gradientColorView)

		topView.addSubview(visualizer)

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
	}

	func setupSwitcher() {
		switcherControlHolder.backgroundColor = RGB(70)
		view.addSubview(switcherControlHolder)

		switcherControl.selectedSegmentIndex = 0
		switcherControl.tintColor = Constants.Color.tint
		switcherControl.setTitleTextAttributes([NSForegroundColorAttributeName: RGB(255)], forState: .Selected)
		switcherControl.addTarget(self, action: Selector("didChangeSegmentIndex"), forControlEvents: .ValueChanged)
		switcherControlHolder.addSubview(switcherControl)

		switcherScrollView.scrollEnabled = false
		switcherScrollView.showsHorizontalScrollIndicator = false
		switcherScrollView.showsVerticalScrollIndicator = false
		view.addSubview(switcherScrollView)
	}

	func setupContentView() {
		switcherContentView.backgroundColor = RGB(255)
		switcherScrollView.addSubview(switcherContentView)

		songsTableView.delegate = self
		songsTableView.dataSource = self
		songsTableView.registerReusableCell(SelectSongCell)
		switcherContentView.addSubview(songsTableView)

		queueTableView.delegate = self
		queueTableView.dataSource = self
		queueTableView.registerReusableCell(UpNextSongCell)
		switcherContentView.addSubview(queueTableView)

		switcherContentView.addSubview(commentsTableView)

		settingsScrollView.addSubview(settingsContentView)
		switcherContentView.addSubview(settingsScrollView)
	}

	func setupSettingsContentView() {
		broadcastingStatusBG.backgroundColor = RGB(220)
		settingsContentView.addSubview(broadcastingStatusBG)

		recordSwitch.tintColor = RGB(255)
		recordSwitch.backgroundColor = RGB(255)
		recordSwitch.layer.cornerRadius = 16.0
		recordSwitch.onTintColor = RGB(232, g: 61, b: 14)
		recordSwitch.addTarget(self, action: Selector("didToggleOnAir"), forControlEvents: .TouchUpInside)
		broadcastingStatusBG.addSubview(recordSwitch)

		recordingStatusLabel.text = "Not Broadcasting"
		recordingStatusLabel.textAlignment = .Center
		recordingStatusLabel.font = UIFont.systemFontOfSize(16)
		recordingStatusLabel.backgroundColor = RGB(255)
		recordingStatusLabel.textColor = recordSwitch.onTintColor
		recordingStatusLabel.layer.cornerRadius = 16.0
		recordingStatusLabel.layer.masksToBounds = true
		recordingStatusLabel.clipsToBounds = true
		broadcastingStatusBG.addSubview(recordingStatusLabel)

		micVolumeSlider.value = 1.0
		micActiveMusicVolumeSlider.value = 0.2
		micInactiveMusicVolumeSlider.value = 1.0

		micFadeTimeSlider.minimumValue = 0.0
		micFadeTimeSlider.maximumValue = 10.0
		micFadeTimeSlider.value = 2.0
	}

	func setupToolbar() {
		bottomBlurBar.layer.masksToBounds = false
		bottomBlurBar.layer.shadowOffset = CGSize(width: 0, height: 2)
		bottomBlurBar.layer.shadowRadius = 8
		bottomBlurBar.layer.shadowOpacity = 0.2
		view.addSubview(bottomBlurBar)

		streamInfoHolder.listeners = 0
		streamInfoHolder.bandwidth = 0
		streamInfoHolder.comments = 0
		bottomBlurBar.addSubview(streamInfoHolder)

		micToggleBT.setImage(UIImage(named: "toolbar_micOff"), forState: .Normal)
		micToggleBT.setImage(UIImage(named: "toolbar_micOn"), forState: .Selected)
		micToggleBT.addTarget(self, action: Selector("toggleMic"), forControlEvents: .TouchUpInside)
		bottomBlurBar.addSubview(micToggleBT)

		micIndicatorGradientView.gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
		micIndicatorGradientView.gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
		micIndicatorGradientView.gradientLayer.colors = [RGB(0, g: 255, b: 0).CGColor, RGB(255, g: 255, b: 0).CGColor, RGB(255, g: 0, b: 0).CGColor]
		micIndicatorGradientView.gradientLayer.locations = [NSNumber(float: 0.0), NSNumber(float: 0.7), NSNumber(float: 1.0)]
		micIndicatorGradientView.layer.cornerRadius = 10.0
		micIndicatorGradientView.layer.masksToBounds = true
		bottomBlurBar.addSubview(micIndicatorGradientView)

		micIndicatorView.backgroundColor = RGB(255, a: 200)
		micIndicatorGradientView.addSubview(micIndicatorView)
	}

	// **********************************************************************
	// **********************************************************************
	// **********************************************************************

	// MARK: View Changes/Updates

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

	/**
	 Toggles the output of the mic to the stream
	 */
	func toggleMic() {
		micToggleBT.selected = !micToggleBT.selected

		// Music Bus = 0, Mic Bus = 1

		let bus0Volume = EZOutput.sharedOutput().mixerNode.volumeForBus(0)
		let bus1Volume = EZOutput.sharedOutput().mixerNode.volumeForBus(1)
		let bus0ToVolume = micToggleBT.selected ? micActiveMusicVolumeSlider.value : micInactiveMusicVolumeSlider.value
		let bus1ToVolume = micToggleBT.selected ? micVolumeSlider.value : 0.0

		engine + FUXTween.Tween(micFadeTimeSlider.value, fromToValueFunc(from: bus0Volume, to: bus0ToVolume, valueFunc: { (value) -> () in
			EZOutput.sharedOutput().mixerNode.setVolume(value, forBus: 0)
			}))

		engine + FUXTween.Tween(micFadeTimeSlider.value, fromToValueFunc(from: bus1Volume, to: bus1ToVolume, valueFunc: { (value) -> () in
			EZOutput.sharedOutput().mixerNode.setVolume(value, forBus: 1)
			}))

		toggleToolbar(micToggleBT.selected)
	}

	/**
	 Called when UISwitch is toggled for recording
	 */
	func didToggleOnAir() {
		UIView.transitionWithView(recordingStatusLabel, duration: 0.5, options: (isOnAir() ? .TransitionFlipFromBottom : .TransitionFlipFromTop), animations: { () -> Void in
			self.refreshRecordingLabel()
			}, completion: nil)
	}

	/**
	 Changes UIScrollView offset when UISegmentControl changes index
	 */
	func didChangeSegmentIndex() {
		UIView.animateWithDuration(0.4) { () -> Void in
			self.switcherScrollView.contentOffset = CGPoint(x: CGFloat(self.switcherControl.selectedSegmentIndex) * self.switcherScrollView.frame.width, y: 0)
		}
	}

	/**
	 Refreshes various times & numbers
	 */
	func refresh() {
		streamInfoHolder.bandwidth = statsPacketsReceived
	}

	func refreshRecordingLabel() {
		if isOnAir() {
			if playbackPaused {
				recordingStatusLabel.text = "Live: Playback Paused"
			} else {
				recordingStatusLabel.text = "Live"
			}

			recordingStatusLabel.textColor = RGB(255)
			recordingStatusLabel.backgroundColor = recordSwitch.onTintColor
			gradientColorView.backgroundColor = Constants.Color.tint.colorWithAlphaComponent(0.66)
		} else {
			recordingStatusLabel.text = "Not Broadcasting"
			recordingStatusLabel.textColor = recordSwitch.onTintColor
			recordingStatusLabel.backgroundColor = RGB(255)
			gradientColorView.backgroundColor = Constants.Color.off.colorWithAlphaComponent(0.66)
		}
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
            songInfoHolderViewTopPadding?.constant = -5
		} else {
			songInfoLabel1.text = "No Song Playing"
			songInfoLabel2.text = nil
			songInfoLabel3.text = nil
            songInfoHolderViewTopPadding?.constant = 5
		}
	}

	/**
	 Updates the MPNowPlayingInfoCenter (lock screen) with the song info

	 - parameter item: The song that has started playing
	 */
	func updateNowPlayingInfo(item: KZPlayerItem?) {
		let center = MPNowPlayingInfoCenter.defaultCenter()

		var dict = [String : AnyObject]()
		dict[MPNowPlayingInfoPropertyPlaybackRate] = NSNumber(double: Double(playbackPaused))

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
		if tableView == songsTableView {
			return songs
		} else if tableView == queueTableView {
			return upNextSongs
		}

		return super.tableViewCellData(tableView, section: section)
	}

	override func tableViewCellClass(tableView: UITableView, indexPath: NSIndexPath?) -> KZTableViewCell.Type {
		if tableView == songsTableView {
			return SelectSongCell.self
		} else if tableView == queueTableView {
			return UpNextSongCell.self
		}

		return super.tableViewCellClass(tableView, indexPath: indexPath)
	}

	override func tableViewNoDataText(tableView: UITableView) -> String {
		if tableView == songsTableView {
			return "No Songs in Library"
		} else if tableView == queueTableView {
			return "No Songs in Queue"
		}

		return super.tableViewNoDataText(tableView)
	}

	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)

		if let cell = cell as? SelectSongCell {
			cell.defaultColor = RGB(227)
			cell.setSwipeGestureWith(SelectSongCell.viewWithImageName("selectCell_playBT"), color: RGB(85, g: 213, b: 80), mode: .Switch, state: .State4, completionBlock: { (cell, state, mode) -> Void in
				if let item = self.tableViewCellData(tableView, section: indexPath.section)[indexPath.row] as? KZPlayerItem {
					self.playSong(item)
				}
			})

			cell.setSwipeGestureWith(SelectSongCell.viewWithImageName("selectCell_addBT"), color: RGB(254, g: 217, b: 56), mode: .Switch, state: .State3, completionBlock: { (cell, state, mode) -> Void in
				if let item = self.tableViewCellData(tableView, section: indexPath.section)[indexPath.row] as? KZPlayerItem {
					self.addToUpNext(item)
				}
			})
		}

		if let cell = cell as? UpNextSongCell {
			cell.defaultColor = RGB(227)
			cell.setSwipeGestureWith(SelectSongCell.viewWithImageName("selectCell_removeBT"), color: RGB(232, g: 61, b: 14), mode: .Exit, state: .State3, completionBlock: { (cell, state, mode) -> Void in
				if let indexPath = tableView.indexPathForCell(cell) {
					self.removeFromUpNext(indexPath)
				}
			})

			cell.setSwipeGestureWith(SelectSongCell.viewWithImageName("selectCell_addBT"), color: RGB(254, g: 217, b: 56), mode: .Switch, state: .State4, completionBlock: { (cell, state, mode) -> Void in
				if let indexPath = tableView.indexPathForCell(cell) {
					if let item = self.tableViewCellData(tableView, section: indexPath.section)[indexPath.row] as? KZPlayerItem {
						self.addToUpNext(item)
					}
				}
			})
		}

		return cell
	}
}

//**********************************************************************
//**********************************************************************
//**********************************************************************

//MARK: Initialize Stream
extension HostViewController {
	func start(type: StreamType, name: String, passcode: String, description: String, callback: (Bool, String?) -> Void) {
		let progressView = M13ProgressViewRing()
		progressView.primaryColor = Constants.Color.tint
		progressView.secondaryColor = Constants.Color.disabled
		progressView.indeterminate = true

		let hud = M13ProgressHUD(progressView: progressView)
		if let hud = hud {
			hud.frame = (AppDelegate.del().window?.bounds)!
			hud.progressViewSize = CGSize(width: 60, height: 60)
			hud.animationPoint = CGPoint(x: UIScreen.mainScreen().bounds.size.width / 2, y: UIScreen.mainScreen().bounds.size.height / 2)
			hud.status = "Setting Up Stream"
			hud.applyBlurToBackground = true
			hud.maskType = M13ProgressHUDMaskTypeIOS7Blur
			AppDelegate.del().window?.addSubview(hud)
			hud.show(true)
		}

		if type == .Global {
			Constants.Network.POST("/createStream", parameters: ["name": name, "passcode": passcode, "description": description], completionHandler: { (response, error) -> Void in
				hud.hide(true)
				self.handleResponse(response, error: error, successCompletion: { (result) -> Void in
					if let result = result as? JSON {
						if let stream = STMStream(json: result) {
							self.stream = stream
							callback(true, nil)
							self.setUpAudioSession()
							self.connectGlobalStream()
							self.loadLibrary()
						}
					}
					}, errorCompletion: { (error) -> Void in
					self.dismiss()
					callback(false, error)
				})
			})
		}
	}

	func start(stream: STMStream, callback: (Bool, String?) -> Void) {
		let progressView = M13ProgressViewRing()
		progressView.primaryColor = Constants.Color.tint
		progressView.secondaryColor = Constants.Color.disabled
		progressView.indeterminate = true

		let hud = M13ProgressHUD(progressView: progressView)
		if let hud = hud {
			hud.frame = (AppDelegate.del().window?.bounds)!
			hud.progressViewSize = CGSize(width: 60, height: 60)
			hud.animationPoint = CGPoint(x: UIScreen.mainScreen().bounds.size.width / 2, y: UIScreen.mainScreen().bounds.size.height / 2)
			hud.status = "Starting Stream"
			hud.applyBlurToBackground = true
			hud.maskType = M13ProgressHUDMaskTypeIOS7Blur
			AppDelegate.del().window?.addSubview(hud)
			hud.show(true)
		}

		Constants.Network.POST("/continueStream/" + String(stream.id ?? 0), parameters: nil, completionHandler: { (response, error) -> Void in
			hud.hide(true)
			self.handleResponse(response, error: error, successCompletion: { (result) -> Void in
				if let result = result as? JSON {
					if let stream = STMStream(json: result) {
						self.stream = stream

						self.setUpAudioSession()
						self.connectGlobalStream()
						self.loadLibrary()
						callback(true, nil)
					}
				}
				}, errorCompletion: { (error) -> Void in
				self.dismiss()
				callback(false, error)
			})
		})
	}
}

//**********************************************************************
//**********************************************************************
//**********************************************************************

//MARK: Audio Data
extension HostViewController: EZOutputDataSource {
	func connectGlobalStream() {
		guard let user = AppDelegate.del().currentUser else {
			return
		}

		guard let stream = self.stream else {
			return
		}

		if let userID = user.id {
			if let streamID = stream.id {
				if let securityHash = stream.securityHash {
					if let baseURL = NSURL(string: Constants.baseURL) {
						let oForcePolling = SocketIOClientOption.ForcePolling(true)
						let oHost = SocketIOClientOption.Nsp("/host")
						let oAuth = SocketIOClientOption.ConnectParams(["streamID": streamID, "securityHash": securityHash, "userID": userID, "stmHash": Constants.Config.streamHash])
						let options = [oForcePolling, oHost, oAuth] as Set<SocketIOClientOption>
						self.socket = SocketIOClient(socketURL: baseURL, options: options)
						if let socket = self.socket {
							socket.on("connect") { data, ack in
								print("Stream: Socket Connected")
							}

							socket.connect()
						}
					}
				}
			}
		}
	}

	func loadLibrary() {
		EZOutput.sharedOutput().aacEncode = true

		self.songs.removeAll()
		let predicate1 = MPMediaPropertyPredicate(value: MPMediaType.AnyAudio.rawValue, forProperty: MPMediaItemPropertyMediaType)
		let predicate12 = MPMediaPropertyPredicate(value: 0, forProperty: MPMediaItemPropertyIsCloudItem)
		let query = MPMediaQuery(filterPredicates: [predicate1, predicate12])
		if let items = query.items {
			for item in items {
				let newItem = KZPlayerItem(item: item)
				if newItem.assetURL.characters.count > 0 {
					self.songs.append(newItem)
				}
			}
		}

		EZOutput.sharedOutput().outputDataSource = self
		EZOutput.sharedOutput().mixerNode.setVolume(0.0, forBus: 1)
		EZOutput.sharedOutput().startPlayback()
		EZOutput.sharedOutput().inputMonitoring = true
	}

	/**
	 Start the AVAudioSession and add the remote commands
	 */
	func setUpAudioSession() {
		do {
			try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(0.04)
			try AVAudioSession.sharedInstance().setPreferredSampleRate(44100)
			try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord, withOptions: .DefaultToSpeaker)
			try AVAudioSession.sharedInstance().setActive(true)
		} catch {
			print("Error starting audio sesssion")
		}

		MPRemoteCommandCenter.sharedCommandCenter().playCommand.addTarget(self, action: Selector("play"))
		MPRemoteCommandCenter.sharedCommandCenter().pauseCommand.addTarget(self, action: Selector("pause"))
		MPRemoteCommandCenter.sharedCommandCenter().nextTrackCommand.addTarget(self, action: Selector("next"))

		MPRemoteCommandCenter.sharedCommandCenter().playCommand.enabled = true
		MPRemoteCommandCenter.sharedCommandCenter().pauseCommand.enabled = true
		MPRemoteCommandCenter.sharedCommandCenter().nextTrackCommand.enabled = true
		MPRemoteCommandCenter.sharedCommandCenter().previousTrackCommand.enabled = false
	}

	func output(output: EZOutput!, shouldFillAudioBufferList audioBufferList: UnsafeMutablePointer<AudioBufferList>, withNumberOfFrames frames: UInt32) {
		if !playbackPaused {
			if let audioFile0 = audioFile0 {
				var bufferSize = UInt32()
				var eof = ObjCBool(false)
				audioFile0.readFrames(frames, audioBufferList: audioBufferList, bufferSize: &bufferSize, eof: &eof)
				if eof && !playbackReachedEnd && audioFile1 == nil {
					self.audioFile0 = nil
					self.next()
				} else if upNextSongs.count > 0 && audioFile1 == nil && (audioFile0.totalDuration() - audioFile0.duration()) < settings.crossfadeDuration {
					self.next()
				}
			} else {
				memset(audioBufferList.memory.mBuffers.mData, 0, Int(audioBufferList.memory.mBuffers.mDataByteSize))
			}
		}
	}

	func output(output: EZOutput!, shouldFillAudioBufferList2 audioBufferList: UnsafeMutablePointer<AudioBufferList>, withNumberOfFrames frames: UInt32) {
		if !playbackPaused {
			if let audioFile1 = audioFile1 {
				var bufferSize = UInt32()
				var eof = ObjCBool(false)
				audioFile1.readFrames(frames, audioBufferList: audioBufferList, bufferSize: &bufferSize, eof: &eof)
				if eof && !playbackReachedEnd && audioFile0 == nil {
					self.audioFile1 = nil
					self.next()
				} else if upNextSongs.count > 0 && audioFile0 == nil && (audioFile1.totalDuration() - audioFile1.duration()) < settings.crossfadeDuration {
					self.next()
				}
			} else {
				memset(audioBufferList.memory.mBuffers.mData, 0, Int(audioBufferList.memory.mBuffers.mDataByteSize))
			}
		}
	}

	func playedData(buffer: NSData!, frames: Int32) {
		let data = NSData(data: buffer)
		if isOnAir() {
			dispatch_async(backgroundQueue) { () -> Void in
				if let socket = self.socket {
					if socket.status == .Connected {
						socket.emitWithAck("dataForStream", ["data": data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions())])(timeoutAfter: 0) { data in
							if let response = data[0] as? [String: AnyObject] {
								if let bytes = response["bytes"] as? Float {
									self.statsPacketsReceived += bytes
								}
							}
						}
					}
				}
			}
		}
	}

	func updateMicLevel(level: Float) {
		if let con = micIndicatorWidthConstraint {
			con.constant = micIndicatorGradientView.frame.width * CGFloat(level)
			micIndicatorView.layoutIfNeeded()
		}
	}

	func heightForVisualizer() -> CGFloat {
		return visualizer.frame.size.height
	}

	func setBarHeight(barIndex: Int32, height: CGFloat) {
		self.visualizer.setBarHeight(Int(barIndex), height: height)
	}
}

//**********************************************************************
//**********************************************************************
//**********************************************************************

//MARK: Audio Playback
extension HostViewController: EZAudioFileDelegate {
	func play() {
	}

	func pause() {
	}

	func isOnAir() -> Bool {
		return recordSwitch.on
	}

	func next() {
		var didPlay = false

		while true {
			if let item = popUpNext() {
				if self.playSong(item) {
					didPlay = true
					break
				}
			} else {
				break
			}
		}

		if !didPlay && !playbackReachedEnd {
			dispatch_async(dispatch_get_main_queue(), { () -> Void in
				self.didReachEndOfQueue()
			})
			playbackReachedEnd = true
			audioFile0 = nil
			audioFile1 = nil
		}
	}

	func playSong(song: KZPlayerItem) -> Bool {
		let assetURL = song.fileURL()
		if EZOutput.sharedOutput().activePlayer == 1 {
			audioFile0 = EZAudioFile(URL: assetURL, andDelegate: self)
			EZOutput.sharedOutput().setActivePlayer(0, withCrossfadeDuration: settings.crossfadeDuration)
		} else {
			audioFile1 = EZAudioFile(URL: assetURL, andDelegate: self)
			EZOutput.sharedOutput().setActivePlayer(1, withCrossfadeDuration: settings.crossfadeDuration)
		}

		dispatch_async(dispatch_get_main_queue(), { () -> Void in
			self.updateCurrentSong(song)
		})
		playbackReachedEnd = false
		return true
	}

	func finishedCrossfade() {
		if EZOutput.sharedOutput().activePlayer == 0 {
			audioFile1 = nil
		} else {
			audioFile0 = nil
		}
	}

	func addToUpNext(item: KZPlayerItem) {
		if playbackReachedEnd {
			playSong(item)
		} else {
			upNextSongs.append(item)
			queueTableView.reloadData()
		}
	}

	func removeFromUpNext(indexPath: NSIndexPath) {
		upNextSongs.removeAtIndex(indexPath.row)
		updateUpNext()
	}

	func popUpNext() -> KZPlayerItem? {

		var x: KZPlayerItem?
		if upNextSongs.count > 0 {
			if let item = upNextSongs.first as? KZPlayerItem {
				x = item
				upNextSongs.removeAtIndex(0)
				updateUpNext()
			}
		}

		return x
	}

	func updateUpNext() {
		dispatch_async(dispatch_get_main_queue()) { () -> Void in
			self.queueTableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Fade)
		}
	}

	func didReachEndOfQueue() {
		AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
		updateCurrentSong(nil)
	}
}
