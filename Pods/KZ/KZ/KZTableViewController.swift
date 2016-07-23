//
//  KZTableViewController.swift
//  KZ
//
//  Created by Kesi Maduka on 1/25/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit

public class KZTableViewController: KZViewController {

    public var tableView: UITableView? = nil
    public var items = [Any]()
    public var createTable = true

    //MARK: Setup View

    public convenience init(createTable: Bool) {
        self.init()
        self.createTable = createTable
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        if createTable {
            tableView = UITableView(frame: view.bounds, style: .Grouped)
            tableView!.delegate = self
            tableView!.dataSource = self
            tableView?.separatorStyle = .None
            tableView?.showsVerticalScrollIndicator = false
            tableView?.sectionIndexBackgroundColor = RGB(224)
            tableView?.sectionIndexColor = RGB(103)
            view.addSubview(tableView!)
        }
    }

    override public func setupConstraints() {
        super.setupConstraints()

        if createTable {
            tableView!.autoPinToTopLayoutGuideOfViewController(self, withInset: 0.0)
            tableView!.autoPinEdgeToSuperviewEdge(.Left)
            tableView!.autoPinEdgeToSuperviewEdge(.Right)
            tableView!.autoPinEdgeToSuperviewEdge(.Bottom)
        }
    }

    public override func tableViewCellData(tableView: UITableView, section: Int) -> [Any] {
        return items
    }
}

public struct TableSection {
    public var sectionName: String
    public var sectionObjects: [Any]

    public init(sectionName: String, sectionObjects: [Any]) {
        self.sectionName = sectionName
        self.sectionObjects = sectionObjects
    }
}
