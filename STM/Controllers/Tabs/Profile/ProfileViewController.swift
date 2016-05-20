//
//  ProfileViewController.swift
//  STM
//
//  Created by Kesi Maduka on 4/27/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import Foundation
import DGElasticPullToRefresh
import NYSegmentedControl
import M13ProgressSuite

class ProfileViewController: KZViewController, UIViewControllerPreviewingDelegate {

    let headerView = UIView()
    let avatarImageView = UIImageView()
    let displayNameLabel = UILabel()
    let descriptionLabel = UILabel()
    let rightSideHolder = UIView()
    let leftSideHolder = UIView()
    let followButton = UIButton()
    let messageButton = UIButton()

    let commentsStatView = ProfileStatView(count: 0, name: "COMMENTS")
    let followersStatView = ProfileStatView(count: 0, name: "FOLLOWERS")
    let followingStatView = ProfileStatView(count: 0, name: "FOLLOWING")

    let segmentControl = NYSegmentedControl(items: ["Timeline", "Streams", "Likes"])

    let tableView = KZIntrinsicTableView()

    var user: STMUser
    let isOwner: Bool

    var comments = [Any]()
    var streams = [Any]()
    var likes = [Any]()

    init(user: STMUser, isOwner: Bool = false) {
        self.user = user
        self.isOwner = isOwner
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        tableView.dg_removePullToRefresh()
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        headerView.backgroundColor = RGB(122, g: 86, b: 229, a: 255)

        self.navigationItem.title = isOwner ? "My Profile (@\(user.username))" : "@\(user.username)"
        self.automaticallyAdjustsScrollViewInsets = false
        if isOwner {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: .Plain, target: self, action: #selector(self.editProfile))
        }

        avatarImageView.layer.cornerRadius = 140.0 / 9.0
        avatarImageView.backgroundColor = Constants.UI.Color.imageViewDefault
        avatarImageView.clipsToBounds = true
        headerView.addSubview(avatarImageView)

        displayNameLabel.font = UIFont.systemFontOfSize(19, weight: UIFontWeightBold)
        displayNameLabel.text = user.displayName
        displayNameLabel.textColor = RGB(255)
        headerView.addSubview(displayNameLabel)

        descriptionLabel.text = user.description
        descriptionLabel.numberOfLines = 0
        descriptionLabel.font = UIFont.systemFontOfSize(13)
        descriptionLabel.textAlignment = .Center
        descriptionLabel.textColor = RGB(255)
        headerView.addSubview(descriptionLabel)

        followButton.addTarget(self, action: #selector(self.toggleFollow), forControlEvents: .TouchUpInside)
        followButton.setImage(UIImage(named: "profileFollowButton"), forState: .Normal)
        followButton.setImage(UIImage(named: "profileUnfollowButton"), forState: .Selected)
        followButton.enabled = !isOwner
        followButton.selected = user.isFollowing
        if isOwner {
            followButton.alpha = 0.4
        }
        rightSideHolder.addSubview(followButton)
        headerView.addSubview(rightSideHolder)

        messageButton.addTarget(self, action: #selector(self.messageUser), forControlEvents: .TouchUpInside)
        messageButton.setImage(UIImage(named: "profileMessageButton"), forState: .Normal)
        messageButton.enabled = !isOwner
        if isOwner {
            messageButton.alpha = 0.4
        }
        leftSideHolder.addSubview(messageButton)
        headerView.addSubview(leftSideHolder)

        segmentControl.titleTextColor = Constants.UI.Color.tint
        segmentControl.selectedTitleTextColor = RGB(255)
        segmentControl.selectedTitleFont = UIFont.systemFontOfSize(15)
        segmentControl.segmentIndicatorBackgroundColor = headerView.backgroundColor
        segmentControl.backgroundColor = RGB(255)
        segmentControl.borderWidth = 0.0
        segmentControl.segmentIndicatorBorderWidth = 0.0
        segmentControl.segmentIndicatorInset = 2.0
        segmentControl.segmentIndicatorBorderColor = self.view.backgroundColor
        segmentControl.usesSpringAnimations = true
        segmentControl.addTarget(self, action: #selector(self.segmentDidChange), forControlEvents: .ValueChanged)

        let tap1 = UITapGestureRecognizer(target: self, action: #selector(viewUserFollowing))
        followingStatView.addGestureRecognizer(tap1)
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(viewUserFollowers))
        followersStatView.addGestureRecognizer(tap2)
        [commentsStatView, followersStatView, followingStatView, segmentControl].forEach({ headerView.addSubview($0) })

        tableView.delegate = self
        tableView.dataSource = self
        tableView.showsVerticalScrollIndicator = false
        tableView.backgroundColor = RGB(250, g: 251, b: 252)
        tableView.tableHeaderView = headerView
        tableView.registerReusableCell(UserCommentCell)
        tableView.registerReusableCell(SearchStreamCell)
        view.addSubview(tableView)

        registerForPreviewingWithDelegate(self, sourceView: tableView)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.fetchData), name: Constants.Notification.UpdateUserProfile, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.fetchData), name: Constants.Notification.DidLikeComment, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.fetchData), name: Constants.Notification.DidRepostComment, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.fetchData), name: Constants.Notification.DidPostComment, object: nil)

        let loadingView = DGElasticPullToRefreshLoadingViewCircle()
        loadingView.tintColor = Constants.UI.Color.tint

        tableView.dg_addPullToRefreshWithActionHandler({ [weak self] () -> Void in
            if let me = self {
                me.fetchDataWithCompletion() {
                    me.tableView.dg_stopLoading()
                }
            }
            }, loadingView: loadingView)
        tableView.dg_setPullToRefreshFillColor(RGB(255))
        tableView.dg_setPullToRefreshBackgroundColor(RGB(122, g: 86, b: 229, a: 255))
        fetchData()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        if isOwner {
            if let cUser = AppDelegate.del().currentUser {
                user = cUser
            }
        }

        segmentControl.cornerRadius = segmentControl.frame.size.height/2.0
        avatarImageView.kf_setImageWithURL(user.profilePictureURL(), placeholderImage: UIImage(named: "defaultProfilePicture"))
        displayNameLabel.text = user.displayName
        descriptionLabel.text = user.description

        if let headerView = tableView.tableHeaderView {
            let height = headerView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
            var headerFrame = headerView.frame

            if height != headerFrame.size.height {
                headerFrame.size.height = height
                headerView.frame = headerFrame
                tableView.tableHeaderView = headerView
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if let headerView = tableView.tableHeaderView {
            let height = headerView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
            var headerFrame = headerView.frame

            if height != headerFrame.size.height {
                headerFrame.size.height = height
                headerView.frame = headerFrame
                tableView.tableHeaderView = headerView
            }
        }

        descriptionLabel.preferredMaxLayoutWidth = 250
    }

    override func setupConstraints() {
        super.setupConstraints()

        tableView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero, excludingEdge: .Bottom)
        tableView.autoPinToBottomLayoutGuideOfViewController(self, withInset: 0)

        avatarImageView.autoPinEdgeToSuperviewEdge(.Top, withInset: 20)
        avatarImageView.autoAlignAxisToSuperviewAxis(.Vertical)
        NSLayoutConstraint.autoSetPriority(999) {
            self.avatarImageView.autoSetDimensionsToSize(CGSize(width: 140, height: 140))
        }

        leftSideHolder.autoAlignAxis(.Horizontal, toSameAxisOfView: avatarImageView)
        leftSideHolder.autoMatchDimension(.Height, toDimension: .Height, ofView: avatarImageView)
        leftSideHolder.autoPinEdge(.Right, toEdge: .Left, ofView: avatarImageView)
        leftSideHolder.autoPinEdgeToSuperviewEdge(.Left)

        messageButton.autoSetDimensionsToSize(CGSize(width: 70, height: 70))
        messageButton.autoAlignAxisToSuperviewAxis(.Horizontal)
        messageButton.autoAlignAxisToSuperviewAxis(.Vertical)

        rightSideHolder.autoAlignAxis(.Horizontal, toSameAxisOfView: avatarImageView)
        rightSideHolder.autoMatchDimension(.Height, toDimension: .Height, ofView: avatarImageView)
        rightSideHolder.autoPinEdge(.Left, toEdge: .Right, ofView: avatarImageView)
        rightSideHolder.autoPinEdgeToSuperviewEdge(.Right)

        followButton.autoSetDimensionsToSize(CGSize(width: 70, height: 70))
        followButton.autoAlignAxisToSuperviewAxis(.Horizontal)
        followButton.autoAlignAxisToSuperviewAxis(.Vertical)

        displayNameLabel.autoPinEdge(.Top, toEdge: .Bottom, ofView: avatarImageView, withOffset: 15)
        displayNameLabel.autoSetDimension(.Width, toSize: 250, relation: .LessThanOrEqual)
        displayNameLabel.autoAlignAxisToSuperviewAxis(.Vertical)

        descriptionLabel.autoPinEdge(.Top, toEdge: .Bottom, ofView: displayNameLabel, withOffset: 10)
        descriptionLabel.autoSetDimension(.Width, toSize: 250, relation: .LessThanOrEqual)
        descriptionLabel.autoAlignAxisToSuperviewAxis(.Vertical)

        NSLayoutConstraint.autoSetPriority(999) {
            self.commentsStatView.autoPinEdge(.Top, toEdge: .Bottom, ofView: self.descriptionLabel, withOffset: 15)
        }
        commentsStatView.autoPinEdgeToSuperviewEdge(.Left)

        followersStatView.autoPinEdge(.Top, toEdge: .Bottom, ofView: descriptionLabel, withOffset: 15)
        followersStatView.autoPinEdge(.Left, toEdge: .Right, ofView: commentsStatView)
        followersStatView.autoMatchDimension(.Width, toDimension: .Width, ofView: commentsStatView)

        followingStatView.autoPinEdge(.Top, toEdge: .Bottom, ofView: descriptionLabel, withOffset: 15)
        followingStatView.autoPinEdge(.Left, toEdge: .Right, ofView: followersStatView)
        followingStatView.autoMatchDimension(.Width, toDimension: .Width, ofView: commentsStatView)
        followingStatView.autoPinEdgeToSuperviewEdge(.Right)

        segmentControl.autoPinEdge(.Top, toEdge: .Bottom, ofView: commentsStatView, withOffset: 20)
        segmentControl.autoPinEdgeToSuperviewEdge(.Bottom, withInset: 10)
        segmentControl.autoPinEdgeToSuperviewEdge(.Left, withInset: 10)

        NSLayoutConstraint.autoSetPriority(999) {
            self.segmentControl.autoPinEdgeToSuperviewEdge(.Right, withInset: 10)
        }
    }

    func segmentDidChange() {
        self.tableView.reloadData()
    }

    //MARK: Table View Delegate

    override func tableViewCellClass(tableView: UITableView, indexPath: NSIndexPath?) -> KZTableViewCell.Type {
        switch segmentControl.selectedSegmentIndex {
        case 0:
            return UserCommentCell.self
        case 1:
            return SearchStreamCell.self
        case 2:
            return UserCommentCell.self
        default:
            return UserCommentCell.self
        }
    }

    override func tableViewCellData(tableView: UITableView, section: Int) -> [Any] {
        switch segmentControl.selectedSegmentIndex {
        case 0:
            return comments
        case 1:
            return streams
        case 2:
            return likes
        default:
             return []
        }
    }

    override func tableViewNoDataText(tableView: UITableView) -> String {
        switch segmentControl.selectedSegmentIndex {
        case 0:
            return isOwner ? "You haven't posted anything :(" : "This user hasn't posted anything"
        case 1:
            return isOwner ? "You haven't created a stream :(" : "This user has no streams"
        case 2:
            return isOwner ? "You haven't liked anything :(" : "This user hasn't liked anything"
        default:
            return "No Results Found"
        }
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if tableViewCellData(tableView, section: indexPath.section).count == 0 {
            return 100
        }

        return UITableViewAutomaticDimension
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        super.tableView(tableView, didSelectRowAtIndexPath: indexPath)

        guard self.tableViewCellData(tableView, section: indexPath.section).count > 0 else {
            return
        }

        let model = self.tableViewCellData(tableView, section: indexPath.section)[indexPath.row]

        if let comment = model as? STMComment {
            let vc = CommentViewController(comment: comment)
            self.navigationController?.pushViewController(vc, animated: true)
        } else if let stream = model as? STMStream {
            if AppDelegate.del().activeStreamController is HostViewController {
                if let activeVC = AppDelegate.del().topViewController() {
                    return activeVC.showError("You must close out of the stream you are currently hosting before you can listen to a different one")
                }
            }

            let vc = PlayerViewController()
            vc.start(stream, vc: self, showHUD: true, callback: { (success, error) in
                if error == nil {
                    AppDelegate.del().presentStreamController(vc)
                }
            })
        }
    }

    //MARK: UIViewController Previewing Delegate

    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = tableView.indexPathForRowAtPoint(location), cell = tableView.cellForRowAtIndexPath(indexPath) else {
            return nil
        }

        guard self.tableViewCellData(tableView, section: indexPath.section).count > 0 else {
            return nil
        }

        var vc: UIViewController?
        previewingContext.sourceRect = cell.frame

        let model = self.tableViewCellData(tableView, section: indexPath.section)[indexPath.row]

        if let comment = model as? STMComment {
            vc = CommentViewController(comment: comment)
        } else if let stream = model as? STMStream {
            guard AppDelegate.del().activeStreamController == nil else {
                return nil
            }

            let pVC = PlayerViewController()
            pVC.isPreviewing = true
            pVC.start(stream, vc: self, showHUD: false)
            vc = pVC
        }

        if let vc = vc {
            vc.preferredContentSize = CGSize(width: 0.0, height: 0.0)
        }

        return vc
    }

    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        if let vc = viewControllerToCommit as? PlayerViewController {
            vc.isPreviewing = false
            AppDelegate.del().presentStreamController(vc)
        } else {
            self.navigationController?.pushViewController(viewControllerToCommit, animated: true)
        }
    }

    override func fetchData() {
        fetchDataWithCompletion(nil)
    }

    func fetchDataWithCompletion(completion: (() -> Void)?) {
        var count = 0

        func runCompletion() {
            count = count - count
            if count == 0 {
                if let completion = completion {
                    completion()
                }
            }
        }

        count = count + 1
        Constants.Network.GET("/user/\(user.id)/stats", parameters: nil) { (response, error) -> Void in
            self.handleResponse(response, error: error, successCompletion: { (result) -> Void in
                if let followers = result["followers"] as? Int {
                    self.followersStatView.count = followers
                }

                if let following = result["following"] as? Int {
                     self.followingStatView.count = following
                }

                if let comments = result["comments"] as? Int {
                    self.commentsStatView.count = comments
                }

                if let isFollowing = result["isFollowing"] as? Bool {
                    self.followButton.selected = isFollowing
                }
            })

            runCompletion()
        }

        count = count + 1
        Constants.Network.GET("/user/\(user.id)/comments", parameters: nil) { (response, error) -> Void in
            self.handleResponse(response, error: error, successCompletion: { (result) -> Void in
                self.comments.removeAll()

                guard let results = result as? [JSON] else {
                    return
                }

                let comments = [STMComment].fromJSONArray(results)
                comments.forEach({ self.comments.append($0) })

                if self.segmentControl.selectedSegmentIndex == 0 {
                    self.tableView.reloadData()
                }
            })

            runCompletion()
        }

        count = count + 1
        Constants.Network.GET("/user/\(user.id)/streams", parameters: nil) { (response, error) -> Void in
            self.handleResponse(response, error: error, successCompletion: { (result) -> Void in
                self.streams.removeAll()
                if let result = result as? [JSON] {
                    let streams = [STMStream].fromJSONArray(result)
                    streams.forEach({ self.streams.append($0) })

                    if self.segmentControl.selectedSegmentIndex == 1 {
                        self.tableView.reloadData()
                    }
                }
            })

            runCompletion()
        }

        count = count + 1
        Constants.Network.GET("/user/\(user.id)/likes", parameters: nil) { (response, error) -> Void in
            self.handleResponse(response, error: error, successCompletion: { (result) -> Void in
                self.likes.removeAll()
                if let result = result as? [JSON] {
                    let likes = [STMComment].fromJSONArray(result)
                    likes.forEach({ self.likes.append($0) })

                    if self.segmentControl.selectedSegmentIndex == 2 {
                        self.tableView.reloadData()
                    }
                }
            })

            runCompletion()
        }
    }

    func editProfile() {
        let vc = ProfileSettingsViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }

    func toggleFollow() {
        let method = followButton.selected ? "unfollow" : "follow"
        UIView.transitionWithView(self.followButton, duration: 0.2, options: .TransitionCrossDissolve, animations: {
            self.followButton.selected = !self.followButton.selected
        }, completion: nil)
        Constants.Network.GET("/user/\(user.id)/\(method)", parameters: nil) { (response, error) in
            dispatch_async(dispatch_get_main_queue(), {
                NSNotificationCenter.defaultCenter().postNotificationName(Constants.Notification.UpdateUserProfile, object: nil)
            })
        }
    }

    func messageUser() {
        guard let tabVC = self.navigationController?.tabBarController else {
            return
        }

        guard let navVC = tabVC.viewControllers?[2] as? NavigationController else {
            return
        }

        guard let vc = navVC.viewControllers[0] as? MessagesViewController else {
            return
        }

        var singleConvo: STMConversation?

        for convo in vc.convos {
            if let convo = convo as? STMConversation {
                if let users = convo.users {
                    if users.count == 2 && users.contains({ $0.id == user.id }) {
                        singleConvo = convo
                    }
                }
            }
        }

        if let singleConvo = singleConvo {
            let vc = ConversationViewController(convo: singleConvo)
            self.navigationController?.pushViewController(vc, animated: true)
        } else {
            createConvo()
        }
    }

    func createConvo() {
        guard let currentUser = AppDelegate.del().currentUser else {
            return
        }

        let progressView = M13ProgressViewRing()
        progressView.primaryColor = RGB(255)
        progressView.secondaryColor = Constants.UI.Color.disabled
        progressView.indeterminate = true

        let hud = M13ProgressHUD(progressView: progressView)
        if let window = AppDelegate.del().window {
            hud.frame = window.bounds
            window.addSubview(hud)
        }
        hud.progressViewSize = CGSize(width: 60, height: 60)
        hud.animationPoint = CGPoint(x: hud.frame.size.width / 2, y: hud.frame.size.height / 2)
        hud.applyBlurToBackground = true
        hud.maskType = M13ProgressHUDMaskTypeIOS7Blur
        hud.show(true)

        let nav = self.navigationController
        Constants.Network.POST("/conversation/create", parameters: ["users": [user.id, currentUser.id]], completionHandler: { (response, error) -> Void in
            self.handleResponse(response, error: error, successCompletion: { (result) in
                guard let result = result as? JSON else {
                    return
                }

                guard let convo = STMConversation(json: result) else {
                    return
                }

                let vc = ConversationViewController(convo: convo)
                nav?.pushViewController(vc, animated: false)

                hud.hide(true)
                }, errorCompletion: { (errorString) in
                    hud.hide(true)
            })
        })
    }

    func viewUserFollowing() {
        let vc = ProfileStatsListViewController(user: user, type: .Following)
        self.navigationController?.pushViewController(vc, animated: true)
    }

    func viewUserFollowers() {
        let vc = ProfileStatsListViewController(user: user, type: .Followers)
        self.navigationController?.pushViewController(vc, animated: true)
    }

}
