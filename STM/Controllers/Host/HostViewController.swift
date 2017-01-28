//
//  HostViewController.swift
//  STM
//
//  Created by Kesi Maduka on 1/30/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit
import ALCameraViewController
import M13ProgressSuite
import MediaPlayer

struct HostSettings {
	var crossfadeDuration = Float(5.0)
}

// MARK: Variables
class HostViewController: KZViewController, UISearchBarDelegate, UIViewControllerPreviewingDelegate, UITextFieldDelegate, UITextViewDelegate {
	var streamType: StreamType?
	var stream: STMStream?

	var socket: SocketIOClient?
    var commentSocket: SocketIOClient?
	let backgroundQueue = DispatchQueue(label: "com.stormedgeapps.streamtome.stream", attributes: [])
    let commentBackgroundQueue = DispatchQueue(label: "com.stormedgeapps.streamtome.comment", attributes: [])

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
    var musicVolumeSettingView = UIView()
    let musicVolumeSlider = UISlider()

	let settingsHeaderMicrophone = UILabel.styledForSettingsHeader("MICROPHONE")
	var micVolumeSettingView = UIView()
	let micVolumeSlider = UISlider()
	var micActiveMusicVolumeSettingView = UIView()
	let micActiveMusicVolumeSlider = UISlider()
	var micFadeTimeSettingView = UIView()
	let micFadeTimeSlider = UISlider()
    var monitoringSettingView = UIView()
    let monitoringSwitch = UISwitch()

    let settingsHeaderMeta = UILabel.styledForSettingsHeader("META")
    var metaNameSettingView = UIView()
    let metaNameField = TextField(insets: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
    var metaDescriptionSettingView = UIView()
    let metaDescriptionField = UITextView()
    var metaPictureSettingView = UIView()
    let metaPictureButton = UIImageView()
    var metaColorSettingsView = UIView()
    let metaColorSlider = GradientSlider()

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
    var settingsieldKeyboardConstraint: NSLayoutConstraint?
    lazy var keynode: Keynode.Connector = Keynode.Connector(view: self.view)

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
        self.socket?.disconnect()
        self.commentSocket?.disconnect()
    }

	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = RGB(0)

		setupTopView()
		setupSwitcher()
		setupContentView()
		setupToolbar()
		setupSettingsContentView()

        loadLibrary()

        keynode.animationsHandler = { [weak self] show, rect in
            if let me = self {
                me.toggleTop(!show)

                let offset: CGFloat = me.micToggleBT.isSelected ? 88 : 44

                if let con = me.commentFieldKeyboardConstraint {
                    con.constant = (show ? -(rect.size.height - offset) : 0)
                    me.view.layoutIfNeeded()
                }

                if let con = me.settingsieldKeyboardConstraint {
                    con.constant = (show ? -(rect.size.height - offset) : 0)
                    me.view.layoutIfNeeded()
                }
            }
        }

        fetchOnce()
		Timer.scheduledTimer(timeInterval: 1.5, target: self, selector: #selector(HostViewController.refresh), userInfo: nil, repeats: true)
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		if let hud = hud {
			hud.dismiss(true)
		}
	}

	// MARK: Constraints
	override func setupConstraints() {
		super.setupConstraints()

		// Top View
		topView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .bottom)
		topViewHeightConstraint = topView.autoMatch(.height, to: .height, of: view, withMultiplier: 0.334)

        dismissBTTopPadding = dismissBT.autoPinEdge(toSuperviewEdge: .top, withInset: 25)
        dismissBT.autoPinEdge(toSuperviewEdge: .left, withInset: 20)

        miscBT.autoAlignAxis(.horizontal, toSameAxisOf: dismissBT)
        miscBT.autoPinEdge(toSuperviewEdge: .right, withInset: 20)

		albumPoster.autoPinEdgesToSuperviewEdges()

		gradientView.autoPinEdgesToSuperviewEdges()
		gradientColorView.autoPinEdgesToSuperviewEdges()

        visualizer.autoPinEdge(toSuperviewEdge: .left)
        visualizer.autoPinEdge(toSuperviewEdge: .right)
        visualizer.autoMatch(.height, to: .height, of: topView, withMultiplier: 0.8)
        visualizer.autoAlignAxis(.horizontal, toSameAxisOf: songInfoHolderView)

		// Info Holder
		songInfoHolderViewTopPadding = songInfoHolderView.autoAlignAxis(.horizontal, toSameAxisOf: topView, withOffset: 15)
		songInfoHolderView.autoAlignAxis(toSuperviewAxis: .vertical)
		songInfoHolderView.autoPinEdge(toSuperviewEdge: .left, withInset: 20)
		songInfoHolderView.autoPinEdge(toSuperviewEdge: .right, withInset: 20)

		songInfoLabel1.autoPinEdge(toSuperviewEdge: .top)
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
		switcherControlHolder.autoPinEdge(.top, to: .bottom, of: topView)
		switcherControlHolder.autoPinEdge(toSuperviewEdge: .left)
		switcherControlHolder.autoPinEdge(toSuperviewEdge: .right)
		switcherControlHolder.autoSetDimension(.height, toSize: 44)

		switcherControl.autoAlignAxis(toSuperviewAxis: .horizontal)
		switcherControl.autoPinEdge(toSuperviewEdge: .left, withInset: 22)
		switcherControl.autoPinEdge(toSuperviewEdge: .right, withInset: 22)

		// Scroll View
		switcherScrollView.autoPinEdge(.top, to: .bottom, of: switcherControlHolder)
		switcherScrollView.autoPinEdge(toSuperviewEdge: .left)
		switcherScrollView.autoPinEdge(toSuperviewEdge: .right)

		switcherContentView.autoPinEdgesToSuperviewEdges()
		switcherContentView.autoMatch(.height, to: .height, of: switcherScrollView)

		for view in [songsTableView, queueTableView, commentContentView] {
			view.autoPinEdge(toSuperviewEdge: .top)
			view.autoMatch(.width, to: .width, of: switcherScrollView)
			view.autoPinEdge(toSuperviewEdge: .bottom)
		}

		songsTableView.autoPinEdge(toSuperviewEdge: .left)
		queueTableView.autoPinEdge(.left, to: .right, of: songsTableView)
		commentContentView.autoPinEdge(.left, to: .right, of: queueTableView)

        settingsScrollView.autoPinEdge(toSuperviewEdge: .top)
        settingsScrollView.autoMatch(.width, to: .width, of: switcherScrollView)
		settingsScrollView.autoPinEdge(.left, to: .right, of: commentContentView)
		settingsScrollView.autoPinEdge(toSuperviewEdge: .right)
        settingsieldKeyboardConstraint = settingsScrollView.autoPinEdge(toSuperviewEdge: .bottom)

