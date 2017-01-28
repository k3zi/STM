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
    var descriptionLabelPadding: NSLayoutConstraint?
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
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if isOwner {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(self.editProfile))

            followButton.isHidden = true
            messageButton.isHidden = true
        }

        headerView.backgroundColor = RGB(122, g: 86, b: 229, a: 255)

        self.automaticallyAdjustsScrollViewInsets = true

        avatarImageView.layer.cornerRadius = 140.0 / 9.0
        avatarImageView.backgroundColor = Constants.UI.Color.imageViewDefault
        avatarImageView.clipsToBounds = true
        headerView.addSubview(avatarImageView)

        displayNameLabel.font = UIFont.systemFont(ofSize: 19, weight: UIFontWeightBold)
        displayNameLabel.textColor = RGB(255)
        headerView.addSubview(displayNameLabel)

        descriptionLabel.numberOfLines = 0
        descriptionLabel.font = UIFont.systemFont(ofSize: 13)
        descriptionLabel.textAlignment = .center
        descriptionLabel.textColor = RGB(255)
        headerView.addSubview(descriptionLabel)

        followButton.addTarget(self, action: #selector(self.toggleFollow), for: .touchUpInside)
        followButton.setImage(UIImage(named: "profileFollowButton"), for: UIControlState())
        followButton.setImage(UIImage(named: "profileUnfollowButton"), for: .selected)
        followButton.layer.cornerRadius = 70.0/2.0
        followButton.clipsToBounds = true
        followButton.isEnabled = !isOwner
        rightSideHolder.addSubview(followButton)
        headerView.addSubview(rightSideHolder)

        messageButton.addTarget(self, action: #selector(self.messageUser), for: .touchUpInside)
        messageButton.setImage(UIImage(named: "profileMessageButton"), for: UIControlState())
        messageButton.setImage(UIImage(named: "profileMessageButtonHighlighted"), for: .highlighted)
        messageButton.isEnabled = !isOwner
        leftSideHolder.addSubview(messageButton)
        headerView.addSubview(leftSideHolder)

        segmentControl?.titleTextColor = Constants.UI.Color.tint
        segmentControl?.selectedTitleTextColor = RGB(255)
        segmentControl?.selectedTitleFont = UIFont.systemFont(ofSize: 15)
        segmentControl?.segmentIndicatorBackgroundColor = headerView.backgroundColor
        segmentControl?.backgroundColor = RGB(255)
        segmentControl?.borderWidth = 0.0
        segmentControl?.segmentIndicatorBorderWidth = 0.0
        segmentControl?.segmentIndicatorInset = 2.0
        segmentControl?.segmentIndicatorBorderColor = self.view.backgroundColor
        segmentControl?.usesSpringAnimations = true
        segmentControl?.addTarget(self, action: #selector(self.segmentDidChange), for: .valueChanged)

        let tap1 = UITapGestureRecognizer(target: self, action: #selector(viewUserFollowing))
        followingStatView.addGestureRecognizer(tap1)
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(viewUserFollowers))
        followersStatView.addGestureRecognizer(tap2)
        [commentsStatView, followersStatView, followingStatView, segmentControl].forEach({
            if let x = $0 {
                headerView.addSubview(x)
            }
        })

        tableView.delegate = self
        tableView.dataSource = self
        tableView.showsVerticalScrollIndicator = false
        tableView.backgroundColor = RGB(250, g: 251, b: 252)
        tableView.tableHeaderView = headerView
        tableView.registerReusableCell(UserCommentCell.self)
        tableView.registerReusableCell(SearchStreamCell.self)
        view.addSubview(tableView)

        registerForPreviewing(with: self, sourceView: tableView)

        NotificationCenter.default.addObserver(self, selector: #selector(self.fetchData), name: NSNotification.Name(rawValue: Constants.Notification.UpdateUserProfile), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.fetchData), name: NSNotification.Name(rawValue: Constants.Notification.DidLikeComment), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.fetchData), name: NSNotification.Name(rawValue: Constants.Notification.DidRepostComment), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.fetchData), name: NSNotification.Name(rawValue: Constants.Notification.DidPostComment), object: nil)

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

        fillUserData()
        fetchData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if isOwner {
            if let cUser = AppDelegate.del().currentUser {
                user = cUser
            }
        }

        segmentControl?.cornerRadius = (segmentControl?.frame.size.height)!/2.0
        avatarImageView.kf.setImage(with: user.profilePictureURL(), placeholder: UIImage(named: "defaultProfilePicture"))
        displayNameLabel.text = user.displayName
        descriptionLabel.text = user.description

        if let headerView = tableView.tableHeaderView {
            let height = headerView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
            var headerFrame = headerView.frame

            if height != headerFrame.size.height {
                headerFrame.size.height = height
                headerView.frame = headerFrame
                tableView.tableHeaderView = headerView
            }
        }

        scrollViewDidScroll(tableView)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.layer.shadowOpacity = 0.0
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if let headerView = tableView.tableHeaderView {
            let height = headerView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
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

        tableView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .bottom)
        tableView.autoPin(toBottomLayoutGuideOf: self, withInset: 0)

        avatarImageView.autoPinEdge(toSuperviewEdge: .top, withInset: 20)
        avatarImageView.autoAlignAxis(toSuperviewAxis: .vertical)
        NSLayoutConstraint.autoSetPriority(999) {
            self.avatarImageView.autoSetDimensions(to: CGSize(width: 140, height: 140))
        }

        leftSideHolder.autoAlignAxis(.horizontal, toSameAxisOf: avatarImageView)
        leftSideHolder.autoMatch(.height, to: .height, of: avatarImageView)
        leftSideHolder.autoPinEdge(.right, to: .left, of: avatarImageView)
        leftSideHolder.autoPinEdge(toSuperviewEdge: .left)

        messageButton.autoSetDimensions(to: CGSize(width: 70, height: 70))
        messageButton.autoAlignAxis(toSuperviewAxis: .horizontal)
        messageButton.autoAlignAxis(toSuperviewAxis: .vertical)

        rightSideHolder.autoAlignAxis(.horizontal, toSameAxisOf: avatarImageView)
        rightSideHolder.autoMatch(.height, to: .height, of: avatarImageView)
        rightSideHolder.autoPinEdge(.left, to: .right, of: avatarImageView)
        rightSideHolder.autoPinEdge(toSuperviewEdge: .right)

        followButton.autoSetDimensions(to: CGSize(width: 70, height: 70))
        followButton.autoAlignAxis(toSuperviewAxis: .horizontal)
        followButton.autoAlignAxis(toSuperviewAxis: .vertical)

        displayNameLabel.autoPinEdge(.top, to: .bottom, of: avatarImageView, withOffset: 15)
        displayNameLabel.autoSetDimension(.width, toSize: 250, relation: .lessThanOrEqual)
        displayNameLabel.autoAlignAxis(toSuperviewAxis: .vertical)

        descriptionLabelPadding = descriptionLabel.autoPinEdge(.top, to: .bottom, of: displayNameLabel, withOffset: 10)
        descriptionLabel.autoSetDimension(.width, toSize: 250, relation: .lessThanOrEqual)
        descriptionLabel.autoAlignAxis(toSuperviewAxis: .vertical)

        NSLayoutConstraint.autoSetPriority(999) {
            self.commentsStatView.autoPinEdge(.top, to: .bottom, of: self.descriptionLabel, withOffset: 15)
        }
        commentsStatView.autoPinEdge(toSuperviewEdge: .left)

        followersStatView.autoPinEdge(.top, to: .bottom, of: descriptionLabel, withOffset: 15)
        followersStatView.autoPinEdge(.left, to: .right, of: commentsStatView)
        followersStatView.autoMatch(.width, to: .width, of: commentsStatView)

        followingStatView.autoPinEdge(.top, to: .bottom, of: descriptionLabel, withOffset: 15)
        followingStatView.autoPinEdge(.left, to: .right, of: followersStatView)
        followingStatView.autoMatch(.width, to: .width, of: commentsStatView)
        followingStatView.autoPinEdge(toSuperviewEdge: .right)

        segmentControl?.autoPinEdge(.top, to: .bottom, of: commentsStatView, withOffset: 20)
        segmentControl?.autoPinEdge(toSuperviewEdge: .bottom, withInset: 10)
        segmentControl?.autoPinEdge(toSuperviewEdge: .left, withInset: 10)

        NSLayoutConstraint.autoSetPriority(999) {
            self.segmentControl?.autoPinEdge(toSuperviewEdge: .right, withInset: 10)
        }
    }

    func segmentDidChange() {
        self.tableView.reloadData()
    }

    // MARK: Table View Delegate

    override func tableViewCellClass(_ tableView: UITableView, indexPath: IndexPath?) -> KZTableViewCell.Type {
        let value = Int(segmentControl?.selectedSegmentIndex ?? 27)
        switch value {
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

    override func tableViewCellData(_ tableView: UITableView, section: Int) -> [Any] {
        let value = Int(segmentControl?.selectedSegmentIndex ?? 27)
        switch value {
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

    override func tableViewNoDataText(_ tableView: UITableView) -> String {
        let value = Int(segmentControl?.selectedSegmentIndex ?? 27)
        switch value {
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

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableViewCellData(tableView, section: indexPath.section).count == 0 {
            return 100
        }

        return UITableViewAutomaticDimension
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        super.tableView(tableView, didSelectRowAt: indexPath)

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

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        var shadowOffset = scrollView.contentOffset.y/72.0
        shadowOffset = min(shadowOffset, 1.0)

        //apply the offset and radius
        self.navigationController?.navigationBar.layer.shadowOffset = CGSize(width: 0, height: shadowOffset)
        self.navigationController?.navigationBar.layer.shadowRadius = 1.0
        self.navigationController?.navigationBar.layer.shadowColor = RGB(0).cgColor
        self.navigationController?.navigationBar.layer.shadowOpacity = shadowOffset == 0.0 ? 0.0 : 0.6
    }

    // MARK: UIViewController Previewing Delegate

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = tableView.indexPathForRow(at: location), let cell = tableView.cellForRow(at: indexPath) else {
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

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        if let vc = viewControllerToCommit as? PlayerViewController {
            vc.isPreviewing = false
            AppDelegate.del().presentStreamController(vc)
        } else {
            self.navigationController?.pushViewController(viewControllerToCommit, animated: true)
        }
    }

    // MARK: Handdle Data

    func fillUserData() {
        self.navigationItem.title = isOwner ? "My Profile (@\(user.username))" : "@\(user.username)'s Profile"
        descriptionLabel.text = user.description
        displayNameLabel.text = user.displayName
        followButton.isEnabled = !isOwner
        followButton.isSelected = user.isFollowing

        if descriptionLabel.text?.characters.count == 0 {
            descriptionLabelPadding?.constant = 0
        } else {
            descriptionLabelPadding?.constant = 10
        }
    }

    override func fetchData() {
        fetchDataWithCompletion(nil)
    }

    func fetchDataWithCompletion(_ completion: (() -> Void)?) {
        var count = 0

        func runCompletion() {
            count = count - 1
            if count == 0 {
                if let completion = completion {
                    completion()
                }
            }
        }

        count = count + 1
        Constants.Network.GET("/user/\(user.id)/stats", parameters: nil) { (response, error) -> Void in
            self.handleResponse(response as AnyObject?, error: error as NSError?, successCompletion: { (result) -> Void in
                guard let result = result as? JSON else {
                    return
                }

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
                    self.followButton.isSelected = isFollowing
                }

                if let isFollower = result["isFollower"] as? Bool {
                    self.messageButton.isEnabled = isFollower
                    self.messageButton.alpha = isFollower ? 1.0 : 0.4
                }
            })

            runCompletion()
        }

        count = count + 1
        Constants.Network.GET("/user/\(user.id)/comments", parameters: nil) { (response, error) -> Void in
            self.handleResponse(response as AnyObject?, error: error as NSError?, successCompletion: { (result) -> Void in
                self.comments.removeAll()

                guard let results = result as? [JSON] else {
                    return
                }

                let comments = [STMComment].from(jsonArray:results)
                comments?.forEach({ self.comments.append($0) })

                if self.segmentControl?.selectedSegmentIndex == 0 {
                    self.tableView.reloadData()
                }
            })

            runCompletion()
        }

        count = count + 1
        Constants.Network.GET("/user/\(user.id)/streams", parameters: nil) { (response, error) -> Void in
            self.handleResponse(response as AnyObject?, error: error as NSError?, successCompletion: { (result) -> Void in
                self.streams.removeAll()
                if let result = result as? [JSON] {
                    let streams = [STMStream].from(jsonArray:result)
                    streams?.forEach({ self.streams.append($0) })

                    if self.segmentControl?.selectedSegmentIndex == 1 {
                        self.tableView.reloadData()
                    }
                }
            })

            runCompletion()
        }

        count = count + 1
        Constants.Network.GET("/user/\(user.id)/likes", parameters: nil) { (response, error) -> Void in
            self.handleResponse(response as AnyObject?, error: error as NSError?, successCompletion: { (result) -> Void in
                self.likes.removeAll()
                if let result = result as? [JSON] {
                    let likes = [STMComment].from(jsonArray:result)
                    likes?.forEach({ self.likes.append($0) })

                    if self.segmentControl?.selectedSegmentIndex == 2 {
                        self.tableView.reloadData()
                    }
                }
            })

            runCompletion()
        }
    }

    // MARK: Handle Actions

    func editProfile() {
        let vc = ProfileSettingsViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }

    func toggleFollow() {
        let method = followButton.isSelected ? "unfollow" : "follow"
        UIView.transition(with: self.followButton, duration: 0.2, options: .transitionCrossDissolve, animations: {
            self.followButton.isSelected = !self.followButton.isSelected
        }, completion: nil)
        Constants.Network.GET("/user/\(user.id)/\(method)", parameters: nil) { (response, error) in
            DispatchQueue.main.async(execute: {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.Notification.UpdateUserProfile), object: nil)
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
                    if users.count == 2 && users.contains(where: { $0.id == user.id }) {
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
            hud?.frame = window.bounds
            window.addSubview(hud!)
        }
        hud?.progressViewSize = CGSize(width: 60, height: 60)
        hud?.animationPoint = CGPoint(x: (hud?.frame.size.width)! / 2, y: (hud?.frame.size.height)! / 2)
        hud?.applyBlurToBackground = true
        hud?.maskType = M13ProgressHUDMaskTypeIOS7Blur
        hud?.show(true)

        let nav = self.navigationController
        Constants.Network.POST("/conversation/create", parameters: ["users": [user.id, currentUser.id]], completionHandler: { (response, error) -> Void in
            self.handleResponse(response as AnyObject?, error: error as NSError?, successCompletion: { (result) in
                guard let result = result as? JSON else {
                    return
                }

                guard let convo = STMConversation(json: result) else {
                    return
                }

                let vc = ConversationViewController(convo: convo)
                nav?.pushViewController(vc, animated: false)

                hud?.hide(true)
                }, errorCompletion: { (errorString) in
                    hud?.hide(true)
            })
        })
    }

    func viewUserFollowing() {
        let vc = ProfileStatsListViewController(user: user, type: .following)
        self.navigationController?.pushViewController(vc, animated: true)
    }

    func viewUserFollowers() {
        let vc = ProfileStatsListViewController(user: user, type: .followers)
        self.navigationController?.pushViewController(vc, animated: true)
    }

}
