//
//  NewMessageViewController.swift
//  STM
//
//  Created by Kesi Maduka on 4/30/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import Foundation
import M13ProgressSuite

class NewMessageViewController: KZViewController, UISearchBarDelegate {

    let tableView = UITableView()
    let searchBar = UISearchBar()
    var searchResults = [Any]()
    var searchAttempt = 0

    var selectedUsers = [Int]()

    lazy var keynode: Keynode.Connector = Keynode.Connector(view: self.view)
    var tableViewBottomConstraint: NSLayoutConstraint?

    init() {
        super.init(nibName: nil, bundle: nil)
        self.hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "New Conversation"
        self.automaticallyAdjustsScrollViewInsets = false
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Next", style: .Plain, target: self, action: #selector(self.next))

        searchBar.delegate = self
        view.addSubview(searchBar)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsMultipleSelection = true
        tableView.registerReusableCell(UserSelectionCell)
        view.addSubview(tableView)

        keynode.animationsHandler = { [weak self] show, rect in
            guard let me = self else {
                return
            }

            if let con = me.tableViewBottomConstraint {
                con.constant = Constants.UI.Screen.keyboardAdjustment(show, rect: rect)
                me.view.layoutIfNeeded()
                me.tableView.reloadData()
            }
        }
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)

        self.view.endEditing(true)
    }

    override func setupConstraints() {
        super.setupConstraints()

        searchBar.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero, excludingEdge: .Bottom)

        tableView.autoPinEdge(.Top, toEdge: .Bottom, ofView: searchBar)
        tableView.autoPinEdgeToSuperviewEdge(.Left)
        tableView.autoPinEdgeToSuperviewEdge(.Right)
        tableViewBottomConstraint = tableView.autoPinToBottomLayoutGuideOfViewController(self, withInset: 0)
    }

    override func tableViewCellData(tableView: UITableView, section: Int) -> [Any] {
        return searchResults
    }

    override func tableViewCellClass(tableView: UITableView, indexPath: NSIndexPath?) -> KZTableViewCell.Type {
        return UserSelectionCell.self
    }

    override func tableViewNoDataText(tableView: UITableView) -> String {
        if let text = searchBar.text {
            if text.characters.count == 0 {
                return "Search for a user using the field above"
            }
        } else {
            return "Search for a user using the field above"
        }

        return super.tableViewNoDataText(tableView)
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard tableViewCellData(tableView, section: indexPath.section).count > 0 else {
            return
        }

        if let user = searchResults[indexPath.row] as? STMUser {
            selectedUsers.append(user.id)
            tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = .Checkmark
        }
    }

    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        guard tableViewCellData(tableView, section: indexPath.section).count > 0 else {
            return
        }

        if let user = searchResults[indexPath.row] as? STMUser {
            selectedUsers.removeObject(user.id)
            tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = .None
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)

        if let cell = cell as? UserSelectionCell, let user = searchResults[indexPath.row] as? STMUser {
            cell.accessoryType = selectedUsers.contains(user.id) ? .Checkmark : .None
        }

        return cell
    }

    // MARK: UISearchBar Delegate

    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }

    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        searchResults = [Any]()
        tableView.reloadData()

        guard let text = searchBar.text else {
            return
        }

        guard text.characters.count > 0 else {
            return
        }

        let attempt = searchAttempt + 1
        searchAttempt = attempt

        Constants.Network.POST("/search/followers", parameters: ["q": text]) { (response, error) in
            self.handleResponse(response, error: error, successCompletion: { (result) in
                if attempt == self.searchAttempt {
                    guard let results = result as? [[String: AnyObject]] else {
                        return
                    }

                    for item in results {
                        if let user = STMUser(json: item) {
                            self.searchResults.append(user)
                        }
                    }

                    self.tableView.reloadData()
                }
            })
        }
    }

    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchResults = [Any]()
        searchBar.text = ""
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
        tableView.reloadData()
    }

    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    func next() {
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
        nav?.popViewControllerAnimated(false)
        Constants.Network.POST("/messages/create", parameters: ["users": selectedUsers], completionHandler: { (response, error) -> Void in
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
}
