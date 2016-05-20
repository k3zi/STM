//
//  ProfileStatsViewController.swift
//  STM
//
//  Created by Kesi Maduka on 5/5/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import Foundation

enum ProfileStatsType {
    case Followers
    case Following
}

class ProfileStatsListViewController: KZViewController {

    let tableView = UITableView()
    let type: ProfileStatsType
    let user: STMUser

    var users = [Any]()

    init(user: STMUser, type: ProfileStatsType) {
        self.type = type
        self.user = user
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "@\(user.username)'s \(self.navigationItemTitle())"

        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerReusableCell(SearchUserCell)
        tableView.backgroundColor = UIColor.whiteColor()
        view.addSubview(tableView)
    }

    func navigationItemTitle() -> String {
        switch self.type {
            case .Followers:
                return "Followers"
            case .Following:
                return "Following"
        }
    }

    func apiMethod() -> String {
        switch self.type {
        case .Followers:
            return "followers"
        case .Following:
            return "following"
        }
    }

    override func setupConstraints() {
        super.setupConstraints()

        tableView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero, excludingEdge: .Bottom)
        tableView.autoPinToBottomLayoutGuideOfViewController(self, withInset: 0)
    }

    override func tableViewCellData(tableView: UITableView, section: Int) -> [Any] {
        return users
    }

    override func tableViewCellClass(tableView: UITableView, indexPath: NSIndexPath? = nil) -> KZTableViewCell.Type {
        return SearchUserCell.self
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        super.tableView(tableView, didSelectRowAtIndexPath: indexPath)

        guard tableViewCellData(tableView, section: indexPath.section).count > 0 else {
            return
        }

        if let user = tableViewCellData(tableView, section: indexPath.section)[indexPath.row] as? STMUser {
            let vc = ProfileViewController(user: user, isOwner: AppDelegate.del().currentUser?.id == user.id)
            self.navigationController?.pushViewController(vc, animated: true)
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
        Constants.Network.GET("/user/\(user.id)/\(apiMethod())", parameters: nil) { (response, error) -> Void in
            self.handleResponse(response, error: error, successCompletion: { (result) -> Void in
                self.users.removeAll()
                if let result = result as? [JSON] {
                    let users = [STMUser].fromJSONArray(result)
                    users.forEach({ self.users.append($0) })
                    self.tableView.reloadData()
                }
            })

            runCompletion()
        }
    }

}
