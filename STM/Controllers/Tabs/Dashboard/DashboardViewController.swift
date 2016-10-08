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
    let tableView = UITableView(frame: .zero, style: .grouped)
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
        self.view.backgroundColor = Constants.UI.Color.tint4

        let titleView = UIImageView(image: #imageLiteral(resourceName: "navBarLogo"))
        self.navigationItem.titleView = titleView

        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerReusableCell(FeaturedStreamCell.self)
        tableView.registerReusableCell(UserCommentCell.self)
        tableView.backgroundColor = UIColor.clear
        tableView.separatorInset = UIEdgeInsets(top: 2, left: 0, bottom: 2, right: 0)
        tableView.separatorColor = UIColor.clear
        view.addSubview(tableView)

        self.registerForPreviewing(with: self, sourceView: tableView)

        let loadingView = DGElasticPullToRefreshLoadingViewCircle()
        loadingView.tintColor = Constants.UI.Color.tint2

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

        tableView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 0, bottom: 2, right: 0))
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return dashboardItems.count
    }

    override func tableViewNoDataText(_ tableView: UITableView) -> String {
        return "\n\nHmmm... Seems Empty\nSearch for streams/users in the search tab below to get started!"
    }

    override func tableViewCellData(_ tableView: UITableView, section: Int) -> [Any] {
        return (dashboardItems[section] as? STMDashboardItem)?.items ?? []
    }

    override func tableViewCellClass(_ tableView: UITableView, indexPath: IndexPath?) -> KZTableViewCell.Type {
        return FeaturedStreamCell.self
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

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let item = (dashboardItems[section] as? STMDashboardItem)
        let view = UIView()
        let headerLabel = UILabel.styledForDashboardHeader(item?.name ?? "")

        view.addSubview(headerLabel)

        headerLabel.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 10, left: 12, bottom: 8, right: 12))

        return view
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let view = self.tableView(tableView, viewForHeaderInSection: section)
        return view?.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height ?? 52
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
            count = count - 1
            if count == 0 {
                if let completion = completion {
                    completion()
                }

                if let window = AppDelegate.del().window as? Window {
                    window.screenIsReady = true
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
