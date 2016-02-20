//
//  BareboneViewController.swift
//  Dawgtown
//
//  Created by Kesi Maduka on 7/31/15.
//  Copyright (c) 2015 Storm Edge Apps LLC. All rights reserved.
//

import UIKit
import Reusable

public class KZViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var didSetConstraints = false
    public var isReady = false
    public var fetchAUtomatically = true
    public var fetchOnLoad = true
    public var didPresentVC = false
    
    var offscreenCells = [String: KZTableViewCell]()
    public var showsNoText = true
    
    var timer: NSTimer?
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.view.backgroundColor = UIColor.whiteColor()
        if fetchOnLoad {
            self.fetchData()
        }
    }
    
    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.view.setNeedsUpdateConstraints()
        
        didPresentVC = false
    }
    
    override public func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if timer == nil && fetchAUtomatically {
            timer = NSTimer.scheduledTimerWithTimeInterval(15.0, target: self, selector: Selector("fetchData"), userInfo: nil, repeats: true)
        }
    }
    
    override public func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        if timer != nil {
            timer?.invalidate()
            timer = nil
        }
    }
    
    override public func presentViewController(viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?) {
        super.presentViewController(viewControllerToPresent, animated: flag, completion: completion)
        didPresentVC = true
    }
    
    override public func updateViewConstraints() {
        if !didSetConstraints {
            setupConstraints()
            didSetConstraints = true
        }
        
        super.updateViewConstraints()
    }
    
    public func setupConstraints() {
        
    }
    
    public dynamic func fetchData() {
        
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    //MARK: Tableview Datasource/Delegate
    
    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.tableViewCellData(tableView, section: section).count == 0 && showsNoText {
            return 1
        }
        
        return self.tableViewCellData(tableView, section: section).count
    }
    
    public func tableViewCellClass(tableView: UITableView, indexPath: NSIndexPath? = nil) -> KZTableViewCell.Type {
        return KZTableViewCell.self
    }
    
    public func tableViewCellData(tableView: UITableView, section: Int) -> [Any] {
        return []
    }
    
    public func tableViewNoDataText(tableView: UITableView) -> String {
        return "No Results Found"
    }
    
    public func tableViewShowsSectionHeader(tableView: UITableView) -> Bool {
        return false
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if self.tableViewCellData(tableView, section: indexPath.section).count == 0 && showsNoText {
            let cell = UITableViewCell(style: .Default, reuseIdentifier: "NoneFound")
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.text = tableViewNoDataText(tableView)
            cell.textLabel?.font = UIFont.systemFontOfSize(20, weight: UIFontWeightLight)
            cell.textLabel?.textAlignment = .Center
            cell.textLabel?.textColor = UIColor.grayColor()
            cell.selectionStyle = .None
            tableView.userInteractionEnabled = false
            return cell
        }
        
        tableView.userInteractionEnabled = true
        let cellClass = tableViewCellClass(tableView, indexPath: indexPath)
        
        let cell = tableView.dequeueReusableCell(indexPath, cellType: cellClass)
        cell.setIndexPath(indexPath, last: indexPath.row == (self.tableView(tableView, numberOfRowsInSection: indexPath.section) - 1))
        if cell.tag != -1 {
            cell.setContent(tableViewCellData(tableView, section: indexPath.section)[indexPath.row])
        }
        cell.updateConstraintsIfNeeded()
        cell.layoutIfNeeded()
        
        return cell
    }
    
    public func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if self.tableViewCellData(tableView, section: indexPath.section).count == 0 && showsNoText {
            return tableView.frame.height
        }
        
        var cell = offscreenCells[String(tableViewCellClass(tableView, indexPath: indexPath))]
        if cell == nil {
            cell = tableViewCellClass(tableView, indexPath: indexPath).init(style: .Default, reuseIdentifier: String(tableView.tag))
            offscreenCells.updateValue(cell!, forKey: String(tableViewCellClass(tableView, indexPath: indexPath)))
        }
        
        cell!.setIndexPath(indexPath, last: (indexPath.row + 1) == tableViewCellData(tableView, section: indexPath.section).count)
        if cell!.tag != -1 {
            cell!.setContent(tableViewCellData(tableView, section: indexPath.section)[indexPath.row])
        }
        
        return cell!.getHeight()
    }
    
    public func tableView(_tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if cell.respondsToSelector("setSeparatorInset:") {
            cell.separatorInset = UIEdgeInsetsZero
        }
        
        if cell.respondsToSelector("setLayoutMargins:") {
            cell.layoutMargins = UIEdgeInsetsZero
        }
        
        if cell.respondsToSelector("setPreservesSuperviewLayoutMargins:") {
            cell.preservesSuperviewLayoutMargins = false
        }
    }
    
    //MARK: Section Header/Footer
    
    public func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if tableViewShowsSectionHeader(tableView) {
            let view = UIView(frame: CGRectMake(0.0, 0.0, self.view.frame.size.width, 20))
            view.backgroundColor = RGB(240)
            
            let label = UILabel(frame: view.bounds)
            label.font = UIFont.systemFontOfSize(16)
            label.text = self.tableView(tableView, titleForHeaderInSection: section)
            label.sizeToFit()
            label.frame.size.height = view.frame.size.height
            label.frame.origin.x = 18
            view.addSubview(label)
            
            let line1 = UIView(frame: CGRectMake(0, 0, view.frame.size.width, (1.0/UIScreen.mainScreen().scale)))
            line1.backgroundColor = RGB(217)
            view.addSubview(line1)
            
            let line2 = UIView(frame: CGRectMake(0, view.frame.size.height - 1, view.frame.size.width, (1.0/UIScreen.mainScreen().scale)))
            line2.backgroundColor = RGB(217)
            view.addSubview(line2)
            
            return view
        }
        
        return nil
    }
    
    public func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if tableViewShowsSectionHeader(tableView) {
            return "Pending"
        }
        
        return nil
    }
    
    public func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if tableViewShowsSectionHeader(tableView) {
            return 19.0
        }
        
        return CGFloat.min
    }
    
    public func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
        var x = [String]()
        if tableViewShowsSectionHeader(tableView) {
            for var i = 0; i < numberOfSectionsInTableView(tableView); i++ {
                if let s = self.tableView(tableView, titleForHeaderInSection: i) {
                    x.append(s)
                }
            }
            
            return x
        }
        
        return []
    }
    
    public func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.min
    }
    
    
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
}