		// Comments
		commentsTableView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .bottom)

		commentToolbar.autoPinEdge(.top, to: .bottom, of: commentsTableView)
		commentToolbar.autoPinEdge(toSuperviewEdge: .left)
		commentToolbar.autoPinEdge(toSuperviewEdge: .right)
		commentFieldKeyboardConstraint = commentToolbar.autoPinEdge(toSuperviewEdge: .bottom)

		// Settings: Content View
		settingsContentView.autoPinEdgesToSuperviewEdges()
		settingsContentView.autoMatch(.width, to: .width, of: settingsScrollView)

		// Settings: Status
		settingsHeaderStatus.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .bottom)

		broadcastingStatusBG.autoPinEdge(.top, to: .bottom, of: settingsHeaderStatus)
		broadcastingStatusBG.autoPinEdge(toSuperviewEdge: .left)
		broadcastingStatusBG.autoPinEdge(toSuperviewEdge: .right)

		recordSwitch.autoPinEdge(toSuperviewEdge: .top, withInset: 22)
		recordSwitch.autoPinEdge(toSuperviewEdge: .left, withInset: 22)
		recordSwitch.autoPinEdge(toSuperviewEdge: .bottom, withInset: 22)

		recordingStatusLabel.autoAlignAxis(.horizontal, toSameAxisOf: recordSwitch)
		recordingStatusLabel.autoPinEdge(.left, to: .right, of: recordSwitch, withOffset: 22)
		recordingStatusLabel.autoPinEdge(toSuperviewEdge: .right, withInset: 22)
		recordingStatusLabel.autoMatch(.height, to: .height, of: recordSwitch)

		// Settings: Playback
		settingsHeaderPlayback.autoPinEdge(.top, to: .bottom, of: broadcastingStatusBG)
		settingsHeaderPlayback.autoPinEdge(toSuperviewEdge: .left)
		settingsHeaderPlayback.autoPinEdge(toSuperviewEdge: .right)

		musicVolumeSettingView.autoPinEdge(.top, to: .bottom, of: settingsHeaderPlayback)
		musicVolumeSettingView.autoPinEdge(toSuperviewEdge: .left)
		musicVolumeSettingView.autoPinEdge(toSuperviewEdge: .right)

		// Settings: Microphone
		settingsHeaderMicrophone.autoPinEdge(.top, to: .bottom, of: musicVolumeSettingView)
		settingsHeaderMicrophone.autoPinEdge(toSuperviewEdge: .left)
		settingsHeaderMicrophone.autoPinEdge(toSuperviewEdge: .right)

		micVolumeSettingView.autoPinEdge(.top, to: .bottom, of: settingsHeaderMicrophone)
		micVolumeSettingView.autoPinEdge(toSuperviewEdge: .left)
		micVolumeSettingView.autoPinEdge(toSuperviewEdge: .right)

		micActiveMusicVolumeSettingView.autoPinEdge(toSuperviewEdge: .left)
		micActiveMusicVolumeSettingView.autoPinEdge(toSuperviewEdge: .right)

		micFadeTimeSettingView.autoPinEdge(toSuperviewEdge: .left)
		micFadeTimeSettingView.autoPinEdge(toSuperviewEdge: .right)

        monitoringSettingView.autoPinEdge(toSuperviewEdge: .left)
        monitoringSettingView.autoPinEdge(toSuperviewEdge: .right)

        settingsHeaderMeta.autoPinEdge(.top, to: .bottom, of: monitoringSettingView)
        settingsHeaderMeta.autoPinEdge(toSuperviewEdge: .left)
        settingsHeaderMeta.autoPinEdge(toSuperviewEdge: .right)

        metaNameSettingView.autoPinEdge(.top, to: .bottom, of: settingsHeaderMeta)
        metaNameSettingView.autoPinEdge(toSuperviewEdge: .left)
        metaNameSettingView.autoPinEdge(toSuperviewEdge: .right)

        metaDescriptionSettingView.autoPinEdge(.top, to: .bottom, of: metaNameSettingView)
        metaDescriptionSettingView.autoPinEdge(toSuperviewEdge: .left)
        metaDescriptionSettingView.autoPinEdge(toSuperviewEdge: .right)

        metaPictureSettingView.autoPinEdge(.top, to: .bottom, of: metaDescriptionSettingView)
        metaPictureSettingView.autoPinEdge(toSuperviewEdge: .left)
        metaPictureSettingView.autoPinEdge(toSuperviewEdge: .right)

        metaColorSettingsView.autoPinEdge(.top, to: .bottom, of: metaPictureSettingView)
        metaColorSettingsView.autoPinEdge(toSuperviewEdge: .left)
        metaColorSettingsView.autoPinEdge(toSuperviewEdge: .right)
		metaColorSettingsView.autoPinEdge(toSuperviewEdge: .bottom, withInset: 0, relation: .greaterThanOrEqual)

		// Toolbar
		bottomBlurBar.autoSetDimension(.height, toSize: 88)
		bottomBlurBar.autoPinEdge(.top, to: .bottom, of: switcherScrollView)
		bottomBlurBar.autoPinEdge(toSuperviewEdge: .left)
		bottomBlurBar.autoPinEdge(toSuperviewEdge: .right)
		bottomBlurBarConstraint = bottomBlurBar.autoPinEdge(toSuperviewEdge: .bottom, withInset: -44)

		streamInfoHolder.autoPinEdge(toSuperviewEdge: .top, withInset: 14)
		streamInfoHolder.autoAlignAxis(toSuperviewAxis: .vertical)

        pauseBT.autoPinEdge(toSuperviewEdge: .top, withInset: 11)
        pauseBT.autoPinEdge(toSuperviewEdge: .left, withInset: 11)

		micToggleBT.autoPinEdge(toSuperviewEdge: .top, withInset: 11)
		micToggleBT.autoPinEdge(toSuperviewEdge: .right, withInset: 11)

		micIndicatorGradientView.autoSetDimension(.height, toSize: 22)
		micIndicatorGradientView.autoPinEdge(toSuperviewEdge: .left, withInset: 11)
		micIndicatorGradientView.autoPinEdge(toSuperviewEdge: .right, withInset: 11)
		micIndicatorGradientView.autoPinEdge(toSuperviewEdge: .bottom, withInset: 11)

		micIndicatorWidthConstraint = micIndicatorView.autoPinEdge(toSuperviewEdge: .left, withInset: 0)
		micIndicatorView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .left)
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()

		self.switcherScrollView.contentOffset = CGPoint(x: CGFloat(self.switcherControl.selectedSegmentIndex) * self.switcherScrollView.frame.width, y: 0)
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

        dismissBT.addTarget(self, action: #selector(HostViewController.toggleDismiss), for: .touchUpInside)
        topView.addSubview(dismissBT)

        miscBT.addTarget(self, action: #selector(HostViewController.showMenu), for: .touchUpInside)
        topView.addSubview(miscBT)

		topView.addSubview(songInfoHolderView)
        [songInfoLabel1, songInfoLabel2, songInfoLabel3].forEach { (label) -> () in
			label.textAlignment = .center
			label.textColor = RGB(255)
			if label != songInfoLabel1 {
				label.alpha = 0.66
				label.font = UIFont.systemFont(ofSize: 13, weight: UIFontWeightMedium)
			} else {
				label.text = "No Song Playing"
				label.font = UIFont.systemFont(ofSize: 18, weight: UIFontWeightMedium)
			}
			songInfoHolderView.addSubview(label)
		}
	}

	func setupSwitcher() {
		switcherControlHolder.backgroundColor = RGB(70)
		view.addSubview(switcherControlHolder)

		switcherControl.selectedSegmentIndex = 0
		switcherControl.tintColor = Constants.UI.Color.tint
		switcherControl.setTitleTextAttributes([NSForegroundColorAttributeName: RGB(255)], for: .selected)
		switcherControl.addTarget(self, action: #selector(HostViewController.didChangeSegmentIndex), for: .valueChanged)
		switcherControlHolder.addSubview(switcherControl)

		switcherScrollView.isScrollEnabled = false
		switcherScrollView.showsHorizontalScrollIndicator = false
		switcherScrollView.showsVerticalScrollIndicator = false
		view.addSubview(switcherScrollView)
	}

	func setupContentView() {
		switcherContentView.backgroundColor = RGB(255)
		switcherScrollView.addSubview(switcherContentView)

		songsTableView.delegate = self
		songsTableView.dataSource = self
		songsTableView.registerReusableCell(SelectSongCell.self)
		switcherContentView.addSubview(songsTableView)

		queueTableView.delegate = self
		queueTableView.dataSource = self
		queueTableView.registerReusableCell(UpNextSongCell.self)
        queueTableView.setEditing(true, animated: false)
		switcherContentView.addSubview(queueTableView)

        commentsTableView.delegate = self
        commentsTableView.dataSource = self
        commentsTableView.registerReusableCell(CommentCell.self)
        commentsTableView.registerReusableCell(TimelineItemCell.self)
		switcherContentView.addSubview(commentContentView)
		commentContentView.addSubview(commentsTableView)

        registerForPreviewing(with: self, sourceView: commentsTableView)

		commentToolbar.delegate = self
		commentContentView.addSubview(commentToolbar)

		settingsScrollView.addSubview(settingsContentView)
		switcherContentView.addSubview(settingsScrollView)
	}

	func setupSettingsContentView() {
		// ***********STATUS**********\\
		settingsContentView.addSubview(settingsHeaderStatus)

		broadcastingStatusBG.backgroundColor = RGB(250, g: 251, b: 252)
		settingsContentView.addSubview(broadcastingStatusBG)

		recordSwitch.tintColor = RGB(220, g: 221, b: 222)
		recordSwitch.backgroundColor = RGB(220, g: 221, b: 222)
		recordSwitch.layer.cornerRadius = 16.0
		recordSwitch.onTintColor = RGB(232, g: 61, b: 14)
		recordSwitch.addTarget(self, action: #selector(HostViewController.didToggleOnAir), for: .touchUpInside)
		broadcastingStatusBG.addSubview(recordSwitch)

		recordingStatusLabel.text = "Not Broadcasting"
		recordingStatusLabel.textAlignment = .center
		recordingStatusLabel.font = UIFont.systemFont(ofSize: 16)
		recordingStatusLabel.backgroundColor = RGB(220, g: 221, b: 222)
		recordingStatusLabel.textColor = recordSwitch.onTintColor
		recordingStatusLabel.layer.cornerRadius = 16.0
		recordingStatusLabel.layer.masksToBounds = true
		recordingStatusLabel.clipsToBounds = true
		broadcastingStatusBG.addSubview(recordingStatusLabel)

		// ***********PLAYBACK**********\\
		settingsContentView.addSubview(settingsHeaderPlayback)

		musicVolumeSlider.value = 1.0
        musicVolumeSlider.addTarget(self, action: #selector(HostViewController.didChangeMusicVolume(_:)), for: .valueChanged)
		let musicVolumeSettingView = SettingJoinedView(text: NSLocalizedString("Settings_HostMusicVolume", comment: "Music Volume"), detailText: NSLocalizedString("Settings_HostMusicVolumeDescription", comment: ""), control: musicVolumeSlider)
		self.musicVolumeSettingView = musicVolumeSettingView
		settingsContentView.addSubview(musicVolumeSettingView)

		// ***********MICROPHONE**********\\
		settingsContentView.addSubview(settingsHeaderMicrophone)

		micVolumeSlider.value = 1.0
        micVolumeSlider.addTarget(self, action: #selector(HostViewController.didChangeMicVolume(_:)), for: .valueChanged)
		let micVolumeSettingView = SettingJoinedView(text: NSLocalizedString("Settings_HostMicrophoneVolume", comment: "Microphone Volume"), detailText: NSLocalizedString("Settings_HostMicrophoneVolumeDescription", comment: ""), control: micVolumeSlider)
		self.micVolumeSettingView = micVolumeSettingView
		settingsContentView.addSubview(micVolumeSettingView)

		micActiveMusicVolumeSlider.value = 0.2
        micActiveMusicVolumeSlider.addTarget(self, action: #selector(HostViewController.didChangeMusicVolumeMicActive(_:)), for: .valueChanged)
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

        let monitoringSettingView = SettingJoinedView(text: NSLocalizedString("Settings_HostMonitoring", comment: "Mic Monitoring"), detailText: NSLocalizedString("Settings_HostMonitoringDescription", comment: ""), control: monitoringSwitch)
        self.monitoringSettingView = monitoringSettingView
        settingsContentView.addSubview(monitoringSettingView)
        monitoringSettingView.setPrevChain(micFadeTimeSettingView)

        // ***********META**********\\
        settingsContentView.addSubview(settingsHeaderMeta)

        metaNameField.backgroundColor = RGB(235, g: 236, b: 237)
        metaNameField.layer.cornerRadius = 5.0
        metaNameField.clipsToBounds = true
        metaNameField.returnKeyType = .done
        metaNameField.delegate = self
        metaNameField.textAlignment = .center
        metaNameField.text = stream?.name
        metaNameField.font = UIFont.systemFont(ofSize: 14)
        let metaNameSettingView = SettingJoinedView(text: NSLocalizedString("Settings_StreamName", comment: "Stream Name"), detailText: NSLocalizedString("Settings_StreamNameDescription", comment: ""), control: metaNameField)
        self.metaNameSettingView = metaNameSettingView
        settingsContentView.addSubview(metaNameSettingView)

        metaDescriptionField.backgroundColor = RGB(235, g: 236, b: 237)
        metaDescriptionField.layer.cornerRadius = 5.0
        metaDescriptionField.clipsToBounds = true
        metaDescriptionField.delegate = self
        metaDescriptionField.inputAccessoryView = UIToolbar.styleWithButtons(self)
        metaDescriptionField.text = stream?.description
        metaDescriptionField.font = UIFont.systemFont(ofSize: 14)
        metaDescriptionField.autoSetDimension(.height, toSize: 150)
        let metaDescriptionSettingView = SettingJoinedView(text: NSLocalizedString("Settings_StreamDescription", comment: "Stream Desscription"), detailText: NSLocalizedString("Settings_StreamDescriptionDescription", comment: ""), control: metaDescriptionField)
        self.metaDescriptionSettingView = metaDescriptionSettingView
        settingsContentView.addSubview(metaDescriptionSettingView)
        metaDescriptionSettingView.setPrevChain(metaNameSettingView)

        let metaPictureButtonHolder = UIView()
        metaPictureButtonHolder.addSubview(metaPictureButton)
        metaPictureButton.backgroundColor = RGB(235, g: 236, b: 237)
        metaPictureButton.isUserInteractionEnabled = true
        metaPictureButton.layer.cornerRadius = 100.0/2.0
        metaPictureButton.layer.borderColor = RGB(235, g: 236, b: 237).cgColor
        metaPictureButton.layer.borderWidth = 1.0
        metaPictureButton.clipsToBounds = true
        metaPictureButton.autoSetDimensions(to: CGSize(width: 100, height: 100))
        metaPictureButton.autoPinEdge(toSuperviewEdge: .top, withInset: 10)
        metaPictureButton.autoAlignAxis(toSuperviewAxis: .horizontal)
        metaPictureButton.autoAlignAxis(toSuperviewAxis: .vertical)
        metaPictureButton.autoPinEdge(toSuperviewEdge: .bottom, withInset: 10)
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.changePicture))
        tap.numberOfTapsRequired = 1
        tap.numberOfTouchesRequired = 1
        metaPictureButton.addGestureRecognizer(tap)
        let metaPictureSettingView = SettingJoinedView(text: NSLocalizedString("Settings_StreamPhoto", comment: "Stream Photo"), detailText: NSLocalizedString("Settings_StreamPhotoDescription", comment: ""), control: metaPictureButtonHolder)
        self.metaPictureSettingView = metaPictureSettingView
        settingsContentView.addSubview(metaPictureSettingView)
        metaPictureSettingView.setPrevChain(metaDescriptionSettingView)

        metaColorSlider.hasRainbow = true
        metaColorSlider.actionBlock = { slider, value in
            CATransaction.begin()
            let color = UIColor(hue: value, saturation: 0.85, brightness: 0.99, alpha: 1.0)
            CATransaction.setValue(true, forKey: kCATransactionDisableActions)
            slider.thumbColor = color
            self.updateThemeColor(color)
            CATransaction.commit()
        }
        let metaColorSettingsView = SettingJoinedView(text: NSLocalizedString("Settings_StreamThemeColor", comment: "Stream Theme Color"), detailText: NSLocalizedString("Settings_StreamThemeColorDescription", comment: ""), control: metaColorSlider)
        self.metaColorSettingsView = metaColorSettingsView
        settingsContentView.addSubview(metaColorSettingsView)
        metaColorSettingsView.setPrevChain(metaPictureSettingView)

        if let stream = stream {
            var hue: CGFloat = 0
            var saturation: CGFloat = 0
            var brightness: CGFloat = 0
            var alpha: CGFloat = 0
            stream.color().getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
            metaPictureButton.kf.setImage(with: stream.pictureURL(), placeholder: UIImage(named: "defaultStreamImage"), options: [KingfisherOptionsInfoItem.forceRefresh], progressBlock: nil, completionHandler: nil)
            metaColorSlider.value = hue
            metaColorSlider.thumbColor = UIColor(hue: metaColorSlider.value, saturation: 0.85, brightness: 0.99, alpha: 1.0)
        }
	}

	func setupToolbar() {
		view.addSubview(bottomBlurBar)

		//streamInfoHolder.listeners = 0
		streamInfoHolder.bandwidth = 0
		streamInfoHolder.comments = 0
		bottomBlurBar.addSubview(streamInfoHolder)

        pauseBT.setImage(UIImage(named: "toolbar_pauseOff"), for: .normal)
        pauseBT.setImage(UIImage(named: "toolbar_pauseOn"), for: .selected)
        pauseBT.addTarget(self, action: #selector(HostViewController.togglePause), for: .touchUpInside)
        bottomBlurBar.addSubview(pauseBT)

		micToggleBT.setImage(UIImage(named: "toolbar_micOff"), for: .normal)
		micToggleBT.setImage(UIImage(named: "toolbar_micOn"), for: .selected)
		micToggleBT.addTarget(self, action: #selector(HostViewController.toggleMic), for: .touchUpInside)
		bottomBlurBar.addSubview(micToggleBT)

		micIndicatorGradientView.gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
		micIndicatorGradientView.gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
		micIndicatorGradientView.gradientLayer.colors = [RGB(0, g: 255, b: 0).cgColor, RGB(255, g: 255, b: 0).cgColor, RGB(255, g: 0, b: 0).cgColor]
		micIndicatorGradientView.gradientLayer.locations = [NSNumber(value: 0.0 as Float), NSNumber(value: 0.7 as Float), NSNumber(value: 1.0 as Float)]
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
            self.socket?.disconnect()
            self.commentSocket?.disconnect()
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
                vc.dismiss(animated: true, completion: nil)
            }
        }

        if self.dismissBT.isSelected {
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
        let menu = UIAlertController(title: "Host Menu", message: nil, preferredStyle: .actionSheet)
        menu.popoverPresentationController?.sourceView = miscBT

        menu.addAction(UIAlertAction(title: "Play Next Song", style: .default, handler: { (action) in
            self.next()
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
        let vc = UIActivityViewController(activityItems: [streamURL], applicationActivities: nil)
        self.present(vc, animated: true, completion: nil)
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

    func toggleTop(_ show: Bool? = nil) {
        guard let con = topViewHeightConstraint else {
            return
        }

        let isShown = con.constant != 109

        if let show = (show != nil ? show : !isShown) {
            guard isShown != show else {
                return
            }

            con.autoRemove()

            UIView.animate(withDuration: 0.4, animations: {
                self.innerToggleTop(show)
            })
        }
    }

    fileprivate func innerToggleTop(_ show: Bool) {
        if show {
            topViewHeightConstraint = topView.autoMatch(.height, to: .height, of: view, withMultiplier: 0.334)
        } else {
            topViewHeightConstraint = topView.autoSetDimension(.height, toSize: 109)
        }

        view.layoutIfNeeded()
    }

	/**
	 Toggles the extended layout of the toolbar

	 - parameter show: whether to extend(true) or collapse(false) the toolbar
	 */
	func toggleToolbar(_ show: Bool? = nil) {
        guard let con = bottomBlurBarConstraint else {
            return
        }

        if let show = show != nil ? show : (con.constant == 44) {
            UIView.animate(withDuration: 0.5, animations: { () -> Void in
                con.constant = show ? 0 : 44
                self.view.layoutIfNeeded()
            })
        }
	}

    func togglePause() {
        setPaused(!pauseBT.isSelected)
    }

    func setPaused(_ enabled: Bool) {
        pauseBT.isSelected = enabled
        playbackPaused = pauseBT.isSelected
        self.refreshRecordingLabel()
    }

	/**
	 Toggles the output of the mic to the stream
	 */
	func toggleMic() {
		micToggleBT.isSelected = !micToggleBT.isSelected

		// Music Bus = 0, Mic Bus = 1

		let bus0Volume = EZOutput.shared().mixerNode.volume(forBus: 0)
		let bus1Volume = EZOutput.shared().mixerNode.volume(forBus: 1)
		let bus0ToVolume = micToggleBT.isSelected ? micActiveMusicVolumeSlider.value : musicVolumeSlider.value
		let bus1ToVolume = micToggleBT.isSelected ? micVolumeSlider.value : 0.0

		engine + FUXTween.tween(micFadeTimeSlider.value, fromToValueFunc(bus0Volume, to: bus0ToVolume, valueFunc: { (value) -> () in
			EZOutput.shared().mixerNode.setVolume(value, forBus: 0)
			}))

		engine + FUXTween.tween(micFadeTimeSlider.value, fromToValueFunc(bus1Volume, to: bus1ToVolume, valueFunc: { (value) -> () in
			EZOutput.shared().mixerNode.setVolume(value, forBus: 1)
			}))

		toggleToolbar(micToggleBT.isSelected)
	}

	/**
	 Called when UISwitch is toggled for recording
	 */
	func didToggleOnAir() {
		UIView.transition(with: recordingStatusLabel, duration: 0.5, options: (isOnAir() ? .transitionFlipFromBottom : .transitionFlipFromTop), animations: { () -> Void in
			self.refreshRecordingLabel()
			}, completion: nil)
	}

	/**
	 Changes UIScrollView offset when UISegmentControl changes index
	 */
	func didChangeSegmentIndex() {
		UIView.animate(withDuration: 0.4, animations: { () -> Void in
			self.switcherScrollView.contentOffset = CGPoint(x: CGFloat(self.switcherControl.selectedSegmentIndex) * self.switcherScrollView.frame.width, y: 0)
		})

		view.endEditing(true)
	}

    func didChangeMusicVolume(_ sender: UISlider) {
        if !micToggleBT.isSelected {
            EZOutput.shared().mixerNode.setVolume(sender.value, forBus: 0)
        }
    }

    func didChangeMusicVolumeMicActive(_ sender: UISlider) {
        if micToggleBT.isSelected {
            EZOutput.shared().mixerNode.setVolume(sender.value, forBus: 0)
        }
    }

    func didChangeMicVolume(_ sender: UISlider) {
        EZOutput.shared().mixerNode.setVolume(sender.value, forBus: 1)
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
			recordingStatusLabel.backgroundColor = stream?.color()
			gradientColorView.backgroundColor = stream?.color().withAlphaComponent(0.66)
		} else {
			recordingStatusLabel.text = "Not Broadcasting"
			recordingStatusLabel.textColor = recordSwitch.onTintColor
			recordingStatusLabel.backgroundColor = RGB(220, g: 221, b: 222)
			gradientColorView.backgroundColor = Constants.UI.Color.off.withAlphaComponent(0.66)
		}
	}

    func updateMetadata(_ song: KZPlayerItem?) {
        guard let socket = self.socket else {
            return
        }

        backgroundQueue.async { () -> Void in
            while socket.status != .connected {
                RunLoop.main.run(mode: RunLoopMode.defaultRunLoopMode, before: Date.distantFuture)
            }

            var params = JSON()
            params["artist"] = song?.artist as AnyObject?
            params["title"] = song?.title as AnyObject?
            params["album"] = song?.album as AnyObject?

            if let artwork = song?.artwork() {
                if let image = artwork.image(at: CGSize(width: self.view.frame.size.width, height: self.view.frame.size.width)) {
                    let data = UIImageJPEGRepresentation(image, 0.2)
                    if let data = data {
                        params["image"] = data.base64EncodedString(options: [])
                    }
                }
            }

            socket.emitWithAck("updateMeta", params).timingOut(after: 15, callback: { (data) in
                print("Socket: Sent Meta")
            })
        }
    }

	/**
	 Updates the controller's views with the correct song info/artwork

	 - parameter song: The song that has started playing
	 */
	func updateCurrentSong(_ song: KZPlayerItem?) {
		updateNowPlayingInfo(song)
        updateMetadata(song)

		if let song = song {
			if let artwork = song.artwork() {
				UIView.transition(with: albumPoster, duration: 0.5, options: .transitionCrossDissolve, animations: { () -> Void in
					self.albumPoster.image = artwork.image(at: CGSize(width: self.albumPoster.frame.width, height: self.albumPoster.frame.width))
                }, completion: nil)
            } else {
                UIView.transition(with: albumPoster, duration: 0.5, options: .transitionCrossDissolve, animations: { () -> Void in
                    self.albumPoster.image = nil
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
	func updateNowPlayingInfo(_ item: KZPlayerItem?) {
		let center = MPNowPlayingInfoCenter.default()

		var dict = [String : Any]()
        dict[MPNowPlayingInfoPropertyPlaybackRate] = NSNumber(value: Double(playbackPaused ? 1.0 : 0.0) as Double)

		if let item = item {
			dict[MPMediaItemPropertyTitle] = item.title as AnyObject?? ?? "" as AnyObject?
			dict[MPMediaItemPropertyArtist] = item.artist as AnyObject?? ?? "" as AnyObject?
			dict[MPMediaItemPropertyAlbumTitle] = item.album as AnyObject?? ?? "" as AnyObject?
			dict[MPMediaItemPropertyArtwork] = item.artwork() ?? MPMediaItemArtwork(image: UIImage())
			dict[MPMediaItemPropertyPlaybackDuration] = item.endTime - item.startTime
		} else {
			dict[MPMediaItemPropertyTitle] = "No Song Playing" as AnyObject?
		}

		center.nowPlayingInfo = dict
	}

    func updateThemeColor(_ color: UIColor) {
        switcherControl.tintColor = color
        if isOnAir() {
            gradientColorView.backgroundColor = color.withAlphaComponent(0.66)
        } else {
            gradientColorView.backgroundColor = Constants.UI.Color.off.withAlphaComponent(0.66)
        }

        [settingsHeaderMeta, settingsHeaderStatus, settingsHeaderPlayback, settingsHeaderMicrophone].forEach({ $0.backgroundColor = color })

        NSObject.cancelPreviousPerformRequests(withTarget: self)
        perform(#selector(didChangeThemeColor), with: color, afterDelay: 1.0)

        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
    }

    func didChangeThemeColor(_ color: UIColor) {
        let hexString = color.hexString
        stream?.colorHex = hexString
        self.updateStream("colorHex", value: hexString as AnyObject)

        guard let socket = self.socket else {
            return
        }

        backgroundQueue.async { () -> Void in
            while socket.status != .connected {
                RunLoop.main.run(mode: RunLoopMode.defaultRunLoopMode, before: Date.distantFuture)
            }

            var params = [String: AnyObject]()
            params["hexString"] = hexString as AnyObject?

            socket.emitWithAck("updateHex", params).timingOut(after: 15, callback: { (data) in
                print("Socket: Sent Color")
            })
        }
    }

	// **********************************************************************
	// **********************************************************************
	// **********************************************************************

	// MARK: TableView Data Source
	override func tableViewCellData(_ tableView: UITableView, section: Int) -> [Any] {
		if tableView == songsTableView {
			return searchResults ?? songs
		} else if tableView == queueTableView {
			return upNextSongs
        } else if tableView == commentsTableView {
            return comments
        }

		return super.tableViewCellData(tableView, section: section)
	}

	override func tableViewCellClass(_ tableView: UITableView, indexPath: IndexPath?) -> KZTableViewCell.Type {
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

	override func tableViewNoDataText(_ tableView: UITableView) -> String {
		if tableView == songsTableView {
			return searchResults != nil ? "No Results" : "No Songs in Library"
		} else if tableView == queueTableView {
			return "No Songs in Queue"
        } else if tableView == commentsTableView {
            return "No Comments\n\nBe the first one to comment :)"
        }

		return super.tableViewNoDataText(tableView)
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = super.tableView(tableView, cellForRowAt: indexPath)

		if let cell = cell as? SelectSongCell {
			cell.defaultColor = RGB(227)
			cell.setSwipeGestureWith(SelectSongCell.viewWithImageName("selectCell_playBT"), color: RGB(85, g: 213, b: 80), mode: .switch, state: .state4, completionBlock: { (cell, state, mode) -> Void in
				if let item = self.tableViewCellData(tableView, section: indexPath.section)[indexPath.row] as? KZPlayerItem {
					self.playSong(item)
				}
			})

			cell.setSwipeGestureWith(SelectSongCell.viewWithImageName("selectCell_addBT"), color: RGB(254, g: 217, b: 56), mode: .switch, state: .state3, completionBlock: { (cell, state, mode) -> Void in
				if let item = self.tableViewCellData(tableView, section: indexPath.section)[indexPath.row] as? KZPlayerItem {
					self.addToUpNext(item)
				}
			})
		}

		if let cell = cell as? UpNextSongCell {
			cell.defaultColor = RGB(227)
			cell.setSwipeGestureWith(SelectSongCell.viewWithImageName("selectCell_removeBT"), color: RGB(232, g: 61, b: 14), mode: .exit, state: .state3, completionBlock: { (cell, state, mode) -> Void in
				if let indexPath = tableView.indexPath(for: cell) {
					self.removeFromUpNext(indexPath)
				}
			})

			cell.setSwipeGestureWith(SelectSongCell.viewWithImageName("selectCell_addBT"), color: RGB(254, g: 217, b: 56), mode: .switch, state: .state4, completionBlock: { (cell, state, mode) -> Void in
				if let indexPath = tableView.indexPath(for: cell) {
					if let item = self.tableViewCellData(tableView, section: indexPath.section)[indexPath.row] as? KZPlayerItem {
						self.addToUpNext(item)
					}
				}
			})
		}

		return cell
	}

	override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		if tableView == songsTableView {
			searchBar.delegate = self
			searchBar.frame.size.height = 44
			searchBar.frame.size.width = tableView.frame.width
			return searchBar
		}

		return super.tableView(tableView, viewForHeaderInSection: section)
	}

	override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		if tableView == songsTableView {
			return 44
		}

		return super.tableView(tableView, heightForHeaderInSection: section)
	}

    func tableView(_ tableView: UITableView, canMoveRowAtIndexPath indexPath: IndexPath) -> Bool {
        return tableView == queueTableView && upNextSongs.count > 1
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAtIndexPath indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .none
    }

    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAtIndexPath indexPath: IndexPath) -> Bool {
        return false
    }

    func tableView(_ tableView: UITableView, moveRowAtIndexPath sourceIndexPath: IndexPath, toIndexPath destinationIndexPath: IndexPath) {
        if tableView == queueTableView {
            let sourceItem = upNextSongs[(sourceIndexPath as IndexPath).row]
            upNextSongs.remove(at: (sourceIndexPath as IndexPath).row)
            upNextSongs.insert(sourceItem, at: (destinationIndexPath as IndexPath).row)
            tableView.reloadData()
        }
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

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if self.tableViewCellData(tableView, section: indexPath.section).count > 0 {
            return UITableViewAutomaticDimension
        } else {
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
    }

	// MARK: UISearchBar Delegate
	func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
		searchBar.setShowsCancelButton(true, animated: true)
	}

	func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
		searchResults = [Any]()
		songsTableView.reloadData()

		searchResults = songs.filter({ (song) -> Bool in
			if let song = song as? KZPlayerItem {
				return song.aggregateText().lowercased().contains(searchText.lowercased())
			}

			return false
		})

		songsTableView.reloadData()
	}

	func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
		searchResults = nil
		searchBar.text = ""
		searchBar.resignFirstResponder()
		searchBar.setShowsCancelButton(false, animated: true)
		songsTableView.reloadData()
	}

	func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
		searchBar.resignFirstResponder()
	}

    // MARK: UITextView Delegate
    func textViewDidEndEditing(_ textView: UITextView) {
        guard let text = textView.text else {
            return
        }

        guard text.characters.count > 0 else {
            return
        }

        if textView == metaDescriptionField {
            updateStream("description", value: text as AnyObject)
        }
    }

    // MARK: UITextField Delegate

    func textFieldDidEndEditing(_ textField: UITextField) {
        textFieldShouldReturn(textField)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let text = textField.text else {
            return false
        }

        guard text.characters.count > 0 else {
            return false
        }

        if textField == metaNameField {
            updateStream("name", value: text as AnyObject)
        }

        textField.resignFirstResponder()
        return false
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

    func updateStream(_ property: String, value: AnyObject) {
        guard let stream = stream else {
            return
        }

        Constants.Network.POST("/stream/\(stream.id)/update/\(property)", parameters: ["value": value]) { (response, error) in
            self.handleResponse(response as AnyObject?, error: error as NSError?)
        }
    }

    func changePicture() {
        guard let stream = stream else {
            return
        }

        let vc = CameraViewController(croppingEnabled: true) { image in
            self.dismiss(animated: true, completion: nil)
            guard let image = image.0 else {
                return
            }

            guard let imageData = UIImagePNGRepresentation(resizeImage(image, newWidth: 200)) else {
                return
            }

            self.metaPictureButton.image = image

            let progressView = M13ProgressViewRing()
            progressView.primaryColor = RGB(255)
            progressView.secondaryColor = Constants.UI.Color.disabled

            let hud = M13ProgressHUD(progressView: progressView)
            if let window = AppDelegate.del().window {
                hud?.frame = window.bounds
            }
            hud?.progressViewSize = CGSize(width: 60, height: 60)
            hud?.animationPoint = CGPoint(x: (hud?.frame.size.width)! / 2, y: (hud?.frame.size.height)! / 2)
            hud?.status = "Uploading Image"
            hud?.applyBlurToBackground = true
            hud?.maskType = M13ProgressHUDMaskTypeIOS7Blur
            AppDelegate.del().window?.addSubview(hud!)
            hud?.show(true)

            Constants.Network.UPLOAD("/stream/\(stream.id)/upload/picture", data: imageData, progressHandler: { (progress) in
                hud?.setProgress(CGFloat(progress), animated: true)
                }, completionHandler: { (response, error) in
                    hud?.hide(true)
                    self.handleResponse(response as AnyObject?, error: error as NSError?)
            })
        }

        present(vc, animated: true, completion: nil)
    }
}

//**********************************************************************
//**********************************************************************
//**********************************************************************

// MARK: Comment Updates
extension HostViewController: MessageToolbarDelegate {

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
                didUpdateComments(shouldScrollDown)
            }
        }
    }

    func didReciveUserJoined(_ response: AnyObject) {
        if let result = response as? JSON {
            if let item = STMTimelineItem(json: result) {
                let isAtBottom = commentsTableView.indexPathsForVisibleRows?.contains(where: { ($0 as IndexPath).row == (comments.count - 1) })
                let shouldScrollDown = didPostComment || (isAtBottom ?? false)
                comments.append(item)
                didUpdateComments(shouldScrollDown)
            }
        }
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
                    self.commentsTableView.reloadData()
                    self.commentsTableView.scrollToBottom(false)
                }
            })
        })
    }

	func fetchData(_ scrollToBottom: Bool) {
	}
}

//**********************************************************************
//**********************************************************************
//**********************************************************************

// MARK: Initialize Stream
extension HostViewController {

    /**
     Creates a stream with the given attributes

     - parameter type:        Wether the user is doing a global or local stream
     - parameter name:        The name the user picked for the stream
     - parameter passcode:    The associated passcode the user typed in
     - parameter description: The description the user gave to the stream
     - parameter callback:    Any error or nil if there was none
     */
	func start(_ type: STMStreamType, name: String, passcode: String, description: String, callback: @escaping (Bool, String?) -> Void) {
		let progressView = M13ProgressViewRing()
		progressView.primaryColor = Constants.UI.Color.tint
		progressView.secondaryColor = Constants.UI.Color.disabled
		progressView.indeterminate = true

		hud = M13ProgressHUD(progressView: progressView)
		if let hud = hud {
			hud.frame = (AppDelegate.del().window?.bounds)!
			hud.progressViewSize = CGSize(width: 60, height: 60)
			hud.animationPoint = CGPoint(x: UIScreen.main.bounds.size.width / 2, y: UIScreen.main.bounds.size.height / 2)
			hud.status = "Setting Up Stream"
			hud.applyBlurToBackground = true
			hud.maskType = M13ProgressHUDMaskTypeIOS7Blur
			AppDelegate.del().window?.addSubview(hud)
			hud.show(true)
		}

        Constants.Network.POST("/stream/create", parameters: ["name": name, "type": type.rawValue, "description": description], completionHandler: { (response, error) -> Void in
            self.handleResponse(response as AnyObject?, error: error as NSError?, successCompletion: { (result) -> Void in
                if let result = result as? JSON {
                    if let stream = STMStream(json: result) {
                        self.stream = stream
                        callback(true, nil)
                        self.toggleAudioSession()
                        self.connectGlobalStream()

                        Answers.logCustomEvent(withName: "Created Stream", customAttributes: [:])
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

    /**
     Continues an existing stream

     - parameter stream:   The stream to continue
     - parameter callback: Any error or nil if there was none
     */
	func start(_ stream: STMStream, callback: @escaping (Bool, String?) -> Void) {
		let progressView = M13ProgressViewRing()
		progressView.primaryColor = Constants.UI.Color.tint
		progressView.secondaryColor = Constants.UI.Color.disabled
		progressView.indeterminate = true

		hud = M13ProgressHUD(progressView: progressView)
		if let hud = hud {
			hud.frame = (AppDelegate.del().window?.bounds)!
			hud.progressViewSize = CGSize(width: 60, height: 60)
			hud.animationPoint = CGPoint(x: UIScreen.main.bounds.size.width / 2, y: UIScreen.main.bounds.size.height / 2)
			hud.status = "Starting Stream"
			hud.applyBlurToBackground = true
			hud.maskType = M13ProgressHUDMaskTypeIOS7Blur
			AppDelegate.del().window?.addSubview(hud)
			hud.show(true)
		}

        func dismiss() {
            if let hud = self.hud {
                hud.dismiss(true)
            }

            self.close()
        }

		Constants.Network.POST("/stream/\(stream.id)/continue", parameters: nil, completionHandler: { (response, error) -> Void in
			self.handleResponse(response as AnyObject?, error: error as NSError?, successCompletion: { (result) -> Void in
                guard let result = result as? JSON else {
                    return dismiss()
                }

                guard let stream = STMStream(json: result) else {
                    return dismiss()
                }

                self.stream = stream

                self.toggleAudioSession()
                self.connectGlobalStream()
                self.loadLibrary()
                callback(true, nil)
                Answers.logCustomEvent(withName: "Continued Stream", customAttributes: [:])

				}, errorCompletion: { (error) -> Void in
                    dismiss()
                    callback(false, error)
			})
		})
	}
}

//**********************************************************************
//**********************************************************************
//**********************************************************************

// MARK: Audio Data
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

        guard let baseURL = URL(string: Constants.Config.apiBaseURL) else {
            return
        }

        let oForcePolling = SocketIOClientOption.forcePolling(true)
        let oHost = SocketIOClientOption.nsp("/host")
        let streamQueue = SocketIOClientOption.handleQueue(backgroundQueue)
        let oAuth = SocketIOClientOption.connectParams(["streamID": stream.id, "securityHash": securityHash, "userID": user.id, "stmHash": Constants.Config.streamHash])
        let oLog = SocketIOClientOption.log(false)
        let oForceNew = SocketIOClientOption.forceNew(true)
        let options = SocketIOClientConfiguration(arrayLiteral: oForcePolling, oHost, oAuth, streamQueue, oForceNew)

        self.socket = SocketIOClient(socketURL: baseURL, config: options)
        if let socket = self.socket {
            socket.on("connect") { data, ack in
                print("Stream: Socket Connected")
                self.updateThemeColor(stream.color())
            }

            socket.connect()
        }

        let commentHost = SocketIOClientOption.nsp("/comment")
        let commentOptions = SocketIOClientConfiguration(arrayLiteral: oForcePolling, commentHost, oAuth, oLog, oForceNew)
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

            socket.connect()
        }
	}

	func loadLibrary() {
		EZOutput.shared().aacEncode = true
        AppDelegate.del().setUpAudioSession(true)

        if #available(iOS 9.3, *) {
            MPMediaLibrary.requestAuthorization { (status) in
                if status == .authorized {
                    DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.low).async {
                        self.songs.removeAll()
                        let predicate1 = MPMediaPropertyPredicate(value: MPMediaType.anyAudio.rawValue, forProperty: MPMediaItemPropertyMediaType)
                        let predicate12 = MPMediaPropertyPredicate(value: 0, forProperty: MPMediaItemPropertyIsCloudItem)
                        let query = MPMediaQuery(filterPredicates: [predicate1, predicate12])
                        var songs = [Any]()
                        if let items = query.items {
                            for item in items {
                                let newItem = KZPlayerItem(item: item)
                                if newItem.assetURL.characters.count > 0 {
                                    songs.append(newItem)
                                }
                            }
                        }

                        DispatchQueue.main.async(execute: {
                            self.songs = songs
                            self.songsTableView.reloadData()
                        })
                    }
                }
            }
        } else {
            DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.low).async {
                self.songs.removeAll()
                let predicate1 = MPMediaPropertyPredicate(value: MPMediaType.anyAudio.rawValue, forProperty: MPMediaItemPropertyMediaType)
                let predicate12 = MPMediaPropertyPredicate(value: 0, forProperty: MPMediaItemPropertyIsCloudItem)
                let query = MPMediaQuery(filterPredicates: [predicate1, predicate12])
                var songs = [Any]()
                if let items = query.items {
                    for item in items {
                        let newItem = KZPlayerItem(item: item)
                        if newItem.assetURL.characters.count > 0 {
                            songs.append(newItem)
                        }
                    }
                }

                DispatchQueue.main.async(execute: {
                    self.songs = songs
                    self.songsTableView.reloadData()
                })
            }
        }

		EZOutput.shared().outputDataSource = self
		EZOutput.shared().mixerNode.setVolume(0.0, forBus: 1)
		EZOutput.shared().startPlayback()
		EZOutput.shared().inputMonitoring = true
	}

	/**
	 Start the AVAudioSession and add the remote commands
	 */
    func toggleAudioSession(_ enabled: Bool = true) {
        if enabled {
            MPRemoteCommandCenter.shared().playCommand.addTarget(self, action: #selector(HostViewController.play))
            MPRemoteCommandCenter.shared().pauseCommand.addTarget(self, action: #selector(HostViewController.stop))
            MPRemoteCommandCenter.shared().nextTrackCommand.addTarget(self, action: #selector(getter: HostViewController.next))
        }

		MPRemoteCommandCenter.shared().pauseCommand.isEnabled = enabled
		MPRemoteCommandCenter.shared().nextTrackCommand.isEnabled = enabled
		MPRemoteCommandCenter.shared().previousTrackCommand.isEnabled = enabled
	}

	func output(_ output: EZOutput!, shouldFill audioBufferList: UnsafeMutablePointer<AudioBufferList>, withNumberOfFrames frames: UInt32) {
        func reset() {
            memset(audioBufferList.pointee.mBuffers.mData, 0, Int(audioBufferList.pointee.mBuffers.mDataByteSize))
        }

		if !playbackPaused {
			if let audioFile0 = audioFile0 {
				var bufferSize = UInt32()
				var eof = ObjCBool(false)
				audioFile0.readFrames(frames, audioBufferList: audioBufferList, bufferSize: &bufferSize, eof: &eof)
				if eof.boolValue && !playbackReachedEnd && audioFile1 == nil {
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

	func output(_ output: EZOutput!, shouldFillAudioBufferList2 audioBufferList: UnsafeMutablePointer<AudioBufferList>, withNumberOfFrames frames: UInt32) {
		if !playbackPaused {
			if let audioFile1 = audioFile1 {
				var bufferSize = UInt32()
				var eof = ObjCBool(false)
				audioFile1.readFrames(frames, audioBufferList: audioBufferList, bufferSize: &bufferSize, eof: &eof)
				if eof.boolValue && !playbackReachedEnd && audioFile0 == nil {
					self.audioFile1 = nil
					self.next()
				} else if upNextSongs.count > 0 && audioFile0 == nil && (audioFile1.totalDuration() - audioFile1.duration()) < settings.crossfadeDuration {
					self.next()
				}
			} else {
				memset(audioBufferList.pointee.mBuffers.mData, 0, Int(audioBufferList.pointee.mBuffers.mDataByteSize))
			}
		}
	}

	func playedData(_ buffer: Data!, frames: Int32) {
		let data = NSData(data: buffer) as Data

		guard isOnAir() else {
			return
		}

		guard let socket = self.socket else {
			return
		}

		guard socket.status == .connected else {
			return
		}

		backgroundQueue.async { () -> Void in
			var params = [String: AnyObject]()
			params["data"] = data.base64EncodedString(options: NSData.Base64EncodingOptions()) as AnyObject?
			params["time"] = Date().timeIntervalSince1970 as AnyObject?
			socket.emitWithAck("dataForStream", params).timingOut(after: 15, callback: { (data) in

				guard let response = data[0] as? [String: AnyObject] else {
                    return
                }

                if let bytes = response["bytes"] as? Float {
                    self.statsPacketsReceived += bytes
                }

                if let listeners = response["listeners"] as? Int {
                    self.statsNumberOfListeners = listeners
                }
			})
		}
	}

	func updateMicLevel(_ level: Float) {
		if let con = micIndicatorWidthConstraint {
			con.constant = micIndicatorGradientView.frame.width * CGFloat(level)
			micIndicatorView.layoutIfNeeded()
		}
	}

	func heightForVisualizer() -> CGFloat {
		return visualizer.frame.size.height
	}

	func setBarHeight(_ barIndex: Int32, height: CGFloat) {
		self.visualizer.setBarHeight(Int(barIndex), height: height)
	}
}

//**********************************************************************
//**********************************************************************
//**********************************************************************

// MARK: Audio Playback
extension HostViewController: EZAudioFileDelegate {
	func play() {
        EZOutput.shared().startPlayback()
        setPaused(false)
        toggleAudioSession(true)
        MPRemoteCommandCenter.shared().pauseCommand.isEnabled = true
	}

    func stop() {
        EZOutput.shared().stopPlayback()
        setPaused(true)
        toggleAudioSession(false)
        MPRemoteCommandCenter.shared().playCommand.isEnabled = true
    }

	func pause() {
        setPaused(true)
	}

	func isOnAir() -> Bool {
		return recordSwitch.isOn
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
			DispatchQueue.main.async(execute: { () -> Void in
				self.didReachEndOfQueue()
			})
			playbackReachedEnd = true
            MPRemoteCommandCenter.shared().nextTrackCommand.isEnabled = false

			audioFile0 = nil
			audioFile1 = nil
		}
	}

	func playSong(_ song: KZPlayerItem) -> Bool {
		let assetURL = song.fileURL()
		if EZOutput.shared().activePlayer == 1 {
			audioFile0 = EZAudioFile(url: assetURL, andDelegate: self)
			EZOutput.shared().setActivePlayer(0, withCrossfadeDuration: settings.crossfadeDuration)
		} else {
			audioFile1 = EZAudioFile(url: assetURL, andDelegate: self)
			EZOutput.shared().setActivePlayer(1, withCrossfadeDuration: settings.crossfadeDuration)
		}

		DispatchQueue.main.async(execute: { () -> Void in
			self.updateCurrentSong(song)
		})
		playbackReachedEnd = false
		return true
	}

	func finishedCrossfade() {
		if EZOutput.shared().activePlayer == 0 {
			audioFile1 = nil
		} else {
			audioFile0 = nil
		}
	}

	func addToUpNext(_ item: KZPlayerItem) {
		if playbackReachedEnd {
			playSong(item)
		} else {
			upNextSongs.append(item)
			updateUpNext()
		}
	}

	func removeFromUpNext(_ indexPath: IndexPath) {
		upNextSongs.remove(at: indexPath.row)
		updateUpNext()
	}

	func popUpNext() -> KZPlayerItem? {
		var x: KZPlayerItem?
		if upNextSongs.count > 0 {
			if let item = upNextSongs.first as? KZPlayerItem {
				x = item
				upNextSongs.remove(at: 0)
				updateUpNext()
			}
		}

		return x
	}

	func updateUpNext() {
		DispatchQueue.main.async { () -> Void in
			self.queueTableView.reloadSections(IndexSet(integer: 0), with: .fade)

            MPRemoteCommandCenter.shared().nextTrackCommand.isEnabled = (self.upNextSongs.count > 0)
		}
	}

	func didReachEndOfQueue() {
		AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
		updateCurrentSong(nil)
	}
}
