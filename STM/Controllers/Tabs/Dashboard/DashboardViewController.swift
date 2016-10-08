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
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Dashboard"
        self.automaticallyAdjustsScrollViewInsets = true

        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerReusableCell(DashboardItemCell.self)
        tableView.registerReusableCell(UserCommentCell.self)

        self.registerForPreviewing(with: self, sourceView: tableView)
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

        NotificationCenter.default.addObserver(self, selector: #selector(fetchDataWithForce), name: NSNotification.Name(rawValue: Constants.Notification.DidLikeComment), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(fetchDataWithForce), name: NSNotification.Name(rawValue: Constants.Notification.DidRepostComment), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(fetchDataWithForce), name: NSNotification.Name(rawValue: Constants.Notification.DidPostComment), object: nil)
        fetchData()
    }

    override func setupConstraints() {
        super.setupConstraints()

        tableView.autoPinEdge(toSuperviewEdge: .left)
        tableView.autoPinEdge(toSuperviewEdge: .right)
        tableView.autoPinEdge(toSuperviewEdge: .top)
        tableView.autoPin(toBottomLayoutGuideOf: self, withInset: 0)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableViewNoDataText(_ tableView: UITableView) -> String {
        return "\n\nHmmm... Seems Empty\nSearch for streams/users in the search tab below to get started!"
    }

    override func tableViewCellData(_ tableView: UITableView, section: Int) -> [Any] {
        if section == 0 {
            return dashboardItems
        } else {
            return comments
        }
    }

    override func tableViewCellClass(_ tableView: UITableView, indexPath: IndexPath?) -> KZTableViewCell.Type {
        if indexPath?.section == 0 {
            return DashboardItemCell.self
        } else {
            return UserCommentCell.self
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        super.tableView(tableView, didSelectRowAt: indexPath)

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

    func fetchDataWithCompletion(_ force: Bool = false, completion: (() -> Void)? = nil) {
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
            self.handleResponse(response as AnyObject?, error: error as NSError?, successCompletion: { (result) -> Void in
                self.dashboardItems.removeAll()
                if let result = result as? [JSON] {
                    let items = [STMDashboardItem].fromJSONArray(result)
                    items?.forEach({
                        if ($0.items?.count)! > 0 {
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
            self.handleResponse(response as AnyObject?, error: error as NSError?, successCompletion: { (result) -> Void in
                guard let results = result as? [JSON] else {
                    return
                }

                let comments = [STMComment].fromJSONArray(results)
                var didSwipeOut = false
                if let oldComments = self.comments as? [STMComment] {
                    if oldComments.count == comments?.count {
                        for i in 0..<self.comments.count {
                            self.comments[i] = comments?[i]
                        }

                        if let indexPaths = self.tableView.indexPathsForVisibleRows {
                            self.tableView.reloadRows(at: indexPaths, with: .none)
                            didSwipeOut = true
                        }
                    }
                }

                if !didSwipeOut {
                    self.comments.removeAll()
                    comments?.forEach({ self.comments.append($0) })
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

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = tableView.indexPathForRow(at: location), let cell = tableView.cellForRow(at: indexPath) else {
            return nil
        }

        var vc: UIViewController?
        previewingContext.sourceRect = cell.frame

        if indexPath.section == 0 {
            if let itemView = cell.hitTest(cell.convert(location, from: tableView), with: nil) {
                if let innerCell = itemView.superview as? DashboardItemCollectionCell {
                    if let stream = innerCell.model as? STMStream {
                        guard AppDelegate.del().activeStreamController == nil else {
                            return nil
                        }

                        let pVC = PlayerViewController()
                        pVC.isPreviewing = true
                        pVC.start(stream, vc: self, showHUD: false)
                        vc = pVC
                        previewingContext.sourceRect = view.convert(itemView.frame, from: innerCell)
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

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        if let vc = viewControllerToCommit as? PlayerViewController {
            vc.isPreviewing = false
            AppDelegate.del().presentStreamController(vc)
        } else {
            self.navigationController?.pushViewController(viewControllerToCommit, animated: true)
        }
    }

}
