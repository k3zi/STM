//
//  DashboardViewController.swift
//  STM
//
//  Created by Kesi Maduka on 1/30/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit
import DGElasticPullToRefresh

class DashboardViewController: KZViewController, UIViewControllerPreviewingDelegate {
    let tableView = UITableView()
    var dashboardItems = [Any]()
    var comments = [Any]()

    deinit {
        tableView.dg_removePullToRefresh()
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Dashboard"

        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerReusableCell(DashboardItemCell)
        tableView.registerReusableCell(UserCommentCell)

        self.registerForPreviewingWithDelegate(self, sourceView: tableView)
        view.addSubview(tableView)

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

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.fetchDataWithForce), name: Constants.Notification.DidLikeComment, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.fetchDataWithForce), name: Constants.Notification.DidRepostComment, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.fetchDataWithForce), name: Constants.Notification.DidPostComment, object: nil)
        fetchData()
    }

    override func setupConstraints() {
        super.setupConstraints()

        tableView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero, excludingEdge: .Bottom)
        tableView.autoPinToBottomLayoutGuideOfViewController(self, withInset: 0)
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    override func tableViewNoDataText(tableView: UITableView) -> String {
        return "\n\nHmmm... Seems Empty\nSearch for streams/users in the search tab below to get started!"
    }

    override func tableViewCellData(tableView: UITableView, section: Int) -> [Any] {
        if section == 0 {
            return dashboardItems
        } else {
            return comments
        }
    }

    override func tableViewCellClass(tableView: UITableView, indexPath: NSIndexPath?) -> KZTableViewCell.Type {
        if indexPath?.section == 0 {
            return DashboardItemCell.self
        } else {
            return UserCommentCell.self
        }
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        super.tableView(tableView, didSelectRowAtIndexPath: indexPath)

        guard indexPath.section == 1 else {
            return
        }

        guard tableViewCellData(tableView, section: indexPath.section).count > 0 else {
            return
        }

        if let comment = tableViewCellData(tableView, section: indexPath.section)[indexPath.row] as? STMComment {
            let vc = CommentViewController(comment: comment)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    override func fetchData() {
        fetchDataWithCompletion()
    }

    func fetchDataWithForce() {
        fetchDataWithCompletion(true, completion: nil)
    }

    func fetchDataWithCompletion(force: Bool = false, completion: (() -> Void)? = nil) {
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
        Constants.Network.GET("/dashboard/items", parameters: nil) { (response, error) -> Void in
            self.handleResponse(response, error: error, successCompletion: { (result) -> Void in
                self.dashboardItems.removeAll()
                if let result = result as? [JSON] {
                    let items = [STMDashboardItem].fromJSONArray(result)
                    items.forEach({
                        if $0.items?.count > 0 {
                            self.dashboardItems.append($0)
                        }
                    })

                    self.tableView.reloadData()
                }
            })

            runCompletion()
        }

        count = count + 1
        Constants.Network.GET("/dashboard/timeline", parameters: nil) { (response, error) -> Void in
            self.handleResponse(response, error: error, successCompletion: { (result) -> Void in
                guard let results = result as? [JSON] else {
                    return
                }

                let comments = [STMComment].fromJSONArray(results)
                var didSwipeOut = false
                if let oldComments = self.comments as? [STMComment] {
                    if oldComments.count == comments.count {
                        for i in 0..<self.comments.count {
                            self.comments[i] = comments[i]
                        }

                        if let indexPaths = self.tableView.indexPathsForVisibleRows {
                            self.tableView.reloadRowsAtIndexPaths(indexPaths, withRowAnimation: .None)
                            didSwipeOut = true
                        }
                    }
                }

                if !didSwipeOut {
                    self.comments.removeAll()
                    comments.forEach({ self.comments.append($0) })
                    self.tableView.reloadData()
                }

                if let window = AppDelegate.del().window as? Window {
                    window.screenIsReady = true
                }
            })

            runCompletion()
        }
    }

    //MARK: UIViewController Previewing Delegate

    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = tableView.indexPathForRowAtPoint(location), cell = tableView.cellForRowAtIndexPath(indexPath) else {
            return nil
        }

        var vc: UIViewController?
        previewingContext.sourceRect = cell.frame

        if indexPath.section == 0 {
            if let itemView = cell.hitTest(cell.convertPoint(location, fromView: tableView), withEvent: nil) {
                if let innerCell = itemView.superview as? DashboardItemCollectionCell {
                    if let stream = innerCell.model as? STMStream {
                        guard AppDelegate.del().activeStreamController == nil else {
                            return nil
                        }

                        let pVC = PlayerViewController()
                        pVC.isPreviewing = true
                        pVC.start(stream, vc: self, showHUD: false)
                        vc = pVC
                        previewingContext.sourceRect = view.convertRect(itemView.frame, fromView: innerCell)
                    }
                }
            }
        } else if indexPath.section == 1 {
            if comments.count > indexPath.row {
                if let comment = comments[indexPath.row] as? STMComment {
                    vc = CommentViewController(comment: comment)
                }
            }
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

}
