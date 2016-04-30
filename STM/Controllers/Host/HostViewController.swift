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

	var settings = HostSettings()
	var playbackReachedEnd = true
	var playbackPaused = false

	var statsPacketsReceived = Float(0)
    var statsNumberOfListeners = Int(0)

	var audioFile0: EZAudioFile?
	var audioFile1: EZAudioFile?

	var hud: M13ProgressHUD?

	let topView = UIView()
    var topViewHeightConstraint: NSLayoutConstraint?
    let dismissBT = UIButton.styleForDismissButton()
    var dismissBTTopPadding: NSLayoutConstraint?
    let miscBT = UIButton.styleForMiscButton()
	let albumPoster = UIImageView()
	let gradientView = GradientView()
	let gradientColorView = UIView()
	let visualizer = STMVisualizer()

	let songInfoHolderView = UIView()
	var songInfoHolderViewTopPadding: NSLayoutConstraint?
	let songInfoLabel1 = UILabel()
	let songInfoLabel2 = UILabel()
	let songInfoLabel3 = UILabel()

	let switcherControl = UISegmentedControl(items: ["Media", "Queue", "Timeline", "Settings"])
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

    let settingsHeaderMeta = UILabel.styledForSettingsHeader("META")
    var metaNameSettingView = UIView()
    let metaNameField = UITextField()

	let bottomBlurBar = UIToolbar()
	var bottomBlurBarConstraint: NSLayoutConstraint?
	let streamInfoHolder = HostInfoHolderView()

    let pauseBT = ExtendedButton()

	let micToggleBT = ExtendedButton()
	let micIndicatorView = UIView()
	let micIndicatorGradientView = GradientView()
	var micIndicatorWidthConstraint: NSLayoutConstraint?

	// Keyboard Adjustment
	var commentFieldKeyboardConstraint: NSLayoutConstraint?
    lazy var keynode: Keynode.Connector = Keynode.Connector(view: self.view)

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
		setupSwitcher()
		setupContentView()
		setupToolbar()
		setupSettingsContentView()

        keynode.animationsHandler = { [weak self] show, rect in
            if let me = self {
                if let con = me.commentFieldKeyboardConstraint {
                    //Take into account the bottom toolbar
                    con.constant = (show ? -(rect.size.height - 44) : 0)
                    me.view.layoutIfNeeded()
                }
            }
        }

        fetchOnce()
		NSTimer.scheduledTimerWithTimeInterval(1.5, target: self, selector: #selector(HostViewController.refresh), userInfo: nil, repeats: true)
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
		topViewHeightConstraint = topView.autoMatchDimension(.Height, toDimension: .Height, ofView: view, withMultiplier: 0.334)

        dismissBTTopPadding = dismissBT.autoPinEdgeToSuperviewEdge(.Top, withInset: 25)
        dismissBT.autoPinEdgeToSuperviewEdge(.Left, withInset: 20)

        miscBT.autoAlignAxis(.Horizontal, toSameAxisOfView: dismissBT)
        miscBT.autoPinEdgeToSuperviewEdge(.Right, withInset: 20)

		albumPoster.autoPinEdgesToSuperviewEdges()

		gradientView.autoPinEdgesToSuperviewEdges()
		gradientColorView.autoPinEdgesToSuperviewEdges()

		visualizer.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0))

		// Info Holder
		songInfoHolderViewTopPadding = songInfoHolderView.autoAlignAxis(.Horizontal, toSameAxisOfView: topView, withOffset: 15)
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

        settingsHeaderMeta.autoPinEdge(.Top, toEdge: .Bottom, ofView: micFadeTimeSettingView)
        settingsHeaderMeta.autoPinEdgeToSuperviewEdge(.Left)
        settingsHeaderMeta.autoPinEdgeToSuperviewEdge(.Right)

        metaNameSettingView.autoPinEdge(.Top, toEdge: .Bottom, ofView: settingsHeaderMeta)
        metaNameSettingView.autoPinEdgeToSuperviewEdge(.Left)
        metaNameSettingView.autoPinEdgeToSuperviewEdge(.Right)
		metaNameSettingView.autoPinEdgeToSuperviewEdge(.Bottom, withInset: 0, relation: .GreaterThanOrEqual)

		// Toolbar
		bottomBlurBar.autoSetDimension(.Height, toSize: 88)
		bottomBlurBar.autoPinEdge(.Top, toEdge: .Bottom, ofView: switcherScrollView)
		bottomBlurBar.autoPinEdgeToSuperviewEdge(.Left)
		bottomBlurBar.autoPinEdgeToSuperviewEdge(.Right)
		bottomBlurBarConstraint = bottomBlurBar.autoPinEdgeToSuperviewEdge(.Bottom, withInset: -44)

		streamInfoHolder.autoPinEdgeToSuperviewEdge(.Top, withInset: 14)
		streamInfoHolder.autoAlignAxisToSuperviewAxis(.Vertical)

        pauseBT.autoPinEdgeToSuperviewEdge(.Top, withInset: 11)
        pauseBT.autoPinEdgeToSuperviewEdge(.Left, withInset: 11)

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
        albumPoster.clipsToBounds = true
		topView.addSubview(albumPoster)

		gradientView.gradientLayer.colors = [RGB(0, a: 0).CGColor, RGB(0, a: 0).CGColor, RGB(0).CGColor]
		gradientView.gradientLayer.locations = [NSNumber(float: 0.0), NSNumber(float: 0.5), NSNumber(float: 1.0)]
		topView.addSubview(gradientView)

		gradientColorView.backgroundColor = Constants.UI.Color.off.colorWithAlphaComponent(0.66)
		topView.addSubview(gradientColorView)

		topView.addSubview(visualizer)

        dismissBT.addTarget(self, action: #selector(HostViewController.toggleDismiss), forControlEvents: .TouchUpInside)
        topView.addSubview(dismissBT)

        miscBT.addTarget(self, action: #selector(HostViewController.showMenu), forControlEvents: .TouchUpInside)
        topView.addSubview(miscBT)

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
		switcherControl.tintColor = Constants.UI.Color.tint
		switcherControl.setTitleTextAttributes([NSForegroundColorAttributeName: RGB(255)], forState: .Selected)
		switcherControl.addTarget(self, action: #selector(HostViewController.didChangeSegmentIndex), forControlEvents: .ValueChanged)
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
        queueTableView.setEditing(true, animated: false)
		switcherContentView.addSubview(queueTableView)

        commentsTableView.delegate = self
        commentsTableView.dataSource = self
        commentsTableView.registerReusableCell(CommentCell)
        commentsTableView.registerReusableCell(TimelineItemCell)
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
		recordSwitch.addTarget(self, action: #selector(HostViewController.didToggleOnAir), forControlEvents: .TouchUpInside)
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
        musicVolumeSlider.addTarget(self, action: #selector(HostViewController.didChangeMusicVolume(_:)), forControlEvents: .ValueChanged)
		let musicVolumeSettingView = SettingJoinedView(text: NSLocalizedString("Settings_HostMusicVolume", comment: "Music Volume"), detailText: NSLocalizedString("Settings_HostMusicVolumeDescription", comment: ""), control: musicVolumeSlider)
		self.musicVolumeSettingView = musicVolumeSettingView
		settingsContentView.addSubview(musicVolumeSettingView)

		// ***********MICROPHONE**********\\
		settingsContentView.addSubview(settingsHeaderMicrophone)

		micVolumeSlider.value = 1.0
        micVolumeSlider.addTarget(self, action: #selector(HostViewController.didChangeMicVolume(_:)), forControlEvents: .ValueChanged)
		let micVolumeSettingView = SettingJoinedView(text: NSLocalizedString("Settings_HostMicrophoneVolume", comment: "Microphone Volume"), detailText: NSLocalizedString("Settings_HostMicrophoneVolumeDescription", comment: ""), control: micVolumeSlider)
		self.micVolumeSettingView = micVolumeSettingView
		settingsContentView.addSubview(micVolumeSettingView)

		micActiveMusicVolumeSlider.value = 0.2
        micActiveMusicVolumeSlider.addTarget(self, action: #selector(HostViewController.didChangeMusicVolumeMicActive(_:)), forControlEvents: .ValueChanged)
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

        settingsContentView.addSubview(settingsHeaderMeta)
        let metaNameSettingView = SettingJoinedView(text: NSLocalizedString("Settings_StreamName", comment: "Stream Name"), detailText: NSLocalizedString("Settings_StreamNameDescription", comment: ""), control: metaNameField)
        self.metaNameSettingView = metaNameSettingView
        settingsContentView.addSubview(metaNameSettingView)
	}

	func setupToolbar() {
		view.addSubview(bottomBlurBar)

		streamInfoHolder.listeners = 0
		streamInfoHolder.bandwidth = 0
		streamInfoHolder.comments = 0
		bottomBlurBar.addSubview(streamInfoHolder)

        pauseBT.setImage(UIImage(named: "toolbar_pauseOff"), forState: .Normal)
        pauseBT.setImage(UIImage(named: "toolbar_pauseOn"), forState: .Selected)
        pauseBT.addTarget(self, action: #selector(HostViewController.togglePause), forControlEvents: .TouchUpInside)
        bottomBlurBar.addSubview(pauseBT)

		micToggleBT.setImage(UIImage(named: "toolbar_micOff"), forState: .Normal)
		micToggleBT.setImage(UIImage(named: "toolbar_micOn"), forState: .Selected)
		micToggleBT.addTarget(self, action: #selector(HostViewController.toggleMic), forControlEvents: .TouchUpInside)
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
     Close the host player view controller
     */
    func close() {

        if AppDelegate.del().activeStreamController == self {
            AppDelegate.del().activeStreamController = nil
        }

        audioFile0 = nil
        audioFile1 = nil

        delay(1.0) {
            self.stop()
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

    func showMenu() {
        let menu = UIAlertController(title: "Host Menu", message: nil, preferredStyle: .ActionSheet)
        menu.popoverPresentationController?.sourceView = miscBT

        menu.addAction(UIAlertAction(title: "Share", style: .Default, handler: { (action) in
            self.showShareDialog()
        }))

        menu.addAction(UIAlertAction(title: "Close Stream", style: .Destructive, handler: { (action) in
            self.close()
        }))

        menu.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))

        presentViewController(menu, animated: true, completion: nil)
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

    func toggleTop(show: Bool? = nil) {
        guard let con = topViewHeightConstraint else {
            return
        }

        let isShown = con.constant != 109

        if let show = (show != nil ? show : !isShown) {
            guard isShown != show else {
                return
            }

            con.autoRemove()

            UIView.animateWithDuration(0.4, animations: {
                self.innerToggleTop(show)
            })
        }
    }

    private func innerToggleTop(show: Bool) {
        if show {
            topViewHeightConstraint = topView.autoMatchDimension(.Height, toDimension: .Height, ofView: view, withMultiplier: 0.334)
        } else {
            topViewHeightConstraint = topView.autoSetDimension(.Height, toSize: 109)
        }

        view.layoutIfNeeded()
    }

	/**
	 Toggles the extended layout of the toolbar

	 - parameter show: whether to extend(true) or collapse(false) the toolbar
	 */
	func toggleToolbar(show: Bool? = nil) {
        guard let con = bottomBlurBarConstraint else {
            return
        }

        if let show = show != nil ? show : (con.constant == 44) {
            UIView.animateWithDuration(0.5, animations: { () -> Void in
                con.constant = show ? 0 : 44
                self.view.layoutIfNeeded()
            })
        }
	}

    func togglePause() {
        setPaused(!pauseBT.selected)
    }

    func setPaused(enabled: Bool) {
        pauseBT.selected = enabled
        playbackPaused = pauseBT.selected
        self.refreshRecordingLabel()
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

    func didChangeMusicVolume(sender: UISlider) {
        if !micToggleBT.selected {
            EZOutput.sharedOutput().mixerNode.setVolume(sender.value, forBus: 0)
        }
    }

    func didChangeMusicVolumeMicActive(sender: UISlider) {
        if micToggleBT.selected {
            EZOutput.sharedOutput().mixerNode.setVolume(sender.value, forBus: 0)
        }
    }

    func didChangeMicVolume(sender: UISlider) {
        EZOutput.sharedOutput().mixerNode.setVolume(sender.value, forBus: 1)
    }

	/**
	 Refreshes various times & numbers
	 */
	func refresh() {
		streamInfoHolder.bandwidth = statsPacketsReceived
        streamInfoHolder.listeners = statsNumberOfListeners
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
			gradientColorView.backgroundColor = Constants.UI.Color.tint.colorWithAlphaComponent(0.66)
		} else {
			recordingStatusLabel.text = "Not Broadcasting"
			recordingStatusLabel.textColor = recordSwitch.onTintColor
			recordingStatusLabel.backgroundColor = RGB(255)
			gradientColorView.backgroundColor = Constants.UI.Color.off.colorWithAlphaComponent(0.66)
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

		if (songInfoLabel2.text?.characters.count == 0 && songInfoLabel3.text?.characters.count == 0) || (songInfoLabel2.text == nil || songInfoLabel3.text == nil) {
			songInfoHolderViewTopPadding?.constant = 15
		} else if (songInfoLabel2.text?.characters.count != 0 && songInfoLabel3.text?.characters.count != 0) || (songInfoLabel2.text != nil && songInfoLabel3.text != nil) {
			songInfoHolderViewTopPadding?.constant = 5
		} else {
			songInfoHolderViewTopPadding?.constant = 10
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
        } else if tableView == commentsTableView {
            if comments[indexPath?.row ?? 0] is STMTimelineItem {
                return TimelineItemCell.self
            } else {
                return CommentCell.self
            }
        }

		return super.tableViewCellClass(tableView, indexPath: indexPath)
	}

	override func tableViewNoDataText(tableView: UITableView) -> String {
		if tableView == songsTableView {
			return searchResults != nil ? "No Results" : "No Songs in Library"
		} else if tableView == queueTableView {
			return "No Songs in Queue"
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

    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return tableView == queueTableView && upNextSongs.count > 1
    }

    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return .None
    }

    func tableView(tableView: UITableView, shouldIndentWhileEditingRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        if tableView == queueTableView {
            let sourceItem = upNextSongs[sourceIndexPath.row]
            upNextSongs.removeAtIndex(sourceIndexPath.row)
            upNextSongs.insert(sourceItem, atIndex: destinationIndexPath.row)
            tableView.reloadData()
        }
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        super.tableView(tableView, didSelectRowAtIndexPath: indexPath)
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 50
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
				return song.aggregateText().lowercaseString.containsString(searchText.lowercaseString)
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
        if let result = response as? JSON {
            if let item = STMTimelineItem(json: result) {
                let isAtBottom = commentsTableView.indexPathsForVisibleRows?.contains({ $0.row == (comments.count - 1) })
                let shouldScrollDown = (didPostComment ?? false) || (isAtBottom ?? false)
                comments.append(item)
                didUpdateComments(shouldScrollDown)
            }
        }
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
		progressView.primaryColor = Constants.UI.Color.tint
		progressView.secondaryColor = Constants.UI.Color.disabled
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
							self.toggleAudioSession()
							self.connectGlobalStream()
							self.loadLibrary()

							Answers.logCustomEventWithName("Created Stream", customAttributes: [:])
						}
					}
					}, errorCompletion: { (error) -> Void in
					if let hud = self.hud {
						hud.dismiss(true)
					}
					self.close()
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
		progressView.primaryColor = Constants.UI.Color.tint
		progressView.secondaryColor = Constants.UI.Color.disabled
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

						self.toggleAudioSession()
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
				self.close()
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

        guard let securityHash = stream.securityHash else {
            return
        }

        guard let baseURL = NSURL(string: Constants.Config.apiBaseURL) else {
            return
        }

        let oForcePolling = SocketIOClientOption.ForcePolling(true)
        let oHost = SocketIOClientOption.Nsp("/host")
        let streamQueue = SocketIOClientOption.HandleQueue(backgroundQueue)
        let oAuth = SocketIOClientOption.ConnectParams(["streamID": stream.id, "securityHash": securityHash, "userID": user.id, "stmHash": Constants.Config.streamHash])
        let oLog = SocketIOClientOption.Log(false)
        let oForceNew = SocketIOClientOption.ForceNew(true)
        let options = [oForcePolling, oHost, oAuth, streamQueue, oForceNew] as Set<SocketIOClientOption>

        self.socket = SocketIOClient(socketURL: baseURL, options: options)
        if let socket = self.socket {
            socket.on("connect") { data, ack in
                print("Stream: Socket Connected")
            }

            socket.connect()
        }

        let commentHost = SocketIOClientOption.Nsp("/comment")
        let commentOptions = [oForcePolling, commentHost, oAuth, oLog, oForceNew] as Set<SocketIOClientOption>
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

	func loadLibrary() {
		EZOutput.sharedOutput().aacEncode = true
        AppDelegate.del().setUpAudioSession(withMic: true)

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
    func toggleAudioSession(enabled: Bool = true) {
        if enabled {
            MPRemoteCommandCenter.sharedCommandCenter().playCommand.addTarget(self, action: #selector(HostViewController.play))
            MPRemoteCommandCenter.sharedCommandCenter().pauseCommand.addTarget(self, action: #selector(HostViewController.stop))
            MPRemoteCommandCenter.sharedCommandCenter().nextTrackCommand.addTarget(self, action: #selector(HostViewController.next))
        }


		MPRemoteCommandCenter.sharedCommandCenter().pauseCommand.enabled = enabled
		MPRemoteCommandCenter.sharedCommandCenter().nextTrackCommand.enabled = enabled
		MPRemoteCommandCenter.sharedCommandCenter().previousTrackCommand.enabled = enabled
	}

	func output(output: EZOutput!, shouldFillAudioBufferList audioBufferList: UnsafeMutablePointer<AudioBufferList>, withNumberOfFrames frames: UInt32) {
        func reset() {
            memset(audioBufferList.memory.mBuffers.mData, 0, Int(audioBufferList.memory.mBuffers.mDataByteSize))
        }

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
				reset()
			}
		} else {
            reset()
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

                    if let listeners = response["listeners"] as? Int {
                        self.statsNumberOfListeners = listeners
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
        EZOutput.sharedOutput().startPlayback()
        setPaused(false)
        toggleAudioSession(true)
        MPRemoteCommandCenter.sharedCommandCenter().pauseCommand.enabled = true
	}

    func stop() {
        EZOutput.sharedOutput().stopPlayback()
        setPaused(true)
        toggleAudioSession(false)
        MPRemoteCommandCenter.sharedCommandCenter().playCommand.enabled = true
    }

	func pause() {
        setPaused(true)
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
            MPRemoteCommandCenter.sharedCommandCenter().nextTrackCommand.enabled = false

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
			updateUpNext()
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

            MPRemoteCommandCenter.sharedCommandCenter().nextTrackCommand.enabled = (self.upNextSongs.count > 0)
		}
	}

	func didReachEndOfQueue() {
		AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
		updateCurrentSong(nil)
	}
}
