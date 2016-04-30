//
//  ProfileViewController.swift
//  STM
//
//  Created by Kesi Maduka on 4/27/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import Foundation

class ProfileViewController: KZViewController {

    let headerView = UIView()
    let avatarImageView = UIImageView()
    let displayNameLabel = UILabel()
    let descriptionLabel = UILabel()
    let rightSideHolder = UIView()
    let followButton = UIButton()

    let commentsStatView = ProfileStatView(count: 0, name: "COMMENTS")
    let followersStatView = ProfileStatView(count: 0, name: "FOLLOWERS")
    let followingStatView = ProfileStatView(count: 0, name: "FOLLOWING")

    let tableView = KZIntrinsicTableView()

    let user: STMUser
    let isOwner: Bool

    var comments = [Any]()

    init(user: STMUser, isOwner: Bool = false) {
        self.user = user
        self.isOwner = isOwner
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = isOwner ? "My Profile (@\(user.username))" : "@\(user.username)"
        self.automaticallyAdjustsScrollViewInsets = false
        if isOwner {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: .Plain, target: self, action: #selector(self.editProfile))
        }

        avatarImageView.layer.cornerRadius = 140.0 / 9.0
        avatarImageView.backgroundColor = RGB(72, g: 72, b: 72)
        avatarImageView.clipsToBounds = true
        headerView.addSubview(avatarImageView)

        displayNameLabel.text = user.displayName
        headerView.addSubview(displayNameLabel)

        descriptionLabel.text = user.description
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

        [commentsStatView, followersStatView, followingStatView].forEach({ headerView.addSubview($0) })

        tableView.delegate = self
        tableView.dataSource = self
        tableView.showsVerticalScrollIndicator = false
        tableView.backgroundColor = RGB(250, g: 251, b: 252)
        tableView.tableHeaderView = headerView
        tableView.registerReusableCell(UserCommentCell)
        view.addSubview(tableView)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.fetchData), name: Constants.Notification.UpdateUserProfile, object: nil)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        avatarImageView.kf_setImageWithURL(user.profilePictureURL(), placeholderImage: UIImage(named: "defaultProfilePicture"))
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
            self.commentsStatView.autoPinEdge(.Top, toEdge: .Bottom, ofView: self.descriptionLabel, withOffset: 20)
        }
        commentsStatView.autoPinEdgeToSuperviewEdge(.Left)
        commentsStatView.autoPinEdgeToSuperviewEdge(.Bottom, withInset: 20)

        followersStatView.autoPinEdge(.Top, toEdge: .Bottom, ofView: descriptionLabel, withOffset: 20)
        followersStatView.autoPinEdge(.Left, toEdge: .Right, ofView: commentsStatView)
        followersStatView.autoMatchDimension(.Width, toDimension: .Width, ofView: commentsStatView)

        followingStatView.autoPinEdge(.Top, toEdge: .Bottom, ofView: descriptionLabel, withOffset: 20)
        followingStatView.autoPinEdge(.Left, toEdge: .Right, ofView: followersStatView)
        followingStatView.autoMatchDimension(.Width, toDimension: .Width, ofView: commentsStatView)
        followingStatView.autoPinEdgeToSuperviewEdge(.Right)
    }

    //MARK: Table View Delegate

    override func tableViewCellClass(tableView: UITableView, indexPath: NSIndexPath?) -> KZTableViewCell.Type {
        return UserCommentCell.self
    }

    override func tableViewCellData(tableView: UITableView, section: Int) -> [Any] {
        return comments
    }

    override func tableViewNoDataText(tableView: UITableView) -> String {
        if isOwner {
            return "You haven't posted anything :("
        } else {
            return "This user hasn't posted anything"
        }
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if tableViewCellData(tableView, section: indexPath.section).count == 0 {
            return 100
        }

        return UITableViewAutomaticDimension
    }

    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 50.0
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        super.tableView(tableView, didSelectRowAtIndexPath: indexPath)

        if indexPath.section == 1 {
            if let comment = comments[indexPath.row] as? STMComment {
                let vc = CommentViewController(comment: comment)
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }

    //MARK: UIViewController Previewing Delegate

    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = tableView.indexPathForRowAtPoint(location), cell = tableView.cellForRowAtIndexPath(indexPath) else {
            return nil
        }

        var vc: UIViewController? = KZViewController()
        previewingContext.sourceRect = cell.frame

        if let comment = comments[indexPath.row] as? STMComment {
            vc = CommentViewController(comment: comment)
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
        Constants.Network.GET("/stats/user/\(user.id)", parameters: nil) { (response, error) -> Void in
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
            })
        }

        Constants.Network.GET("/comments/user/\(user.id)", parameters: nil) { (response, error) -> Void in
            self.handleResponse(response, error: error, successCompletion: { (result) -> Void in
                self.comments.removeAll()

                guard let results = result as? [JSON] else {
                    return
                }

                let comments = [STMComment].fromJSONArray(results)
                comments.forEach({ self.comments.append($0) })

                self.tableView.reloadData()
            })
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
        Constants.Network.GET("/\(method)/\(user.id)", parameters: nil) { (response, error) in
            dispatch_async(dispatch_get_main_queue(), {
                NSNotificationCenter.defaultCenter().postNotificationName(Constants.Notification.UpdateUserProfile, object: nil)
            })
        }
    }

}
