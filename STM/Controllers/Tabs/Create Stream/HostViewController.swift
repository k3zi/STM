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
class HostViewController: KZViewController, UISearchBarDelegate {
	var streamType: StreamType?
	var stream: STMStream?

	var socket: SocketIOClient?
    var commentSocket: SocketIOClient?
	let backgroundQueue = dispatch_queue_create("com.stormedgeapps.streamtome.stream", nil)
    let commentBackgroundQueue = dispatch_queue_create("com.stormedgeapps.streamtome.comment", nil)

	var songs = [Any]()
	var upNextSongs = [Any]()
	let engine = FUXEngine()
	var audiobusController = AppDelegate.del().audiobusController
	let receiverPort = ABReceiverPort(name: "STM Boroadcast", title: "STM Boroadcast Input")

	var settings = HostSettings()
	var playbackReachedEnd = true
	var playbackPaused = false

	var statsPacketsReceived = Float(0)

	var audioFile0: EZAudioFile?
	var audioFile1: EZAudioFile?

	var hud: M13ProgressHUD?

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
	var searchResults: [Any]?

	let commentContentView = UIView()
	let commentToolbar = MessageToolbarView()
    var comments = [Any]()
    var didPostComment = false

	let settingsHeaderStatus = UILabel.styledForSettingsHeader("STATUS")
	let recordSwitch = UISwitch()
	let recordingStatusLabel = UILabel()
	let broadcastingStatusBG = UIView()

	let settingsHeaderPlayback = UILabel.styledForSettingsHeader("PLAYBACK")

	let settingsHeaderMicrophone = UILabel.styledForSettingsHeader("MICROPHONE")
	var micVolumeSettingView = UIView()
	let micVolumeSlider = UISlider()
	var micActiveMusicVolumeSettingView = UIView()
	let micActiveMusicVolumeSlider = UISlider()
	var musicVolumeSettingView = UIView()
	let musicVolumeSlider = UISlider()
	var micFadeTimeSettingView = UIView()
	let micFadeTimeSlider = UISlider()

	let bottomBlurBar = UIToolbar()
	var bottomBlurBarConstraint: NSLayoutConstraint?
	let streamInfoHolder = HostInfoHolderView()

	let micToggleBT = ExtendedButton()
	let micIndicatorView = UIView()
	let micIndicatorGradientView = GradientView()
	var micIndicatorWidthConstraint: NSLayoutConstraint?

	// Keyboard Adjustment
	var keyboardVisible = CGFloat(0)
	var commentFieldKeyboardConstraint: NSLayoutConstraint?

	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = RGB(0)

		setupTopView()
		setupSwitcher()
		setupContentView()
		setupToolbar()
		setupSettingsContentView()

		self.setKeyboardWillShowAnimationBlock { (keyboardFrame) -> Void in
			if self.keyboardVisible == 0 {
				self.commentFieldKeyboardConstraint?.constant = -keyboardFrame.size.height + 44
			}
			self.view.layoutIfNeeded()
			self.keyboardVisible = keyboardFrame.size.height
		}

		self.setKeyboardWillHideAnimationBlock { (keyboardFrame) -> Void in
			if self.keyboardVisible != 0 {
				self.commentFieldKeyboardConstraint?.constant = 0
			}
			self.view.layoutIfNeeded()
			self.keyboardVisible = 0
		}

        fetchOnce()
		NSTimer.scheduledTimerWithTimeInterval(1.5, target: self, selector: Selector("refresh"), userInfo: nil, repeats: true)
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		if let hud = hud {
			hud.dismiss(true)
		}
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

		for view in [songsTableView, queueTableView, commentContentView, settingsScrollView] {
			view.autoPinEdgeToSuperviewEdge(.Top)
			view.autoMatchDimension(.Width, toDimension: .Width, ofView: switcherScrollView)
			view.autoPinEdgeToSuperviewEdge(.Bottom)
		}

		songsTableView.autoPinEdgeToSuperviewEdge(.Left)
		queueTableView.autoPinEdge(.Left, toEdge: .Right, ofView: songsTableView)
		commentContentView.autoPinEdge(.Left, toEdge: .Right, ofView: queueTableView)
		settingsScrollView.autoPinEdge(.Left, toEdge: .Right, ofView: commentContentView)
		settingsScrollView.autoPinEdgeToSuperviewEdge(.Right)

