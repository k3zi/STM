//
//  DashboardViewController.swift
//  STM
//
//  Created by Kesi Maduka on 1/30/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit

class DashboardViewController: KZViewController, UIViewControllerPreviewingDelegate {
    let tableView = UITableView()
    var dashboardItems = [Any]()

    override func viewDidLoad() {
        super.viewDidLoad()

        if let window = AppDelegate.del().window as? Window {
            window.screenIsReady = true
        }

        self.title = "Dashboard"

        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerReusableCell(DashboardItemCell)
        view.addSubview(tableView)

        self.registerForPreviewingWithDelegate(self, sourceView: tableView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        tableView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero, excludingEdge: .Bottom)
        tableView.autoPinToBottomLayoutGuideOfViewController(self, withInset: 0)
    }

    override func tableViewCellData(tableView: UITableView, section: Int) -> [Any] {
        return dashboardItems
    }

    override func tableViewCellClass(tableView: UITableView, indexPath: NSIndexPath?) -> KZTableViewCell.Type {
        return DashboardItemCell.self
    }

    override func fetchData() {
        Constants.Network.GET("/dashboard", parameters: nil) { (response, error) -> Void in
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
        }
    }

    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard AppDelegate.del().activeStreamController == nil else {
            return nil
        }

        guard let indexPath = tableView.indexPathForRowAtPoint(location), cell = tableView.cellForRowAtIndexPath(indexPath) else {
            return nil
        }

        var vc: UIViewController? = KZViewController()
        previewingContext.sourceRect = cell.frame

        if let itemView = cell.hitTest(cell.convertPoint(location, fromView: tableView), withEvent: nil) {
            if let innerCell = itemView.superview as? DashboardItemCollectionCell {
                if let stream = innerCell.model as? STMStream {
                    let pVC = PlayerViewController()
                    pVC.isPreviewing = true
                    pVC.start(stream, vc: self, showHUD: false)
                    vc = pVC
                    previewingContext.sourceRect = view.convertRect(itemView.frame, fromView: innerCell)
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
        }
    }

}
