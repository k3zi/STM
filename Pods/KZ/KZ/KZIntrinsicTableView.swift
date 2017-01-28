//
//  KZIntrinsicTableView.swift
//  KZ
//
//  Created by Kesi Maduka on 1/25/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit

open class KZIntrinsicTableView: UITableView {

    override open var intrinsicContentSize : CGSize {
        self.layoutIfNeeded()
        return CGSize(width: UIViewNoIntrinsicMetric, height: self.contentSize.height)
    }

    override open func endUpdates() {
        super.endUpdates()
        self.invalidateIntrinsicContentSize()
    }
    
    override open func reloadData() {
        super.reloadData()
        self.invalidateIntrinsicContentSize()
    }
    
    override open func reloadRows(at indexPaths: [IndexPath], with animation: UITableViewRowAnimation) {
        super.reloadRows(at: indexPaths, with: animation)
        self.invalidateIntrinsicContentSize()
    }
    
    override open func reloadSections(_ sections: IndexSet, with animation: UITableViewRowAnimation) {
        super.reloadSections(sections, with: animation)
        self.invalidateIntrinsicContentSize()
    }
    
    override open func insertRows(at indexPaths: [IndexPath], with animation: UITableViewRowAnimation) {
        super.insertRows(at: indexPaths, with: animation)
        self.invalidateIntrinsicContentSize()
    }
    
    override open func insertSections(_ sections: IndexSet, with animation: UITableViewRowAnimation) {
        super.insertSections(sections, with: animation)
        self.invalidateIntrinsicContentSize()
    }
    
    override open func deleteRows(at indexPaths: [IndexPath], with animation: UITableViewRowAnimation) {
        super.deleteRows(at: indexPaths, with: animation)
        self.invalidateIntrinsicContentSize()
    }
    
    override open func deleteSections(_ sections: IndexSet, with animation: UITableViewRowAnimation) {
        super.deleteSections(sections, with: animation)
        self.invalidateIntrinsicContentSize()
    }
    
}
