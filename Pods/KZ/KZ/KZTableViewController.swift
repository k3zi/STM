//
//  TableViewController.swift
//  Dawgtown
//
//  Created by Kesi Maduka on 7/31/15.
//  Copyright (c) 2015 Storm Edge Apps LLC. All rights reserved.
//

import UIKit

public class KZTableViewController: KZViewController {
    
    public var tableView: UITableView? = nil
    public var items = [Any]()
    public var ct = true
    
    //MARK: Setup View
    
    public convenience init(createTable: Bool) {
        self.init()
        self.ct = createTable
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        if ct {
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
        
        if ct {
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
