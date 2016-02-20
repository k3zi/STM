//
//  IntrinsicTableView.swift
//  Dawgtown
//
//  Created by Kesi Maduka on 1/7/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit

public class KZIntrinsicCollectionView: UICollectionView {

    override public func intrinsicContentSize() -> CGSize {
        self.layoutIfNeeded()
        return CGSize(width: UIViewNoIntrinsicMetric, height: self.collectionViewLayout.collectionViewContentSize().height + 12)
    }
    
    override public func reloadData() {
        super.reloadData()
        self.invalidateIntrinsicContentSize()
    }
}