		// Comments
		commentsTableView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero, excludingEdge: .Bottom)

		commentToolbar.autoPinEdge(.Top, toEdge: .Bottom, ofView: commentsTableView)
		commentToolbar.autoPinEdgeToSuperviewEdge(.Left)
		commentToolbar.autoPinEdgeToSuperviewEdge(.Right)
		commentFieldKeyboardConstraint = commentToolbar.autoPinEdgeToSuperviewEdge(.Bottom)

		// Settings: Content View
		settingsContentView.autoPinEdgesToSuperviewEdges()
		settingsContentView.autoMatchDimension(.Width, toDimension: .Width, ofView: settingsScrollView)

		// Settings: Status
		settingsHeaderStatus.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero, excludingEdge: .Bottom)

		broadcastingStatusBG.autoPinEdge(.Top, toEdge: .Bottom, ofView: settingsHeaderStatus)
		broadcastingStatusBG.autoPinEdgeToSuperviewEdge(.Left)
		broadcastingStatusBG.autoPinEdgeToSuperviewEdge(.Right)

		recordSwitch.autoPinEdgeToSuperviewEdge(.Top, withInset: 22)
		recordSwitch.autoPinEdgeToSuperviewEdge(.Left, withInset: 22)
		recordSwitch.autoPinEdgeToSuperviewEdge(.Bottom, withInset: 22)

		recordingStatusLabel.autoAlignAxis(.Horizontal, toSameAxisOfView: recordSwitch)
		recordingStatusLabel.autoPinEdge(.Left, toEdge: .Right, ofView: recordSwitch, withOffset: 22)
		recordingStatusLabel.autoPinEdgeToSuperviewEdge(.Right, withInset: 22)
		recordingStatusLabel.autoMatchDimension(.Height, toDimension: .Height, ofView: recordSwitch)

		// Settings: Playback
		settingsHeaderPlayback.autoPinEdge(.Top, toEdge: .Bottom, ofView: broadcastingStatusBG)
		settingsHeaderPlayback.autoPinEdgeToSuperviewEdge(.Left)
		settingsHeaderPlayback.autoPinEdgeToSuperviewEdge(.Right)

		musicVolumeSettingView.autoPinEdge(.Top, toEdge: .Bottom, ofView: settingsHeaderPlayback)
		musicVolumeSettingView.autoPinEdgeToSuperviewEdge(.Left)
		musicVolumeSettingView.autoPinEdgeToSuperviewEdge(.Right)

		// Settings: Microphone
		settingsHeaderMicrophone.autoPinEdge(.Top, toEdge: .Bottom, ofView: musicVolumeSettingView)
		settingsHeaderMicrophone.autoPinEdgeToSuperviewEdge(.Left)
		settingsHeaderMicrophone.autoPinEdgeToSuperviewEdge(.Right)

		micVolumeSettingView.autoPinEdge(.Top, toEdge: .Bottom, ofView: settingsHeaderMicrophone)
		micVolumeSettingView.autoPinEdgeToSuperviewEdge(.Left)
		micVolumeSettingView.autoPinEdgeToSuperviewEdge(.Right)

		micActiveMusicVolumeSettingView.autoPinEdgeToSuperviewEdge(.Left)
		micActiveMusicVolumeSettingView.autoPinEdgeToSuperviewEdge(.Right)

		micFadeTimeSettingView.autoPinEdgeToSuperviewEdge(.Left)
		micFadeTimeSettingView.autoPinEdgeToSuperviewEdge(.Right)
		micFadeTimeSettingView.autoPinEdgeToSuperviewEdge(.Bottom, withInset: 0, relation: .GreaterThanOrEqual)

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

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()

		self.switcherScrollView.contentOffset = CGPoint(x: CGFloat(self.switcherControl.selectedSegmentIndex) * self.switcherScrollView.frame.width, y: 0)
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

        commentsTableView.delegate = self
        commentsTableView.dataSource = self
        commentsTableView.registerReusableCell(CommentCell)
		switcherContentView.addSubview(commentContentView)
		commentContentView.addSubview(commentsTableView)

		commentToolbar.delegate = self
		commentContentView.addSubview(commentToolbar)

		settingsScrollView.addSubview(settingsContentView)
		switcherContentView.addSubview(settingsScrollView)
	}

	func setupSettingsContentView() {
		// ***********STATUS**********\\
		settingsContentView.addSubview(settingsHeaderStatus)

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

		// ***********PLAYBACK**********\\
		settingsContentView.addSubview(settingsHeaderPlayback)

		musicVolumeSlider.value = 1.0
		let musicVolumeSettingView = SettingJoinedView(text: NSLocalizedString("Settings_HostMusicVolume", comment: "Music Volume"), detailText: NSLocalizedString("Settings_HostMusicVolumeDescription", comment: ""), control: musicVolumeSlider)
		self.musicVolumeSettingView = musicVolumeSettingView
		settingsContentView.addSubview(musicVolumeSettingView)

		// ***********MICROPHONE**********\\
		settingsContentView.addSubview(settingsHeaderMicrophone)

		micVolumeSlider.value = 1.0
		let micVolumeSettingView = SettingJoinedView(text: NSLocalizedString("Settings_HostMicrophoneVolume", comment: "Microphone Volume"), detailText: NSLocalizedString("Settings_HostMicrophoneVolumeDescription", comment: ""), control: micVolumeSlider)
		self.micVolumeSettingView = micVolumeSettingView
		settingsContentView.addSubview(micVolumeSettingView)

		micActiveMusicVolumeSlider.value = 0.2
		let micActiveMusicVolumeSettingView = SettingJoinedView(text: NSLocalizedString("Settings_HostMusicVolumeWhenMicActive", comment: "Music Volume When Mic Active"), detailText: NSLocalizedString("Settings_HostMusicVolumeWhenMicActiveDescription", comment: ""), control: micActiveMusicVolumeSlider)
		self.micActiveMusicVolumeSettingView = micActiveMusicVolumeSettingView
		settingsContentView.addSubview(micActiveMusicVolumeSettingView)
		micActiveMusicVolumeSettingView.setPrevChain(micVolumeSettingView)

		micFadeTimeSlider.minimumValue = 0.0
		micFadeTimeSlider.maximumValue = 10.0
		micFadeTimeSlider.value = 2.0
		let micFadeTimeSettingView = SettingJoinedView(text: NSLocalizedString("Settings_HostMicFadeTime", comment: "Microphone Fade Time"), detailText: NSLocalizedString("Settings_HostMicFadeTimeDescription", comment: ""), control: micFadeTimeSlider)
		self.micFadeTimeSettingView = micFadeTimeSettingView
		settingsContentView.addSubview(micFadeTimeSettingView)
		micFadeTimeSettingView.setPrevChain(micActiveMusicVolumeSettingView)
	}

	func setupToolbar() {
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

		micIndicatorView.backgroundColor = RGB(255, a: 0.78)
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
		let bus0ToVolume = micToggleBT.selected ? micActiveMusicVolumeSlider.value : musicVolumeSlider.value
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

		view.endEditing(true)
	}

	/**
	 Refreshes various times & numbers
	 */
	func refresh() {
		streamInfoHolder.bandwidth = statsPacketsReceived
        streamInfoHolder.comments = comments.count
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
		} else {
			songInfoLabel1.text = "No Song Playing"
			songInfoLabel2.text = nil
			songInfoLabel3.text = nil
		}

		if songInfoLabel2.text?.characters.count == 0 && songInfoLabel3.text?.characters.count == 0 {
			songInfoHolderViewTopPadding?.constant = 5
		} else if songInfoLabel2.text?.characters.count != 0 && songInfoLabel3.text?.characters.count != 0 {
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
			return searchResults ?? songs
		} else if tableView == queueTableView {
			return upNextSongs
		}
        } else if tableView == commentsTableView {
            return comments
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
			return searchResults != nil ? "No Results" : "No Songs in Library"
		} else if tableView == queueTableView {
			return "No Songs in Queue"
		}
        } else if tableView == commentsTableView {
            return "No Comments\n\nBe the first one to comment :)"
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

	override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		if tableView == songsTableView {
			searchBar.delegate = self
			searchBar.frame.size.height = 44
			searchBar.frame.size.width = tableView.frame.width
			searchBar.keyboardDistanceFromTextField = 0
			return searchBar
		}

		return super.tableView(tableView, viewForHeaderInSection: section)
	}

	override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		if tableView == songsTableView {
			return 44
		}

		return super.tableView(tableView, heightForHeaderInSection: section)
	}

	// MARK: UISearchBar Delegate
	func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
		searchBar.setShowsCancelButton(true, animated: true)
	}

	func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
		searchResults = [Any]()
		songsTableView.reloadData()

		searchResults = songs.filter({ (song) -> Bool in
			if let song = song as? KZPlayerItem {
				return song.aggregateText().containsString(searchText)
			}

			return false
		})

		songsTableView.reloadData()
	}

	func searchBarCancelButtonClicked(searchBar: UISearchBar) {
		searchResults = nil
		searchBar.text = ""
		searchBar.resignFirstResponder()
		searchBar.setShowsCancelButton(false, animated: true)
		songsTableView.reloadData()
	}

	func searchBarSearchButtonClicked(searchBar: UISearchBar) {
		searchBar.resignFirstResponder()
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
extension HostViewController: MessageToolbarDelegate {

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
        }
    }

    func fetchOnce() {
        guard let stream = stream else {
            return
        }

        guard let streamID = stream.id else {
            return
        }

        Constants.Network.GET("/stream/" + String(streamID) + "/comments", parameters: nil, completionHandler: { (response, error) -> Void in
            self.handleResponse(response, error: error, successCompletion: { (result) -> Void in
                self.comments.removeAll()
                if let result = result as? [JSON] {
                    let comments = [STMComment].fromJSONArray(result)
                    comments.forEach({ self.comments.insert($0, atIndex: 0) })
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
extension HostViewController {

    /**
     Creates a stream with the given attributes

     - parameter type:        Wether the user is doing a global or local stream
     - parameter name:        The name the user picked for the stream
     - parameter passcode:    The associated passcode the user typed in
     - parameter description: The description the user gave to the stream
     - parameter callback:    Any error or nil if there was none
     */
	func start(type: StreamType, name: String, passcode: String, description: String, callback: (Bool, String?) -> Void) {
		let progressView = M13ProgressViewRing()
		progressView.primaryColor = Constants.Color.tint
		progressView.secondaryColor = Constants.Color.disabled
		progressView.indeterminate = true

		hud = M13ProgressHUD(progressView: progressView)
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
				self.handleResponse(response, error: error, successCompletion: { (result) -> Void in
					if let result = result as? JSON {
						if let stream = STMStream(json: result) {
							self.stream = stream
							callback(true, nil)
							self.setUpAudioSession()
							self.connectGlobalStream()
							self.loadLibrary()

							Answers.logCustomEventWithName("Created Stream", customAttributes: [:])
						}
					}
					}, errorCompletion: { (error) -> Void in
					if let hud = self.hud {
						hud.dismiss(true)
					}
					self.dismiss()
					callback(false, error)
				})
			})
		}
	}

    /**
     Continues an existing stream

     - parameter stream:   The stream to continue
     - parameter callback: Any error or nil if there was none
     */
	func start(stream: STMStream, callback: (Bool, String?) -> Void) {
		let progressView = M13ProgressViewRing()
		progressView.primaryColor = Constants.Color.tint
		progressView.secondaryColor = Constants.Color.disabled
		progressView.indeterminate = true

		hud = M13ProgressHUD(progressView: progressView)
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
			self.handleResponse(response, error: error, successCompletion: { (result) -> Void in
				if let result = result as? JSON {
					if let stream = STMStream(json: result) {
						self.stream = stream

						self.setUpAudioSession()
						self.connectGlobalStream()
						self.loadLibrary()
						callback(true, nil)
						Answers.logCustomEventWithName("Continued Stream", customAttributes: [:])
					}
				}
				}, errorCompletion: { (error) -> Void in
				if let hud = self.hud {
					hud.dismiss(true)
				}
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

    /**
     Connects to the Output/Comment Socket.IO
     */
	func connectGlobalStream() {
		guard let user = AppDelegate.del().currentUser else {
			return
		}

		guard let stream = self.stream else {
			return
		}

		guard let userID = user.id else {
            return
        }

        guard let streamID = stream.id else {
            return
        }

        guard let securityHash = stream.securityHash else {
            return
        }

        guard let baseURL = NSURL(string: Constants.baseURL) else {
            return
        }

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

        let commentHost = SocketIOClientOption.Nsp("/comment")
        let commentOptions = [oForcePolling, commentHost, oAuth] as Set<SocketIOClientOption>
        self.commentSocket = SocketIOClient(socketURL: baseURL, options: commentOptions)
        if let socket = self.commentSocket {
            socket.on("connect") { data, ack in
                print("Comment Socket Connected")
            }

            socket.on("newComment") { data, ack in
                self.didReciveComment(data[0])
            }

            socket.connect()
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

		let senderPort = ABSenderPort(name: "STM V+M", title: "Stream To Me: Voice + Music", audioComponentDescription: EZOutput.sharedOutput().component(), audioUnit: EZOutput.sharedOutput().remoteIONode().audioUnit)
		senderPort.derivedFromLiveAudioSource = true
		if let a = audiobusController {
			a.addSenderPort(senderPort)
			a.addReceiverPort(receiverPort)
			receiverPort.clientFormat = EZOutput.sharedOutput().outputASBD
		}
	}

	/**
	 Start the AVAudioSession and add the remote commands
	 */
	func setUpAudioSession() {
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

		guard isOnAir() else {
			return
		}

		guard let socket = self.socket else {
			return
		}

		guard socket.status == .Connected else {
			return
		}

		dispatch_async(backgroundQueue) { () -> Void in
			var params = [String: AnyObject]()
			params["data"] = data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions())
			params["time"] = NSDate().timeIntervalSince1970
			socket.emitWithAck("dataForStream", params)(timeoutAfter: 0) { data in
				if let response = data[0] as? [String: AnyObject] {
					if let bytes = response["bytes"] as? Float {
						self.statsPacketsReceived += bytes
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

	func port() -> ABReceiverPort {
		return receiverPort
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
