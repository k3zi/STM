//
//  KZIntrinsicTableView.swift
//  KZ
//
//  Created by Kesi Maduka on 1/25/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit

public class KZIntrinsicTableView: UITableView {

    override public func intrinsicContentSize() -> CGSize {
        self.layoutIfNeeded()
        return CGSize(width: UIViewNoIntrinsicMetric, height: self.contentSize.height)
    }

    override public func endUpdates() {
        super.endUpdates()
        self.invalidateIntrinsicContentSize()
    }
    
    override public func reloadData() {
        super.reloadData()
        self.invalidateIntrinsicContentSize()
    }
    
    override public func reloadRowsAtIndexPaths(indexPaths: [NSIndexPath], withRowAnimation animation: UITableViewRowAnimation) {
        super.reloadRowsAtIndexPaths(indexPaths, withRowAnimation: animation)
        self.invalidateIntrinsicContentSize()
    }
    
    override public func reloadSections(sections: NSIndexSet, withRowAnimation animation: UITableViewRowAnimation) {
        super.reloadSections(sections, withRowAnimation: animation)
        self.invalidateIntrinsicContentSize()
    }
    
    override public func insertRowsAtIndexPaths(indexPaths: [NSIndexPath], withRowAnimation animation: UITableViewRowAnimation) {
        super.insertRowsAtIndexPaths(indexPaths, withRowAnimation: animation)
        self.invalidateIntrinsicContentSize()
    }
    
    override public func insertSections(sections: NSIndexSet, withRowAnimation animation: UITableViewRowAnimation) {
        super.insertSections(sections, withRowAnimation: animation)
        self.invalidateIntrinsicContentSize()
    }
    
    override public func deleteRowsAtIndexPaths(indexPaths: [NSIndexPath], withRowAnimation animation: UITableViewRowAnimation) {
        super.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: animation)
        self.invalidateIntrinsicContentSize()
    }
    
    override public func deleteSections(sections: NSIndexSet, withRowAnimation animation: UITableViewRowAnimation) {
        super.deleteSections(sections, withRowAnimation: animation)
        self.invalidateIntrinsicContentSize()
    }
    
}
