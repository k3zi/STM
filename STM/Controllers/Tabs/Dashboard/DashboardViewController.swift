//
//  DashboardViewController.swift
//  STM
//
//  Created by Kesi Maduka on 1/30/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit

class DashboardViewController: KZViewController {
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
                    items.forEach({ self.dashboardItems.append($0) })
                    self.tableView.reloadData()
                }
            })
        }
    }
}
