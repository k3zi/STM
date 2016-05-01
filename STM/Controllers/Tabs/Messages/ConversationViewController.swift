//
//  ConversationViewController.swift
//  STM
//
//  Created by Kesi Maduka on 4/29/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import Foundation
import DGElasticPullToRefresh

class ConversationViewController: KZViewController, MessageToolbarDelegate {

    let tableView = UITableView()
    let convo: STMConversation
    var messages = [Any]()

    lazy var keynode: Keynode.Connector = Keynode.Connector(view: self.view)
    var toolbarBottomConstraint: NSLayoutConstraint?
    let commentToolbar = MessageToolbarView()

    init(convo: STMConversation) {
        self.convo = convo
        super.init(nibName: nil, bundle: nil)
        self.hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        tableView.dg_removePullToRefresh()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = convo.listNames()
        self.automaticallyAdjustsScrollViewInsets = false
        if convo.users?.count == 2 {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "navBarUserBT"), style: .Plain, target: self, action: #selector(self.goToProfile))
        }

        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .None
        tableView.registerReusableCell(STMMessageYouCell)
        tableView.registerReusableCell(STMMessageOtherCell)
        view.addSubview(tableView)

        commentToolbar.delegate = self
        view.addSubview(commentToolbar)

        keynode.animationsHandler = { [weak self] show, rect in
            guard let me = self else {
                return
            }

            if let con = me.toolbarBottomConstraint {
                con.constant = Constants.UI.Screen.keyboardAdjustment(show, rect: rect)
                me.view.layoutIfNeeded()
            }
        }

        let loadingView = DGElasticPullToRefreshLoadingViewCircle()
        loadingView.tintColor = Constants.UI.Color.tint

        tableView.dg_addPullToRefreshWithActionHandler({ [weak self] () -> Void in
            if let me = self {
                me.fetchDataWithCompletion() {
                    me.tableView.dg_stopLoading()
                }
            }
            }, loadingView: loadingView)
        tableView.dg_setPullToRefreshFillColor(RGB(250, g: 251, b: 252))
    }

    func goToProfile() {
        if let users = convo.users {
            for user in users {
                if user.id != AppDelegate.del().currentUser?.id {
                    let vc = ProfileViewController(user: user)
                    self.navigationController?.pushViewController(vc, animated: true)
                    return
                }
            }
        }
    }

    /**
     Called on comment submit

     - parameter text: the text that was posted
     */
    func handlePost(text: String) {
        guard text.characters.count > 0 else {
            return
        }

        self.commentToolbar.sendBT.enabled = false
        Constants.Network.POST("/messages/\(convo.id)/send", parameters: ["text": text], completionHandler: { (response, error) -> Void in
            self.commentToolbar.sendBT.enabled = true
            self.handleResponse(response, error: error, successCompletion: { (result) -> Void in
                self.fetchDataWithCompletion({
                    self.tableView.scrollToBottom()
                })
                Answers.logCustomEventWithName("Message", customAttributes: [:])
                NSNotificationCenter.defaultCenter().postNotificationName(Constants.Notification.DidPostMessage, object: nil)
            })
        })

        view.endEditing(true)
    }

    func didBeginEditing() {
        tableView.scrollToBottom()
    }

    override func setupConstraints() {
        super.setupConstraints()

        tableView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero, excludingEdge: .Bottom)

        commentToolbar.autoPinEdge(.Top, toEdge: .Bottom, ofView: tableView)
        commentToolbar.autoPinEdgeToSuperviewEdge(.Left)
        commentToolbar.autoPinEdgeToSuperviewEdge(.Right)
        toolbarBottomConstraint = commentToolbar.autoPinToBottomLayoutGuideOfViewController(self, withInset: 0)
    }

    override func tableViewCellData(tableView: UITableView, section: Int) -> [Any] {
        return messages
    }

    override func tableViewCellClass(tableView: UITableView, indexPath: NSIndexPath?) -> KZTableViewCell.Type {
        if let message = tableViewCellData(tableView, section: indexPath!.section)[indexPath!.row] as? STMMessage {
            if let user = message.user {
                return user.id == AppDelegate.del().currentUser?.id ? STMMessageYouCell.self : STMMessageOtherCell.self
            }
        }

        return STMMessageYouCell.self
    }

    override func tableViewNoDataText(tableView: UITableView) -> String {
        return "No Messages"
    }

    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 50.0
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if messages.count > 0 {
            return UITableViewAutomaticDimension
        } else {
            return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
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
        Constants.Network.GET("/messages/\(convo.id)/list", parameters: nil) { (response, error) -> Void in
            self.handleResponse(response, error: error, successCompletion: { (result) -> Void in
                self.messages.removeAll()

                guard let results = result as? [JSON] else {
                    return
                }

                let messages = [STMMessage].fromJSONArray(results)
                messages.forEach({ self.messages.append($0) })

                self.tableView.reloadData()
                if self.tableView.layer.animationForKey("bounds") == nil {
                    self.tableView.scrollToBottom()
                }
                runCompletion()
            })
        }
    }

}
