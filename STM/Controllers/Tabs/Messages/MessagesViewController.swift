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
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Messages"
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "navBarMessageBT"), style: .Plain, target: self, action: #selector(self.createNewMessage))

        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerReusableCell(ConvoCell)
        view.addSubview(tableView)

        registerForPreviewingWithDelegate(self, sourceView: tableView)

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

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.fetchData), name: Constants.Notification.DidPostMessage, object: nil)
    }

    func createNewMessage() {
        let vc = NewMessageViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }

    override func setupConstraints() {
        super.setupConstraints()

        tableView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero, excludingEdge: .Bottom)
        tableView.autoPinToBottomLayoutGuideOfViewController(self, withInset: 0)
    }

    override func tableViewCellData(tableView: UITableView, section: Int) -> [Any] {
        return convos
    }

    override func tableViewCellClass(tableView: UITableView, indexPath: NSIndexPath?) -> KZTableViewCell.Type {
        return ConvoCell.self
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
        Constants.Network.GET("/messages/list", parameters: nil) { (response, error) -> Void in
            self.handleResponse(response, error: error, successCompletion: { (result) -> Void in
                self.convos.removeAll()

                guard let results = result as? [JSON] else {
                    return
                }

                let convos = [STMConversation].fromJSONArray(results)
                convos.forEach({ self.convos.append($0) })

                self.tableView.reloadData()
            })

            runCompletion()
        }
    }

    override func tableViewNoDataText(tableView: UITableView) -> String {
        return "No Conversations"
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        super.tableView(tableView, didSelectRowAtIndexPath: indexPath)

        guard convos.count > indexPath.row else {
            return
        }

        if let convo = convos[indexPath.row] as? STMConversation {
            let vc = ConversationViewController(convo: convo)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    //MARK: UIViewController Previewing Delegate

    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = tableView.indexPathForRowAtPoint(location), cell = tableView.cellForRowAtIndexPath(indexPath) else {
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

    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        self.navigationController?.pushViewController(viewControllerToCommit, animated: true)
    }

}
