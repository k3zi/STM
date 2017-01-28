//
//  MessagesViewController.swift
//  STM
//
//  Created by Kesi Maduka on 4/29/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import Foundation
import DGElasticPullToRefresh

class MessagesViewController: KZViewController, UIViewControllerPreviewingDelegate {

    let tableView = UITableView()
    var convos = [Any]()

    deinit {
        tableView.dg_removePullToRefresh()
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Messages"
        self.automaticallyAdjustsScrollViewInsets = false

        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "navBarMessageBT"), style: .plain, target: self, action: #selector(self.createNewMessage))

        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerReusableCell(ConvoCell.self)
        view.addSubview(tableView)

        registerForPreviewing(with: self, sourceView: tableView)

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

        NotificationCenter.default.addObserver(self, selector: #selector(self.fetchData), name: NSNotification.Name(rawValue: Constants.Notification.DidPostMessage), object: nil)
        fetchData()
    }

    func createNewMessage() {
        let vc = NewMessageViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }

    override func setupConstraints() {
        super.setupConstraints()

        tableView.autoPin(toTopLayoutGuideOf: self, withInset: 0)
        tableView.autoPinEdge(toSuperviewEdge: .left)
        tableView.autoPinEdge(toSuperviewEdge: .right)
        tableView.autoPin(toBottomLayoutGuideOf: self, withInset: 0)
    }

    override func tableViewCellData(_ tableView: UITableView, section: Int) -> [Any] {
        return convos
    }

    override func tableViewCellClass(_ tableView: UITableView, indexPath: IndexPath?) -> KZTableViewCell.Type {
        return ConvoCell.self
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
        Constants.Network.GET("/conversation/list", parameters: nil) { (response, error) -> Void in
            self.handleResponse(response as AnyObject?, error: error as NSError?, successCompletion: { (result) -> Void in
                self.convos.removeAll()

                guard let results = result as? [JSON] else {
                    return
                }

                let convos = [STMConversation].fromJSONArray(results)
                var unreadCount = 0
                convos?.forEach({
                    unreadCount = unreadCount + $0.unreadCount
                    self.convos.append($0)
                })

                self.navigationController?.tabBarItem.badgeValue = unreadCount > 0 ? String(unreadCount) : nil
                self.tableView.reloadData()
                runCompletion()
            })
        }
    }

    override func tableViewNoDataText(_ tableView: UITableView) -> String {
        return "No Conversations"
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        super.tableView(tableView, didSelectRowAt: indexPath)

        guard tableViewCellData(tableView, section: indexPath.section).count > 0 else {
            return
        }

        if let convo = tableViewCellData(tableView, section: indexPath.section)[indexPath.row] as? STMConversation {
            if let badgeString = self.navigationController?.tabBarItem.badgeValue {
                var badgeInt = Int(badgeString) ?? 0
                badgeInt = badgeInt - convo.unreadCount
                self.navigationController?.tabBarItem.badgeValue = badgeInt > 0 ? String(badgeInt) : nil
                AppDelegate.del().updateServerBadgeCount(badgeInt)
            }

            let vc = ConversationViewController(convo: convo)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    // MARK: UIViewController Previewing Delegate

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = tableView.indexPathForRow(at: location), let cell = tableView.cellForRow(at: indexPath) else {
            return nil
        }

        guard convos.count > indexPath.row else {
            return nil
        }

        var vc: UIViewController?

        if let convo = convos[indexPath.row] as? STMConversation {
            vc = ConversationViewController(convo: convo)
        }

        if let vc = vc {
            vc.preferredContentSize = CGSize(width: 0.0, height: 0.0)
            previewingContext.sourceRect = cell.frame
        }

        return vc
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        self.navigationController?.pushViewController(viewControllerToCommit, animated: true)
    }

}
