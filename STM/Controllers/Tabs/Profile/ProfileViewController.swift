//
//  ProfileViewController.swift
//  STM
//
//  Created by Kesi Maduka on 4/27/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import Foundation

class ProfileViewController: KZViewController {

    var scrollView = UIScrollView()
    var contentView = UIView()

    let headerView = UIView()
    let avatarImageView = UIImageView()
    let displayNameLabel = UILabel()
    let descriptionLabel = UILabel()

    let commentsStatView = ProfileStatView(count: 0, name: "COMMENTS")
    let followersStatView = ProfileStatView(count: 0, name: "FOLLOWERS")
    let followingStatView = ProfileStatView(count: 0, name: "FOLLOWING")

    let tableView = KZIntrinsicTableView()

    let user: STMUser
    let isOwner: Bool

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

        scrollView.showsVerticalScrollIndicator = false
        scrollView.addSubview(contentView)
        view.addSubview(scrollView)

        avatarImageView.layer.cornerRadius = 140.0 / 9.0
        avatarImageView.backgroundColor = RGB(72, g: 72, b: 72)
        avatarImageView.clipsToBounds = true
        headerView.addSubview(avatarImageView)

        displayNameLabel.text = user.displayName
        headerView.addSubview(displayNameLabel)

        descriptionLabel.text = user.description
        headerView.addSubview(descriptionLabel)

        [commentsStatView, followersStatView, followingStatView].forEach({ headerView.addSubview($0) })

        contentView.addSubview(headerView)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = RGB(250, g: 251, b: 252)
        contentView.addSubview(tableView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        scrollView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero, excludingEdge: .Bottom)
        scrollView.autoPinToBottomLayoutGuideOfViewController(self, withInset: 0)

        contentView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)
        contentView.autoMatchDimension(.Width, toDimension: .Width, ofView: view)

        headerView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero, excludingEdge: .Bottom)

        avatarImageView.autoPinEdgeToSuperviewEdge(.Top, withInset: 20)
        avatarImageView.autoAlignAxisToSuperviewAxis(.Vertical)
        avatarImageView.autoSetDimensionsToSize(CGSize(width: 140, height: 140))

        displayNameLabel.autoPinEdge(.Top, toEdge: .Bottom, ofView: avatarImageView, withOffset: 15)
        displayNameLabel.autoSetDimension(.Width, toSize: 250, relation: .LessThanOrEqual)
        displayNameLabel.autoAlignAxisToSuperviewAxis(.Vertical)

        descriptionLabel.autoPinEdge(.Top, toEdge: .Bottom, ofView: displayNameLabel, withOffset: 10)
        descriptionLabel.autoSetDimension(.Width, toSize: 250, relation: .LessThanOrEqual)
        descriptionLabel.autoAlignAxisToSuperviewAxis(.Vertical)

        commentsStatView.autoPinEdge(.Top, toEdge: .Bottom, ofView: descriptionLabel, withOffset: 20)
        commentsStatView.autoPinEdgeToSuperviewEdge(.Left)
        commentsStatView.autoPinEdgeToSuperviewEdge(.Bottom, withInset: 20)

        followersStatView.autoPinEdge(.Top, toEdge: .Bottom, ofView: descriptionLabel, withOffset: 20)
        followersStatView.autoPinEdge(.Left, toEdge: .Right, ofView: commentsStatView)
        followersStatView.autoMatchDimension(.Width, toDimension: .Width, ofView: commentsStatView)

        followingStatView.autoPinEdge(.Top, toEdge: .Bottom, ofView: descriptionLabel, withOffset: 20)
        followingStatView.autoPinEdge(.Left, toEdge: .Right, ofView: followersStatView)
        followingStatView.autoMatchDimension(.Width, toDimension: .Width, ofView: commentsStatView)
        followingStatView.autoPinEdgeToSuperviewEdge(.Right)

        tableView.autoPinEdge(.Top, toEdge: .Bottom, ofView: headerView)
        tableView.autoPinEdgeToSuperviewEdge(.Left)
        tableView.autoPinEdgeToSuperviewEdge(.Right)
        tableView.autoPinEdgeToSuperviewEdge(.Bottom)
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

        return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
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
    }

}
